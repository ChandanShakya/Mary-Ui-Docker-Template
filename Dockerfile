FROM dunglas/frankenphp:latest

# Install performance-related PHP extensions
RUN install-php-extensions \
    pcntl \
    pdo_pgsql \
    zip \
    opcache \
    apcu \
    redis \
    bcmath \
    intl \
    xdebug

# Configure PHP for production performance
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.enable_cli=1" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.memory_consumption=128" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.max_accelerated_files=10000" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.validate_timestamps=0" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "realpath_cache_size=4096K" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "realpath_cache_ttl=600" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.jit=1255" >> /usr/local/etc/php/conf.d/opcache.ini && \
    echo "opcache.jit_buffer_size=50M" >> /usr/local/etc/php/conf.d/opcache.ini

# Set recommended PHP production settings for limited resources
RUN echo "memory_limit=256M" >> /usr/local/etc/php/conf.d/php.ini && \
    echo "max_execution_time=30" >> /usr/local/etc/php/conf.d/php.ini && \
    echo "display_errors=Off" >> /usr/local/etc/php/conf.d/php.ini && \
    echo "log_errors=On" >> /usr/local/etc/php/conf.d/php.ini && \
    echo "error_reporting=E_ALL & ~E_DEPRECATED & ~E_STRICT" >> /usr/local/etc/php/conf.d/php.ini && \
    echo "zend.assertions=-1" >> /usr/local/etc/php/conf.d/php.ini && \
    echo "upload_max_filesize=10M" >> /usr/local/etc/php/conf.d/php.ini && \
    echo "post_max_size=10M" >> /usr/local/etc/php/conf.d/php.ini && \
    echo "expose_php=Off" >> /usr/local/etc/php/conf.d/php.ini

# Configure Xdebug (disabled by default)
RUN echo "xdebug.mode=off" >> /usr/local/etc/php/conf.d/xdebug.ini && \
    echo "xdebug.start_with_request=trigger" >> /usr/local/etc/php/conf.d/xdebug.ini && \
    echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/xdebug.ini && \
    echo "xdebug.client_port=9003" >> /usr/local/etc/php/conf.d/xdebug.ini && \
    echo "xdebug.log=/tmp/xdebug.log" >> /usr/local/etc/php/conf.d/xdebug.ini && \
    echo "xdebug.idekey=VSCODE" >> /usr/local/etc/php/conf.d/xdebug.ini

WORKDIR /app

# Add health check endpoint
COPY --chown=www-data:www-data ./docker-health-check.php /app/public/health.php

# Use multi-stage build to keep final image clean
RUN apt-get update && apt-get install -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set default configuration for Octane
ENV OCTANE_SERVER=frankenphp \
    OCTANE_HTTPS=0

ENTRYPOINT ["php", "artisan", "octane:frankenphp"]