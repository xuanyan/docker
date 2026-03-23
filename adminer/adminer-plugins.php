<?php

$databases = require __DIR__ . '/databases.php';

return [
    new AdminerTablesFilter(),
    new AdminerImagefields(100, 100),
    new Adminer\MultiDatabases($databases)
];
