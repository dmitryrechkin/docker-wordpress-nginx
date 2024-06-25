#!/bin/bash

# Fetch the salts from the WordPress API
response=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)

# Convert the response into KEY="VALUE" format
formatted_response=$(echo "$response" | sed -e "s/define('\(.*\)', *'\(.*\)');/\\1=\"\\2\"/" | tr '\n' ' ')

# Output the formatted response
echo "$formatted_response"