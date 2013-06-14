<?php

define('GA_ACCOUNT', 'UA-98596-15');

if ( php_uname('n') == "cylon" ) {
  DB::$user = 'root';
  DB::$password = '';
  DB::$dbName = 'gopherpedia';
  //  define('RESTRICT_TO_MATCH', "/gopherpedia.com/");
  define('CACHE_LIFETIME', 1);

  define('START_REQUEST', 'localhost:7070/');
  define('START_INPUT', '');

}
else {
  define('ALLOW_ALL_PORTS', false);      
  define('RESTRICT_TO_MATCH', "/gopherpedia.com/");
  define('CACHE_LIFETIME', 3600);

  DB::$user = 'gopherpedia';
  DB::$host = 'mysql.muffinlabs.com';
  DB::$password = 'g0ferp3dlia';
  DB::$dbName = 'gopherpedia';
  DB::$dbName = 'gopherpedia';

  define('START_REQUEST', 'gopherpedia.com/');
  define('START_INPUT', '');
}

define('CACHE_LIFETIME', 3600);
define('CACHE_PATH', "/tmp/gopher");

define('APP_NAME', 'Gopherpedia');
define('MAX_FILESIZE', 100000);

define('LOG_STATS', true);

?>