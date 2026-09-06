FROM php:8.3-apache

RUN apt-get update && apt-get install -y \
    libpng-dev libjpeg-dev libfreetype6-dev libzip-dev \
    libonig-dev libxml2-dev libicu-dev curl unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_mysql mbstring zip bcmath gd xml pcntl intl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite headers

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY . .

RUN composer install --no-dev --optimize-autoloader --no-interaction \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

RUN { \
    echo '<VirtualHost *:80>'; \
    echo '    DocumentRoot /var/www/html/public'; \
    echo '    <Directory /var/www/html/public>'; \
    echo '        AllowOverride All'; \
    echo '        Require all granted'; \
    echo '    </Directory>'; \
    echo '</VirtualHost>'; \
} > /etc/apache2/sites-available/000-default.conf

EXPOSE 80

CMD ["sh", "start.sh"]
