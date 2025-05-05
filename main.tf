

locals {
  location_lower = replace(lower(var.location), " ", "") //e.g. "Germany West Central" becomes "germanywestcentral"
}


/////////////////////////////////////////////////////////////////
// Kubernetes Cluster
/////////////////////////////////////////////////////////////////


resource "azurerm_user_assigned_identity" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
}


resource "azurerm_kubernetes_cluster" "this" {
  name                              = var.name
  location                          = var.location
  resource_group_name               = var.resource_group_name
  node_resource_group               = "${var.resource_group_name}-nodes"
  kubernetes_version                = var.kubernetes_version
  sku_tier                          = "Free"
  oidc_issuer_enabled               = true
  private_cluster_enabled           = false
  azure_policy_enabled              = true
  role_based_access_control_enabled = true
  open_service_mesh_enabled         = false
  dns_prefix                        = "aks"

  default_node_pool {
    name                         = "system"
    only_critical_addons_enabled = true // Setting to "true" will set the "CriticalAddonsOnly=true:NoSchedule" taint, preventing non-system applications from scheduling here
    orchestrator_version         = var.kubernetes_version
    zones                        = var.zones
    type                         = "VirtualMachineScaleSets"
    vnet_subnet_id               = var.ingress_subnet_id
    pod_subnet_id                = var.system_subnet_id
    auto_scaling_enabled         = var.system_node_pool.enable_auto_scaling
    host_encryption_enabled      = var.system_node_pool.enable_host_encryption
    node_public_ip_enabled       = var.system_node_pool.enable_node_public_ip
    min_count                    = var.system_node_pool.min_count
    max_count                    = var.system_node_pool.max_count
    os_disk_size_gb              = var.system_node_pool.os_disk_size_gb
    vm_size                      = var.system_node_pool.vm_size
    
    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    admin_group_object_ids = var.administrator_object_ids
  }


  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    outbound_type      = "loadBalancer"
    pod_cidr           = null
  }


  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  storage_profile {
    blob_driver_enabled         = true
    disk_driver_enabled         = true
    snapshot_controller_enabled = true
  }

}

// Add "User" node pools
resource "azurerm_kubernetes_cluster_node_pool" "this" {
  for_each                = var.general_node_pools
  name                    = each.key
  mode                    = "User"
  kubernetes_cluster_id   = azurerm_kubernetes_cluster.this.id
  orchestrator_version    = var.kubernetes_version
  vnet_subnet_id          = var.ingress_subnet_id
  pod_subnet_id           = var.apps_subnet_id
  node_public_ip_enabled  = each.value.enable_node_public_ip
  vm_size                 = each.value.vm_size
  os_disk_size_gb         = each.value.os_disk_size_gb
  auto_scaling_enabled    = each.value.enable_auto_scaling
  host_encryption_enabled = each.value.enable_host_encryption
  min_count               = each.value.min_count
  max_count               = each.value.max_count
  node_count              = each.value.node_count
  max_pods                = each.value.max_pods
  node_taints             = each.value.node_taints
  node_labels             = each.value.node_labels
  priority                = each.value.priority
  eviction_policy         = each.value.eviction_policy

  lifecycle {
    ignore_changes = [
      node_count //ignore changes on node count since autoscaler might change it
    ]
  }
}

resource "azuread_group_member" "acr_pull" {
  for_each         = toset(var.azurecr_pull_group_ids)
  group_object_id  = each.key
  member_object_id = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

