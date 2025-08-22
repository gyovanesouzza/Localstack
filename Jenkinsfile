pipeline {
    agent any
    environment {
        SSH_REMOTE = "jenkins@192.168.100.161"
        PROJECT_DIR = "/home/project/Localstack"
    }
    stages {
        stage('Checkout from Git') {
            steps {
               
                git branch: 'main', url: 'git@github.com:gyovanesouzza/Localstack.git'
            }
        }
        
        stage('Deploy Remoto Completo') {
            steps {
                script {
     
                    sh """
                    ssh $SSH_REMOTE '
                      cd $PROJECT_DIR && 
                      git pull origin main &&
                      tflocal init && 
                      tflocal apply -parallelism=1 -auto-approve &&
                      docker compose up -d --build && 
                      ./run_tests.sh
                    '
                    """
                }
            }
        }
    }
    post {
        success {
            echo '✅ Pipeline concluída com sucesso!'
        }
        failure {
            echo '❌ Pipeline falhou.'
        }
    }
}