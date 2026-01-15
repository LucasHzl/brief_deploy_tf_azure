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

output "acr_login_server" {
  value = module.acr.login_server
}

output "acr_admin_username" {
  value = module.acr.admin_username
}

output "acr_admin_password" {
  value     = module.acr.admin_password
  sensitive = true
}

output "postgres_host" {
  value = module.cosmos_postgres.host
}

output "postgres_port" {
  value = module.cosmos_postgres.port
}

output "postgres_db" {
  value = module.cosmos_postgres.db
}

output "postgres_user" {
  value = module.cosmos_postgres.user
}