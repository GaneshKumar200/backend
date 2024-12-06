# Use the PHP base image from the docker-compose configuration
ARG PHP_VERSION=8.2
FROM php:${PHP_VERSION}-fpm AS php

# Install system dependencies in a single layer to reduce image size
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libicu-dev \
    zip \
    unzip \
    git \
    supervisor \
    cron \
    nginx \
    default-mysql-client \
    jpegoptim \
    optipng \
    pngquant \
    gifsicle \
    locales \
    nano \
    vim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set locales for Russian language support
RUN sed -i -e 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=ru_RU.UTF-8

# Set environment variables for locale
ENV LANG ru_RU.UTF-8
ENV LC_ALL ru_RU.UTF-8

# Install PHP extensions in a single layer
RUN docker-php-source extract \
    && docker-php-ext-install \
        bcmath \
        exif \
        pcntl \
        pdo_mysql \
        zip \
        sockets \
        intl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd \
    && docker-php-ext-configure opcache --enable-opcache \
    && docker-php-ext-install opcache \
    && pecl install redis-5.3.4 \
    && docker-php-ext-enable redis \
    && docker-php-source delete

# Use production PHP configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Copy configuration files
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx/conf.d/ /etc/nginx/conf.d/
COPY docker/php/supervisord.conf /etc/supervisord.conf
COPY docker/php/crontab /etc/cron.d/crontab
COPY docker/php/docker-entrypoint.sh /usr/local/bin/docker-entrypoint

# Set proper permissions for configuration files
RUN chmod 0644 /etc/cron.d/crontab \
    && chmod +x /usr/local/bin/docker-entrypoint

# Copy Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Copy application files
COPY --chown=www-data:www-data . /var/www

# Expose ports
EXPOSE 80 8000

# Set entrypoint and default command
ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
