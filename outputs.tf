output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# AKS Outputs
output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "aks_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "kube_config" {
  description = "Kubernetes configuration"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

# ACR Outputs
output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.main.name
}

output "acr_login_server" {
  description = "Login server URL for the Azure Container Registry"
  value       = azurerm_container_registry.main.login_server
}

output "acr_admin_username" {
  description = "Admin username for the Azure Container Registry"
  value       = azurerm_container_registry.main.admin_username
  sensitive   = true
}

output "acr_admin_password" {
  description = "Admin password for the Azure Container Registry"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true
}

# Jenkins Service Principal Outputs
output "jenkins_client_id" {
  description = "Client ID for Jenkins service principal"
  value       = azuread_application.jenkins.client_id
}

output "jenkins_client_secret" {
  description = "Client secret for Jenkins service principal"
  value       = azuread_service_principal_password.jenkins.value
  sensitive   = true
}

output "jenkins_tenant_id" {
  description = "Tenant ID for Jenkins service principal"
  value       = data.azurerm_client_config.current.tenant_id
}

output "jenkins_subscription_id" {
  description = "Subscription ID for Jenkins service principal"
  value       = data.azurerm_client_config.current.subscription_id
}

# Jenkins VM Outputs
output "jenkins_public_ip" {
  description = "Public IP address of Jenkins server"
  value       = azurerm_public_ip.jenkins.ip_address
}

output "jenkins_ssh_connection" {
  description = "SSH connection string for Jenkins server"
  value       = "ssh ${var.jenkins_admin_username}@${azurerm_public_ip.jenkins.ip_address}"
}

output "jenkins_url" {
  description = "Jenkins web interface URL"
  value       = "http://${azurerm_public_ip.jenkins.ip_address}:8080"
}

output "github_actions_client_id" {
  description = "Client ID for GitHub Actions authentication"
  value       = azuread_application.github_actions.application_id
  # Or wherever your client ID is stored
  sensitive   = false
}
output "github_actions_tenant_id" {
  description = "Tenant ID for GitHub Actions authentication"
  value       = data.azurerm_client_config.current.tenant_id
}

output "github_actions_client_secret" {
  description = "Client secret for GitHub Actions authentication"
  value       = azuread_service_principal_password.github_actions.value
  sensitive   = true
}

output "jenkins_vm_public_ip" {
  description = "Public IP address of Jenkins VM"
  value       = azurerm_public_ip.jenkins.ip_address
}

# outputs.tf
output "github_actions_subscription_id" {
  description = "Azure Subscription ID for GitHub Actions"
  value       = data.azurerm_client_config.current.subscription_id
}