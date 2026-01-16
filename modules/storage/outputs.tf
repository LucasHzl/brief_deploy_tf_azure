output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "raw_container_name" {
  value = azurerm_storage_container.raw.name
}

output "processed_container_name" {
  value = azurerm_storage_container.processed.name
}

output "storage_connection_string" {
  value     = azurerm_storage_account.this.primary_connection_string
  sensitive = true
}

output "connection_string" {
  description = "Connection string du Storage Account (Blob)"
  value       = azurerm_storage_account.this.primary_connection_string
  sensitive   = true
}