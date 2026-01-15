variable "resource_group_name" { type = string }
variable "location" { type = string }

variable "cluster_name" { type = string }

variable "admin_user" { type = string }
variable "admin_password" {
  type      = string
  sensitive = true
}
