#!/bin/bash

# Azure AKS WebApp Deployment Script
# This script helps deploy the complete infrastructure and application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}==== $1 ====${NC}"
}

# Check if required tools are installed
check_prerequisites() {
    print_header "Checking Prerequisites"

    local missing_tools=()

    if ! command -v az &> /dev/null; then
        missing_tools+=("azure-cli")
    fi

    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    fi

    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi

    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "The following tools are required but not installed:"
        for tool in "${missing_tools[@]}"; do
            echo "  - $tool"
        done
        exit 1
    fi

    print_status "All prerequisites are installed"
}

# Check Azure login
check_azure_login() {
    print_header "Checking Azure Authentication"

    if ! az account show &> /dev/null; then
        print_error "Not logged into Azure. Please run 'az login' first"
        exit 1
    fi

    local subscription_id=$(az account show --query id -o tsv)
    local account_name=$(az account show --query name -o tsv)

    print_status "Logged into Azure subscription: $account_name ($subscription_id)"
}

# Deploy infrastructure
deploy_infrastructure() {
    print_header "Deploying Infrastructure with Terraform"

    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Creating from example..."
        cp terraform.tfvars.example terraform.tfvars
        print_warning "Please edit terraform.tfvars with your desired configuration before proceeding"
        read -p "Press Enter to continue once you've updated terraform.tfvars..."
    fi

    print_status "Initializing Terraform..."
    terraform init

    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan

    echo
    print_warning "Review the plan above. This will create real Azure resources that may incur costs."
    read -p "Do you want to proceed with the deployment? (y/N): " confirm

    if [[ $confirm =~ ^[Yy]$ ]]; then
        print_status "Applying Terraform configuration..."
        terraform apply tfplan
        print_status "Infrastructure deployment completed!"
    else
        print_status "Deployment cancelled"
        exit 0
    fi
}

# Extract Terraform outputs
extract_outputs() {
    print_header "Extracting Deployment Information"

    # Extract outputs
    RESOURCE_GROUP=$(terraform output -raw resource_group_name)
    CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
    ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
    ACR_USERNAME=$(terraform output -raw acr_admin_username)
    ACR_PASSWORD=$(terraform output -raw acr_admin_password)
    CLIENT_ID=$(terraform output -raw github_actions_client_id)
    CLIENT_SECRET=$(terraform output -raw github_actions_client_secret)
    TENANT_ID=$(terraform output -raw github_actions_tenant_id)
    SUBSCRIPTION_ID=$(terraform output -raw github_actions_subscription_id)

    print_status "Deployment information extracted successfully"
}

# Configure kubectl
configure_kubectl() {
    print_header "Configuring kubectl"

    print_status "Getting AKS credentials..."
    az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing

    print_status "Testing kubectl connection..."
    kubectl cluster-info

    print_status "kubectl configured successfully"
}

# Display GitHub secrets
display_github_secrets() {
    print_header "GitHub Repository Secrets"

    echo "Configure the following secrets in your GitHub repository:"
    echo
    echo "Repository Settings > Secrets and variables > Actions > New repository secret"
    echo
    echo "Secret Name: AZURE_CREDENTIALS"
    echo "Value:"
    cat << EOF
{
  "clientId": "$CLIENT_ID",
  "clientSecret": "$CLIENT_SECRET",
  "subscriptionId": "$SUBSCRIPTION_ID",
  "tenantId": "$TENANT_ID"
}
EOF
    echo
    echo "Secret Name: ACR_LOGIN_SERVER"
    echo "Value: $ACR_LOGIN_SERVER"
    echo
    echo "Secret Name: ACR_USERNAME"
    echo "Value: $ACR_USERNAME"
    echo
    echo "Secret Name: ACR_PASSWORD"
    echo "Value: $ACR_PASSWORD"
    echo
    echo "Secret Name: RESOURCE_GROUP"
    echo "Value: $RESOURCE_GROUP"
    echo
    echo "Secret Name: CLUSTER_NAME"
    echo "Value: $CLUSTER_NAME"
    echo
    print_warning "IMPORTANT: Store these secrets securely and never commit them to version control"
}

# Deploy application manually (for testing)
deploy_application() {
    print_header "Deploying Application for Testing"

    # Create namespace
    print_status "Creating namespace..."
    kubectl apply -f k8s/namespace.yaml

    # For demo purposes, we'll build and push the image manually
    print_status "Building and pushing demo image..."

    # Login to ACR
    az acr login --name $(echo $ACR_LOGIN_SERVER | cut -d'.' -f1)

    # Build and push image with Docker fallback to ACR build
    if check_docker_available; then
        print_status "Docker available - building locally..."
        docker build -t $ACR_LOGIN_SERVER/vincent-portfolio:latest ./app
        docker push $ACR_LOGIN_SERVER/vincent-portfolio:latest
    else
        print_status "Docker not available - using ACR build task..."
        az acr build --registry $(echo $ACR_LOGIN_SERVER | cut -d'.' -f1) \
                    --image vincent-portfolio:latest \
                    ./app
    fi

    # Update deployment manifest with actual values
    print_status "Updating Kubernetes manifests..."
    sed "s|__ACR_LOGIN_SERVER__|$ACR_LOGIN_SERVER|g" k8s/deployment.yaml | \
    sed "s|__IMAGE_TAG__|latest|g" | \
    sed "s|__AKS_CLUSTER_NAME__|$CLUSTER_NAME|g" | \
    sed "s|__LOCATION__|eastus|g" > k8s/deployment-updated.yaml

    # Deploy application
    print_status "Deploying application..."
    kubectl apply -f k8s/deployment-updated.yaml

    # Wait for deployment
    print_status "Waiting for deployment to be ready..."
    kubectl rollout status deployment/vincent-portfolio -n vincent-portfolio --timeout=300s

    print_status "Application deployed successfully!"


# Helper function to check if Docker is available and running
check_docker_available() {
    if ! command -v docker &> /dev/null; then
        print_status "Docker command not found"
        return 1
    fi
    
    if ! docker info &> /dev/null; then
        print_status "Docker is not running"
        return 1
    fi
    
    return 0
}

    # Show access information
    echo
    print_status "Application Access Information:"
    echo "Port forward command: kubectl port-forward svc/vincent-portfolio-service 8080:80 -n vincent-portfolio"
    echo "Then access: http://localhost:8080"

    # Clean up temporary file
    rm -f k8s/deployment-updated.yaml
}

# Main execution
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                  Azure AKS WebApp Deployer                   ║"
    echo "║              Complete Infrastructure & Application           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo

    check_prerequisites
    check_azure_login
    deploy_infrastructure
    extract_outputs
    configure_kubectl
    display_github_secrets

    echo
    read -p "Do you want to deploy the application for testing? (y/N): " deploy_app
    if [[ $deploy_app =~ ^[Yy]$ ]]; then
        if command -v docker &> /dev/null; then
            deploy_application
        else
            print_warning "Docker not found. Skipping application deployment."
            print_status "You can deploy via GitHub Actions once secrets are configured."
        fi
    fi

    echo
    print_header "Deployment Complete!"
    print_status "Your AKS infrastructure is ready!"
    print_status "Configure the GitHub secrets shown above to enable CI/CD"
    print_status "Push your code to the main branch to trigger automated deployment"
    echo
    print_status "Next steps:"
    echo "  1. Configure GitHub repository secrets"
    echo "  2. Push your code to trigger CI/CD pipeline"
    echo "  3. Monitor deployment in GitHub Actions"
    echo "  4. Access your application via the ingress URL or port forwarding"
}

# Run main function
main "$@"