output kubelet_identity {
  value = azurerm_kubernetes_cluster.k8s.kubelet_identity
}

/*
output "client_key" {
    value = azurerm_kubernetes_cluster.k8s.kube_config.0.client_key
}

output "client_certificate" {
    value = azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate
}

output "cluster_ca_certificate" {
    value = azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate
}
output "kube_config" {
    value = azurerm_kubernetes_cluster.k8s.kube_config_raw
}



output "cluster_username" {
    value = azurerm_kubernetes_cluster.k8s.kube_config.0.username
}

output "cluster_password" {
    value = azurerm_kubernetes_cluster.k8s.kube_config.0.password
}

output "host" {
    value = azurerm_kubernetes_cluster.k8s.kube_config.0.host
}


*/

/*
output "jumpbox_ip_address" {
    value = azurerm_public_ip.pip.ip_address
}
*/

output "sql_server" {
  value = azurerm_sql_server.example.name
}

output "sql_server_fqdn" {
  value = azurerm_sql_server.example.fully_qualified_domain_name
}

output "sql_database" {
  value = azurerm_sql_database.example.name
}

output "acr_fqdn" {
  value = azurerm_container_registry.acr.login_server
}
