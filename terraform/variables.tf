variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "polandcentral"
}
variable "vm_name" {
  type = string
  default = ""
}

variable "vm_size" {
  type    = string
  default = "Standard_B2ats_v2"
}
variable "ssh_public_key" {
  type = string
  default = ""
}
variable "single_domain_mode" {
  type    = bool
  default = false
}

variable "public_ports" {
  type    = list(number)
  default = []

  validation {
    condition = alltrue([
      for port in var.public_ports :
      port >= 1 && port <= 65535
    ])
    error_message = "Public ports must be between 1 and 65535."
  }
}
