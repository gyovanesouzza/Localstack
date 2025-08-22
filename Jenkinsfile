pipeline {
    agent any
    environment {
        SSH_REMOTE = "jenkins@192.168.100.161"
        PROJECT_DIR = "/home/project/Localstack"
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'git@github.com:gyovanesouzza/Localstack.git'
            }
        }
        stage('Update Remote') {
            steps {
                sh "ssh -o StrictHostKeyChecking=no $SSH_REMOTE 'cd $PROJECT_DIR && git pull origin main'"
            }
        }
        stage('Terraform Init & Apply') {
            steps {
                sh """
                ssh $SSH_REMOTE '
                  cd $PROJECT_DIR &&
                  terraform init &&
                  terraform apply -auto-approve
                '
                """
            }
        }
        stage('Docker Compose Up') {
            steps {
                sh """
                ssh $SSH_REMOTE '
                  cd $PROJECT_DIR &&
                  docker compose up -d --build
                '
                """
            }
        }
        stage('Test') {
            steps {
                sh "ssh $SSH_REMOTE 'cd $PROJECT_DIR && ./run_tests.sh'"
            }
        }
    }
    post {
        success {
            echo 'Pipeline concluída com sucesso!'
        }
        failure {
            echo 'Pipeline falhou.'
        }
    }
}
