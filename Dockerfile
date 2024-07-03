# @see https://github.com/TrafeX/docker-php-nginx/blob/master/Dockerfile

ARG ALPINE_VERSION=3.20
ARG PHP_VERSION_SUFFIX=83
FROM alpine:${ALPINE_VERSION}
LABEL Maintainer="Dmitry Rechkin <rechkin@gmail.com>"
LABEL Description="Lightweight container with Nginx & PHP for WordPress on Alpine Linux."

# Persist the PHP version and PHP configuration directory as environment variables
ARG PHP_VERSION_SUFFIX
ENV PHP_VERSION_SUFFIX=${PHP_VERSION_SUFFIX}
ENV PHP_INI_DIR /etc/php${PHP_VERSION_SUFFIX}

# Set the default port
ENV PORT=8080

# Setup document root
WORKDIR /var/www/html

# Install packages and remove default server definition
RUN apk --update --no-cache add \
    curl \
    nginx \
    php${PHP_VERSION_SUFFIX} \
    php${PHP_VERSION_SUFFIX}-ctype \
    php${PHP_VERSION_SUFFIX}-curl \
    php${PHP_VERSION_SUFFIX}-dom \
    php${PHP_VERSION_SUFFIX}-fileinfo \
    php${PHP_VERSION_SUFFIX}-fpm \
    php${PHP_VERSION_SUFFIX}-gd \
    php${PHP_VERSION_SUFFIX}-intl \
    php${PHP_VERSION_SUFFIX}-mbstring \
    php${PHP_VERSION_SUFFIX}-mysqli \
    php${PHP_VERSION_SUFFIX}-opcache \
    php${PHP_VERSION_SUFFIX}-openssl \
    php${PHP_VERSION_SUFFIX}-phar \
    php${PHP_VERSION_SUFFIX}-session \
    php${PHP_VERSION_SUFFIX}-tokenizer \
    php${PHP_VERSION_SUFFIX}-xml \
    php${PHP_VERSION_SUFFIX}-xmlreader \
    php${PHP_VERSION_SUFFIX}-xmlwriter \
    php${PHP_VERSION_SUFFIX}-json \
    php${PHP_VERSION_SUFFIX}-zlib \
    php${PHP_VERSION_SUFFIX}-exif \
    php${PHP_VERSION_SUFFIX}-sodium \
    php${PHP_VERSION_SUFFIX}-simplexml \
    php${PHP_VERSION_SUFFIX}-zip \
    php${PHP_VERSION_SUFFIX}-iconv \
    php${PHP_VERSION_SUFFIX}-pecl-imagick \
    php${PHP_VERSION_SUFFIX}-redis \
    bash \
    less \
    gettext \
    rsync \
    lsof \
    openssl \
    ca-certificates \
    supervisor

# Update the CA certificates
RUN update-ca-certificates

# Adjust OpenSSL configuration
RUN echo -e "\n[system_default_sect]\nMinProtocol = TLSv1.2\nCipherString = DEFAULT@SECLEVEL=1" >> /etc/ssl/openssl.cnf

# Link php-fpm to php-fpm${PHP_VERSION_SUFFIX} so we can call a generic command, if it does not exist
RUN if [ ! -f /usr/sbin/php-fpm ]; then ln -s /usr/sbin/php-fpm${PHP_VERSION_SUFFIX} /usr/sbin/php-fpm; fi

# Link php to php${PHP_VERSION_SUFFIX} so we can call a generic command, if it does not exist
RUN if [ ! -f /usr/bin/php ]; then ln -s /usr/bin/php${PHP_VERSION_SUFFIX} /usr/bin/php; fi

