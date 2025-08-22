
stage('Build Lambdas') {
    steps {
        sh '''
            cd $WORKSPACE
            echo "Instalando dependências da Lambda..."
            mkdir lambda_pkg
            cp index.py lambda_pkg/
            echo "redis==5.0.1" > requirements.txt
            pip install -r requirements.txt -t lambda_pkg/
            cd lambda_pkg && zip -r ../lambda_from_sqs.zip . && zip -r ../lambda_direct.zip .
        '''
    }
}
