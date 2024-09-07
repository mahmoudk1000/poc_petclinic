locals {
  name = "petclinic"

  tags = {
    Application = "petclinic"
    Author      = "Mahmoud Ayman (mahmoudk1000)"
  }
}

resource "azurerm_resource_group" "main" {
  name     = local.name
  location = "West Europe"

  tags = local.tags
}

resource "azurerm_virtual_network" "vnet" {
  name          = "${local.name}-vnet"
  address_space = ["10.52.0.0/16"]

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  depends_on = [azurerm_resource_group.main]

  tags = local.tags
}

resource "azurerm_subnet" "subnet" {
  name             = "${local.name}-subnet"
  address_prefixes = ["10.52.0.0/16"]

  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  depends_on = [azurerm_virtual_network.vnet]
}

resource "azurerm_public_ip" "public_ip" {
  count             = var.fleet_count
  name              = "${local.name}-public-ip-${count.index}"
  allocation_method = "Dynamic"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_network_security_group" "nsg" {
  name = "${local.name}-nsg"

  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowFromSameSubnet"
    priority                   = 500
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = azurerm_subnet.subnet.address_prefixes[0]
    destination_address_prefix = azurerm_subnet.subnet.address_prefixes[0]
  }

  security_rule {
    name                       = "AllowSSH"
    priority                   = 700
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.white_list_ips
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "KubeAPI"
    description                = "Allow inbound kubeAPI"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefixes    = var.white_list_ips
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "EtcdAPI"
    description                = "Allow inbound kubeAPI"
    priority                   = 1020
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2379-2380"
    source_address_prefixes    = azurerm_public_ip.public_ip[*].ip_address
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "KubeletAPI"
    description                = "Allow inbound kubeAPI"
    priority                   = 1030
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10250"
    source_address_prefixes    = azurerm_public_ip.public_ip[*].ip_address
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "KubeScheduler"
    description                = "Allow inbound kubeAPI"
    priority                   = 1040
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10259"
    source_address_prefixes    = azurerm_public_ip.public_ip[*].ip_address
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "KubeContoller"
    description                = "Allow inbound kubeAPI"
    priority                   = 1050
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10257"
    source_address_prefixes    = azurerm_public_ip.public_ip[*].ip_address
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "KubeProxy"
    description                = "Allow inbound kubeAPI"
    priority                   = 1060
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10256"
    source_address_prefixes    = azurerm_public_ip.public_ip[*].ip_address
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "NodePortHttp"
    priority                   = 1070
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30080"
    source_address_prefixes    = var.white_list_ips
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "NodePortHttps"
    priority                   = 1080
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30443"
    source_address_prefixes    = var.white_list_ips
    destination_address_prefix = "*"
  }

  depends_on = [azurerm_public_ip.public_ip]
}

resource "azurerm_network_interface" "nic" {
  count = var.fleet_count
  name  = "${local.name}-nic-${count.index}"

  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip[count.index].id
  }

  depends_on = [azurerm_subnet.subnet]
}

resource "azurerm_network_interface_security_group_association" "nic_nsg_link" {
  count                     = length(azurerm_network_interface.nic)
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id

  depends_on = [azurerm_network_interface.nic, azurerm_network_security_group.nsg]
}

resource "azurerm_subnet_network_security_group_association" "sub_nsg_link" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  count = var.fleet_count
  name  = "${local.name}-vm-${count.index}"

  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  size = var.vm_size

  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_key_path)
  }

  computer_name = "wm-${count.index}"

  admin_username = var.admin_username
  admin_password = var.admin_password

  disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  depends_on = [azurerm_network_interface.nic]

  tags = local.tags
}
