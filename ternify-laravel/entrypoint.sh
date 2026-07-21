#!/bin/bash
set -e

: "${PORT:=80}"

echo "=== DEBUG: isi mods-enabled sebelum fix ==="
ls -la /etc/apache2/mods-enabled | grep -i mpm || echo "(tidak ada file mpm_* ditemukan)"

# Fix defensif: paksa ulang di runtime juga, jangan andalkan build-time saja
a2dismod mpm_event mpm_worker 2>/dev/null || true
a2enmod mpm_prefork 2>/dev/null || true

echo "=== DEBUG: isi mods-enabled sesudah fix ==="
ls -la /etc/apache2/mods-enabled | grep -i mpm

echo "=== DEBUG: modul yang benar-benar ke-load Apache ==="
apache2ctl -M 2>&1 | grep -i mpm || echo "(apache2ctl -M gagal / tidak ada info mpm)"

echo "Mengatur Apache untuk listen di port ${PORT}..."
sed -i "s/Listen 80/Listen ${PORT}/g" /etc/apache2/ports.conf
sed -i "s/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/g" /etc/apache2/sites-available/000-default.conf

exec "$@"