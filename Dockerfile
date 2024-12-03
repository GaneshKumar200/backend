# Use the PHP base image from the docker-compose configuration
ARG PHP_VERSION=8.2
FROM php:${PHP_VERSION}-fpm AS php

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
    vim \
    unzip \
    git \
    supervisor \
    cron \
    libicu-dev \
    nano \
    nginx

# Set locales
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y locales \
    && sed -i -e 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG=ru_RU.UTF-8
ENV LANG ru_RU.UTF-8
ENV LC_ALL ru_RU.UTF-8

# Clean up package lists
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-source extract \
    && docker-php-ext-install bcmath exif pcntl pdo_mysql zip sockets \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd \
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl \
    && pecl install redis-5.3.4 \
    && docker-php-ext-enable redis \
    && docker-php-source delete

# Install MySQL client
RUN apt-get update && apt-get install default-mysql-client -y

# Configure OPcache
RUN docker-php-ext-configure opcache --enable-opcache \
    && docker-php-ext-install opcache

# Use production PHP configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Copy Nginx configuration
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx/conf.d/ /etc/nginx/conf.d/

# Copy supervisor configuration
COPY docker/php/supervisord.conf /etc/supervisord.conf

# Copy crontab
COPY docker/php/crontab /etc/cron.d/crontab
RUN chmod 0644 /etc/cron.d/crontab

# Copy entrypoint script
COPY docker/php/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

# Copy Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Copy backend files
COPY --chown=www-data:www-data . /var/www

# Expose ports
EXPOSE 80 8000

# Set entrypoint and default command
ENTRYPOINT ["docker-entrypoint"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
