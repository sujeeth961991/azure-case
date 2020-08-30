resource "azuread_application" "aks" {
  name                       = "${var.name}"
  available_to_other_tenants = true
  oauth2_allow_implicit_flow = true
}

resource "azuread_service_principal" "aks-sp" {
  application_id = "${azuread_application.aks.application_id}"
}

resource "azuread_service_principal_password" "aks-sp-pass" {
  service_principal_id = "${azuread_service_principal.aks-sp.id}"
  value                = "${var.aks_client_secret}"
  end_date             = "2999-01-01T01:02:03Z"
}

resource "azurerm_kubernetes_cluster" "aks" {
  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }

  name                            = var.name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  dns_prefix                      = var.name
  kubernetes_version              = var.kubernetes_version
  node_resource_group             = "${var.name}-worker"
  private_cluster_enabled         = var.private_cluster
  sku_tier                        = var.sla_sku
  api_server_authorized_ip_ranges = var.api_auth_ips

  default_node_pool {
    name                 = substr(var.default_node_pool.name, 0, 12)
    orchestrator_version = var.kubernetes_version
    node_count           = var.default_node_pool.node_count
    vm_size              = var.default_node_pool.vm_size
    type                 = "VirtualMachineScaleSets"
    max_pods             = 250
    os_disk_size_gb      = 128
    vnet_subnet_id       = var.vnet_subnet_id
    node_labels          = var.default_node_pool.labels
  }

  service_principal {
    client_id     = azuread_application.aks.application_id
    client_secret = azuread_service_principal_password.aks-sp-pass.value
  }

  role_based_access_control {
    enabled = true
  }

  addon_profile {
    oms_agent {
      enabled                    = var.addons.oms_agent
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
    kube_dashboard {
      enabled = var.addons.kubernetes_dashboard
    }
    azure_policy {
      enabled = var.addons.azure_policy
    }
    http_application_routing {
      enabled = var.addons.http_application_routing
    }
  }

  network_profile {
    load_balancer_sku  = "standard"
    outbound_type      = "loadBalancer"
    network_plugin     = "azure"
    network_policy     = "calico"
    dns_service_ip     = "10.1.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
    service_cidr       = "10.1.0.0/16"
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "aks" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azuread_service_principal.aks-sp.object_id
}

resource "azurerm_role_assignment" "aks_subnet" {
  scope                = var.vnet_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azuread_service_principal.aks-sp.object_id
}

resource "azurerm_role_assignment" "aks_acr" {
  scope                = var.container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = azuread_service_principal.aks-sp.object_id
}