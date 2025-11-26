// Jenkins Groovy Script to Setup Credentials for Vincent's Portfolio Pipeline
// This script should be run in Jenkins Script Console (Manage Jenkins > Script Console)

import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import hudson.util.Secret

def instance = Jenkins.getInstance()
def domain = Domain.global()
def store = instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

// Azure Service Principal Credentials
// These values should be obtained from Terraform outputs
def azureCredentials = [
    [id: 'azure-client-id', description: 'Azure Client ID', secret: System.getenv('AZURE_CLIENT_ID') ?: 'your-azure-client-id'],
    [id: 'azure-client-secret', description: 'Azure Client Secret', secret: System.getenv('AZURE_CLIENT_SECRET') ?: 'your-azure-client-secret'],
    [id: 'azure-tenant-id', description: 'Azure Tenant ID', secret: System.getenv('AZURE_TENANT_ID') ?: 'your-azure-tenant-id'],
    [id: 'azure-subscription-id', description: 'Azure Subscription ID', secret: System.getenv('AZURE_SUBSCRIPTION_ID') ?: 'your-azure-subscription-id'],
]

// Azure Container Registry Credentials
def acrCredentials = [
    [id: 'acr-login-server', description: 'ACR Login Server', secret: System.getenv('ACR_LOGIN_SERVER') ?: 'your-acr-login-server'],
    [id: 'acr-username', description: 'ACR Username', secret: System.getenv('ACR_USERNAME') ?: 'your-acr-username'],
    [id: 'acr-password', description: 'ACR Password', secret: System.getenv('ACR_PASSWORD') ?: 'your-acr-password'],
]

// AKS Cluster Credentials
def aksCredentials = [
    [id: 'resource-group-name', description: 'Resource Group Name', secret: System.getenv('RESOURCE_GROUP_NAME') ?: 'rg-vincent-portfolio'],
    [id: 'aks-cluster-name', description: 'AKS Cluster Name', secret: System.getenv('AKS_CLUSTER_NAME') ?: 'aks-vincent-portfolio'],
]

// Create credentials
def credentialsList = azureCredentials + acrCredentials + aksCredentials

credentialsList.each { cred ->
    def credential = new StringCredentialsImpl(
        CredentialsScope.GLOBAL,
        cred.id,
        cred.description,
        Secret.fromString(cred.secret)
    )

    store.addCredentials(domain, credential)
    println "Created credential: ${cred.id} - ${cred.description}"
}

// Create GitHub credentials (if using GitHub for source control)
def githubCredential = new StringCredentialsImpl(
    CredentialsScope.GLOBAL,
    'github-token',
    'GitHub Personal Access Token',
    Secret.fromString(System.getenv('GITHUB_TOKEN') ?: 'your-github-token')
)

store.addCredentials(domain, githubCredential)
println "Created credential: github-token - GitHub Personal Access Token"

// Save the credentials
instance.save()

println "\n✅ All credentials have been created successfully!"
println "\nIMPORTANT: Please update the credential values with actual values from your Terraform outputs:"
println "1. Go to Manage Jenkins > Manage Credentials"
println "2. Click on 'global' domain"
println "3. Update each credential with the correct values"
println "\nCredentials created:"
credentialsList.each { cred ->
    println "  - ${cred.id}: ${cred.description}"
}
println "  - github-token: GitHub Personal Access Token"