#!/bin/sh

# @see https://github.com/TrafeX/docker-wordpress/blob/master/entrypoint.sh

# terminate on errors
set -e

# Run original entrypoint logic
echo "Running entrypoint logic..."

# Sync WordPress CORE files
/sync_wp_core.sh &

# Sync wp-content files
/sync_wp_content.sh &

# ================================

echo "Preparing nginx configuration..."

# Default PORT to 80 if not set
PORT=${PORT:-80}

# Export the PORT environment variable so it can be substituted
export PORT

# Use envsubst to replace only the $PORT variable in the nginx config
envsubst '$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

# ================================

# We want to manually start PHP-FPM and Nginx so we can ensure PHP-FPM is ready before Nginx starts

echo "Launching PHP-FPM..."

php-fpm -D

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