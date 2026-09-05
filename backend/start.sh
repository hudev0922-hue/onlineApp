#!/bin/sh
set -e

php artisan storage:link --force
php artisan migrate --force
php artisan db:seed --class=AccessControlSeeder --force
php -S "0.0.0.0:${PORT:-8000}" -t public
