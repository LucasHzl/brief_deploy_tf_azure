data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
  numeric = true
}

locals {
  prefix = "${var.project_name}-${var.environment}"
  prefix_safe = lower(
    trim(
      replace(local.prefix, "_", "-"),
      "-"
    )
  )

  # base sans tirets/underscores, lowercase
  storage_base = lower(replace(replace("${var.project_name}${var.environment}", "-", ""), "_", ""))

  # Storage account name constraints:
  # - 3-24 chars
  # - storage_base + 6 random chars
  storage_account_name = substr("${local.storage_base}${random_string.suffix.result}", 0, 24)

  acr_name = substr(
    lower(replace(replace("${var.project_name}${var.environment}${random_string.suffix.result}", "-", ""), "_", "")),
    0,
    50
  )

  pg_cluster_name = "cpg-${local.prefix_safe}-${random_string.suffix.result}"

  log_analytics_name = "law-${local.prefix_safe}"

  cae_name = "cae-${local.prefix_safe}"

  app_base = substr(local.prefix_safe, 0, 20)

  container_app_name = "ca-${local.app_base}"
}

module "storage" {
  source = "./modules/storage"

  resource_group_name  = data.azurerm_resource_group.this.name
  location             = data.azurerm_resource_group.this.location
  storage_account_name = local.storage_account_name

  raw_container_name       = "raw"
  processed_container_name = "processed"
}

module "acr" {
  source = "./modules/acr"

  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  acr_name            = local.acr_name
}

module "cosmos_postgres" {
  source = "./modules/cosmos_postgres"

  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  cluster_name   = local.pg_cluster_name
  admin_user     = var.postgres_admin_user
  admin_password = var.postgres_admin_password
}

module "log_analytics" {
  source = "./modules/log_analytics"

  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  workspace_name      = local.log_analytics_name
}

module "container_apps_env" {
  source = "./modules/container_apps_env"

  resource_group_name        = data.azurerm_resource_group.this.name
  location                   = data.azurerm_resource_group.this.location
  env_name                   = local.cae_name
  log_analytics_workspace_id = module.log_analytics.id
}

module "container_app" {
  source = "./modules/container_app"

  name                         = local.container_app_name
  resource_group_name          = data.azurerm_resource_group.this.name
  container_app_environment_id = module.container_apps_env.id

  image  = "${module.acr.login_server}/nyc-taxi-pipeline:latest"
  cpu    = 0.5
  memory = "1Gi"
}