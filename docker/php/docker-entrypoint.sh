#!/bin/sh
set -e

role=${CONTAINER_ROLE:-app}
env=${APP_ENV:-production}

if [ "$env" != "local" ]; then
    echo "Caching configuration..."
    (cd /var/www/html && php artisan config:cache && php artisan route:cache)

    echo "Removing Xdebug..."
    rm -rf /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini || true
    rm -rf /usr/local/etc/php/conf.d/xdebug.ini || true
fi

if [ "$env" == "local" ] && [ ! -z "$DEV_UID" ]; then
    echo "Changing www-data UID to $DEV_UID"
    echo "The UID should only be changed in development environments."
    usermod -u $DEV_UID www-data
fi

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- php-fpm "$@"
fi

su - www-data -s /bin/sh -c 'cd /var/www/html'

exec docker-php-entrypoint "$@"
