variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "environment" {
  description = "Environnement (ex: dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Région Azure (ex: francecentral, westeurope)"
  type        = string
  default     = "francecentral"
}

variable "resource_group_name" {
  description = "Nom du Resource Group EXISTANT (fourni par l'organisation)"
  type        = string
}

variable "postgres_admin_user" {
  description = "Utilisateur admin Postgres (ex: citus)"
  type        = string
  default     = "citus"
}

variable "postgres_admin_password" {
  description = "Mot de passe admin Postgres (ne pas commit)"
  type        = string
  sensitive   = true
}
