data "azurerm_client_config" "current" {
}

resource "azuread_group" "group" {
  name    = var.group_name
  members = concat(list(data.azurerm_client_config.current.id), var.group_members)
}