# Use php-fpm image
FROM mediawiki:stable-fpm

# Install packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    cron \
    bash \
    curl \
    lua5.1-dev \
    nginx \
    supervisor \
    unzip \
    && \
    chown -Rf www-data:www-data /var/lib/nginx

# Install extra php extensions
RUN pecl install luasandbox; \
	docker-php-ext-enable \
		luasandbox \
	; \
    rm -r /tmp/pear

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
COPY config/var/www/html/composer.local.json /var/www/html

# Copy all configuration values to their respective directories
COPY config /

# Install scripts and run extension installer
COPY scripts /scripts
RUN chmod -R +x /scripts/; \
    /bin/bash /scripts/extensionInstaller.sh && \
    rm /scripts/extensionInstaller.sh && \
    chown -Rf www-data:www-data /scripts

# Set file permissions
RUN chmod -R 644 /etc/cron.d

CMD ["/scripts/entrypoint.sh"]