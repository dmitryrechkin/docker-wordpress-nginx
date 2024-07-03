
# WordPress Docker Container with NGINX and PHP-FPM

This project, derived from Trafex’s images, aims to provide a high-performance WordPress environment optimized for Google Cloud Run, Dokku, other Kubernetes clusters, and serverless environments. It is based on best practices for NGINX and PHP-FPM configurations using Alpine Linux.

## Features

* Includes the latest version of WordPress
* Allows specification of essential and optional WordPress plugins
* Compatible with TiDB Serverless database
* Optimized for up to 100 concurrent users
* Efficiently uses resources only during traffic with PHP-FPM's `ondemand` process manager
* Integrates seamlessly with CloudFlare for SSL termination and CDN
* Built on the lightweight and secure Alpine Linux distribution
* Utilizes PHP 8.3 for optimal performance, low CPU usage, and minimal memory footprint
* Configurable to use different versions of Alpine Linux and PHP
* Can be updated safely without data loss
* Fully configurable via environment variables passed to `wp-config.php`
* Supports using `/var/www/html` or `/var/www/html/wp-content` as volumes, automatically populating empty folders or preserving existing files on the persistently mounted volume

![nginx 1.24](https://img.shields.io/badge/nginx-1.24-brightgreen.svg)
![php 8.3](https://img.shields.io/badge/php-8.3-brightgreen.svg)
![License MIT](https://img.shields.io/badge/license-MIT-blue.svg)


## Getting Started

### 1. Clone and Build the Docker Image

1. Clone the repository:
    ```sh
    git clone https://github.com/dmitryrechkin/docker-wordpress-nginx.git
    cd docker-wordpress-nginx
    ```

2. Build the Docker image:
    ```sh
    docker build -t wordpress-nginx:latest .
    ```

3. Push the Docker image to Google Cloud or Dokku (see below).

### 2. Fork and Customize

You can also fork this repository and customize it to your liking. Simply click on the "Fork" button on the GitHub page, and make any modifications you need. Then follow the steps above to build and deploy your customized Docker image.

## Local Build and Run

To build this Docker image locally:

```sh
docker build -t wordpress-nginx:latest .
```

To run this Docker image locally:

```sh
docker run -d -p 8080:8080 -v /path/to/your/local/html:/var/www/html -v /path/to/your/local/wp-content:/var/www/html/wp-content wordpress-nginx:latest
```

In this command:
- Replace `/path/to/your/local/html` with the path to your local WordPress root directory.
- Replace `/path/to/your/local/wp-content` with the path to your local WordPress `wp-content` directory.

## Deployment

### 1. Deployment on Google Cloud Run

To deploy this Docker image to Google Cloud Run:

```sh
scripts/gcloud_deploy.sh cloudrun-wordpress-test
```

After the first deployment, it may take some time for the instance to become fully usable. This delay is due to the synchronization of files to the Google Cloud Storage bucket, which can take a while.

### 2. Deployment on Dokku

If you run [Dokku K3S cluster (Heroku alternative)](https://github.com/dmitryrechkin/Dokku-with-K3S-Cluster-in-LXC-on-Proxmox) then follow these steps to launch it as a Dokku app:

1. Create a new Dokku app:
    ```sh
    dokku apps:create NAME
    ```

2. Push the repository to Dokku:
    ```sh
    git push dokku main
    ```
    
3. Set environment variable to connect WordPress app to the database:
    ```sh
    dokku config:set DB_HOST="YOUR_DATABASE_HOST:DATABASE_PORT" DB_NAME="YOUR_DATABASE_NAME" DB_USER="YOUR_DATABASE_USER" DB_PASSWORD="YOUR_USERNAME_PASSWORD"
    ```
    
4. Set salts (secrets) as environment variables:
    ```sh
    ./scripts/dokku_set_secrets.sh
    ```

## Environment Variables

This Docker image supports various environment variables to configure WordPress via wp-config.php. Here are the key environment variables:

	- DB_NAME - The name of the database for WordPress.
	- DB_USER - The database username.
	- DB_PASSWORD - The database password.
	- DB_HOST - The database hostname.
	- DB_CHARSET - The database charset to use in creating database tables.
	- DB_COLLATE - The database collate type.
	- AUTH_KEY - Authentication unique key.
	- SECURE_AUTH_KEY - Secure authentication unique key.
	- LOGGED_IN_KEY - Logged-in authentication unique key.
	- NONCE_KEY - Nonce unique key.
	- AUTH_SALT - Authentication salt.
	- SECURE_AUTH_SALT - Secure authentication salt.
	- LOGGED_IN_SALT - Logged-in authentication salt.
	- NONCE_SALT - Nonce salt.
	- WP_DEBUG - Enable debugging mode.
	- TABLE_PREFIX - WordPress database table prefix.
	- ABSPATH - Absolute path to the WordPress directory.

In general, it supports all possible WordPress settings via environment variables.

## Customizing Plugins

You can customize the WordPress installation by specifying the plugins you want to include. Edit the `plugins-download-list.txt` file to add the URLs of the zip files for the plugins you wish to install. These plugins will be downloaded and installed automatically unless you mount a persistent volume with a ready-to-use WordPress installation.

By default, this project includes the `tidb-compatibility` plugin, as the aim is to use WordPress with a [TiDB serverless](https://tidb.cloud/) cluster. This plugin is pre-installed and automatically activated to ensure WordPress works seamlessly with TiDB.

For must-use plugins (MU-plugins) that should be automatically activated, you can edit the `mu-plugins-download-list.txt` file. Add the URLs of the zip files for the must-use plugins, and they will be downloaded and activated automatically.

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

## Using Persistent Storage

This Docker image offers flexibility by allowing you to mount `/var/www/html`, containing the entire WordPress installation, enabling updates without the need to rebuild the image. Additionally, you can mount only the `wp-content` directory to maintain custom themes, plugins, and uploads separately from the core WordPress files.

### 1. Mounting `wp-content` Locally

To mount the `wp-content` directory when running the Docker image locally, use the `-v` option to bind the local directory to the container's `wp-content` directory:

```sh
docker run -d -p 8080:8080 -v /path/to/your/local/wp-content:/var/www/html/wp-content wordpress-nginx:latest
```

Replace /path/to/your/local/wp-content with the path to your local wp-content directory.

### 2. Mounting `wp-content` on Dokku

Dokku allows you to mount persistent storage to your app. To mount the wp-content directory:

1.	Create a persistent storage directory on the server (it can be NFS, mounted S3 bucke and so on) for your app:
```sh
mkdir -p /var/lib/dokku/data/storage/your-app-name/wp-content
```

2. Mount the storage directory to your Dokku app:
```sh
dokku storage:mount your-app-name /var/lib/dokku/data/storage/your-app-name/wp-content:/var/www/html/wp-content
```

By following these steps, you can ensure that your custom themes, plugins, and uploads are preserved across container updates and deployments.

### Note on Persistent Storage
Generally, using persistent storage isn’t required. It’s often better to use a plugin like [WP CloudSync Master](https://wordpress.com/plugins/wp-cloudsync-master) to offload your media to the cloud. For updating plugins and the WordPress installation, consider rebuilding the image with the latest versions to ensure everything is up-to-date and optimized.

## Other documentation and examples

To modify this container to your specific needs, please see the following examples:

* [Adding xdebug support](https://github.com/TrafeX/docker-php-nginx/blob/master/docs/xdebug-support.md)
* [Adding composer](https://github.com/TrafeX/docker-php-nginx/blob/master/docs/composer-support.md)
* [Getting the real IP of the client behind a load balancer](https://github.com/TrafeX/docker-php-nginx/blob/master/docs/real-ip-behind-loadbalancer.md)
* [Sending e-mails](https://github.com/TrafeX/docker-php-nginx/blob/master/docs/sending-emails.md)

