@Library('jenkins-shared-library@stable')_

pipeline {
    agent {
        label 'linux'
    }

    environment {
        COMMIT_SHA = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
    }

    stages {
        stage('SonarQube Analysis') {
            steps {
                echo 'Running SCA...'
                withSonarQubeEnv(installationName: 'SonarQubeServer', credentialsId: 'SonarQubeToken') {
                    sh "./mvnw clean verify sonar:sonar -Dsonar.projectKey=petclinic -Dsonar.projectName='petclinic'"
                }
            }
        }
        stage('Build Artifact') {
            steps {
                echo 'Building..'
                    sh "./mvnw package -DskipTests"
            }
        }
        stage('Building Image') {
            steps {
                echo 'Building Image..'
                buildDockerImage("mahmoudk1000/petclinic:${env.COMMIT_SHA}")
                dockerLogin()
                dockerPushImage("mahmoudk1000/petclinic:${env.COMMIT_SHA}")
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying soon IsA.'
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
