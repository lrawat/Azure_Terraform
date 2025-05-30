terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0.0"
    }
  }
}


provider "azurerm" {
  features {}
  client_id = var.client_id
  client_secret = var.client_secret
  subscription_id = var.subscription_id
  tenant_id = var.tenant_id

}

resource "azurerm_resource_group" "rc_gp" {
  name     = "terraform_traingroup-1"
  location = var.location
}
resource "azurerm_storage_account" "sibatf2" {
  name                     = "sibatf2"
  resource_group_name      = azurerm_resource_group.rc_gp.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  depends_on = [ azurerm_resource_group.rc_gp] 
  
}

resource "azurerm_storage_container" "data1" {
  name                  = "data1"
  storage_account_id    = azurerm_storage_account.sibatf2.id
  container_access_type = "private"
  depends_on = [ azurerm_storage_account.sibatf2, azurerm_resource_group.rc_gp ]
}

resource "azurerm_storage_blob" "ctfile1" {
  name                   = "ctfile1"
  storage_account_name   = azurerm_storage_account.sibatf2.name
  storage_container_name = azurerm_storage_container.data1.name
  type                   = "Block"
  source                 = "sample.txt"
  depends_on = [ azurerm_storage_container.data1]
}

resource "azurerm_virtual_network" "appnet" {
  name                = "appnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rc_gp.name
  depends_on = [ azurerm_resource_group.rc_gp ]
  
}
resource "azurerm_subnet" "subnet1" {
  name                 = "subnet-web"
  resource_group_name  = azurerm_resource_group.rc_gp.name
  virtual_network_name = azurerm_virtual_network.appnet.name
  address_prefixes     =  ["10.0.1.0/24"]
  depends_on = [ azurerm_virtual_network.appnet]
}
resource "azurerm_subnet" "subnet2" {
  name                 = "subnet-db"
  resource_group_name  = azurerm_resource_group.rc_gp.name
  virtual_network_name = azurerm_virtual_network.appnet.name
  address_prefixes     = ["10.0.2.0/24"]
  
}
resource "azurerm_public_ip" "public_ip" {
  name               = "vm_public_ip"
  location           = var.location
  resource_group_name = azurerm_resource_group.rc_gp.name
  allocation_method   = "Dynamic"

}
resource "azurerm_network_interface" "azinterface" {
  name                = "azinterface"
  location =  var.location
  resource_group_name = azurerm_resource_group.rc_gp.name
  ip_configuration {
    name                         = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}
resource "azurerm_availability_set" "sibaavset" {
    name = "sibaavset"
    resource_group_name          = azurerm_resource_group.rc_gp.name
    location                     = var.location
    platform_fault_domain_count  = 3
    platform_update_domain_count = 3
    depends_on =  [azurerm_resource_group.rc_gp]
  
}
resource "azurerm_windows_virtual_machine" "sibatestvm" {
  name                = "sibatestvm"
  resource_group_name = azurerm_resource_group.rc_gp.name
  location            = var.location
  size                = "Standard_B2ms"
  admin_username      = "adminuser"
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.azinterface.id,
  ]
  availability_set_id = azurerm_availability_set.sibaavset.id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  depends_on = [ azurerm_network_interface.azinterface, azurerm_public_ip.public_ip, azurerm_subnet.subnet1, azurerm_resource_group.rc_gp, azurerm_availability_set.sibaavset]
}
resource "azurerm_network_security_group" "nsg_rule" {
  name = "nsg_rule"
  location = var.location
  resource_group_name = azurerm_resource_group.rc_gp.name

security_rule {
    name                       = "nsg_rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
}

resource "azurerm_network_interface_security_group_association" "nic_attach" {
  network_interface_id = azurerm_network_interface.azinterface.id
  network_security_group_id = azurerm_network_security_group.nsg_rule.id

  depends_on = [ azurerm_network_security_group.nsg_rule, azurerm_network_interface.azinterface, azurerm_resource_group.rc_gp  ]
  
}
