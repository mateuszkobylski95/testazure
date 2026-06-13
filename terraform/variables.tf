variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "polandcentral"
}
variable "vm_name" {
  type = string
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}
variable "ssh_public_key" {
  type = string
}
