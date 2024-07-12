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

Dockerfile is provided, also compose file for testing is present. Additionally, there is compose file with provided sample connection string - one needs to change it accoring to RDS endpoint and user data.

For image creation basic Gradle image is used for build purposes, with addition of distroless layer for application. Image is split into layers according to (at time of creation and my knowlage) current standards, and optimalized for minimal size.

Also two compose files are present - one for testing connection string, other for providing container that connects to RDS.

### Versioning

Versioning is made using Gradle axion-release plugin. Pipeline creates release and pushes tags into repository using GitHub Credentials.

### Deployment

For deployment to run one needs to export manually enviroment variable named `RDS_DB` on Workstation, with correct endpoint from AWS Console. Otherwise compose will not work correctly (Bad gataway error on ALB). This enviroment variable will be passed to webservers via Ansible and used to connect containers to RDS endpoint.

Application is deploied with Ansible from Workstation. Jenkins connects to it via SSH and runs playbook which deploies fresh containers on webservers with docker compose.

For deployment to work correctly one needs to create IP address of workstation in Jenkinsfile credentials (workstation-ip) and ssh-copy-id is needed.

Deployment will remove old containers, pull new image, run application containers and prune system from unsused layers, images, etc.

If one changed default RDS identifier in Terraform configuration please provide it inside Jenkinsfile enviroment variable "RDS_INSTANCE_IDENTIFIER".
