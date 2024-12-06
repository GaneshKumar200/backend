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
    nginx \
    curl \
    net-tools \  # Add net-tools for netstat
    procps      # Add procps for process management

# Rest of your existing Dockerfile remains the same...

# Modify the entrypoint script to handle port conflicts
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Function to check and kill process using port 9001\n\
kill_port_9001() {\n\
    echo "Checking for processes using port 9001..."\n\
    PORT_PID=$(lsof -t -i:9001)\n\
    if [ ! -z "$PORT_PID" ]; then\n\
        echo "Found process $PORT_PID using port 9001. Killing..."\n\
        kill -9 $PORT_PID\n\
        sleep 2\n\
    fi\n\
\n\
    # Additional cleanup\n\
    rm -f /var/run/supervisor.sock\n\
    rm -f /var/run/supervisord.pid\n\
}\n\
\n\
# Run port conflict resolution\n\
kill_port_9001\n\
\n\
# Run any pre-start scripts or migrations\n\
php artisan migrate --force\n\
php artisan config:clear\n\
php artisan cache:clear\n\
\n\
# Start cron\n\
service cron start\n\
\n\
# Execute the CMD passed to the entrypoint\n\
exec "$@"\n\
' > /usr/local/bin/docker-entrypoint

# Ensure executable permissions
RUN chmod +x /usr/local/bin/docker-entrypoint

# Set entrypoint and default command
ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
