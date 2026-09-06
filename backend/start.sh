#!/bin/sh

cd /var/www/html

echo "=== Madaaris Backend ==="
echo "=== PORT=${PORT:-8000} ==="
echo "=== PHP=$(php -v | head -1) ==="
echo "=== public/: $(ls public/) ==="

# DB setup, migrations, seeding — all in background
(
    echo "[DB] Waiting for database..."
    for i in $(seq 1 60); do
        php artisan db:show --counts 2>/dev/null && echo "[DB] Connected!" && break || true
        echo "[DB] Attempt ${i}/60 — retry in 3s..."
        sleep 3
    done
    php artisan migrate --force && echo "[DB] Migrations done!" || echo "[DB] Migrations failed!"
    php artisan db:seed --class=AccessControlSeeder --force 2>/dev/null && echo "[DB] AccessControl seeded!" || true
    php artisan db:seed --class=PlatformAdminSeeder --force 2>/dev/null && echo "[DB] Admin seeded!" || true
    php artisan storage:link --force 2>/dev/null || true
    php artisan config:cache 2>/dev/null && echo "[BG] Config cached!" || true
    php artisan route:cache 2>/dev/null && echo "[BG] Routes cached!" || true
    echo "[DB] Setup complete!"
) &

echo "=== Starting PHP server on 0.0.0.0:${PORT:-8000} ==="
exec php -S "0.0.0.0:${PORT:-8000}" -t public dev-server.php
