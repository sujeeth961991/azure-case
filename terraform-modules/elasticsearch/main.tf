resource "azurerm_public_ip" "single-node" {
  name                = "es-${var.es_cluster}-single-node-public-ip"
  location            = var.azure_location
  resource_group_name = var.rg_name
  domain_name_label   = var.rg_name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "single-node" {
  // Only create if it's a single-node configuration

  name                = "es-${var.es_cluster}-singlenode-nic"
  location            = var.azure_location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "es-${var.es_cluster}-singlenode-ip"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.single-node.id
  }
}

data "azurerm_image" "kibana" {
  resource_group_name = var.rg_name
  name                = "es-delphi-es-singlenode-image-20200830004208"
  sort_descending     = true
}

resource "azurerm_virtual_machine" "single-node" {

  name                  = "es-${var.es_cluster}-singlenode"
  location              = var.azure_location
  resource_group_name   = var.rg_name
  network_interface_ids = [azurerm_network_interface.single-node.id]
  vm_size               = var.data_instance_type


  storage_image_reference {
    id = data.azurerm_image.kibana.id
  }

  storage_os_disk {
    name              = "es-${var.es_cluster}-singlenode-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "es-${var.es_cluster}-singlenode"
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = file(var.key_path)
    }
  }
}