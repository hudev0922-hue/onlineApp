FROM php:8.3-cli-alpine

RUN apk add --no-cache \
    bash \
    curl \
    libpng-dev \
    libzip-dev \
    oniguruma-dev \
    libxml2-dev \
    && docker-php-ext-install \
        pdo \
        pdo_mysql \
        mbstring \
        zip \
        bcmath \
        gd \
        fileinfo \
        xml \
        tokenizer

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY . .

RUN composer install --no-dev --optimize-autoloader --no-interaction

EXPOSE 8000

CMD ["sh", "start.sh"]
