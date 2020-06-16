# Configure the Azure Provider
provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=1.43.0"
}

##########################################################################################################
#                                              VARIABLES                                                 #
##########################################################################################################

# Resource group name
variable "rg_name" {
  type        = string
  description = "Enter the name of the resource group to create"
}

# Location
variable "location" {
  type        = string
  description = "Enter your location (e.g. eastus, westus2, etc.) "
}

# VNet name
variable "vnet_name" {
   type	       = string
   description = "Enter the VNet name to create " 
}

# VNet address space
variable "vnet_addr_space" {
   type	       = string
   description = "Enter the VNet address space CIDR (ex 10.10.0.0/16) " 
}

# Subnet name 
variable "subnet_name" {
    type        = string
    description = "Enter the CGF subnet name to create"
}

# Subnet addr prefix
variable "subnet_addr_prefix" {
    type        = string
    description = "Enter the CGF subnet addr prefix CIDR (ex  10.10.0.0/24)"
}

# CGF temp PIPs
variable "cgf1_pip_name" {
    type        = string
    description = "Enter the CGF1 temp pub IP name "
}

variable "cgf2_pip_name" {
    type        = string
    description = "Enter the CGF2 temp pub IP name "
}

# CGF Standard LB Pub IP
variable "cgf_elb_pip_name" {
    type        = string
    description = "Enter the ELB pub IP name "
}

# NSG for CGF subnet
variable "cgf_subnet_nsg_name" {
    type        = string
    description = "Enter the CGF subnet NSG name "
}

# NICs for CGFs
variable "cgf1_nic_name" {
    type        = string
    description = "Enter the name for CGF NIC 1 "
}

variable "cgf2_nic_name" {
    type        = string
    description = "Enter the name for CGF NIC 2 "
}

# VM names for CGFs
variable "cgf1_vm_name" {
    type        = string
    description = "Enter the VM name for CGF 1 "
}

variable "cgf2_vm_name" {
    type        = string
    description = "Enter the VM name for CGF 2 "
}

# CGF sku, i.e. byol or hourly
variable "cgf_sku" {
    type        = string
    description = "Enter the CGF sku ('byol' or 'hourly') "
}

# CGF VM size, i.e. DS1_v2, etc.
variable "cgf_vm_size" {
    type        = string
    description = "Enter the CGF VM size (DS1_v2, DS2_v2, etc.) "
}

# Admin password
variable "admin_password" {
    type        = string
    description = "Enter the admin password"
}

# CGF license acceptance
variable "cgf_signature" {
    type        = string
    description = "Enter the CGF signature "
}

variable "cgf_email" {
    type        = string
    description = "Enter the CGF email  "
}

variable "cgf_organization" {
    type        = string
    description = "Enter the CGF organization "
}


##########################################################################################################
#                                              RESOURCES                                                 #
##########################################################################################################

# Create the resource group
resource "azurerm_resource_group" "rg-lab" {
    name     = var.rg_name
    location = var.location

    tags = {
        owner = "mcollins"
    }
}

# Create VNet
resource "azurerm_virtual_network" "vnet-lab" {
    name                = var.vnet_name
    location            = var.location
    address_space       = [var.vnet_addr_space]
    resource_group_name = azurerm_resource_group.rg-lab.name
}

# Create Subnet
resource "azurerm_subnet" "cgf-subnet-lab" {
    name                 = var.vnet_name
    resource_group_name  = azurerm_resource_group.rg-lab.name
    virtual_network_name = azurerm_virtual_network.vnet-lab.name
    address_prefix       = var.subnet_addr_prefix
}

# Create CGF PIPs
resource "azurerm_public_ip" "cgf1-pip" {
    name                         = var.cgf1_pip_name
    location                     = var.location
    resource_group_name          = azurerm_resource_group.rg-lab.name
    allocation_method            = "Static"
}

resource "azurerm_public_ip" "cgf2-pip" {
    name                         = var.cgf2_pip_name
    location                     = var.location
    resource_group_name          = azurerm_resource_group.rg-lab.name
    allocation_method            = "Static"
}

