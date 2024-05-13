<?php

// @see https://github.com/TrafeX/docker-wordpress/blob/master/wp-config.php

define('WP_CONTENT_DIR', '/var/www/html/wp-content');

$table_prefix  = getenv('TABLE_PREFIX') ?: 'wp_';

foreach ($_ENV as $key => $value) {
    $capitalized = strtoupper($key);
    if (!defined($capitalized)) {
        // Convert string boolean values to actual booleans
        if (in_array($value, ['true', 'false'])) {
            $value = filter_var($value, FILTER_VALIDATE_BOOLEAN);
        }

        define($capitalized, $value);
    }
}

// we want to use SSL for MySQL connections
if (!defined('MYSQL_CLIENT_FLAGS')) {
    define('MYSQL_CLIENT_FLAGS', MYSQLI_CLIENT_SSL);
}

if (!defined('ABSPATH')) {
    define('ABSPATH', dirname(__FILE__) . '/');
}

require_once(ABSPATH . 'wp-secrets.php');
require_once(ABSPATH . 'wp-settings.php');