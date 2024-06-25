#!/bin/sh

# Signal file to indicate copy process is in progress
copy_signal="/var/www/html/wp-content/.copy_in_progress"

# Check if WordPress wp-content files are already present and the copy process is not in progress
if [ -f "/var/www/html/wp-content/index.php" ] && [ ! -f "$copy_signal" ]; then
    echo "WordPress wp-content already exists in /var/www/html/wp-content - skipping file copy."
    exit 0
fi

# Create the target directory if it does not exist
mkdir -p /var/www/html/wp-content

# Start by touching a file that indicates copying is in progress
touch $copy_signal

echo "Synchronizing WordPress wp-content to /var/www/html/wp-content..."

# Run rsync to copy WordPress wp-content files
rsync -av --inplace --progress /usr/src/wordpress/wp-content/ /var/www/html/wp-content/

# Remove the signal file to indicate the copy is complete
rm $copy_signal

echo "WordPress wp-content has been synchronized to /var/www/html/wp-content."