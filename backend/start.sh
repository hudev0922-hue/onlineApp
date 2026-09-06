#!/bin/sh

cd /var/www/html

APP_PORT=${PORT:-8000}
echo "=== Madaaris Backend starting on PORT=${APP_PORT} ==="

# Inject port into nginx config
sed "s/NGINX_PORT/${APP_PORT}/g" /var/www/html/nginx.conf > /etc/nginx/nginx.conf
echo "=== Nginx config written for port ${APP_PORT} ==="

# Start PHP-FPM (runs in foreground mode per Docker image default)
php-fpm &
FPM_PID=$!
echo "=== PHP-FPM started (PID: ${FPM_PID}) ==="

# Give FPM up to 10s to be ready
for i in $(seq 1 10); do
    sleep 1
    if kill -0 ${FPM_PID} 2>/dev/null; then
        echo "=== PHP-FPM is running after ${i}s ==="
        break
    fi
    echo "=== PHP-FPM not ready yet (attempt ${i}/10)... ==="
done

# Verify FPM is still alive before starting nginx
if ! kill -0 ${FPM_PID} 2>/dev/null; then
    echo "=== ERROR: PHP-FPM crashed. Exiting. ==="
    exit 1
fi

# DB setup in background — never blocks nginx startup
(
    echo "[DB] Waiting for database connection..."
    for i in $(seq 1 50); do
        php artisan db:show --counts 2>/dev/null && echo "[DB] Connected!" && break || true
        echo "[DB] Attempt ${i}/50 — retry in 3s..."
        sleep 3
    done
    php artisan migrate --force && echo "[DB] Migrations done!" || echo "[DB] Migration failed!"
    php artisan db:seed --class=AccessControlSeeder --force 2>/dev/null && echo "[DB] AccessControl seeded!" || true
    php artisan db:seed --class=PlatformAdminSeeder --force 2>/dev/null && echo "[DB] Admin seeded!" || true
    php artisan storage:link --force 2>/dev/null || true
    php artisan config:cache 2>/dev/null && echo "[BG] Config cached!" || true
    php artisan route:cache 2>/dev/null && echo "[BG] Routes cached!" || true
    echo "[DB] Background setup complete!"
) &

echo "=== Starting nginx (foreground) ==="
exec nginx -g 'daemon off;'
