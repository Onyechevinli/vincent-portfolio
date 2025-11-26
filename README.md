# Vincent's Portfolio - Full Stack Flask Application on Azure AKS

A professional portfolio website for **Umeokoli Vincent Tochukwu**, DevOps Cloud Engineer, built with Python Flask and deployed on Azure Kubernetes Service (AKS) using Infrastructure as Code (Terraform) and automated CI/CD with Jenkins.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   Git Repository│────│   Jenkins Server │────│ Azure Container     │
│   (Source Code) │    │   (CI/CD)        │    │ Registry (ACR)      │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
                               │                           │
                               ▼                           ▼
                    ┌──────────────────┐         ┌─────────────────────┐
                    │  Terraform       │         │ Azure Kubernetes    │
                    │  (Infrastructure)│────────▶│ Service (AKS)       │
                    └──────────────────┘         └─────────────────────┘
                                                           │
                                                           ▼
                                                 ┌─────────────────────┐
                                                 │  Load Balancer      │
                                                 │  (Public Access)    │
                                                 └─────────────────────┘
```

## 🚀 Features

### 📱 Flask Web Application
- **Personal Portfolio**: Professional showcase based on Vincent's CV
- **Responsive Design**: Bootstrap 5 with custom styling
- **Health Monitoring**: Built-in health check endpoints
- **API Endpoints**: RESTful APIs for profile data
- **Security**: Production-ready Flask application with Gunicorn

### ☁️ Cloud Infrastructure (Terraform)
- **Azure Resource Group**: Organized resource management
- **Azure Kubernetes Service (AKS)**: Managed Kubernetes cluster
- **Azure Container Registry (ACR)**: Private container image registry
- **Jenkins VM**: Automated CI/CD server with pre-configured tools
- **Virtual Network**: Secure networking with proper security groups
- **Service Principal**: Azure authentication for automated deployments

### 🔄 CI/CD Pipeline (Jenkins)
- **Automated Building**: Python Flask application building and testing
- **Docker Integration**: Container image creation and registry push
- **Kubernetes Deployment**: Automated deployment to AKS cluster
- **Health Checks**: Post-deployment application health verification
- **Security**: Non-root containers, resource limits, network policies

### 🛡️ Security & Best Practices
- **Network Policies**: Kubernetes network segmentation
- **Resource Limits**: CPU and memory constraints
- **Security Context**: Non-root user execution
- **Secrets Management**: Azure Key Vault integration ready
- **RBAC**: Role-based access control for service principals

## 🏃‍♂️ Quick Start

### Prerequisites

1. **Azure Subscription** with appropriate permissions
2. **Azure CLI** installed and authenticated
3. **Terraform** (v1.5+) installed
4. **SSH Key Pair** for Jenkins VM access
5. **Git Repository** for source code hosting

### 1. Clone and Configure

```bash
# Clone the repository
git clone <your-repo-url>
cd vincent-portfolio

# Copy and customize Terraform variables
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your specific values
# IMPORTANT: Add your SSH public key for Jenkins access
```

### 2. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Deploy infrastructure (takes 10-15 minutes)
terraform apply

# Note the outputs - you'll need these for Jenkins configuration
terraform output -json
```

### 3. Configure Jenkins

```bash
# Get Jenkins connection details from Terraform output
JENKINS_IP=$(terraform output -raw jenkins_public_ip)
JENKINS_URL=$(terraform output -raw jenkins_url)

echo "Jenkins URL: $JENKINS_URL"
echo "SSH to Jenkins: $(terraform output -raw jenkins_ssh_connection)"
```

**Access Jenkins:**
1. Navigate to the Jenkins URL from terraform output
2. Default credentials: `admin` / `admin123`
3. **Change the default password immediately!**

**Set up Credentials in Jenkins:**
1. Go to "Manage Jenkins" → "Manage Credentials"
2. Run the provided groovy script in "Script Console":
   - Copy content from `jenkins/setup-credentials.groovy`
   - Update credential values with Terraform outputs
