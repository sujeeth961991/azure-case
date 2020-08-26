data "azuread_group" "aks" {
  name = var.aad_group_name
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
    name                  = substr(var.default_node_pool.name, 0, 12)
    orchestrator_version  = var.kubernetes_version
    node_count            = var.default_node_pool.node_count
    vm_size               = var.default_node_pool.vm_size
    type                  = "VirtualMachineScaleSets"
    max_pods              = 250
    os_disk_size_gb       = 128
    vnet_subnet_id        = var.vnet_subnet_id
    node_labels           = var.default_node_pool.labels
    enable_node_public_ip = true
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control {
    enabled = true

    azure_active_directory {
      managed = true
      admin_group_object_ids = [
        data.azuread_group.aks.id
      ]
    }
  }

  addon_profile {
    oms_agent {
      enabled                    = false
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
    dns_service_ip     = "10.0.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
    service_cidr       = "10.0.0.0/16"
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "aks" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

resource "azurerm_role_assignment" "aks_subnet" {
  scope                = var.vnet_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

resource "azurerm_role_assignment" "aks_acr" {
  scope                = var.container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}