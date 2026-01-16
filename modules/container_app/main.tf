resource "azurerm_container_app" "this" {
  name                         = var.name
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment_id
  revision_mode                = "Single"

  # Auth au registry privé (ACR)
  registry {
    server               = var.registry_server
    username             = var.registry_username
    password_secret_name = "acr-password"
  }

  # Secret pour le password ACR
  secret {
    name  = "acr-password"
    value = var.registry_password
  }

  # Secrets applicatifs (noms ACA safe: lowercase + '-')
  dynamic "secret" {
    for_each = var.secret_values
    content {
      name  = secret.key
      value = secret.value
    }
  }

  template {
    container {
      name   = "pipeline"
      image  = var.image
      cpu    = var.cpu
      memory = var.memory

      # Env vars non sensibles (valeurs en clair)
      dynamic "env" {
        for_each = var.env
        content {
          name  = env.key
          value = env.value
        }
      }

      # Env vars sensibles (env app -> secret ACA)
      dynamic "env" {
        for_each = var.secret_env_map
        content {
          name        = env.key
          secret_name = env.value
        }
      }
    }

    min_replicas = 0
    max_replicas = 1
  }
}