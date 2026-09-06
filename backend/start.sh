#!/bin/sh

cd /var/www/html

echo "=== Starting Madaaris Backend ==="
echo "PORT=${PORT:-8000}"

# Run migrations and setup in background ONLY
(
  echo "[BG] Waiting for database..."
  for i in $(seq 1 50); do
    php artisan db:show --counts 2>/dev/null && echo "[BG] DB connected!" && break || true
    echo "[BG] Attempt $i/50 - retry in 3s..."
    sleep 3
  done

  php artisan migrate --force && echo "[BG] Migrations done!" || echo "[BG] Migrations failed!"
  php artisan db:seed --class=AccessControlSeeder --force 2>/dev/null && echo "[BG] AccessControl seeded!" || true
  php artisan db:seed --class=PlatformAdminSeeder --force 2>/dev/null && echo "[BG] Admin seeded!" || true

  php artisan storage:link --force 2>/dev/null || true
  php artisan config:cache 2>/dev/null && echo "[BG] Config cached!" || true
  php artisan route:cache 2>/dev/null && echo "[BG] Routes cached!" || true
  php artisan view:cache 2>/dev/null && echo "[BG] Views cached!" || true

  echo "[BG] Setup complete!"
) &

echo "Starting PHP server on 0.0.0.0:${PORT:-8000}..."
exec php -S "0.0.0.0:${PORT:-8000}" -t public
