# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Generate a random suffix for unique naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = "${var.acr_name}${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku
  admin_enabled       = true

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create AKS cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.aks_cluster_name}-dns"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.node_vm_size

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Grant AKS pull access to ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.main.id
  skip_service_principal_aad_check = true
}

# Create Azure AD application for Jenkins
resource "azuread_application" "jenkins" {
  display_name = "${var.project_name}-jenkins"
}

# Create service principal for the application
resource "azuread_service_principal" "jenkins" {
  client_id = azuread_application.jenkins.client_id
}

# Create password for the service principal
resource "azuread_service_principal_password" "jenkins" {
  service_principal_id = azuread_service_principal.jenkins.object_id
  end_date            = "2025-12-31T23:59:59Z"
}

# Assign Contributor role to the service principal for the resource group
resource "azurerm_role_assignment" "jenkins_contributor" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.jenkins.object_id
}

# Assign AcrPush role to the service principal for ACR
resource "azurerm_role_assignment" "jenkins_acr_push" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.jenkins.object_id
}

# Create virtual network for Jenkins
resource "azurerm_virtual_network" "jenkins" {
  name                = "vnet-jenkins"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
  }
}

# Create subnet for Jenkins
resource "azurerm_subnet" "jenkins" {
  name                 = "subnet-jenkins"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.jenkins.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IP for Jenkins
resource "azurerm_public_ip" "jenkins" {
  name                = "pip-jenkins"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
  }
}

# Create Network Security Group for Jenkins
resource "azurerm_network_security_group" "jenkins" {
  name                = "nsg-jenkins"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Jenkins"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
  }
}

# Create network interface for Jenkins
resource "azurerm_network_interface" "jenkins" {
  name                = "nic-jenkins"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.jenkins.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jenkins.id
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
  }
}

# Associate Network Security Group to the network interface
resource "azurerm_network_interface_security_group_association" "jenkins" {
  network_interface_id      = azurerm_network_interface.jenkins.id
  network_security_group_id = azurerm_network_security_group.jenkins.id
}

# Create Jenkins VM
resource "azurerm_linux_virtual_machine" "jenkins" {
  name                = "vm-jenkins"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.jenkins_vm_size
  admin_username      = var.jenkins_admin_username

  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.jenkins.id,
  ]

  admin_ssh_key {
    username   = var.jenkins_admin_username
    public_key = var.jenkins_ssh_public_key != "" ? var.jenkins_ssh_public_key : file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/scripts/jenkins-setup.sh", {
    jenkins_admin_username = var.jenkins_admin_username
    azure_client_id        = azuread_application.jenkins.client_id
    azure_client_secret    = azuread_service_principal_password.jenkins.value
    azure_tenant_id        = data.azurerm_client_config.current.tenant_id
    azure_subscription_id  = data.azurerm_client_config.current.subscription_id
    acr_login_server       = azurerm_container_registry.main.login_server
    resource_group_name    = azurerm_resource_group.main.name
    aks_cluster_name       = azurerm_kubernetes_cluster.main.name
  }))

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
  }
}

# Data source for current client configuration
data "azurerm_client_config" "current" {}


# Create Azure AD Application for GitHub Actions
resource "azuread_application" "github_actions" {
  display_name     = "github-actions-jenkins"
  sign_in_audience = "AzureADMyOrg"
  description      = "Service principal for GitHub Actions to deploy Jenkins infrastructure"
}

# Create Service Principal
resource "azuread_service_principal" "github_actions" {
  client_id   = azuread_application.github_actions.client_id
  description = "Service principal for GitHub Actions"
}

# Create client secret
resource "azuread_service_principal_password" "github_actions" {
  service_principal_id = azuread_service_principal.github_actions.id
}