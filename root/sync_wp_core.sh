#!/bin/sh

# Signal file to indicate copy process is in progress
copy_signal="/var/www/html/.copy_in_progress"

# Check if WordPress CORE files are already present and the copy process is not in progress
if [ -f "/var/www/html/wp-config.php" ] && [ ! -f "$copy_signal" ]; then
    echo "WordPress CORE already exists in /var/www/html - skipping file copy."
    exit 0
fi

# Create the target directory if it does not exist
mkdir -p /var/www/html

# Start by touching a file that indicates copying is in progress
touch $copy_signal

echo "Synchronizing WordPress CORE to /var/www/html..."

# Run rsync to copy WordPress files, excluding 'wp-content' and 'wp-secrets.php'
rsync -av --inplace --progress --exclude 'wp-content' --exclude 'wp-secrets.php' /usr/src/wordpress/ /var/www/html/

# Check if wp-secrets.php exists and generate it if it does not
if [ ! -f "/var/www/html/wp-secrets.php" ]; then
    /usr/src/wordpress/generate_secrets.sh /var/www/html/wp-secrets.php
fi

# Remove the signal file to indicate the copy is complete
rm $copy_signal

echo "WordPress CORE has been synchronized to /var/www/html."