resource "azurerm_public_ip" "this" {
  count = var.create_vm ? 1 : 0
  name                = "${var.resource_group_name}-pip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  allocation_method = "Static"

  sku = "Standard"

  domain_name_label = lower(var.resource_group_name)
}
resource "azurerm_network_interface" "this" {
  count = var.create_vm ? 1 : 0
  name                = "${var.resource_group_name}-nic"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"

    public_ip_address_id = azurerm_public_ip.this[0].id
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  count = var.create_vm ? 1 : 0
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  size = var.vm_size

  admin_username = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.this[0].id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}
