#!/bin/bash
set -e

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
until mysqladmin ping -h"mariadb" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; do
    echo "MariaDB is unavailable - sleeping"
    sleep 2
done
echo "MariaDB is up!"

# Download WordPress if not already present
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "WordPress not found. Installing..."
    
    cd /var/www/html
    
    # Download WordPress
    wp core download --allow-root
    
    # Create wp-config.php
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="${DB_HOST}" \
        --allow-root
    
    # Install WordPress
    wp core install \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --allow-root
    
    # Create additional user
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
        --role=editor \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root
    
    # Set correct permissions
    chown -R www-data:www-data /var/www/html
    
    echo "WordPress installed successfully!"
else
    echo "WordPress already installed!"
fi

exec "$@"
