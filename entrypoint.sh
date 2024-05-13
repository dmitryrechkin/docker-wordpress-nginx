#!/bin/sh

# @see https://github.com/TrafeX/docker-wordpress/blob/master/entrypoint.sh

# terminate on errors
set -e

# Path to the sync script
SYNC_SCRIPT="/sync_wordpress.sh"

# Signal file to indicate copy process is in progress
copy_signal="/var/www/html/.copy_in_progress"

# Run original entrypoint logic
echo "Running original entrypoint logic..."

# Check if wp-config.php does not exist and a copy operation is not already in progress
if [ ! -f "/var/www/html/wp-config.php" ] || [ -f "$copy_signal" ]; then
    mkdir -p /var/www/html/wp-content/

    # Touch the signal file to indicate that the copy operation is starting
    touch $copy_signal

    # Run the sync script in the background
    $SYNC_SCRIPT &
fi

# Check if wp-secrets.php exists, we store it inside of wp-content so it won't be killed by the wordpress upgrade
if ! [ -f "/var/www/html/wp-content/wp-secrets.php" ]; then
    # Check that secrets environment variables are not set
    if [ ! $AUTH_KEY ] \
    && [ ! $SECURE_AUTH_KEY ] \
    && [ ! $LOGGED_IN_KEY ] \
    && [ ! $NONCE_KEY ] \
    && [ ! $AUTH_SALT ] \
    && [ ! $SECURE_AUTH_SALT ] \
    && [ ! $LOGGED_IN_SALT ] \
    && [ ! $NONCE_SALT ]; then
        echo "Generating wp-secrets.php"
        # Generate secrets
        echo '<?php' > /var/www/html/wp-content/wp-secrets.php
        curl -f https://api.wordpress.org/secret-key/1.1/salt/ >> /var/www/html/wp-content/wp-secrets.php

        mkdir -p /var/www/html/wp-content/

        ln -s /var/www/html/wp-content/wp-secrets.php /var/www/html/wp-secrets.php
    fi
fi

# ================================

echo "Checking and installing plugins..."
if [ -f "/usr/src/wordpress/plugins-download-list.txt" ]; then
    mkdir -p /var/www/html/wp-content/plugins/

    while IFS= read -r plugin_url; do
        plugin_name=$(basename "$plugin_url" .zip)  # Assuming plugin URLs end with '.zip'
        
        # Check if the plugin directory already exists
        if [ ! -d "/var/www/html/wp-content/plugins/$plugin_name" ]; then
            echo "Downloading and installing ${plugin_name}..."
            curl -L -o plugin.zip "$plugin_url" && \
            unzip -o plugin.zip -d /var/www/html/wp-content/plugins/ && \
            rm plugin.zip
        else
            echo "${plugin_name} is already installed."
        fi
    done < /usr/src/wordpress/plugins-download-list.txt
fi

# ================================

echo "Preparing nginx configuration..."

# Default PORT to 80 if not set
PORT=${PORT:-80}

# Export the PORT environment variable so it can be substituted
export PORT

# Use envsubst to replace only the $PORT variable in the nginx config
envsubst '$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

# ================================

echo "Launching PHP-FPM..."

php-fpm83 -D

# Wait until PHP-FPM Unix socket is available
while ! lsof /run/php-fpm.sock; do
  echo "$(date) INFO Waiting for PHP-FPM service..."
  sleep 1
done

echo "$(date) INFO PHP-FPM service is ready. Starting Nginx..."

# Start nginx
nginx -g 'daemon off;'

# Execute the original CMD
exec "$@"