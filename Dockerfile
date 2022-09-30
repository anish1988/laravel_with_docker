ARG NODE_VERSION=8.11
ARG PHP_VERSION=7.4.30
ARG NGINX_VERSION=1.16
#
# Composer
#
FROM composer:1.7 as vendor

WORKDIR /app

COPY web/database/ database/

COPY web/composer.json composer.json
COPY web/composer.lock composer.lock

RUN composer install \
    --ignore-platform-reqs \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --prefer-dist

#
# PHP Application
#
FROM php:${PHP_VERSION}-fpm-buster as php

# Libs and extensions
RUN apt update \
  && apt install -y libxml2-dev \ 
    libonig-dev \
    xfonts-75dpi \
    zlib1g-dev \
    libpng-dev \
    xfonts-base \
    libxrender1 \
    libxext6 \
    libxcb1 \
    libx11-6 \
    libjpeg62-turbo \
    fontconfig \
    procps \
  && pecl install -f xdebug \
  && docker-php-ext-install mysqli soap opcache pdo_mysql mbstring exif pcntl bcmath gd \
  && rm -rf /var/lib/apt/lists/*

# wkhtmltopdf
COPY docker/php/wkhtmltox_0.12.6-1.buster_amd64.deb /opt/wkhtmltox_0.12.6-1.buster_amd64.deb
RUN dpkg -i /opt/wkhtmltox_0.12.6-1.buster_amd64.deb && rm /opt/wkhtmltox_0.12.6-1.buster_amd64.deb

# XDebug Config
COPY --chown=www-data:www-data docker/php/conf.d/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# Opcache
ENV PHP_OPCACHE_VALIDATE_TIMESTAMPS="0" \
    PHP_OPCACHE_MAX_ACCELERATED_FILES="5000" \
    PHP_OPCACHE_MEMORY_CONSUMPTION="192" \
    PHP_OPCACHE_MAX_WASTED_PERCENTAGE="10"

COPY --chown=www-data:www-data docker/php/conf.d/opcache.ini /usr/local/etc/php/conf.d/opcache.ini 

COPY --from=vendor --chown=www-data:www-data /app/vendor/ /var/www/html/vendor/

COPY docker/php/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

COPY --chown=www-data:www-data web /var/www/html

RUN chmod -R 755 /var/www/html/storage

ENTRYPOINT ["docker-entrypoint"]
CMD ["php-fpm"]

#
# Nginx Proxy
#
FROM nginx:${NGINX_VERSION}-alpine AS nginx

# Remove any existing config files
RUN  rm /etc/nginx/conf.d/* /etc/nginx/nginx.conf
COPY docker/nginx/conf.d/default.conf /etc/nginx/conf.d/default.tmpl
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /var/www/html
WORKDIR /var/www/html

COPY --from=php /var/www/html/public public/

ARG UPSTREAM=php
ENV UPSTREAM $UPSTREAM
CMD /bin/sh -c "envsubst '\$UPSTREAM' < /etc/nginx/conf.d/default.tmpl > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;' || cat /etc/nginx/conf.d/default.conf"
