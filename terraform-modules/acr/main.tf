resource "azurerm_container_registry" "registry" {
  name = var.acr_name

  location            = var.location
  resource_group_name = var.resource_group_name

  sku           = var.sku
  admin_enabled = var.admin_enabled

  georeplication_locations = var.georeplication_locations

  tags = var.tags
}