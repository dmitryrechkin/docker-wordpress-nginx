#!/bin/bash

# Helper method to parse env file and output environment variables
function parse_env_file() {
    local file=$1

    if [ ! -f "$file" ]; then
        return
    fi

    local prefix=$2
    local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')

    sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $file |
    awk -F$fs "{
        indent = length(\$1)/2;
        vname[indent] = \$2;
        for (i in vname) {
            if (i > indent) {
                delete vname[i]
            }
        }

        if (length(\$3) > 0) {
            vn=\"\"; 
            for (i=0; i<indent; i++) {
                vn=(vn)(vname[i])(\"_\")
            }
            printf(\"%s%s%s=%s\\n\", \"$prefix\", vn, \$2, \$3);
        }
    }"
}

# Process command line arguments
service=""
bucket=""
service_account=""
region="us-west1"  # Default region
project=""
env_file=".env"  # Default env file
image=""
memory="1024Mi"
cpu="1"
timeout="300s"
concurrency="25"
min_instances="0"
max_instances="100"
port="8080"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --region=*) region="${1#*=}"; shift ;;
        --project=*) project="${1#*=}"; shift ;;
        --env_file=*) env_file="${1#*=}"; shift ;;
        --image=*) image="${1#*=}"; shift ;;
        --bucket=*) bucket="${1#*=}"; shift ;;
        --memory=*) memory="${1#*=}"; shift ;;
        --cpu=*) cpu="${1#*=}"; shift ;;
        --timeout=*) timeout="${1#*=}"; shift ;;
        --concurrency=*) concurrency="${1#*=}"; shift ;;
        --min_instances=*) min_instances="${1#*=}"; shift ;;
        --max_instances=*) max_instances="${1#*=}"; shift ;;
        --port=*) port="${1#*=}"; shift ;;
        *) 
            if [ -z "$service" ]; then
                service="$1"
            elif [ -z "$service_account" ]; then
                service_account="$1"
            fi
            shift ;;
    esac
done

# Default values if not set
service_account=${service_account:-$service}

# Check if service is provided
if [ -z "$service" ]; then
    echo "Usage: $0 SERVICE [SERVICE_ACCOUNT] [--key=value]..."
    echo "Parameters:"
    echo "SERVICE: The service name. (required)"
    echo "SERVICE_ACCOUNT: The service account. (default: SERVICE)"
    echo "Options:"
    echo "--region=value: The region for the service. (default: us-central1)"
    echo "--project=value: The project name for the service."
    echo "--env_file=value: The file with environment variables. (default: .env.yaml)"
    echo "--bucket=value: The bucket name for the service."
    echo "--image=image:revision The image:revision to deploy. (default: gcr.io/project/service:latest)"
    echo "--memory=value: The maximum amount of memory the service can use. (default: 512Mi)"
    echo "--cpu=value: The maximum amount of CPU the service can use. (default: 1)"
    echo "--timeout=value: The maximum amount of time the service can run. (default: 300s)"
    echo "--concurrency=value: The maximum number of concurrent requests allowed for the service. (default: 80)"
    echo "--min_instances=value: The minimum number of instances for the service. (default: 0)"
    echo "--max_instances=value: The maximum number of instances for the service. (default: 80)"
    echo "--port=value: The port for the service. (default: 80)"
    exit 1
fi


if [ -n "$project" ]; then
    echo "Setting project to $project..."
    gcloud config set project $project
else
    project=$(gcloud config get-value project)
    echo "Project is set to $project."
fi

# Assign values with defaults
region=${region:-"us-west1"}
env_file=${env_file:-".env"}

CURRENT_DIR=$(pwd)
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_DIR")"; pwd -P)/$(basename "$SCRIPT_DIR")"

echo "Service: $service"
echo "Project: $project"
echo "Region: $region"
echo "Service Account: $service_account"
echo "Memory: $memory"
echo "CPU: $cpu"
echo "Timeout: $timeout"
echo "Concurrency: $concurrency"
echo "Env File: $env_file"
echo "Bucket: $bucket"

# Create the bucket if provided
if [ -n "$bucket" ]; then
    $SCRIPT_DIR/gcloud_create_bucket.sh $bucket $service_account $region
fi

# Change directory to the root of the project
cd $SCRIPT_DIR/..

image_not_found="true"

if [ -n "$image" ]; then
    repository=${image%:*}
    tag=${image#*:}

    if gcloud container images list-tags $repository --filter="tags:$tag" --format='get(tags)' | grep -q "$tag"; then
        echo "Image $image exists, skipping build."
        image_not_found="false"
    fi
fi

# If image is not set or image is not found, build the image
if [ -z "$image" ] || [ "$image_not_found" = "true" ]; then
    # Set image as the default if not provided
    image=${image:-"gcr.io/$project/$service:latest"}

    echo "Building $image..."
    gcloud builds submit --tag $image .
fi

echo "Reading environment variables from $env_file..."

env_vars=$(parse_env_file $env_file "--set-env-vars ")

echo "Building and deploying $service to Google Cloud Run..."

cmd="gcloud beta run deploy $service \
    --execution-environment gen2 \
    --allow-unauthenticated \
    --port $port \
    --image $image"

if [ -n "$bucket" ]; then
    cmd="$cmd  --add-volume=name=data,type=cloud-storage,bucket=$bucket \
    --add-volume-mount=volume=data,mount-path='/var/www/html'"
fi

# If service account is set, append it to the command
if [ -n "$service_account" ]; then
    cmd="$cmd --service-account $service_account"
fi

# If region is set, append it to the command
if [ -n "$region" ]; then
    cmd="$cmd --region $region"
fi

# If memory is set, append it to the command
if [ -n "$memory" ]; then
    cmd="$cmd --memory $memory"
fi

# If cpu is set, append it to the command
if [ -n "$cpu" ]; then
    cmd="$cmd --cpu $cpu"
fi

# If timeout is set, append it to the command
if [ -n "$timeout" ]; then
    cmd="$cmd --timeout $timeout"
fi

# If concurrency is set, append it to the command
if [ -n "$concurrency" ]; then
    cmd="$cmd --concurrency $concurrency"
fi
# If min_instances is set, append it to the command
if [ -n "$min_instances" ]; then
    cmd="$cmd --min-instances $min_instances"
fi

# If max_instances is set, append it to the command
if [ -n "$max_instances" ]; then
    cmd="$cmd --max-instances $max_instances"
fi

# If env_vars is set, append it to the command
if [ -n "$env_vars" ]; then
    cmd="$cmd $env_vars"
fi

echo "Executing command: $cmd"

# Run the final command
eval $cmd

cd $CURRENT_DIR
