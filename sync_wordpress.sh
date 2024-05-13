#!/bin/sh

# Signal file to indicate copy process is in progress
copy_signal="/var/www/html/.copy_in_progress"

# Start by touching a file that indicates copying is in progress
touch $copy_signal

echo "Sychronizing WordPress to /var/www/html..."

# Run rsync to copy WordPress files
rsync -av --inplace --progress /usr/src/wordpress/ /var/www/html/

# Remove the signal file to indicate the copy is complete
rm $copy_signal

echo "File copy completed."
