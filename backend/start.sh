#!/bin/sh
set -e

cd /var/www/html

php artisan storage:link --force 2>/dev/null || true
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo "Waiting for database..."
for i in $(seq 1 30); do
  php artisan db:show --counts 2>/dev/null && echo "DB connected!" && break || true
  echo "Attempt $i/30 — retrying in 3s..."
  sleep 3
done

php artisan migrate --force
php artisan db:seed --class=AccessControlSeeder --force
php artisan db:seed --class=PlatformAdminSeeder --force

echo "Starting server on port ${PORT:-8000}..."
exec php -S "0.0.0.0:${PORT:-8000}" -t public
