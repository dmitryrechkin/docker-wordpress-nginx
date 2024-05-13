#!/bin/bash

# Check if sufficient parameters have been passed
if [ $# -lt 1 ]; then
    echo "Usage: $0 ACCOUNT_NAME"
    exit 1
fi

# Assign positional parameters to variables
account_name="$1"
project=$(gcloud config get-value project)

# Create service account
gcloud iam service-accounts create $account_name

# Add storage admin role to the service account
gcloud projects add-iam-policy-binding $project \
    --member "serviceAccount:$account_name@$project.iam.gserviceaccount.com" \
    --role "roles/storage.objectAdmin"

echo "Service account $account_name created and storage.objectAdmin role assigned in project $project."
