# 1. Menggunakan base image PHP 8.2 dengan web server Apache terintegrasi
FROM php:8.4-apache

# 2. Memperbarui sistem Ubuntu di dalam kontainer dan menginstal dependensi sistem
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

# 3. Menginstal dan mengonfigurasi ekstensi PHP yang wajib untuk Laravel dan MySQL
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# 4. Mengaktifkan modul mod_rewrite Apache (wajib agar routing Laravel berfungsi)
RUN a2enmod rewrite

# 5. Menginstal Composer langsung dari image resminya
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 6. Menentukan direktori kerja utama di dalam server
WORKDIR /var/www/html

# 7. Menyalin seluruh file kode Laravel Anda dari komputer ke dalam server
COPY . .

# 8. Menjalankan instalasi dependensi vendor (tanpa paket dev untuk efisiensi RAM)
RUN composer install --no-dev --optimize-autoloader

# 9. Mengatur hak akses folder agar Laravel bisa menulis log dan cache tanpa error permission
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# 10. Menyesuaikan konfigurasi Apache agar membaca folder /public dan menggunakan port dinamis dari Railway
RUN sed -i 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf
RUN echo 'Listen ${PORT}' > /etc/apache2/ports.conf
RUN sed -i 's/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/g' /etc/apache2/sites-available/000-default.conf

# 11. Perintah utama untuk menjalankan Apache saat kontainer dihidupkan
CMD ["apache2-foreground"]