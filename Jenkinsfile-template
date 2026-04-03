pipeline {
    agent any

    environment {
        // Global variables required by the scripts
        // Sesuaikan dengan org Docker Hub Anda
        DOCKER_ORG = 'hegieswe'
        
        // Jenkins Credentials mappings
        DOCKER_USERNAME = credentials('dockerhub-username')
        DOCKER_PASSWORD = credentials('dockerhub-password')
        KUBECONFIG = credentials('k8s-kubeconfig-file')
        GITHUB_CRED = credentials('github-credentials')
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                checkout scm
                script {
                    // Ambil commit hash
                    env.APP_COMMIT = sh(script: 'git rev-parse --short=7 HEAD', returnStdout: true).trim()
                    
                    // ========================================================
                    // PENTING: Ganti nama ini dengan "hi-golang-project" 
                    // atau "hi-golang-project" sesuai dengan nama service
                    // ========================================================
                    env.APP_NAME   = 'hi-golang-project'
                    
                    // Inject ke var lingkungan agar tertangkap oleh ci.sh & cd.sh
                    env.DOCKER_REPO = env.APP_NAME
                }
            }
        }

        stage('CI: Build & Push Image') {
            steps {
                script {
                    echo "Starting CI Build Process for ${env.APP_NAME}..."
                    // ci.sh otomatis akan nge-build dan mem-push image
                    // dengan nama: hegieswe/hi-golang-project
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
                        rm -rf k8s-manifest
                        git clone https://${GIT_USER}:${GIT_PASS}@github.com/hegieswe/k8s-manifest.git
                        cd k8s-manifest
                        
                        # cd.sh akan mencari folder "hi-golang-project" 
                        # di dalam "k8s-manifest/base/" untuk di-kuromize/deploy
                        cd.sh -e development --tags "${APP_NAME}:${APP_COMMIT}"
                        
                        # Wajib: push perubahan terbaru ke GitHub (GitOps)
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
