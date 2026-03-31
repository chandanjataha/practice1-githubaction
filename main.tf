terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.66.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}
variable "subscription_id" {

}
#-------------------------------------
resource "azurerm_resource_group" "az-rg" {
  name     = "prod-rg-01"
  location = "Central India"
}

resource "azurerm_virtual_network" "az-vnet" {
  name                = "prod-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.az-rg.location
  resource_group_name = azurerm_resource_group.az-rg.name
}

resource "azurerm_subnet" "az-subnet" {
  name                 = "subnet"
  resource_group_name  = azurerm_resource_group.az-rg.name
  virtual_network_name = azurerm_virtual_network.az-vnet.name
  address_prefixes     = ["10.0.2.0/26"]
}

resource "azurerm_public_ip" "az-pip" {
  name                = "prod-pip-02"
  resource_group_name = azurerm_resource_group.az-rg.name
  location            = azurerm_resource_group.az-rg.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface" "az-nic" {
  name                = "example-nic"
  location            = azurerm_resource_group.az-rg.location
  resource_group_name = azurerm_resource_group.az-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.az-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.az-pip.id
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  name                            = "prod-vm-01"
  resource_group_name             = azurerm_resource_group.az-rg.name
  location                        = azurerm_resource_group.az-rg.location
  size                            = "Standard_D2s_v3"
  admin_username                  = "adminuser"
  admin_password                  = "Password@123"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.az-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
