# Core variables
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
  description = "Environment name for tagging/naming (e.g., dev, staging, prod)."
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

# AML (Azure Machine Learning) variables
variable "enable_aml_compute_cluster" {
  description = "Create AML compute cluster (min_nodes=0). Default is true."
  type        = bool
  default     = true
}

# AML compute SKU - must be supported by AML + region.
# Note: VM quota is enforced by family (e.g., DSv2 family includes both Standard_DS1_v2 and Standard_D1_v2).
# B-series may be supported depending on region/workspace policies.
# Common options: Standard_F2s_v2 (FSv2), Standard_E2s_v3 (Ev3), Standard_B2s (BS), Standard_D2as_v5 (Dasv5), Standard_A2_v2 (Av2).
variable "aml_compute_vm_size" {
  description = "VM size for AML compute cluster. Must be from a VM family with available quota (D/DS, E, F, B, A series are commonly supported)."
  type        = string
  default     = "Standard_F2s_v2"
}

variable "aml_compute_max_nodes" {
  description = "Max nodes for AML compute cluster."
  type        = number
  default     = 1
}

variable "aml_compute_min_nodes" {
  description = "Min nodes for AML compute cluster."
  type        = number
  default     = 0
}

variable "aml_compute_idle_time_before_scale_down" {
  description = "Idle time before scale down for AML compute cluster (ISO 8601 duration format, e.g., PT3M)."
  type        = string
  default     = "PT3M"
}

# Storage variables
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

variable "synapse_allowed_ips" {
  type        = list(string)
  description = "Public client IPs allowed to access Synapse (Studio + Serverless SQL)."
  default     = []
}

variable "synapse_allow_azure_services" {
  type        = bool
  description = "Allow Azure services/resources to access Synapse via firewall special rule (0.0.0.0)."
  default     = true
}

# Optional toggles
variable "enable_acr" {
  description = "Create Azure Container Registry (useful for custom images). Disabled by default (enable_acr=false)."
  type        = bool
  default     = false
}
