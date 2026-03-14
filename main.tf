terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0" # Optional: pin to a specific major version
    }
  }
}

# The provider block configures the specified provider
provider "azurerm" {
  features {}
  client_id       = "9ecf9177-3e15-418e-ba75-0dbc35fbc1fa"
  client_secret   = "E588Q~njBuG-67ed0LyL5jmD1oJU7P305-jRVdwR"
  tenant_id       = "a9f4b704-5abf-44ad-aa7a-81ac52764712"
  subscription_id = "46916665-00ee-498a-8ac3-e3ddc9ed41a4"
}


resource "azurerm_resource_group" "app" {
  name     = "terraazinfrarg"
  location = "eastus"
}



resource "azurerm_virtual_network" "packvnet" {
  name                = "packervnet"
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  address_space       = ["10.70.0.0/16"]
  dns_servers         = ["10.70.0.4", "10.70.0.5"]

  tags = {
    env = "Development"
  }
}

resource "azurerm_subnet" "packsub" {
  name                 = "packersubnet"
  resource_group_name  = azurerm_resource_group.app.name
  virtual_network_name = azurerm_virtual_network.packvnet.name
  address_prefixes     = ["10.70.1.0/24"]

}

resource "azurerm_network_security_group" "packsg" {
  name                = "packersg"
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name

  security_rule {
    name                       = "packallowall"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

   tags = {
    environment = "Production"
  }
}

/*
resource "azurerm_public_ip" "main" {
  name                = "packpip"
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  allocation_method   = "Static"
}
*/

resource "azurerm_network_interface" "app" {
  count               = 3
  name                = "nic-app-${count.index}"
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.packsub.id
    private_ip_address_allocation = "Dynamic"
    #public_ip_address_id          = azurerm_public_ip.main.id
  }
}

resource "azurerm_linux_virtual_machine" "app" {
  count               = 3
  name                = "vm-app-${count.index}"
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  size                =  "Standard_D2s_v3"
  admin_username      = "adminuser"
  admin_password      = "Ashokgani@123"
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.app[count.index].id]
  
  /*
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
*/

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 30
  }

  # Reference the custom image from the gallery
   source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = {
    Environment  = "production"
    ImageVersion = "1.0.0"
  }
}


