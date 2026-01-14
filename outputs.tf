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
