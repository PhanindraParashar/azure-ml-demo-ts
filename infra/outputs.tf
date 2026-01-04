output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "location" {
  value = azurerm_resource_group.rg.location
}

output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "storage_containers" {
  value = [for c in azurerm_storage_container.containers : c.name]
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

output "log_analytics_workspace_name" {
  value = azurerm_log_analytics_workspace.law.name
}

output "app_insights_name" {
  value = azurerm_application_insights.appi.name
}

output "aml_workspace_name" {
  value = azurerm_machine_learning_workspace.aml.name
}

output "acr_name" {
  value       = var.enable_acr ? azurerm_container_registry.acr[0].name : null
  description = "Null unless enable_acr = true"
}

output "synapse_workspace_name" {
  value       = var.enable_synapse_workspace ? azurerm_synapse_workspace.synapse[0].name : null
  description = "Synapse workspace name"
}

output "synapse_workspace_id" {
  value       = var.enable_synapse_workspace ? azurerm_synapse_workspace.synapse[0].id : null
  description = "Synapse workspace ID"
}

output "synapse_storage_account_name" {
  value       = var.enable_synapse_workspace ? azurerm_storage_account.synapse_datalake[0].name : null
  description = "Data Lake Gen2 storage account name for Synapse"
}

# --- Additions for .env generation ---

output "subscription_id" {
  value       = var.subscription_id
  description = "Azure subscription ID used by this deployment"
}

output "synapse_datalake_account_name" {
  value       = var.enable_synapse_workspace ? azurerm_storage_account.synapse_datalake[0].name : ""
  description = "ADLS Gen2 account name backing Synapse (empty if Synapse disabled)"
}

output "synapse_filesystem" {
  value       = var.enable_synapse_workspace ? azurerm_storage_data_lake_gen2_filesystem.synapse_fs[0].name : ""
  description = "ADLS Gen2 filesystem (container) name for Synapse (empty if disabled)"
}