# Copy the nginx server configuration
COPY config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY config/nginx/conf.d/* /etc/nginx/conf.d/
COPY config/nginx/conf.d/vhost.d/ /etc/nginx/conf.d/vhost.d/

# Change permissions to nobody
RUN chown nobody.nobody /etc/nginx/nginx.conf && chmod 640 /etc/nginx/nginx.conf
# We need the entrypoint to be able to overwrite the configuration because it sets port dynamically
RUN chown -R nobody.nobody /etc/nginx/conf.d && chmod 755 /etc/nginx/conf.d && chmod 644 /etc/nginx/conf.d/*

# Copy the PHP configuration
COPY config/php/php-fpm.d/* ${PHP_INI_DIR}/php-fpm.d/
COPY config/php/conf.d/* ${PHP_INI_DIR}/conf.d/

# Change permissions to nobody
RUN chown nobody.nobody ${PHP_INI_DIR}/php-fpm.d/* && chmod 640 ${PHP_INI_DIR}/php-fpm.d/*
RUN chown nobody.nobody ${PHP_INI_DIR}/conf.d/* && chmod 640 ${PHP_INI_DIR}/conf.d/*

# Configure supervisord
COPY --chown=nobody config/supervisord/conf.d/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessible when they run under the nobody user
RUN chown -R nobody.nobody /var/www/html /run /var/lib/nginx /var/log/nginx /var/log/php*

# WordPress - dynamically download the latest version
RUN mkdir -p /usr/src/wordpress && \
    curl -o wordpress.tar.gz -SL "https://wordpress.org/wordpress-latest.tar.gz" && \
    tar -xzf wordpress.tar.gz -C /usr/src/wordpress --strip-components=1 && \
    rm wordpress.tar.gz

# Add WP CLI and adjust permissions
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
&& chmod +x /usr/local/bin/wp && chown nobody.nobody /usr/local/bin/wp

# Copy WP config and adjust permissions
COPY --chown=nobody config/wordpress/wp-config.php /usr/src/wordpress/
RUN chmod 640 /usr/src/wordpress/wp-config.php

# Copy and run the secrets generation script
COPY --chown=nobody root/generate_secrets.sh /usr/src/wordpress/
RUN chmod +x /usr/src/wordpress/generate_secrets.sh
RUN /usr/src/wordpress/generate_secrets.sh /usr/src/wordpress/wp-secrets.php

# Copy the must use plugins
RUN mkdir -p /usr/src/wordpress/wp-content/mu-plugins
COPY --chown=nobody config/wordpress/wp-content/mu-plugins/* /usr/src/wordpress/wp-content/mu-plugins/

# Copy the list of must plugins
COPY --chown=nobody config/wordpress/plugins-download-list.txt /usr/src/wordpress/
COPY --chown=nobody config/wordpress/mu-plugins-download-list.txt /usr/src/wordpress/
RUN chmod 640 /usr/src/wordpress/mu-plugins-download-list.txt
RUN chmod 640 /usr/src/wordpress/plugins-download-list.txt

# Copy and run the plugin installation script
COPY --chown=nobody root/download_plugins.sh /usr/src/wordpress/
RUN chmod +x /usr/src/wordpress/download_plugins.sh
RUN /usr/src/wordpress/download_plugins.sh /usr/src/wordpress/plugins-download-list.txt /usr/src/wordpress/wp-content/plugins
RUN /usr/src/wordpress/download_plugins.sh /usr/src/wordpress/mu-plugins-download-list.txt /usr/src/wordpress/wp-content/mu-plugins

# Remove the plugin installation script
RUN rm /usr/src/wordpress/download_plugins.sh

# Fix permissions
RUN chown -R nobody.nobody /usr/src/wordpress

# Copy WordPress to the web directory so it can work without mounting the volume
RUN mkdir -p /var/www/html && \
    cp -a /usr/src/wordpress/. /var/www/html/ \
    && chown -R nobody.nobody /var/www/html

# Copy entrypoint script
COPY root/entrypoint.sh /entrypoint.sh
# Give execute permissions to the entrypoint script
RUN chmod +x /entrypoint.sh

# Copy WordPress sync scripts
COPY root/sync_wp_core.sh /sync_wp_core.sh
COPY root/sync_wp_content.sh /sync_wp_content.sh

# Give execute permissions to the sync scripts
RUN chmod +x /sync_wp_core.sh
RUN chmod +x /sync_wp_content.sh

USER nobody

# Set the entrypoint to the custom script
ENTRYPOINT ["/entrypoint.sh"]

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Healthcheck using the environment variable
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:$PORT/fpm-ping || exit 1