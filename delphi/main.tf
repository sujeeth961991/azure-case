terraform {

  backend "azurerm" {

    resource_group_name = "delphi"

    storage_account_name = "delphitfstate"

    container_name = "tfstate"

    key = "terraform.tfstate"

  }
  required_version = ">=0.13.0"
}

provider "azurerm" {
  version = "=2.21.0"
  features {}
}

provider "azuread" {}

data "azurerm_resource_group" "delphi" {
  name = "delphi"
}

module "vnet" {
  source               = "../terraform-modules/virtual_network"
  name                 = "delphivnet"
  location             = data.azurerm_resource_group.delphi.location
  resource_group_name  = data.azurerm_resource_group.delphi.name
  address_space        = ["10.0.0.0/16"]
  subnet_name          = "delphi-subnet-0"
  subnet_address_space = "10.0.0.0/20"
  tags = {
    name = "delphi-vnet"
  }
}

module "acr" {
  source              = "../terraform-modules/acr"
  acr_name            = "delphiacr"
  location            = data.azurerm_resource_group.delphi.location
  resource_group_name = data.azurerm_resource_group.delphi.name
  tags = {
    name = "delphi-acr"
  }
}

module "log-analytics" {
  source              = "../terraform-modules/log_analytics"
  name                = "delphila"
  sku                 = "Free"
  retention           = 7
  location            = data.azurerm_resource_group.delphi.location
  resource_group_name = data.azurerm_resource_group.delphi.name
  tags = {
    name = "delphi-log-analytics-workspace"
  }
}

module "key-vault" {
  source              = "../terraform-modules/key-vault"
  name                = "delphikv"
  resource_group_name = data.azurerm_resource_group.delphi.name
  access_policies = [
    {
      user_principal_names = ["sujeeth.kumar.psg_outlook.com#EXT#@sujeethkumarpsgoutlook978.onmicrosoft.com"]
      secret_permissions   = ["get", "list"]
    },
    {
      group_names        = ["developers"]
      secret_permissions = ["get", "list", "set"]
    },
  ]

  secrets = {
    "message" = "Hello, world!"
  }
  tags = {
    name = "delphi-kv"
  }
}

module "aks" {
  source              = "../terraform-modules/aks"
  name                = "delphiaks"
  vnet_subnet_id      = module.vnet.subnet_id
  resource_group_name = data.azurerm_resource_group.delphi.name
  location            = data.azurerm_resource_group.delphi.location
  private_cluster     = false
  kubernetes_version  = "1.16.13"
  default_node_pool = {
    name       = "defaultpool"
    node_count = 1
    vm_size    = "Standard_D2_v2"
    labels = {
      nodeType = "worker"
    }
  }
  addons = {
    oms_agent                = true
    kubernetes_dashboard     = true
    http_application_routing = true
    azure_policy             = false
  }
  log_analytics_workspace_id = module.log-analytics.id
  sla_sku                    = "Free"
  admin_group_object_ids     = ["94f93b23-5897-4f3a-9084-e2bd466371cb"]
  api_auth_ips               = []
  container_registry_id      = module.acr.acr_id
  tags = {
    name = "delphi-aks"
  }

}

module "elasticsearch" {
  source             = "../terraform-modules/elasticsearch"
  azure_location     = data.azurerm_resource_group.delphi.location
  rg_name            = data.azurerm_resource_group.delphi.name
  es_cluster         = "delphi-es"
  subnet_id          = module.vnet.subnet_id
  data_instance_type = "Standard_B1s"
}

