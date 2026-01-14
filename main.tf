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

  # Storage Account naming constraints:
  # - lowercase only
  # - 3-24 chars
  # - letters and numbers only
  storage_account_name = lower(replace(replace("${var.project_name}${var.environment}${random_string.suffix.result}", "-", ""), "_", ""))
}

module "storage" {
  source = "./modules/storage"

  resource_group_name  = data.azurerm_resource_group.this.name
  location             = data.azurerm_resource_group.this.location
  storage_account_name = local.storage_account_name

  raw_container_name       = "raw"
  processed_container_name = "processed"
}
