resource "azurerm_container_app" "this" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment_id
  revision_mode                = "Single"

  template {
    container {
      name   = "pipeline"
      image  = var.image
      cpu    = var.cpu
      memory = var.memory
    }

    min_replicas = 0
    max_replicas = 1
  }
}