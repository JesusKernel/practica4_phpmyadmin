#!/bin/bash
set -e

# Cargar variables del entorno
source "$(dirname "$0")/.env"

echo "Instalando pila LEMP..."

sudo apt update -y
sudo apt install -y nginx mysql-server php-fpm php-mysql

sudo systemctl enable nginx
sudo systemctl enable mysql

echo "LEMP instalado correctamente."
