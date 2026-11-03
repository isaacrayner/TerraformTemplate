# Output Values for AKS Module

output "cluster_id" {
  description = "AKS cluster resource ID"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "fqdn" {
  description = "Cluster API server FQDN (private_fqdn when private_cluster_enabled is true)"
  value       = coalesce(azurerm_kubernetes_cluster.aks.private_fqdn, azurerm_kubernetes_cluster.aks.fqdn)
}

output "node_resource_group" {
  description = "Auto-created resource group holding the cluster's VM/network infrastructure (MC_*)"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "kubelet_identity_object_id" {
  description = "Kubelet managed identity object ID — grant this AcrPull, not the cluster's own identity"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

output "principal_id" {
  description = "Cluster's SystemAssigned identity principal ID"
  value       = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

output "kube_config_raw" {
  description = "Raw kubeconfig (sensitive) — cluster-admin credentials when local accounts are enabled"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "additional_node_pool_ids" {
  description = "Resource IDs of additional_node_pools, keyed by pool name"
  value       = { for k, v in azurerm_kubernetes_cluster_node_pool.additional : k => v.id }
}
