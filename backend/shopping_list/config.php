<?php
// Configuration for the Shopping List backend

// Directory where list data is stored (must be writable by the web server)
define('DATA_DIR', __DIR__ . '/data');

// Maximum items per list
define('MAX_ITEMS_PER_LIST', 100);

// Maximum number of lists
define('MAX_LISTS', 50);

// Maximum length for list names and item names (characters)
define('MAX_NAME_LENGTH', 100);

// Allowed origins for CORS (set to '*' to allow all, or a specific domain)
define('ALLOWED_ORIGIN', '*');
