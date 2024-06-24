#!/bin/bash

# Check if an instance name was provided
if [ -z "$1" ]; then
  echo "Usage: $0 INSTANCE_NAME"
  exit 1
fi

INSTANCE_NAME=$1
ZONE="us-central1-a"
MACHINE_TYPE="e2-micro" # Free tier eligible machine type
IMAGE_FAMILY="cos-stable"
IMAGE_PROJECT="cos-cloud"
BOOT_DISK_SIZE="30GB" # Free tier eligible boot disk size
TAGS="http-server,https-server,$INSTANCE_NAME"
NETWORK="default"
SUBNET="default"

# Set up a trap to handle script termination and cleanup
trap "exit" INT TERM ERR
trap "kill 0" EXIT

# Create the instance
echo "Creating instance $INSTANCE_NAME in zone $ZONE..."
gcloud compute instances create "$INSTANCE_NAME" \
    --zone="$ZONE" \
    --machine-type="$MACHINE_TYPE" \
    --image-family="$IMAGE_FAMILY" \
    --image-project="$IMAGE_PROJECT" \
    --boot-disk-size="$BOOT_DISK_SIZE" \
    --tags="$TAGS" \
    --network="$NETWORK" \
    --subnet="$SUBNET" \
    --metadata=startup-script='#! /bin/bash
        # Install Docker
        docker-credential-gcr configure-docker
        systemctl enable docker
        systemctl start docker'

# Make the IP publicly available for HTTP/HTTPS access
echo "Configuring firewall rules to allow HTTP/HTTPS traffic..."
gcloud compute firewall-rules create allow-http-https \
    --allow tcp:80,tcp:443 \
    --target-tags "$TAGS" \
    --description="Allow HTTP and HTTPS traffic" \
    --direction=INGRESS

# Wait for the instance to be up and running
echo "Waiting for the instance to be up and running..."
while true; do
  STATUS=$(gcloud compute instances describe "$INSTANCE_NAME" --zone="$ZONE" --format='get(status)')
  if [ "$STATUS" == "RUNNING" ]; then
    echo "Instance $INSTANCE_NAME is up and running."
    break
  else
    echo "Waiting for instance to start..."
    sleep 5
  fi
done

# Get the external IP address of the instance
EXTERNAL_IP=$(gcloud compute instances describe "$INSTANCE_NAME" --zone="$ZONE" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo "Instance $INSTANCE_NAME is created and accessible at http://$EXTERNAL_IP"