#!/bin/bash

# Check if sufficient parameters have been passed
if [ $# -lt 2 ]; then
    echo "Usage: $0 BUCKET_NAME ACCOUNT_NAME [REGION]"
    echo "REGION defaults to 'us-west1' if not provided."
    exit 1
fi

# Assign positional parameters to variables
bucket_name="$1"
account_name="$2"
region="${3:-us-west1}"  # If not provided, defaults to 'us-west1'

project=$(gcloud config get-value project)

# Construct the full service account email address
service_account_email="${account_name}@${project}.iam.gserviceaccount.com"

# Check if the bucket already exists
if gsutil ls "gs://$bucket_name" &>/dev/null; then
    echo "Bucket gs://$bucket_name already exists. Exiting."
    exit 0
fi

# Create the bucket
gsutil mb -l $region gs://$bucket_name

echo "Bucket gs://$bucket_name created in region $region."

# Grant storage admin rights to the service account for the bucket
gsutil iam ch serviceAccount:$service_account_email:roles/storage.admin gs://$bucket_name

echo "Granted Storage Admin rights to $service_account_email on gs://$bucket_name."

# Ensure all users in the project can view and manipulate objects in the bucket
gsutil iam ch projectEditor:${project}:roles/storage.admin gs://$bucket_name

echo "Granted object access to all project viewers and editors on gs://$bucket_name."