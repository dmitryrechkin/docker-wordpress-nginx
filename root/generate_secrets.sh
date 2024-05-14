#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 output_file"
    echo "output_file: The full path and filename where wp-secrets.php will be generated."
    exit 1
}

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    usage
fi

# Get the output file path from the argument
output_file="$1"

# Ensure the output directory exists
output_dir=$(dirname "$output_file")
mkdir -p "$output_dir"

# Fetch the secret keys and salts from the WordPress API
secrets=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)

# Process the fetched values to add conditional definitions
processed_secrets=$(echo "$secrets" | sed -E "s/define\('(.*)',\s*'(.*)'\);/defined('\1') || define('\1', '\2');/g")

# Write the processed values to the specified output file
cat <<EOL > "$output_file"
<?php
/**
 * Authentication unique keys and salts.
 *
 * Change these to different unique phrases! You can generate these using
 * the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}.
 *
 * You can change these at any point in time to invalidate all existing cookies.
 * This will force all users to have to log in again.
 *
 * @since 2.6.0
 */

$processed_secrets
EOL

echo "wp-secrets.php has been generated at $output_file"
