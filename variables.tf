variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-aks-webapp"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = "Development"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "AKS WebApp"
}

variable "owner" {
  description = "Owner of the project"
  type        = string
  default     = "vincent"
}

# AKS Configuration
variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-webapp-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.33.4"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 10
    error_message = "Node count must be between 1 and 10."
  }
}

variable "node_vm_size" {
  description = "VM size for the AKS nodes"
  type        = string
  default     = "Standard_D2_v4"
}

# ACR Configuration
variable "acr_name" {
  description = "Name of the Azure Container Registry (will have random suffix)"
  type        = string
  default     = "acrwebapp"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]*$", var.acr_name))
    error_message = "ACR name can only contain alphanumeric characters."
  }
}

variable "acr_sku" {
  description = "SKU for the Azure Container Registry"
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be Basic, Standard, or Premium."
  }
}

# Application Configuration
variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "webapp-demo"
}

variable "app_namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "default"
}

# Jenkins Configuration
variable "jenkins_vm_size" {
  description = "VM size for the Jenkins server"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "jenkins_admin_username" {
  description = "Admin username for the Jenkins VM"
  type        = string
  default     = "jenkinsadmin"
}

variable "jenkins_ssh_public_key" {
  description = "SSH public key for the Jenkins VM"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCIGjmORQuXkFwXCVKaWqOzL7aTi0jbTXJE/2WPiuoSRZKJMPA3NUcy17bkjxr179c1lamvyoMFTubtd6alxKQh/jbDu/jCJ8zL7i7DHlNGe3XR3wJ1VgMHvh0dXXdA7sUuYLkXYuHhSw/CKBPJc7nw3Xkv5ngijX+fv/vdu9GG4jxQUKQmjC0r6Jr+iqBDWYSaOESrMmv5uLpWqfYrBsgQ0gGCJx0VQKjSKQld9djvd/0K4g2ZY0gPv7eMt5f9q2gZdoOiNLQtq9OFevJFtNfnc2nVJ0PXPdKIV3OQaPctgQEiv5uJEVPnWtD99s2HIax4MciIxNWHJDt6buXrrxXlc"
}