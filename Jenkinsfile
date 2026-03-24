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
                // This will checkout the app repository
                checkout scm
                script {
                    // Auto-detect commit hash and repo name dynamically from Git remote URL
                    env.APP_COMMIT = sh(script: 'git rev-parse --short=7 HEAD', returnStdout: true).trim()
                    env.APP_NAME   = sh(script: "git config --get remote.origin.url | sed -E 's/.*\\/([^\\/]+)(\\.git)?\$/\\1/' | sed 's/\\.git\$//'", returnStdout: true).trim()
                    
                    // Inject DOCKER_REPO into environment so ci.sh catches it perfectly
                    env.DOCKER_REPO = env.APP_NAME
                }
            }
        }

        stage('CI: Build & Push Image') {
            steps {
                script {
                    echo "Starting CI Build Process for ${env.APP_NAME}..."
                    // ci.sh automatically detects the repo name if DOCKER_REPO is not explicitly set
                    sh 'ci.sh'
                }
            }
        }

        stage('CD: Update Manifest & Deploy') {
            steps {
                script {
                    echo "Starting CD Deployment Process for ${env.APP_NAME}..."
                    
                    withCredentials([usernamePassword(credentialsId: 'github-credentials', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                        sh '''
                        # Remove if previously existing in workspace
                        rm -rf k8s-manifest
                        
                        # Clone repository
                        git clone https://${GIT_USER}:${GIT_PASS}@github.com/hegieswe/k8s-manifest.git
                        
                        cd k8s-manifest
                        
                        # Execute global cd.sh dynamically using APP_NAME
                        cd.sh -e development --tags "${APP_NAME}:${APP_COMMIT}"
                        
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
