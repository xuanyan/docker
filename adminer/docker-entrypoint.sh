#!/bin/sh
set -e

if [ -f "/external/databases.php" ]; then
    cp /external/databases.php /app/databases.php
fi

exec "$@"
