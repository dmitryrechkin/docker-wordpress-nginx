<?php

include_once(ABSPATH . 'wp-admin/includes/plugin.php');

$plugins_to_install = [
	'tidb-compatibility/tidb-compatibility.php',
];

foreach ($plugins_to_install as $plugin) {
	if (!is_plugin_active($plugin)) {
		activate_plugin($plugin);
	}
}
