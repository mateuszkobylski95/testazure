output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "public_ip" {
  value = azurerm_public_ip.this.ip_address
}

output "azure_fqdn" {
  value = azurerm_public_ip.this.fqdn
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.this.name
}

output "azure_subnet" {
  value = azurerm_subnet.this.address_prefixes[0]
}
