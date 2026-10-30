// Declarative CI/CD pipeline for the Calculator REST API
// Stages: Checkout -> Build -> Test -> Docker Build -> Push -> Deploy
pipeline {
    agent any

    environment {
        DOCKERHUB_USER = 'imt2023065'          // <- your Docker Hub username
        IMAGE_NAME     = "${DOCKERHUB_USER}/calculator"
        IMAGE_TAG      = "${BUILD_NUMBER}"
        NOTIFY_EMAIL   = 'santhoshkiraniiitb@gmail.com'                   // <- build status mails go here
    }

    triggers {
        githubPush()                 // GitHub webhook (preferred)
        pollSCM('H/2 * * * *')       // fallback: poll GitHub every ~2 minutes
    }

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh 'mvn -B clean package -DskipTests'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn -B test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:latest .
                '''
            }
        }

        stage('Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                                                  usernameVariable: 'DH_USER',
                                                  passwordVariable: 'DH_PASS')]) {
                    sh '''
                        echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${IMAGE_NAME}:latest
                        docker logout
                    '''
                }
            }
        }

        stage('Deploy') {
            steps {
                // Same project name every time => re-running just updates the stack (idempotent)
                sh '''
                    export DOCKERHUB_USER=${DOCKERHUB_USER}
                    export IMAGE_TAG=${IMAGE_TAG}
                    docker compose -p calculator pull
                    docker compose -p calculator up -d --remove-orphans

                    echo "Waiting for health check..."
                    for i in $(seq 1 30); do
                        if curl -sf http://localhost:8081/actuator/health | grep -q UP; then
                            echo "Deployment healthy"
                            docker compose -p calculator ps
                            exit 0
                        fi
                        sleep 5
                    done
                    echo "Health check failed"
                    docker compose -p calculator logs --tail=50
                    exit 1
                '''
            }
        }
    }

    post {
        success {
            mail to: "${NOTIFY_EMAIL}",
                 subject: "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                 body: "Build succeeded and was deployed.\nImage: ${IMAGE_NAME}:${IMAGE_TAG}\nDetails: ${env.BUILD_URL}"
        }
        failure {
            mail to: "${NOTIFY_EMAIL}",
                 subject: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                 body: "Build failed.\nCheck the console output: ${env.BUILD_URL}console"
        }
    }
}
