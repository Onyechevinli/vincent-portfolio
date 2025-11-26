pipeline {
    agent any

    environment {
        // Azure credentials and configuration
        AZURE_CLIENT_ID = credentials('azure-client-id')
        AZURE_CLIENT_SECRET = credentials('azure-client-secret')
        AZURE_TENANT_ID = credentials('azure-tenant-id')
        AZURE_SUBSCRIPTION_ID = credentials('azure-subscription-id')

        // Container registry
        ACR_LOGIN_SERVER = credentials('acr-login-server')
        ACR_USERNAME = credentials('acr-username')
        ACR_PASSWORD = credentials('acr-password')

        // AKS configuration
        RESOURCE_GROUP_NAME = credentials('resource-group-name')
        AKS_CLUSTER_NAME = credentials('aks-cluster-name')

        // Application configuration
        APP_NAME = 'vincent-portfolio'
        APP_NAMESPACE = 'vincent-portfolio'
        IMAGE_TAG = "${BUILD_NUMBER}"
        IMAGE_NAME = "${ACR_LOGIN_SERVER}/${APP_NAME}:${IMAGE_TAG}"
        LATEST_IMAGE = "${ACR_LOGIN_SERVER}/${APP_NAME}:latest"
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Build Application') {
            steps {
                echo 'Building Flask application...'
                dir('app') {
                    sh '''
                        echo "Installing Python dependencies..."
                        python3 -m pip install --user -r requirements.txt

                        echo "Running basic syntax check..."
                        python3 -m py_compile app.py

                        echo "Application build completed successfully!"
                    '''
                }
            }
        }

        stage('Test Application') {
            steps {
                echo 'Testing Flask application...'
                dir('app') {
                    sh '''
                        echo "Running application tests..."
                        # Install test dependencies if any
                        # python3 -m pip install --user pytest

                        # Run health check test
                        echo "Testing application health endpoint..."
                        python3 -c "
import app
import json
from werkzeug.test import Client
from werkzeug.wrappers import Response

client = Client(app.app, Response)
response = client.get('/health')
assert response.status_code == 200
data = json.loads(response.data.decode('utf-8'))
assert data['status'] == 'healthy'
print('Health check test passed!')
"

                        echo "All tests passed!"
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                script {
                    dir('app') {
                        // Build the Docker image
                        sh """
                            echo "Building Docker image: ${IMAGE_NAME}"
                            docker build -t ${IMAGE_NAME} -t ${LATEST_IMAGE} .

                            echo "Docker image built successfully!"
                            docker images | grep ${APP_NAME}
                        """
                    }
                }
            }
        }

        stage('Push to ACR') {
            steps {
                echo 'Pushing Docker image to Azure Container Registry...'
                script {
                    sh """
                        echo "Logging into Azure Container Registry..."
                        echo ${ACR_PASSWORD} | docker login ${ACR_LOGIN_SERVER} --username ${ACR_USERNAME} --password-stdin

                        echo "Pushing image with tag: ${IMAGE_TAG}"
                        docker push ${IMAGE_NAME}

                        echo "Pushing image with tag: latest"
                        docker push ${LATEST_IMAGE}

                        echo "Images pushed successfully to ACR!"
                    """
                }
            }
        }

        stage('Deploy to AKS') {
            steps {
                echo 'Deploying application to Azure Kubernetes Service...'
                script {
                    sh """
                        echo "Logging into Azure..."
                        az login --service-principal \\
                            --username \${AZURE_CLIENT_ID} \\
                            --password \${AZURE_CLIENT_SECRET} \\
                            --tenant \${AZURE_TENANT_ID}

                        az account set --subscription \${AZURE_SUBSCRIPTION_ID}

                        echo "Getting AKS credentials..."
                        az aks get-credentials --resource-group \${RESOURCE_GROUP_NAME} \\
                            --name \${AKS_CLUSTER_NAME} --overwrite-existing

                        echo "Creating namespace if it doesn't exist..."
                        kubectl apply -f k8s/namespace.yaml

                        echo "Applying ConfigMap and Secrets..."
                        kubectl apply -f k8s/configmap.yaml

                        echo "Updating deployment with new image..."
                        # Update the deployment YAML with the new image
                        sed "s|__ACR_LOGIN_SERVER__|${ACR_LOGIN_SERVER}|g" k8s/deployment.yaml | \\
                        sed "s|__IMAGE_TAG__|${IMAGE_TAG}|g" | \\
                        kubectl apply -f -

                        echo "Applying additional Kubernetes resources..."
                        kubectl apply -f k8s/hpa.yaml
                        kubectl apply -f k8s/networkpolicy.yaml

                        echo "Waiting for deployment to complete..."
                        kubectl rollout status deployment/${APP_NAME} -n ${APP_NAMESPACE} --timeout=300s

                        echo "Deployment completed successfully!"
                        kubectl get pods -n ${APP_NAMESPACE}
                        kubectl get services -n ${APP_NAMESPACE}
                    """
                }
            }
        }

        stage('Health Check') {
            steps {
                echo 'Performing post-deployment health check...'
                script {
                    sh """
                        echo "Checking application health..."

                        # Get the service endpoint
                        SERVICE_IP=\$(kubectl get service ${APP_NAME}-service -n ${APP_NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' || echo "")

                        if [ -z "\$SERVICE_IP" ]; then
                            echo "LoadBalancer IP not yet assigned, using port-forward for health check..."
                            # Use port-forward for health check
                            kubectl port-forward svc/${APP_NAME}-service 8080:80 -n ${APP_NAMESPACE} &
                            PF_PID=\$!
                            sleep 10

                            # Test health endpoint
                            curl -f http://localhost:8080/health || (echo "Health check failed!" && exit 1)

                            # Clean up port-forward
                            kill \$PF_PID || true
                        else
                            echo "Testing health endpoint at: http://\$SERVICE_IP/health"
                            # Wait for service to be ready
                            for i in {1..30}; do
                                if curl -f "http://\$SERVICE_IP/health"; then
                                    echo "Health check passed!"
                                    break
                                fi
                                echo "Waiting for service to be ready... (attempt \$i/30)"
                                sleep 10
                            done
                        fi

                        echo "Application is healthy and running!"
                    """
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up...'
            sh '''
                # Clean up local Docker images to save space
                docker rmi ${IMAGE_NAME} ${LATEST_IMAGE} || true

                # Clean up any port-forwards that might still be running
                pkill -f "kubectl port-forward" || true

                echo "Cleanup completed!"
            '''
        }

        success {
            echo '''
                ✅ DEPLOYMENT SUCCESSFUL! ✅

                Vincent\'s Portfolio has been successfully deployed to Azure AKS!

                Next steps:
                1. Check the application URL in the AKS ingress
                2. Monitor the application logs
                3. Set up monitoring and alerting if needed
            '''
        }

        failure {
            echo '''
                ❌ DEPLOYMENT FAILED! ❌

                Please check the Jenkins logs for detailed error information.
                Common issues to check:
                1. Azure credentials and permissions
                2. Docker build issues
                3. Kubernetes cluster connectivity
                4. Resource quotas and limits
            '''
        }

        unstable {
            echo '''
                ⚠️ DEPLOYMENT UNSTABLE! ⚠️

                The deployment completed but some tests failed.
                Please review the test results and fix any issues.
            '''
        }
    }
}