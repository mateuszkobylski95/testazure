resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}
resource "azurerm_virtual_network" "this" {
  name                = "${var.resource_group_name}-vnet"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  address_space = ["10.0.0.0/16"]
}
resource "azurerm_subnet" "this" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name

  address_prefixes = ["10.0.1.0/24"]
}
resource "azurerm_network_security_group" "this" {
  name                = "${var.resource_group_name}-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}
resource "azurerm_network_security_rule" "ssh" {
  name                        = "allow-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"

  source_port_range           = "*"
  destination_port_range      = "22"

  source_address_prefix       = "*"
  destination_address_prefix  = "*"

  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name
}
resource "azurerm_network_security_rule" "http" {
  name                        = "allow-http"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"

  source_port_range           = "*"
  destination_port_range      = "80"

  source_address_prefix       = "*"
  destination_address_prefix  = "*"

  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name
}
resource "azurerm_network_security_rule" "https" {
  name                        = "allow-https"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"

  source_port_range           = "*"
  destination_port_range      = "443"

  source_address_prefix       = "*"
  destination_address_prefix  = "*"

  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name
}
resource "azurerm_network_security_rule" "wireguard" {
  name                        = "allow-wireguard"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"

  source_port_range           = "*"
  destination_port_range      = "51820"

  source_address_prefix       = "*"
  destination_address_prefix  = "*"

  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name
}
resource "azurerm_public_ip" "this" {
  name                = "${var.resource_group_name}-pip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  allocation_method = "Static"

  sku = "Standard"

  domain_name_label = lower(var.resource_group_name)
}
resource "azurerm_network_interface" "this" {
  name                = "${var.resource_group_name}-nic"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"

    public_ip_address_id = azurerm_public_ip.this.id
  }
}
resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}
resource "azurerm_linux_virtual_machine" "this" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  size = var.vm_size

  admin_username = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.this.id
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
