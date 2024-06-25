#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <repository-name>"
  exit 1
fi

REPOSITORY_NAME=$1
PROJECT_ID=$(gcloud config get-value project)

if [ -z "$PROJECT_ID" ]; then
  echo "No project ID set. Use 'gcloud config set project PROJECT_ID' to set the project."
  exit 1
fi

LOCATION=us-central1

gcloud artifacts repositories create $REPOSITORY_NAME \
    --repository-format=docker \
    --location=$LOCATION \
    --description="Docker repository for $REPOSITORY_NAME"

if [ $? -eq 0 ]; then
  echo "Artifact repository '$REPOSITORY_NAME' created successfully."
else
  echo "Failed to create artifact repository '$REPOSITORY_NAME'."
fi
