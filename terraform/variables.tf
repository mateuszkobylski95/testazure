variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "polandcentral"
}
variable "vm_name" {
  type = string
  default = null
}

variable "vm_size" {
  type    = string
  default = "Standard_B2ats_v2"
}
variable "ssh_public_key" {
  type = string
  default = null
}
variable "create_vm" {
  type    = bool
  default = true
}
