#!/bin/bash
set -e

# Generate SSL certificate if not exists
if [ ! -f /etc/nginx/ssl/nginx.crt ]; then
    echo "Generating SSL certificate..."
    mkdir -p /etc/nginx/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=MA/ST=Morocco/L=Khouribga/O=42/OU=42/CN=elbaraka.42.fr"
    echo "SSL certificate generated!"
fi

exec "$@"
