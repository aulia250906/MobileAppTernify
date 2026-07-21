# 1. Menggunakan base image PHP 8.4 dengan web server Apache terintegrasi
FROM php:8.4-apache

# 2. Memperbarui sistem Ubuntu di dalam kontainer dan menginstal dependensi
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

# 3. Menginstal dan mengonfigurasi ekstensi PHP yang wajib untuk Laravel
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# 4. PENGHAPUSAN PAKSA FILE MPM YANG BENTROK & AKTIFKAN REWRITE
RUN rm -f /etc/apache2/mods-enabled/mpm_event.load \
    && rm -f /etc/apache2/mods-enabled/mpm_worker.load \
    && rm -f /etc/apache2/mods-enabled/mpm_event.conf \
    && rm -f /etc/apache2/mods-enabled/mpm_worker.conf \
    && a2enmod mpm_prefork rewrite

# 5. Menginstal Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 6. Menentukan direktori kerja utama
WORKDIR /var/www/html

# 7. Menyalin seluruh file kode Laravel
COPY . .

# 8. Menjalankan instalasi dependensi vendor
RUN composer install --no-dev --optimize-autoloader

# 9. Mengatur hak akses folder
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# 10. Konfigurasi Port Railway dan Root Document
RUN sed -i 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf
RUN echo 'Listen ${PORT}' > /etc/apache2/ports.conf
RUN sed -i 's/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/g' /etc/apache2/sites-available/000-default.conf

# 11. Jalankan Apache
CMD ["apache2-foreground"]