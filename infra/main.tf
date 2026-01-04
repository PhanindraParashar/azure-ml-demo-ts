locals {
  # Keep names consistent and Azure-friendly
  name_prefix = lower(replace("${var.project_name}-${var.environment}", "_", "-"))

  # Resource group + AML workspace allow hyphens
  resource_group_name = "${local.name_prefix}-rg"
  aml_workspace_name  = "${local.name_prefix}-ws"

  # Log Analytics + AppInsights names
  log_analytics_name  = "${local.name_prefix}-law"
  app_insights_name   = "${local.name_prefix}-ai"

  # Key Vault name rules: 3-24 chars, alphanumeric + hyphen, must start with letter.
  # We'll use a compact prefix + random suffix to keep under length.
  key_vault_base = "dazml-kv"
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
  numeric = true

  # Keepers ensure the random string is deterministic
  # It will only change if these values change
  keepers = {
    subscription_id = var.subscription_id
    project_name    = var.project_name
    environment     = var.environment
    location        = var.location
  }
}

# Storage account name rules:
# - 3-24 chars
# - lowercase letters and numbers only
# - globally unique
locals {
  storage_account_name = substr("dazmlstor${random_string.suffix.result}", 0, 24)

  # ACR name rules are stricter (alphanumeric, 5-50, no hyphens)
  acr_name = lower(replace("dazmlacr${random_string.suffix.result}", "-", ""))

  # Data Lake Gen2 storage account for Synapse (requires hierarchical namespace)
  synapse_storage_account_name = substr("dazmldl${random_string.suffix.result}", 0, 24)
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.location
  tags     = var.tags
}

# Storage Account
resource "azurerm_storage_account" "sa" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # cost & security sensible defaults
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"

  # public network access enabled by default for learning simplicity
  # (you can lock down later with private endpoints)
  public_network_access_enabled = true

  tags = var.tags
}

# Blob Containers
resource "azurerm_storage_container" "containers" {
  for_each              = toset(var.storage_containers)
  name                  = each.value
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = local.log_analytics_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # keep costs controlled; can tune later
  sku               = "PerGB2018"
  retention_in_days = 30

  tags = var.tags
}

# Application Insights (workspace-based)
resource "azurerm_application_insights" "appi" {
  name                = local.app_insights_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"

  workspace_id = azurerm_log_analytics_workspace.law.id

  tags = var.tags
}

# Key Vault
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                = "${local.key_vault_base}-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tenant_id = data.azurerm_client_config.current.tenant_id
  sku_name  = "standard"

  # For learning, keep RBAC enabled; manage access with role assignments later if you want.
  enable_rbac_authorization = true

  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  tags = var.tags
}

# Optional: Azure Container Registry (disabled by default)
resource "azurerm_container_registry" "acr" {
  count               = var.enable_acr ? 1 : 0
  name                = local.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false

  tags = var.tags
}

# Azure Machine Learning Workspace
resource "azurerm_machine_learning_workspace" "aml" {
  name                = local.aml_workspace_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  application_insights_id = azurerm_application_insights.appi.id
  key_vault_id            = azurerm_key_vault.kv.id
  storage_account_id      = azurerm_storage_account.sa.id

  # If ACR is enabled, link it; otherwise omit.
  container_registry_id = var.enable_acr ? azurerm_container_registry.acr[0].id : null

  # Keep public access for learning; later you can move to private networking.
  public_network_access_enabled = true

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

#############################
# OPTIONAL AML COMPUTE CLUSTER
#############################
# This is a safe way: min_nodes=0 => no cost when idle.
# Keep it off by default (enable_aml_compute_cluster=false).

resource "azurerm_machine_learning_compute_cluster" "cpu_small" {
  count                        = var.enable_aml_compute_cluster ? 1 : 0
  name                         = "${local.name_prefix}-cpu-small"
  location                     = azurerm_resource_group.rg.location
  machine_learning_workspace_id = azurerm_machine_learning_workspace.aml.id

  vm_size     = var.aml_compute_vm_size
  vm_priority = "Dedicated"

  scale_settings {
    min_node_count                       = 0
    max_node_count                       = var.aml_compute_max_nodes
    scale_down_nodes_after_idle_duration = "PT5M"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

#############################
# AZURE SYNAPSE WORKSPACE
#############################
# Creates a serverless (pay-as-you-go) Synapse workspace
# No dedicated pools are created by default - uses serverless SQL pool

# Data Lake Gen2 Storage Account for Synapse (requires hierarchical namespace)
resource "azurerm_storage_account" "synapse_datalake" {
  count                    = var.enable_synapse_workspace ? 1 : 0
  name                     = local.synapse_storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  # Enable hierarchical namespace for Data Lake Gen2
  is_hns_enabled = true

  # Security settings
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"
  public_network_access_enabled   = true

  tags = var.tags
}

# Data Lake Gen2 Filesystem for Synapse workspace
resource "azurerm_storage_data_lake_gen2_filesystem" "synapse_fs" {
  count              = var.enable_synapse_workspace ? 1 : 0
  name               = "synapse"
  storage_account_id = azurerm_storage_account.synapse_datalake[0].id
}

# Synapse Workspace
resource "azurerm_synapse_workspace" "synapse" {
  count                = var.enable_synapse_workspace ? 1 : 0
  name                 = "${local.name_prefix}-synapse"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location

  # Storage account for Synapse workspace data (Data Lake Gen2)
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapse_fs[0].id

  # SQL admin credentials
  sql_administrator_login         = var.synapse_sql_admin_login
  sql_administrator_login_password = var.synapse_sql_admin_password

  # Managed identity for Synapse
  identity {
    type = "SystemAssigned"
  }

  # Public network access (can be disabled later for security)
  public_network_access_enabled = true

  # No dedicated SQL pools - using serverless (default)
  # The serverless SQL pool is automatically available and pay-as-you-go

  tags = var.tags
}

# Grant Synapse workspace managed identity access to Data Lake Gen2 storage
resource "azurerm_role_assignment" "synapse_storage" {
  count                = var.enable_synapse_workspace ? 1 : 0
  scope                = azurerm_storage_account.synapse_datalake[0].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.synapse[0].identity[0].principal_id
}

