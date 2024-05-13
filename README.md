
# WordPress Docker Container with NGINX and PHP-FPM

Lightweight WordPress container with NGINX 1.24 & PHP-FPM 8.3 based on Alpine Linux. Optimized for deployment on Google Cloud Run.

_WordPress version currently installed:_ **6.5**

* Used in production for many sites, making it stable, tested, and up-to-date
* Optimized for 100 concurrent users
* Optimized to only use resources when there's traffic (by using PHP-FPM's `ondemand` PM)
* Works with Amazon Cloudfront or CloudFlare as SSL terminator and CDN
* Multi-platform, supporting AMD64, ARMv6, ARMv7, ARM64
* Built on the lightweight and secure Alpine Linux distribution
* Small Docker image size (+/-90MB)
* Uses PHP 8.3 for the best performance, low CPU usage, and memory footprint
* Can safely be updated without losing data
* Fully configurable because `wp-config.php` uses the environment variables you can pass as arguments to the container

[![Docker Pulls](https://img.shields.io/docker/pulls/trafex/wordpress.svg)](https://hub.docker.com/r/trafex/wordpress/)
![nginx 1.24](https://img.shields.io/badge/nginx-1.24-brightgreen.svg)
![php 8.3](https://img.shields.io/badge/php-8.3-brightgreen.svg)
![License MIT](https://img.shields.io/badge/license-MIT-blue.svg)

## Goal of this project

The goal of this container image is to provide a WordPress environment optimized for Google Cloud Run, based on best practices for NGINX and PHP-FPM container configurations. It is derived from Trafex's images but tailored specifically for Cloud Run deployments.

## Local Build and Run

To build this Docker image locally:

```sh
docker build -t wordpress-nginx:latest .
```

To run this Docker image locally:

```sh
docker run -d -p 8080:8080 wordpress-nginx:latest
```

## Deployment on Google Cloud Run

To deploy this Docker image to Google Cloud Run:

```sh
scripts/gcloud_deploy.sh cloudrun-wordpress-test
```

After the first deployment, it may take some time for the instance to become fully usable. This delay is due to the synchronization of files to the Google Cloud Storage bucket, which can take a while.

## Configuration

In the `config/` folder, you'll find the default configuration files for NGINX, PHP, and PHP-FPM. 

To extend or customize, mount a configuration file with docker in the correct folder:

NGINX configuration:

```sh
docker run -v "`pwd`/nginx-server.conf:/etc/nginx/conf.d/server.conf" wordpress-nginx:latest
```

PHP configuration:

```sh
docker run -v "`pwd`/php-setting.ini:/etc/php83/conf.d/settings.ini" wordpress-nginx:latest
```

PHP-FPM configuration:

```sh
docker run -v "`pwd`/php-fpm-settings.conf:/etc/php83/php-fpm.d/server.conf" wordpress-nginx:latest
```

_Note: Because `-v` requires an absolute path, `pwd` is used in the example to return the absolute path to the current directory._

## Documentation and examples

To modify this container to your specific needs, please see the following examples:

* [Adding xdebug support](https://github.com/TrafeX/docker-php-nginx/blob/master/docs/xdebug-support.md)
* [Adding composer](https://github.com/TrafeX/docker-php-nginx/blob/master/docs/composer-support.md)
* [Getting the real IP of the client behind a load balancer](https://github.com/TrafeX/docker-php-nginx/blob/master/docs/real-ip-behind-loadbalancer.md)
* [Sending e-mails](https://github.com/TrafeX/docker-php-nginx/blob/master/docs/sending-emails.md)

## Additional Features

This Docker image allows you to mount `/var/www/html`, containing the entire WordPress installation, so it can be updated without rebuilding the image.
