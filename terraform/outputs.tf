output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "public_ip" {
  value = var.create_vm ? azurerm_public_ip.this[0].ip_address : null
}

output "azure_fqdn" {
  value = var.create_vm ? azurerm_public_ip.this[0].fqdn : null
}

output "vm_name" {
  value = var.create_vm ? azurerm_linux_virtual_machine.this[0].name : null
}
output "azure_subnet" {
  value = azurerm_subnet.this.address_prefixes[0]
}
