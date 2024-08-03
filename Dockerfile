
FROM composer AS build
WORKDIR /opt/workspace
COPY ./html/composer.json /opt/workspace
COPY ./html/composer.lock /opt/workspace
RUN composer install --ignore-platform-reqs

FROM php:8.3-apache

LABEL maintainer="Deepak Oberoi <hello@deepakoberoi.com> (@wpconsulate)"

# Enable Apache Rewrite + Expires Module
RUN a2enmod rewrite expires && \
    sed -i 's/ServerTokens OS/ServerTokens ProductOnly/g' \
    /etc/apache2/conf-available/security.conf

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libyaml-dev \
    libzip4 \
    libzip-dev \
    zlib1g-dev \
    libicu-dev \
    g++ \
    git \
    cron \
    vim \
    && docker-php-ext-install opcache \
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install zip \
    && rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
    echo 'upload_max_filesize=128M'; \
    echo 'post_max_size=128M'; \
    echo 'expose_php=off'; \
    } > /usr/local/etc/php/conf.d/php-recommended.ini


# install xdebug
RUN apt-get update -y && apt-get install -y libpng-dev git
RUN pecl install xdebug-3.3.2
RUN docker-php-ext-enable xdebug

# install APCu and YAML
RUN pecl install apcu \
    && pecl install yaml-2.2.3 \
    && docker-php-ext-enable apcu yaml

# Set user to www-data
RUN chown www-data:www-data /var/www
USER www-data

# # Define Grav specific version of Grav or use latest stable
# ARG GRAV_VERSION=latest

# Install grav
WORKDIR /var/www

# Create cron job for Grav maintenance scripts
RUN (crontab -l; echo "* * * * * cd /var/www/html;/usr/local/bin/php bin/grav scheduler 1>> /dev/null 2>&1") | crontab -

# Return to root user
USER root

WORKDIR /var/www

# Copy init scripts
# COPY docker-entrypoint.sh /entrypoint.sh

# provide container inside image for data persistence
# VOLUME ["/var/www/html"]

# ENTRYPOINT ["/entrypoint.sh"]
# CMD ["apache2-foreground"]
# CMD ["sh", "-c", "cron && apache2-foreground"]


COPY --from=composer /usr/bin/composer /usr/bin/composer
COPY --from=build /opt/workspace/vendor /opt/workspace/vendor
COPY --from=build /opt/workspace/composer.lock /opt/workspace/composer.lock