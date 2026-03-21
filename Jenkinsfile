pipeline {
    agent any

    environment {
        // Global variables required by the scripts
        DOCKER_ORG = 'hegieswe'
        DOCKER_REPO = 'golang-gitops-project'
        
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
                script {
                    env.APP_COMMIT = sh(script: 'git rev-parse --short=7 HEAD', returnStdout: true).trim()
                }
            }
        }

        stage('CI: Build & Push Image') {
            steps {
                script {
                    echo "Starting CI Build Process..."
                    // Execute global ci.sh script.
                    sh 'ci.sh'
                }
            }
        }

        stage('CD: Update Manifest & Deploy') {
            steps {
                script {
                    echo "Starting CD Deployment Process..."
                    
                    withCredentials([usernamePassword(credentialsId: 'github-credentials', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                        sh '''
                        # Remove if previously existing in workspace
                        rm -rf k8s-manifest
                        
                        # Clone repository
                        git clone https://${GIT_USER}:${GIT_PASS}@github.com/hegieswe/k8s-manifest.git
                        
                        cd k8s-manifest
                        
                        # Execute global cd.sh
                        cd.sh -e development --tags "golang-gitops-project:${APP_COMMIT}"
                        
                        # Wajib: push perubahan manifest kembali ke repository k8s-manifest
                        git config --global user.email "jenkins@example.com"
                        git config --global user.name "Jenkins CI"
                        git add .
                        git commit -m "Auto-update manifest image [skip ci]" || echo "No changes to commit"
                        git push origin main
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
