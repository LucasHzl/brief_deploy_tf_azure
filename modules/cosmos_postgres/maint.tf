resource "azurerm_cosmosdb_postgresql_cluster" "this" {
  name                = var.cluster_name
  resource_group_name = var.resource_group_name
  location            = var.location

  administrator_login_password = var.admin_password

  coordinator_public_ip_access_enabled = true
  coordinator_server_edition           = "BurstableMemoryOptimized"
  node_server_edition                  = "MemoryOptimized"
  coordinator_vcore_count              = 1
  coordinator_storage_quota_in_mb      = 32768

  node_count = 0
}

resource "azurerm_cosmosdb_postgresql_firewall_rule" "azure_services" {
  name       = "allow-azure-services"
  cluster_id = azurerm_cosmosdb_postgresql_cluster.this.id

  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
