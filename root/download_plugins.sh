#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 plugin_list_path download_path"
    echo "plugin_list_path: The full path to the list of plugins to download."
    echo "download_path: The directory where the plugins will be downloaded."
    exit 1
}

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    usage
fi

# Get the plugin list path and download path from the arguments
plugin_list_path="$1"
download_path="$2"

# Ensure the plugin list file exists
if [ ! -f "$plugin_list_path" ]; then
    echo "Error: Plugin list file not found at $plugin_list_path"
    exit 1
fi

# Ensure the download directory exists
mkdir -p "$download_path"

echo "Downloading plugins from $plugin_list_path list..."

# Function to download a plugin with retry logic
download_plugin() {
    local plugin_url="$1"
    local plugin_name="$2"
    local max_retries=5
    local retry_delay=5
    local attempt=1

    while [ $attempt -le $max_retries ]; do
        echo "Attempt $attempt: Downloading and unzipping ${plugin_name}..."
        curl -L -o plugin.zip "$plugin_url"
        if [ $? -eq 0 ]; then
            unzip -o plugin.zip -d "$download_path"
            if [ $? -eq 0 ]; then
                rm plugin.zip
                echo "${plugin_name} downloaded and unzipped successfully."
                return 0
            else
                echo "Error unzipping ${plugin_name}. Retrying in $retry_delay seconds..."
            fi
        else
            echo "Error downloading ${plugin_name}. Retrying in $retry_delay seconds..."
        fi
        sleep $retry_delay
        attempt=$((attempt + 1))
    done

    echo "Failed to download ${plugin_name} after $max_retries attempts."
    return 1
}

# Read the plugin list file and download each plugin
while IFS= read -r plugin_url; do
    plugin_name=$(basename "$plugin_url" .zip)  # Assuming plugin URLs end with '.zip'
    
    echo "Processing plugin URL: $plugin_url"

    # Check if the plugin directory already exists
    if [ ! -d "$download_path/$plugin_name" ]; then
        download_plugin "$plugin_url" "$plugin_name"
    else
        echo "${plugin_name} is already installed."
    fi
done < "$plugin_list_path"