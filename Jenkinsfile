pipeline {
    agent any

    environment {
        // Global variables required by the scripts
        DOCKER_ORG = 'hegieswe'
        
        // Jenkins Credentials mappings
        // 1. Docker Hub 
        DOCKER_USERNAME = credentials('dockerhub-username')
        DOCKER_PASSWORD = credentials('dockerhub-password')
        
        // 2. Kubernetes Kubeconfig (Secret file)
        KUBECONFIG = credentials('k8s-kubeconfig-file')
        
        // 3. GitHub Credentials for pushing to k8s-manifest repo
        GITHUB_CRED = credentials('github-credentials')
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                // This will checkout golang-gitops-project (the app)
                checkout scm
                sh 'chmod +x ./ci.sh' // Ensure script is executable
                script {
                    env.APP_COMMIT = sh(script: 'git rev-parse --short=7 HEAD', returnStdout: true).trim()
                }
            }
        }

        stage('CI: Build & Push Image') {
            steps {
                script {
                    echo "Starting CI Build Process..."
                    // Execute ci.sh script. It automatically uses DOCKER_USERNAME and DOCKER_PASSWORD
                    // DOCKER_ORG is defined in the environment block.
                    sh './ci.sh'
                }
            }
        }

        stage('CD: Update Manifest & Deploy') {
            steps {
                script {
                    echo "Starting CD Deployment Process..."
                    
                    // Clone K8s Manifest Repo
                    // Replace github.com/hegieswe/k8s-manifest.git if it differs
                    withCredentials([usernamePassword(credentialsId: 'github-credentials', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                        sh '''
                        # Remove if previously existing in workspace
                        rm -rf k8s-manifest
                        
                        # Clone repository
                        git clone https://${GIT_USER}:${GIT_PASS}@github.com/hegieswe/k8s-manifest.git
                        
                        cd k8s-manifest
                        chmod +x ./cd.sh
                        
                        # Execute deployment to development environment
                        ./cd.sh -e development --tags "golang-gitops-project:${APP_COMMIT}"
                        
                        # Optional: push changes back to k8s-manifest repository
                        # git config --global user.email "jenkins@example.com"
                        # git config --global user.name "Jenkins CI"
                        # git add .
                        # git commit -m "Auto-update manifest image [skip ci]" || echo "No changes to commit"
                        # git push origin main
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            // Clean up workspace after build to save space
            cleanWs()
        }
        success {
            echo "CI/CD Pipeline Completed Successfully!"
        }
        failure {
            echo "CI/CD Pipeline Failed. Check the logs."
        }
    }
}
