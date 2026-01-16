variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "container_app_environment_id" { type = string }

variable "image" { type = string }

variable "cpu" { type = number }
variable "memory" { type = string }

variable "registry_server" {
  type = string
}

variable "registry_username" {
  type = string
}

variable "registry_password" {
  type      = string
  sensitive = true
}

variable "env" {
  type = map(string)
}

variable "secret_values" {
  description = "Map des secrets (nom_secret_aca -> valeur)"
  type        = map(string)
  sensitive   = true
}

variable "secret_env_map" {
  description = "Map des env vars (NOM_ENV_APP -> nom_secret_aca)"
  type        = map(string)
}