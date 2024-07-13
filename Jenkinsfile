pipeline {
    agent { label 'petclinic' }

    environment {
        DOCKER_STORAGE = 'testfiesta/petclinic'
        GITHUB_REPOSITORY = 'JustFiesta/spring-petclinic'
        SHORT_COMMIT = "${GIT_COMMIT[0..7]}"
        GITHUB_INFRASTRUCTURE_REPOSITORY_URL = 'https://github.com/JustFiesta/spring-petclinic-infrastructure'
        INFRASTRUCTURE_DIRECTORY = '~/spring-petclinic-infrastructure'
        ALB_NAME = 'capstone-alb'
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
        stage('Save Docker Image (MR)') {
            when {
                changeRequest()
            }
            steps {
                echo 'Saving Docker Image'
                sh 'docker save $DOCKER_STORAGE:${SHORT_COMMIT} -o $WORKSPACE/docker-image-${SHORT_COMMIT}.tar'
                archiveArtifacts artifacts: 'docker-image-${SHORT_COMMIT}.tar', fingerprint: true
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
        stage('Save Docker Image (Main)') {
            when {
                branch 'main'
            }
            steps {
                echo 'Saving Docker Image'
                sh 'docker save $DOCKER_STORAGE:$GIT_TAG -o $WORKSPACE/docker-image-${GIT_TAG}.tar'
                archiveArtifacts artifacts: 'docker-image-*.tar', fingerprint: true
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
        stage('Run Ansible Deploy from Workstation'){
            when {
                expression { params.ACTION == 'Deploy' }
            }
            steps{
                script {
                    withCredentials([string(credentialsId: 'workstation-ip', variable: 'IP')]) {
                        withCredentials([sshUserPrivateKey(credentialsId: 'aws-key', keyFileVariable: 'SSH_KEY')]) {
                            // Add workstation to known hosts
                            sh 'ssh-keyscan -H ${IP} >> ~/.ssh/known_hosts'

                            // Check if the directory already exists
                            def directoryExists = sh(
                                script: 'ssh -i ${SSH_KEY} ubuntu@${IP} "[ -d ~/spring-petclinic-infrastructure ] && echo \"true\" || echo \"false\""',
                                returnStdout: true
                            ).trim() == 'true'
                            
                            // If directory exists, remove it
                            if (directoryExists) {
                                sh 'ssh -i ${SSH_KEY} ubuntu@${IP} "rm -rf ~/spring-petclinic-infrastructure"'
                            }

                            // Clone repository application
                            sh 'ssh -i ${SSH_KEY} ubuntu@${IP} "git clone $GITHUB_INFRASTRUCTURE_REPOSITORY_URL"'

                            // Deploy application
                            sh 'ssh -i ${SSH_KEY} ubuntu@${IP} "cd $INFRASTRUCTURE_DIRECTORY/ansible && pwd && ansible-playbook playbooks/deploy-app.yml"'
                        }
                    }
                }
            }
        }
        stage('Print application link'){
            agent { label 'aws' }

            environment {
                AWS_DEFAULT_REGION="eu-west-1"
                AWS_CREDENTIALS=credentials('mbocak-credentials')
            }

            when {
                expression { params.ACTION == 'Deploy' }
            }

            steps{
                script {
                    def awsAlbDescribeCmd = 'aws elbv2 describe-load-balancers --names $ALB_NAME --query LoadBalancers[*].DNSName --output text'
                    def albDescribeOutput = sh(script: awsAlbDescribeCmd, returnStdout: true).trim()

                    echo "Application link: ${albDescribeOutput}" 
                }
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