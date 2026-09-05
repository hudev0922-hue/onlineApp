#!/bin/sh
set -e

cd /var/www/html

php artisan storage:link --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan migrate --force
php artisan db:seed --class=AccessControlSeeder --force
php -S "0.0.0.0:${PORT:-8000}" -t public
