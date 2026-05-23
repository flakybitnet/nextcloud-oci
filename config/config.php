<?php
$CONFIG = array (
  'htaccess.RewriteBase' => '/',
  'memcache.local' => '\OC\Memcache\APCu',
  'apps_paths' => array (
      0 => array (
              'path'     => OC::$SERVERROOT.'/apps',
              'url'      => '/apps',
              'writable' => false,
      ),
      1 => array (
              'path'     => OC::$SERVERROOT.'/custom_apps',
              'url'      => '/custom_apps',
              'writable' => false,
      ),
  ),
  'check_for_working_htaccess' => true,
  'upgrade.disable-web' => true,
  'updatechecker' => false,
  'appstoreenabled' => false,
  'has_internet_connection' => false,
);
