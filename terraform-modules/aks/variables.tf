variable "container_registry_id" {
  description = "Resource id of the ACR"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}

variable "name" {
  description = "The name of the AKS cluster"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the AKS cluster resource group"
  type        = string
}

variable "location" {
  description = "Azure region of the AKS cluster"
  type        = string
}

variable "vnet_subnet_id" {
  description = "Resource id of the Virtual Network subnet"
  type        = string
}

variable "api_auth_ips" {
  description = "Whitelist of IP addresses that are allowed to access the AKS Master Control Plane API"
  type        = list(string)
}

variable "private_cluster" {
  description = "Deploy an AKS cluster without a public accessible API endpoint."
  type        = bool
}

variable "sla_sku" {
  description = "Define the SLA under which the managed master control plane of AKS is running."
  type        = string
}

variable "default_node_pool" {
  description = "The object to configure the default node pool with number of worker nodes, worker node VM size and Availability Zones."
  type = object({
    name       = string
    node_count = number
    vm_size    = string
    labels     = map(string)
  })
}

variable "addons" {
  description = "Defines which addons will be activated."
  type = object({
    oms_agent                = bool
    kubernetes_dashboard     = bool
    azure_policy             = bool
    http_application_routing = bool
  })
}

variable "tags" {
  description = "Tags to add to AKS"
  type        = map(string)
}

variable "admin_group_object_ids" {
  description = "AD Group Object ID for cluster admin"
  type = list(string)
}