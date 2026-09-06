#!/bin/sh
cd /var/www/html

LISTEN_PORT=${PORT:-80}
echo "=== Madaaris Backend ==="
echo "=== PORT=${LISTEN_PORT} ==="

# Update Apache to listen on Railway's PORT (default 80)
sed -i "s/Listen 80/Listen ${LISTEN_PORT}/g" /etc/apache2/ports.conf
sed -i "s/*:80>/*:${LISTEN_PORT}>/g" /etc/apache2/sites-available/000-default.conf

echo "=== Apache configured for port ${LISTEN_PORT} ==="

# DB setup, migrations, seeding — all in background so Apache starts immediately
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

echo "=== Starting Apache ==="
exec apache2-foreground
