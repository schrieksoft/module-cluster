variable "name" {}

variable "administrator_object_ids" {}

variable "location" {}

variable "subscription_id" {}

variable "tenant_id" {}

variable "kubernetes_version" {}

variable "vnet_id" {}

variable "system_subnet_id" {}

variable "ingress_subnet_id" {}

variable "apps_subnet_id" {}

variable "resource_group_name" {}

variable "resource_group_id" {}

variable "zones" {
  default = ["1"]
}

variable "system_node_pool" {
  type = object({
    enable_auto_scaling    = bool
    enable_node_public_ip  = bool
    enable_host_encryption = bool
    min_count              = number
    max_count              = number
    max_pods               = number
    os_disk_size_gb        = number
    vm_size                = string
    }
  )
}

variable "general_node_pools" {
  type = map(object({
    enable_auto_scaling    = bool
    enable_node_public_ip  = bool
    enable_host_encryption = bool
    min_count              = number
    max_count              = number
    max_pods               = number
    node_count             = number
    os_disk_size_gb        = number
    vm_size                = string
    node_taints            = list(string)
    node_labels            = map(string)
    priority               = string
    eviction_policy        = string
    }
  ))
}

variable "azurecr_pull_group_ids" {
  default = []
}
