# @see https://github.com/TrafeX/docker-wordpress/tree/master
# @see https://github.com/TrafeX/docker-php-nginx/blob/master/Dockerfile
FROM trafex/php-nginx

USER root

# Install additional packages not included in the first configuration
RUN apk --update --no-cache add \
    php83-json \
    php83-zlib \
    php83-exif \
    php83-sodium \
    php83-simplexml \
    php83-zip \
    php83-iconv \
    php83-pecl-imagick \
    bash \
    less \
    gettext \
    rsync \
    lsof

# Copy the nginx server configuration
COPY config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY config/nginx/conf.d/* /etc/nginx/conf.d/
RUN chown nobody.nobody /etc/nginx/nginx.conf && chmod 640 /etc/nginx/nginx.conf
RUN chown nobody.nobody /etc/nginx/conf.d/* && chmod 640 /etc/nginx/conf.d/*

# Copy the PHP configuration
COPY config/php/php-fpm.d/* ${PHP_INI_DIR}/php-fpm.d/
COPY config/php/conf.d/* ${PHP_INI_DIR}/conf.d/

RUN chown nobody.nobody ${PHP_INI_DIR}/php-fpm.d/* && chmod 640 ${PHP_INI_DIR}/php-fpm.d/*
RUN chown nobody.nobody ${PHP_INI_DIR}/conf.d/* && chmod 640 ${PHP_INI_DIR}/conf.d/*

# WordPress - dynamically download the latest version
RUN mkdir -p /usr/src/wordpress && \
    curl -o wordpress.tar.gz -SL "https://wordpress.org/wordpress-latest.tar.gz" && \
    tar -xzf wordpress.tar.gz -C /usr/src/wordpress --strip-components=1 && \
    rm wordpress.tar.gz && \
    chown -R nobody.nobody /usr/src/wordpress

# Add WP CLI
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
&& chmod +x /usr/local/bin/wp

# WP config
COPY config/wordpress/wp-config.php /usr/src/wordpress/
RUN chmod 640 /usr/src/wordpress/wp-config.php

# Copy and run the secrets generation script
COPY root/generate_secrets.sh /usr/src/wordpress/
RUN chmod +x /usr/src/wordpress/generate_secrets.sh
RUN /usr/src/wordpress/generate_secrets.sh /usr/src/wordpress/wp-secrets.php

RUN mkdir -p /usr/src/wordpress/wp-content/mu-plugins
COPY config/wordpress/wp-content/mu-plugins/* /usr/src/wordpress/wp-content/mu-plugins/

# Copy the list of must plugins
COPY config/wordpress/plugins-download-list.txt /usr/src/wordpress/
COPY config/wordpress/mu-plugins-download-list.txt /usr/src/wordpress/
RUN chmod 640 /usr/src/wordpress/mu-plugins-download-list.txt
RUN chmod 640 /usr/src/wordpress/plugins-download-list.txt

# Copy and run the plugin installation script
COPY root/download_plugins.sh /usr/src/wordpress/
RUN chmod +x /usr/src/wordpress/download_plugins.sh
RUN /usr/src/wordpress/download_plugins.sh /usr/src/wordpress/plugins-download-list.txt /var/www/html/wp-content/plugins
RUN /usr/src/wordpress/download_plugins.sh /usr/src/wordpress/mu-plugins-download-list.txt /var/www/html/wp-content/mu-plugins

# Fix permissions
RUN chown -R nobody.nobody /usr/src/wordpress

# Copy WordPress to the web directory, so it can work without mounting the volume
RUN mkdir -p /var/www/html && \
    cp -a /usr/src/wordpress/. /var/www/html/ \
    && chown -R nobody.nobody /var/www/html

# Copy the custom scripts
COPY root/entrypoint.sh /entrypoint.sh
COPY root/sync_wordpress.sh /sync_wordpress.sh

# Give execution rights on the scripts
RUN chmod +x /entrypoint.sh
RUN chmod +x /sync_wordpress.sh

USER nobody

# Set the entrypoint to the custom script
ENTRYPOINT ["/entrypoint.sh"]

# Set the default port
ENV PORT=8080

# Healthcheck using the environment variable
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:$PORT/fpm-ping || exit 1