output "resource_group_name" {
  value = data.azurerm_resource_group.this.name
}

output "resource_group_location" {
  value = data.azurerm_resource_group.this.location
}

output "name_prefix" {
  value = local.prefix
}

output "random_suffix" {
  value = random_string.suffix.result
}

output "storage_account_name" {
  value = module.storage.storage_account_name
}

output "raw_container_name" {
  value = module.storage.raw_container_name
}

output "processed_container_name" {
  value = module.storage.processed_container_name
}
