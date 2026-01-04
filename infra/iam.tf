############################################
# DATA-PLANE RBAC FOR YOUR CURRENT IDENTITY
############################################
# This grants your signed-in identity the ability to read blobs from the "sa"
# and write blobs/files into the Synapse ADLS Gen2 storage.

# Current identity details (already defined in main.tf)
# data "azurerm_client_config" "current" {}

# READ from source blob storage account (dazmlstor...)
resource "azurerm_role_assignment" "me_blob_read_source" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = data.azurerm_client_config.current.object_id
}

# WRITE to ADLS Gen2 storage account used by Synapse (dazmldl...)
resource "azurerm_role_assignment" "me_blob_write_datalake" {
  count                = var.enable_synapse_workspace ? 1 : 0
  scope                = azurerm_storage_account.synapse_datalake[0].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