# Create CGF ELB standard PIP
resource "azurerm_public_ip" "cgf-elb-pip" {
    name                         = var.cgf_elb_pip_name
    location                     = var.location
    resource_group_name          = azurerm_resource_group.rg-lab.name
    allocation_method            = "Static"
    sku                          = "Standard"
}

# Create CGF subnet NSG
resource "azurerm_network_security_group" "cgf-subnet-nsg" {
    name                = var.cgf_subnet_nsg_name
    location            = var.location
    resource_group_name = azurerm_resource_group.rg-lab.name

    security_rule {
        name                       = "Allow_all"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

# Associate subnet with NSG
resource "azurerm_subnet_network_security_group_association" "cgf-nsg-subnet-assoc" {
    subnet_id                 = azurerm_subnet.cgf-subnet-lab.id
    network_security_group_id = azurerm_network_security_group.cgf-subnet-nsg.id
}

# Create NICs for CGFs
resource "azurerm_network_interface" "nic-cgf1" {
    name                      = var.cgf1_nic_name
    location                  = var.location
    resource_group_name       = azurerm_resource_group.rg-lab.name

    ip_configuration {
        name                          = "IPConfig1"
        subnet_id                     = azurerm_subnet.cgf-subnet-lab.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.cgf1-pip.id
    }
}

# Create network interface
resource "azurerm_network_interface" "nic-cgf2" {
    name                      = var.cgf2_nic_name
    location                  = var.location
    resource_group_name       = azurerm_resource_group.rg-lab.name

    ip_configuration {
        name                          = "IPConfig1"
        subnet_id                     = azurerm_subnet.cgf-subnet-lab.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.cgf2-pip.id
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.rg-lab.name
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "sa_boot_diag" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.rg-lab.name
    location                    = var.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"
}

#create CGF1
resource "azurerm_virtual_machine" "vm_cgf1" {
    name                  = var.cgf1_vm_name
    location              = var.location
    plan {
      publisher          = "barracudanetworks"
      name               = var.cgf_sku
      product            = "barracuda-ng-firewall"
    }
    
    resource_group_name   = azurerm_resource_group.rg-lab.name
    network_interface_ids = [azurerm_network_interface.nic-cgf1.id]
    vm_size               = var.cgf_vm_size
	
    delete_os_disk_on_termination = true
    delete_data_disks_on_termination = true

    storage_os_disk {
        name              = "osdisk_cgf1"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "barracudanetworks"
        offer     = "barracuda-ng-firewall"
        sku       = var.cgf_sku
        version   = "latest"
    }
	
    os_profile {
        computer_name  = var.cgf1_vm_name
        admin_username = "not_used"
        admin_password = var.admin_password
        custom_data = ""
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }
}

#create CGF2
resource "azurerm_virtual_machine" "vm_cgf2" {
    name                  = var.cgf2_vm_name
    location              = var.location
    plan {
      publisher          = "barracudanetworks"
      name               = var.cgf_sku
      product            = "barracuda-ng-firewall"
    }
    
    resource_group_name   = azurerm_resource_group.rg-lab.name
    network_interface_ids = [azurerm_network_interface.nic-cgf2.id]
    vm_size               = var.cgf_vm_size
	
    delete_os_disk_on_termination = true
    delete_data_disks_on_termination = true

    storage_os_disk {
        name              = "osdisk_cgf2"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "barracudanetworks"
        offer     = "barracuda-ng-firewall"
        sku       = var.cgf_sku
        version   = "latest"
    }
	
    os_profile {
        computer_name  = var.cgf1_vm_name
        admin_username = "not_used"
        admin_password = var.admin_password
        custom_data = ""
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }
}

output "CGF1_VM_PIP" {
    description = "CGF 1 temp public IP"
    value       = azurerm_public_ip.cgf1-pip.ip_address
}

output "CGF2_VM_PIP" {
    description = "CGF 2 temp public IP"
    value       = azurerm_public_ip.cgf2-pip.ip_address
}

output "CGF_LB_PIP" {
    description = "CGF ELB public IP"
    value       = azurerm_public_ip.cgf-elb-pip.ip_address
}
