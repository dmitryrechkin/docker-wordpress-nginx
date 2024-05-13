#!/bin/sh

# @see https://github.com/TrafeX/docker-wordpress/blob/master/entrypoint.sh

# terminate on errors
set -e

# Path to the sync script
SYNC_SCRIPT="/sync_wordpress.sh"

# Signal file to indicate copy process is in progress
copy_signal="/var/www/html/.copy_in_progress"

# Run original entrypoint logic
echo "Running entrypoint logic..."

# Check if wp-config.php does not exist or if copy operation is already in progress
if [ ! -f "/var/www/html/wp-config.php" ] || [ -f "$copy_signal" ]; then
    echo "WordPress not found in /var/www/html - copying WordPress files..."

    # Touch the signal file to indicate that the copy operation is starting
    #touch $copy_signal

    # Run the sync script in the background
    #$SYNC_SCRIPT &

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