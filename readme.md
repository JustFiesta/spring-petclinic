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

Versioning is made using Gradle axion-release plugin. Pipeline creates local release and pushes tags into repository using GitHub Credentials.
