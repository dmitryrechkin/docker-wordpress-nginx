#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR=$(dirname "$0")

# Call the generate_secrets.sh script and capture its output
secrets=$("$SCRIPT_DIR/generate_secrets.sh")

# Set the secrets in Dokku
dokku config:set $secrets