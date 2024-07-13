# Sprint-petclinic codebase

This repository contains codebase (*spring petclinic application*) for capstone project.

For capstone project I made some changes in this code base. Mainly in: Dockerfile, Jenkinsfile and build.gradle.

Also I learned how to use MySQL for spring petclinic - it reqiures some enviroment variables:

* MYSQL_USER
* MYSQL_PASSWORD
* MYSQL_ROOT_PASSWORD
* MYSQL_DATABASE
* MYSQL_URL

They are needed for conenction to RDS. One can use it via `docker -e MYSQL_...` or `export MYSQL_...` (for `java -jar` usage).

<hr>

## Overview

### Build

* Application is built with Gradle 8.X
* Checkstyle is provided via Gradle plugin
* Semantic Versioning is provided via Axion Release plugin

### Dockerfile

`Dockerfile` and `compose.yaml` is provided. Additionally, there is compose file for tests.

The RDS endpoint is provided via enviroment variable exported manually on workstation (`RDS_DB`).

For image creation basic Gradle image is used for build purposes, with addition of distroless layer for application. Image is split into layers according to (at time of creation and my knowlage) current standards, and optimalized for minimal size.

### Versioning

Versioning is made using Gradle axion-release plugin. Pipeline creates release and pushes tags into repository using GitHub Credentials.

### Pipeline

Jenkins pipeline runs on agent with specyfic label (`petclinic`).

Pipeline steps include:

* Fetching tags from repository
* Gradle: checkstyle, test, build
* Docker: build, login, push
* Run Ansible deploy playbook from Worker VM.

Pipeline is split into two parts based on given parameter (Default "MR" - serves as merge request build).

Parameters:

* MR pushes docker artifact to Dockerhub (default "testfiesta/petclinic") with short commit tag.
* Deploy pushes artifact to Dockerhub with lastest and version tags. Then Jenkins runs ansible playbook for deploying latest tag into webservers.

### Deployment

For deployment to run one needs to export manually enviroment variable named `RDS_DB` on Workstation, with correct endpoint from AWS Console. Otherwise compose will not work correctly (Bad gataway error on ALB). This enviroment variable will be passed to webservers via Ansible and used to connect containers to RDS endpoint.

Application is deploied with Ansible from Workstation. Jenkins connects to it via SSH and runs playbook which deploies fresh containers on webservers with docker compose.

For deployment to work correctly one needs to create credentials (`workstation-ip`) in Jenkins for **IP address of workstation**.

Deployment will: pull new image, remove old containers, run application containers and prune system from unsused layers, images, etc.

If one changed default ALB name in Terraform configuration please provide it inside Jenkinsfile enviroment variable "ALB_NAME" - this is used to print out application link.
