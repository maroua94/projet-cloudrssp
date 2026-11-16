pipeline {
    agent any

    stages {
        stage('Tests') {
            steps {
                sh 'docker build --target test -t mon-app:test .'
            }
        }

        stage('Secrets (Gitleaks)') {
            steps {
                sh '''
                    docker rm -f gitleaks-scan || true
                    docker create --name gitleaks-scan zricethezav/gitleaks:v8.28.0 detect --source /repo --no-git --redact -v
                    docker cp . gitleaks-scan:/repo
                    RC=0
                    docker start -a gitleaks-scan || RC=$?
                    docker rm -f gitleaks-scan
                    exit $RC
                '''
            }
        }

        stage('Build') {
            steps {
                sh 'docker build --target final -t mon-app:${BUILD_NUMBER} .'
            }
        }

        stage('Scan image (Trivy)') {
            steps {
                sh '''
                    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v trivy-cache:/root/.cache/ \
                        aquasec/trivy:0.74.0 image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 mon-app:${BUILD_NUMBER}
                '''
            }
        }

        stage('Deploy + rollback') {
            steps {
                sh '''
                    OLD_IMG=$(docker inspect -f '{{.Image}}' mon-app 2>/dev/null || true)
                    docker rm -f mon-app || true
                    docker run -d --name mon-app --restart unless-stopped -p 5000:5000 \
                        --health-interval=3s --health-timeout=3s --health-retries=3 \
                        mon-app:${BUILD_NUMBER}
                    for i in $(seq 1 20); do
                        STATUS=$(docker inspect -f '{{.State.Health.Status}}' mon-app)
                        echo "Health: $STATUS ($i/20)"
                        [ "$STATUS" = "healthy" ] && exit 0
                        sleep 3
                    done
                    echo "Health check FAILED - rollback"
                    docker rm -f mon-app || true
                    if [ -n "$OLD_IMG" ]; then
                        docker run -d --name mon-app --restart unless-stopped -p 5000:5000 "$OLD_IMG"
                    fi
                    exit 1
                '''
            }
        }
    }
}
