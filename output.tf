output "login_instructions" {
  value = templatefile(
    "${path.module}/templates/login_instructions.tftpl",
    {
      subscription_id     = var.subscription_id
      cluster_name        = azurerm_kubernetes_cluster.this.name
      resource_group_name = var.resource_group_name
  })

}

output "cluster_host" {
  value = azurerm_kubernetes_cluster.this.kube_admin_config.0.host
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = base64decode(azurerm_kubernetes_cluster.this.kube_admin_config.0.cluster_ca_certificate)
  sensitive = true
}

output "cluster_token" {
  value     = yamldecode(azurerm_kubernetes_cluster.this.kube_admin_config_raw).users[0].user.token
  sensitive = true
}

output "cluster_kube_config_raw" {
  value = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive = true
}
output "cluster_kube_admin_config_raw" {
  value = azurerm_kubernetes_cluster.this.kube_admin_config_raw
  sensitive = true
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "cluster_oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "cluster_principal_id" {
  value = azurerm_user_assigned_identity.this.principal_id
}

