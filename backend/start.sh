#!/bin/sh

cd /var/www/html

php artisan storage:link --force 2>/dev/null || true
php artisan config:cache 2>/dev/null || true
php artisan route:cache 2>/dev/null || true
php artisan view:cache 2>/dev/null || true

# Run DB setup in background so PHP starts immediately
(
  echo "[DB] Waiting for database..."
  for i in $(seq 1 40); do
    php artisan db:show --counts 2>/dev/null && echo "[DB] Connected!" && break || true
    echo "[DB] Attempt $i/40 - retrying in 3s..."
    sleep 3
  done
  php artisan migrate --force && echo "[DB] Migrations done!" || echo "[DB] Migration failed!"
  php artisan db:seed --class=AccessControlSeeder --force 2>/dev/null || true
  php artisan db:seed --class=PlatformAdminSeeder --force 2>/dev/null || true
  echo "[DB] Setup complete!"
) &

echo "Starting PHP server on port ${PORT:-8000}..."
exec php -S "0.0.0.0:${PORT:-8000}" -t public
