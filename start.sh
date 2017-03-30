#!/bin/bash

# ------------------------------------------
# Set Custom Webroot
# ------------------------------------------

if [ ! -z "$WEBROOT" ]; then
    webroot=$WEBROOT
    sed -i "s#root /var/www;#root ${webroot};#g" /etc/nginx/sites-available/default.conf
else
    webroot=/var/www
fi

# ------------------------------------------
# Composer
# ------------------------------------------

if [ ! -z "$COMPOSER_DIRECTORY" ] ; then
    cd $COMPOSER_DIRECTORY
    composer update && composer dump-autoload -o
fi

# ------------------------------------------
# Laravel Specific
# ------------------------------------------

if [[ "$LARAVEL" == "1" ]] ; then
    cd $webroot
    php artisan key:generate

    if [[ "$RUN_MIGRATIONS" == "1" ]] ; then
        php artisan migrate
    fi
fi

# ------------------------------------------
# Display PHP error's or not
# ------------------------------------------

if [[ "$PRODUCTION" == "1" ]] || [[ "$IN_PRODUCTION" == "1" ]]; then
    echo php_flag[display_errors] = off >> /etc/php7/php-fpm.conf
    echo log_level = warning >> /etc/php7/php-fpm.conf
    sed -i "s/expose_php = On/expose_php = Off/g" /etc/php7/conf.d/php.ini
else
    echo php_flag[display_errors] = on >> /etc/php7/php-fpm.conf
fi

# ------------------------------------------
# Increase PHP limits
# ------------------------------------------

if [ ! -z "$PHP_MEMORY_LIMIT" ]; then
    sed -i "s/memory_limit = 128M/memory_limit = ${PHP_MEMORY_LIMIT}M/g" /etc/php7/conf.d/php.ini
fi

# ------------------------------------------
# Increase the post_max_size
# ------------------------------------------

if [ ! -z "$PHP_POST_MAX_SIZE" ]; then
    sed -i "s/post_max_size = 100M/post_max_size = ${PHP_POST_MAX_SIZE}M/g" /etc/php7/conf.d/php.ini
fi

# ------------------------------------------
# Increase the upload_max_filesize
# ------------------------------------------

if [ ! -z "$PHP_UPLOAD_MAX_FILESIZE" ]; then
    sed -i "s/upload_max_filesize = 100M/upload_max_filesize= ${PHP_UPLOAD_MAX_FILESIZE}M/g" /etc/php7/conf.d/php.ini
fi

sed -i "s/pm.max_children = 5/pm.max_children = 70/g" /etc/php7/php-fpm.d/www.conf
sed -i "s/pm.start_servers = 3/pm.start_servers = 20/g" /etc/php7/php-fpm.d/www.conf
sed -i "s/pm.min_spare_servers = 2/pm.min_spare_servers = 20/g" /etc/php7/php-fpm.d/www.conf
sed -i "s/pm.max_spare_servers = 4/pm.max_spare_servers = 35/g" /etc/php7/php-fpm.d/www.conf
sed -i "s/;pm.max_requests = 200/pm.max_requests = 0/g" /etc/php7/php-fpm.d/www.conf


# /etc/php7/php-fpm.d/www.conf
# CHANGE PHP SETTINGS FOR
# pm.max_children = 70
# pm.start_servers = 20
# pm.min_spare_servers = 20
# pm.max_spare_servers = 35
# pm.max_requests = 500


# ------------------------------------------
# Start supervisord and services
# ------------------------------------------

exec /usr/bin/supervisord -n -c /etc/supervisord.conf