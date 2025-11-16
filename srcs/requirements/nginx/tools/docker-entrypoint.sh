#!/bin/bash
set -e

# Generate SSL certificate if not exists
if [ ! -f /etc/nginx/ssl/nginx.crt ]; then
    echo "Generating SSL certificate..."
    mkdir -p /etc/nginx/ssl /usr/local/share/ca-certificates/
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=MA/ST=Morocco/L=Ben Guerir/O=42/OU=42/CN=elbaraka.42.fr"
    cp /etc/nginx/ssl/nginx.crt /usr/local/share/ca-certificates/
    update-ca-certificates
    echo "SSL certificate generated!"
fi

exec "$@"
