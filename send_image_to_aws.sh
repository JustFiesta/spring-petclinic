#!/usr/bin/env bash
# -------------------
# This script sets builds and pushes image to previously made ECR
# 
# Reqiured: Docker, configured AWS CLI, EC2 key pair created from AWS

# Global data

AWS_ACCOUNT_ID=""

# Get data from user
echo "---------------------------------------"
echo ""
read -p "Enter your AWS account ID: " AWS_ACCOUNT_ID

# Build docker image locally
echo "---------------------------------------"
echo "Building Docker image..."
if docker build -t spring-petclinic .; then
    echo "Docker image built successfully."
else
    echo "Error: Failed to build Docker image."
    exit 1
fi

# Log in to ECR
echo "---------------------------------------"
echo "Logging in to Amazon ECR..."
DOCKER_LOGIN_CMD=$(aws ecr get-login-password --region "$REGION")

if [ -n "$DOCKER_LOGIN_CMD" ]; then
    echo "Got credentials from AWS CLI."
else
    echo "Error: Failed to get credentials from AWS CLI."
    exit 1
fi

if echo "$DOCKER_LOGIN_CMD" | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID".dkr.ecr."$REGION".amazonaws.com; then
    echo "Logged in to ECR successfully."
else
    echo "Error: Failed to log in to ECR."
    exit 1
fi

# Tag the image
echo "---------------------------------------"
echo "Tagging Docker image..."
if docker tag spring-petclinic:latest "$AWS_ACCOUNT_ID".dkr.ecr."$REGION".amazonaws.com/"$ECR_NAME":latest; then
    echo "Docker image tagged successfully."
else
    echo "Error: Failed to tag Docker image."
    exit 1
fi

# Push image to ECR
echo "---------------------------------------"
echo "Pushing Docker image to ECR..."
if docker push "$AWS_ACCOUNT_ID".dkr.ecr."$REGION".amazonaws.com/"$ECR_NAME":latest; then
    echo "Docker image pushed to ECR successfully."
else
    echo "Error: Failed to push Docker image to ECR."
    exit 1
fi

echo "Docker image has been successfully pushed to ECR."

./run_container_on_EC2.sh