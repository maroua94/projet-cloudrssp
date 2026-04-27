pipeline {
    agent any
    stages {
        stage('Clone') {
            steps {
                git 'https://github.com/maroua94/projet-cloudrssp.git'
            }
        }
        stage('Build') {
            steps {
                sh 'docker build -t mon-app .'
            }
        }
        stage('Deploy') {
            steps {
                sh 'docker stop mon-app || true'
                sh 'docker rm mon-app || true'
                sh 'docker run -d --name mon-app -p 5000:5000 mon-app'
            }
        }
    }
}
