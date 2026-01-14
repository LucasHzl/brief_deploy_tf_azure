resource "azurerm_storage_account" "this" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
  location            = var.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_container" "raw" {
  name                  = var.raw_container_name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "processed" {
  name                  = var.processed_container_name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}