3. Create the pipeline job using `jenkins/pipeline-job.xml`

### 4. Deploy Application

```bash
# Trigger the Jenkins pipeline manually or push code to trigger automatically
# The pipeline will:
# 1. Build the Flask application
# 2. Run tests
# 3. Create Docker image
# 4. Push to ACR
# 5. Deploy to AKS
# 6. Perform health checks
```

### 5. Access Your Application

```bash
# Get the application URL
kubectl get ingress vincent-portfolio-ingress -n vincent-portfolio

# Or use port forwarding for immediate access
kubectl port-forward svc/vincent-portfolio-service 8080:80 -n vincent-portfolio
```

## 📁 Project Structure

```
vincent-portfolio/
├── app/                          # Flask Application
│   ├── app.py                    # Main Flask application
│   ├── templates/                # HTML templates
│   │   ├── base.html            # Base template
│   │   ├── index.html           # Home page
│   │   ├── experience.html      # Experience page
│   │   └── skills.html          # Skills page
│   ├── static/                   # Static assets
│   │   ├── css/style.css        # Custom styles
│   │   └── js/main.js           # JavaScript functionality
│   ├── requirements.txt          # Python dependencies
│   ├── Dockerfile               # Container configuration
│   └── .dockerignore            # Docker ignore rules
├── k8s/                          # Kubernetes Manifests
│   ├── namespace.yaml           # Application namespace
│   ├── deployment.yaml          # Application deployment
│   ├── configmap.yaml           # Configuration and secrets
│   ├── hpa.yaml                 # Horizontal Pod Autoscaler
│   └── networkpolicy.yaml       # Network security policies
├── jenkins/                      # Jenkins Configuration
│   ├── pipeline-job.xml         # Jenkins job configuration
│   └── setup-credentials.groovy # Credentials setup script
├── scripts/                      # Infrastructure Scripts
│   ├── jenkins-setup.sh         # Jenkins VM setup script
│   └── deploy.sh                # Deployment helpers
├── main.tf                       # Terraform main configuration
├── variables.tf                  # Terraform variables
├── outputs.tf                    # Terraform outputs
├── terraform.tfvars.example     # Example configuration
├── Jenkinsfile                   # CI/CD Pipeline definition
├── .gitignore                    # Git ignore rules
└── README.md                     # This documentation
```

## 🔧 Configuration

### Terraform Variables

Key variables in `terraform.tfvars`:

```hcl
# Basic Configuration
resource_group_name = "rg-vincent-portfolio"
location           = "East US"
environment        = "Production"
project_name       = "Vincent Portfolio"
owner              = "Vincent Umeokoli"

# AKS Configuration
aks_cluster_name   = "aks-vincent-portfolio"
kubernetes_version = "1.28"
node_count        = 3
node_vm_size      = "Standard_DS2_v2"

# Jenkins Configuration
jenkins_vm_size        = "Standard_D2s_v3"
jenkins_admin_username = "jenkins"
jenkins_ssh_public_key = "ssh-rsa YOUR_PUBLIC_KEY_HERE"
```

### Application Configuration

Environment variables used by the Flask application:

- `FLASK_ENV`: Application environment (production/development)
- `PORT`: Application port (default: 5000)
- `PYTHONPATH`: Python path for modules
- `PYTHONUNBUFFERED`: Python output buffering

## 🛠️ Development

### Local Development

```bash
# Set up Python virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r app/requirements.txt

# Run the application locally
cd app
python app.py

# Access at http://localhost:5000
```

### Building Locally

```bash
# Build Docker image
docker build -t vincent-portfolio ./app

# Run container locally
docker run -p 5000:5000 vincent-portfolio
```

### Testing Kubernetes Locally

```bash
# Apply manifests to your local cluster
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml

# Check deployment
kubectl get pods -n vincent-portfolio
kubectl logs -f deployment/vincent-portfolio -n vincent-portfolio
```

