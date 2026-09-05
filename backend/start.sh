#!/bin/sh
set -e

cd /var/www/html

PORT="${PORT:-8000}"
sed -i "s/listen 8000/listen ${PORT}/" /etc/nginx/nginx.conf

echo "=== DB DEBUG ==="
echo "DB_HOST=[${DB_HOST}]"
echo "DB_URL=[${DB_URL}]"
echo "MYSQL_URL=[${MYSQL_URL}]"
echo "MYSQLHOST=[${MYSQLHOST}]"
echo "================"

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

echo "Starting PHP-FPM and Nginx on port ${PORT}..."
php-fpm -D
exec nginx -g 'daemon off;'
