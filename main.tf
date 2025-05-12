provider "azurerm" {
  features {}
}

resource "azurerm_marketplace_agreement" "redhat" {
  publisher = "redhat"
  offer     = "rhel-byos"
  plan      = var.product_map[var.rhel_version]
}

resource "azurerm_resource_group" "tfrg" {
  name     = "shadowman-terraform-rg"
  location = "East US"
}

resource "azurerm_virtual_network" "tfvn" {
  name                = "shadowman-terraform-vnet"
  location            = azurerm_resource_group.tfrg.location
  resource_group_name = azurerm_resource_group.tfrg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "tfsubnet" {
  name                 = "shadowman-terraform-subnet"
  resource_group_name  = azurerm_resource_group.tfrg.name
  virtual_network_name = azurerm_virtual_network.tfvn.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "tfpubip" {
  count               = var.number_of_instances
  name                = "shadowman-terraform-public-ip${count.index}"
  location            = azurerm_resource_group.tfrg.location
  resource_group_name = azurerm_resource_group.tfrg.name
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "tfnsg" {
  name                = "shadowman-terraform-nsg"
  location            = azurerm_resource_group.tfrg.location
  resource_group_name = azurerm_resource_group.tfrg.name

  security_rule {
    name                       = "HTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "tfni" {
  count               = var.number_of_instances
  name                = "shadowman-terraform-nic${count.index}"
  location            = azurerm_resource_group.tfrg.location
  resource_group_name = azurerm_resource_group.tfrg.name

  ip_configuration {
    name                          = "shadowman-terraform-nic-ip-config${count.index}"
    subnet_id                     = azurerm_subnet.tfsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.tfpubip[count.index].id
  }
}

resource "azurerm_network_interface_security_group_association" "tfnga" {
  count                     = var.number_of_instances
  network_interface_id      = azurerm_network_interface.tfni[count.index].id
  network_security_group_id = azurerm_network_security_group.tfnsg.id
}

resource "azurerm_linux_virtual_machine" "terraformvms" {
  depends_on                      = [azurerm_marketplace_agreement.redhat]
  count                           = var.number_of_instances
  name                            = "${var.instance_name_convention}${count.index}.shadowman.dev"
  location                        = azurerm_resource_group.tfrg.location
  resource_group_name             = azurerm_resource_group.tfrg.name
  network_interface_ids           = [azurerm_network_interface.tfni[count.index].id]
  size                            = "Standard_B2s"
  admin_username                  = var.azure_user
  admin_password                  = var.azure_password
  disable_password_authentication = false

  source_image_reference {
    publisher = "RedHat"
    offer     = "rhel-byos"
    sku       = var.product_map[var.rhel_version]
    version   = "latest"
  }

  plan {
    name      = var.product_map[var.rhel_version]
    product   = "rhel-byos"
    publisher = "redhat"
  }

  os_disk {
    name                 = "shadowman-terraform-os-disk${count.index}"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  tags = {
    environment      = "dev"
    owner            = "shadowman"
    operating_system = "RHEL"
  }
}
