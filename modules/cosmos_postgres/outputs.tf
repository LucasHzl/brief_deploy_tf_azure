output "host" {
  value = azurerm_cosmosdb_postgresql_cluster.this.servers[0].fqdn
}

output "port" {
  value = 5432
}

output "db" {
  value = "citus"
}

output "user" {
  value = var.admin_user
}
