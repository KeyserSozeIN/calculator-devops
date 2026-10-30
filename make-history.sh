#!/usr/bin/env bash
# Creates a clean, step-by-step git history with feature branches.
# Run ONCE, after ./configure.sh, from the project root:  ./make-history.sh
# Then: git remote add origin <your repo url> && git push -u origin --all
set -e

git init -b main
git add .gitignore README.md pom.xml
git commit -m "Initial project setup: Maven pom, .gitignore, README"

# ---- Feature branch 1: the application and tests ----
git checkout -b feature/calculator-api
git add src/main/java/com/santhosh/calculator/CalculatorApplication.java \
        src/main/java/com/santhosh/calculator/CalculatorService.java \
        src/main/resources/application.properties
git commit -m "Add Spring Boot app, calculator service and actuator config"

git add src/main/java/com/santhosh/calculator/CalculatorController.java
git commit -m "Add REST endpoints for add, subtract, multiply, divide"

git add src/main/java/com/santhosh/calculator/GlobalExceptionHandler.java
git commit -m "Add input validation and structured HTTP 400 error responses"

git add src/test
git commit -m "Add JUnit 5 unit tests and MockMvc integration tests"

git checkout main

# ---- Feature branch 2: Docker, Compose, Jenkins ----
git checkout -b feature/devops-pipeline
git add Dockerfile .dockerignore
git commit -m "Add multi-stage Dockerfile with non-root user and .dockerignore"

git add docker-compose.yml nginx
git commit -m "Add Docker Compose stack with Nginx proxy, healthcheck and restart policy"

git add Jenkinsfile configure.sh make-history.sh SETUP_GUIDE.md
git commit -m "Add declarative Jenkins pipeline: build, test, docker build, push, deploy"

git checkout main
echo
echo "History created. Branches:"
git branch
echo
echo "Next:"
echo "  git remote add origin https://github.com/<you>/calculator-devops.git"
echo "  git push -u origin --all"
echo "  Then open 2 Pull Requests on GitHub (feature/calculator-api and feature/devops-pipeline -> main) and merge them."
