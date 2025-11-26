FROM php:8.2-alpine

# Install system dependencies
RUN apk add --no-cache \
    git \
    zip \
    unzip \
    icu-dev

# Install PHP extensions
RUN docker-php-ext-install intl opcache

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Copy composer files
COPY composer.json composer.lock ./

# Install dependencies
RUN composer install --no-scripts --no-autoloader

# Copy source
COPY . .

# Dump autoload
RUN composer dump-autoload --optimize

EXPOSE 8000

CMD ["php", "-S", "0.0.0.0:8000", "-t", "public"]