## 🔒 Security Features

### Infrastructure Security
- **Service Principal**: Least-privilege Azure access
- **Network Security Groups**: Controlled inbound/outbound traffic
- **RBAC**: Role-based access control for AKS and ACR
- **Private Networking**: Secure communication between components

### Application Security
- **Non-root Container**: Application runs as unprivileged user
- **Resource Limits**: CPU and memory constraints prevent resource exhaustion
- **Health Checks**: Kubernetes liveness and readiness probes
- **Network Policies**: Pod-to-pod communication restrictions

### Container Security
- **Multi-stage Build**: Reduced attack surface
- **Minimal Base Image**: Python slim image for smaller footprint
- **Security Context**: Additional container security constraints

## 📊 Monitoring & Observability

### Built-in Monitoring
- **Health Endpoints**: `/health` endpoint for monitoring
- **Application Metrics**: Request logging and performance data
- **Kubernetes Metrics**: Pod and node monitoring via AKS

### Recommended Additions
- **Azure Monitor**: Container insights and log analytics
- **Prometheus & Grafana**: Custom metrics and dashboards
- **Application Insights**: Application performance monitoring

## 🚨 Troubleshooting

### Common Issues

**1. Terraform Deployment Fails**
```bash
# Check Azure CLI authentication
az account show

# Verify permissions
az role assignment list --assignee $(az account show --query user.name -o tsv)

# Check resource quotas
az vm list-usage --location "East US"
```

**2. Jenkins Setup Issues**
```bash
# SSH to Jenkins server
ssh jenkins@<jenkins-public-ip>

# Check Jenkins logs
sudo journalctl -u jenkins -f

# Restart Jenkins service
sudo systemctl restart jenkins
```

**3. Application Deployment Issues**
```bash
# Check AKS cluster status
kubectl cluster-info

# Check pod status
kubectl get pods -n vincent-portfolio
kubectl describe pod <pod-name> -n vincent-portfolio

# Check application logs
kubectl logs -f deployment/vincent-portfolio -n vincent-portfolio
```

**4. Container Registry Issues**
```bash
# Test ACR connectivity
az acr check-health --name <acr-name>

# Check image list
az acr repository list --name <acr-name>

# Manual docker login test
az acr login --name <acr-name>
```

## 🧹 Cleanup

To remove all resources and avoid ongoing charges:

```bash
# Delete Kubernetes resources
kubectl delete namespace vincent-portfolio

# Destroy infrastructure
terraform destroy

# Confirm all resources are deleted
az group list | grep vincent-portfolio
```

## 📚 Additional Resources

- [Azure Kubernetes Service Documentation](https://docs.microsoft.com/azure/aks/)
- [Azure Container Registry Documentation](https://docs.microsoft.com/azure/container-registry/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 🤝 Contributing

This is a personal portfolio project for Vincent Umeokoli. If you'd like to use this as a template:

1. Fork the repository
2. Update the personal information in `app/app.py`
3. Customize the templates and styling
4. Update the Terraform variables
5. Deploy your own version

## 👨‍💼 About Vincent

**Umeokoli Vincent Tochukwu** is a Cloud & DevOps Engineer with expertise in:
- ☁️ **Cloud Platforms**: AWS, Azure
- 🔧 **DevOps Tools**: Docker, Kubernetes, Jenkins, Terraform
- 💻 **Programming**: Python, Infrastructure as Code
- 🛡️ **Security**: RBAC, Network Policies, Container Security

**Contact:**
- 📧 Email: umeokolivincent@gmail.com
- 💼 LinkedIn: [linkedin.com/in/umeokoli-vincent-493885172](https://linkedin.com/in/umeokoli-vincent-493885172)
- 📞 Phone: 08137425765 | 09070782052

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

**Built with ❤️ by Vincent Umeokoli using Python Flask, Docker, Kubernetes, Terraform, and Jenkins**