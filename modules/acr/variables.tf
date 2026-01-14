variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "acr_name" {
  description = "Nom du Azure Container Registry (globalement unique)"
  type        = string
}
