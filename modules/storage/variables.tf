variable "resource_group_name" { type = string }
variable "location" { type = string }

variable "storage_account_name" {
  description = "Nom du Storage Account (doit être globalement unique et en lowercase)"
  type        = string
}

variable "raw_container_name" {
  type    = string
  default = "raw"
}

variable "processed_container_name" {
  type    = string
  default = "processed"
}
