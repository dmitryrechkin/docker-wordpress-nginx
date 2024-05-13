#!/bin/sh

# Signal file to indicate copy process is in progress
copy_signal="/var/www/html/.copy_in_progress"

# Start by touching a file that indicates copying is in progress
touch $copy_signal

echo "Sychronizing WordPress to /var/www/html..."

# Run rsync to copy WordPress files
rsync -av --inplace --progress /usr/src/wordpress/ /var/www/html/

# Check if the mu-plugins download lists exist and download the plugins
if [ -f "/var/www/html/wordpress/mu-plugins-download-list.txt" ]; then
    /usr/src/wordpress/download_plugins.sh /var/www/html/wordpress/mu-plugins-download-list.txt /var/www/html/wp-content/mu-plugins
	rm /var/www/html/wordpress/mu-plugins-download-list.txt
fi

# Check if the plugins download list exists and download the plugins
if [ -f "/var/www/html/wordpress/plugins-download-list.txt" ]; then
    /usr/src/wordpress/download_plugins.sh /var/www/html/wordpress/plugins-download-list.txt /var/www/html/wp-content/plugins
	rm /var/www/html/wordpress/plugins-download-list.txt
fi

# Check if wp-secrets.php exists and generate it if it does not
if ! [ -f "/var/www/html/wp-secrets.php" ]; then
    /usr/src/wordpress/generate_secrets.sh /var/www/html/wp-secrets.php
fi

# Remove the signal file to indicate the copy is complete
rm $copy_signal

echo "File copy completed."
