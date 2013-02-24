<?php

define('GA_ACCOUNT', 'UA-31225041-1');

if ( php_uname('n') == "cylon" ) {
  DB::$user = 'root';
  DB::$password = '';
  DB::$dbName = 'gopherpedia';
  //  define('RESTRICT_TO_MATCH', "/gopherpedia.com/");
  define('CACHE_LIFETIME', 1);
}
else {
  define('ALLOW_ALL_PORTS', false);      
  define('RESTRICT_TO_MATCH', "/gopherpedia.com/");
  define('CACHE_LIFETIME', 3600);
}

define('CACHE_PATH', "/tmp/gopher");


define('APP_NAME', 'Gopherpedia');

define('LOG_STATS', true);

?>