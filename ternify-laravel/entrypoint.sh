#!/bin/bash
set -e

# Railway menyuntikkan $PORT hanya saat container jalan, bukan saat build.
# Jadi substitusi port HARUS terjadi di sini, bukan di dalam Dockerfile via RUN.
: "${PORT:=80}"

echo "Mengatur Apache untuk listen di port ${PORT}..."

sed -i "s/Listen 80/Listen ${PORT}/g" /etc/apache2/ports.conf
sed -i "s/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/g" /etc/apache2/sites-available/000-default.conf

exec "$@"