pipeline {
    agent { label 'petclinic' }

    environment {
        DOCKER_STORAGE = 'testfiesta/petclinic'
        GITHUB_REPOSITORY = 'JustFiesta/spring-petclinic'
        SHORT_COMMIT = "${GIT_COMMIT[0..7]}"
    }

    tools {
        gradle '8.7'
    }

    parameters {
        choice(name: 'ACTION', choices: ['MR', 'Deploy'], description: 'Choose the action to perform')
    }

    stages {
        stage('Fetch repository tags') {
            steps {
                sh 'git fetch --tags'
            }
        }
        // Merge request pipeline
        stage('Checkstyle') {
            when {
                changeRequest()
            }
            steps{
                echo 'Running gradle checkstyle'
                sh './gradlew clean check -x test -x processTestAot -x processAot --no-daemon'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'build/reports/checkstyleNohttp/*.html', fingerprint: true
                }
            }
        }
        stage('Test') {
            when {
                changeRequest()
            }
            steps {
                echo 'Running gradle test'
                sh './gradlew clean test -x check -x processTestAot -x processAot --no-daemon'
            }
        }
        stage('Build') {
            when {
                changeRequest()
            }
            steps {
                echo 'Running build automation'
                sh './gradlew clean build -x test -x check -x checkFormat -x processTestAot -x processAot --no-daemon'
                archiveArtifacts artifacts: 'build/libs/*.jar', fingerprint: true
            }
        }
        stage('Docker Build (MR)') {
            when {
                changeRequest()
            }
            steps { 
                echo 'Building docker Image'
                sh 'docker build -t $DOCKER_STORAGE:${SHORT_COMMIT} .'
            }
        }
        stage('Docker Login (MR)') {
            when {
                changeRequest()
            }
            steps {
                echo 'Docker Repository Login'
                script{
                    withCredentials([usernamePassword(credentialsId: 'docker-cred', usernameVariable: 'USER', passwordVariable: 'PASS' )]){
                        sh 'echo $PASS | docker login -u $USER --password-stdin'
                    }    
                }
            }
        }
        stage('Docker Push (MR)') {
            when {
                changeRequest()
            }
            steps {
                echo 'Pushing Image to Docker repository'
                sh 'docker push $DOCKER_STORAGE:${SHORT_COMMIT}'
            }
        }

        // Main branch pipeline
        stage('Git tag the current state') {
            when {
                branch 'main'
            }
            steps { 
                echo 'Tagging'

                script {
                    withCredentials([usernamePassword(credentialsId: 'github-cred', usernameVariable: 'USER', passwordVariable: 'TOKEN')]) {
                        sh './gradlew release -Prelease.disableChecks -Prelease.pushTagsOnly -Prelease.customUsername="${USER}" -Prelease.customPassword="${TOKEN}"'
                    }

                    env.GIT_TAG = sh(script: './gradlew currentVersion | grep "Project version:" | sed "s/Project version: //"', returnStdout: true).trim()
                }
                echo "tag of recent release: $GIT_TAG"
            }
        }
        stage('Docker Build (Main)') {
            when {
                branch 'main'
            }
            steps { 
                echo 'Building docker Image'
                sh 'docker build -t $DOCKER_STORAGE:latest -t $DOCKER_STORAGE:$GIT_TAG .'
            }
        }
        stage('Docker Login (Main)') {
            when {
                branch 'main'
            }
            steps {
                echo 'Docker Repository Login'
                script{
                    withCredentials([usernamePassword(credentialsId: 'docker-cred', usernameVariable: 'USER', passwordVariable: 'PASS' )]){
                        sh 'echo $PASS | docker login -u $USER --password-stdin'
                    }
                }
            }
        }
        stage('Docker Push (Main)') {
            when {
                branch 'main'
            }
            steps {
                echo 'Pushing Image to Docker repository'
                sh 'docker push $DOCKER_STORAGE:$GIT_TAG'
                sh 'docker push $DOCKER_STORAGE:latest'
            }
        }
    }
    post {
        always {
            sh 'docker logout'
            cleanWs()
        }
    }
}