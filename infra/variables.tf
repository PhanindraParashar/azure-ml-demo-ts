variable "subscription_id" {
  description = "Azure subscription ID (DO NOT commit real value to git)."
  type        = string
}

variable "location" {
  description = "Azure region for resources."
  type        = string
  default     = "germanywestcentral"
}

variable "project_name" {
  description = "Short project slug used in naming."
  type        = string
  default     = "demo-azure-ml"
}

variable "environment" {
  description = "Environment name for tagging/naming (single-env friendly)."
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "Common tags applied to resources."
  type        = map(string)
  default = {
    owner   = "phani"
    project = "demo-azure-ml"
    env     = "prod"
    iac     = "terraform"
  }
}

# Optional toggles (keep defaults cost-safe)
variable "enable_acr" {
  description = "Create Azure Container Registry (useful for custom images)."
  type        = bool
  default     = false
}

variable "enable_aml_compute_cluster" {
  description = "Create AML compute cluster (min_nodes=0). Keep false by default."
  type        = bool
  default     = false
}

# AML compute SKU - must be supported by AML + region.
# Start with DS1_v2 (small CPU) and change if your workspace doesn't support it.
variable "aml_compute_vm_size" {
  description = "VM size for AML compute cluster."
  type        = string
  default     = "Standard_DS1_v2"
}

variable "aml_compute_max_nodes" {
  description = "Max nodes for AML compute cluster."
  type        = number
  default     = 1
}

variable "storage_containers" {
  description = "Blob containers for project."
  type        = list(string)
  default     = ["data", "models", "artifacts", "tmp"]
}

# Synapse workspace configuration
variable "enable_synapse_workspace" {
  description = "Create Azure Synapse Analytics workspace with serverless SQL pool (pay-as-you-go)."
  type        = bool
  default     = true
}

variable "synapse_sql_admin_login" {
  description = "SQL admin login for Synapse workspace."
  type        = string
  sensitive   = true
}

variable "synapse_sql_admin_password" {
  description = "SQL admin password for Synapse workspace."
  type        = string
  sensitive   = true
}

