# 1. Gunakan base image spesifik (Bookworm) untuk menghindari bug dan memaksa reset cache
FROM php:8.4-apache-bookworm

# 2. Update dan install dependensi sistem
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    zip \
    unzip \
    git \
    libonig-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 3. Konfigurasi dan install ekstensi PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# 4. SOLUSI DEFINITIF: Sapu bersih semua konfigurasi MPM bawaan, lalu aktifkan prefork
RUN find /etc/apache2/mods-enabled -name "mpm_*.load" -delete \
    && find /etc/apache2/mods-enabled -name "mpm_*.conf" -delete \
    && a2enmod mpm_prefork rewrite

# 5. Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 6. Set direktori kerja
WORKDIR /var/www/html

# 7. Salin file aplikasi
COPY . .

# 8. Install vendor dependencies
RUN composer install --no-dev --optimize-autoloader

# 9. Set hak akses (Penting agar framework bisa menulis log/cache)
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# 10. Konfigurasi Apache untuk membaca /public dan port Railway
RUN sed -i 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf
RUN echo 'Listen ${PORT}' > /etc/apache2/ports.conf
RUN sed -i 's/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/g' /etc/apache2/sites-available/000-default.conf

# 11. Jalankan Apache
CMD ["apache2-foreground"]