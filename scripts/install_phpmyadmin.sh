#!/bin/bash
set -e
source "$(dirname "$0")/.env"

echo "===================================================="
echo "  Instalando y configurando phpMyAdmin para NGINX   "
echo "===================================================="

# 1-Instalación de phpMyAdmin y extensiones PHP necesarias
echo "[1/6] Instalando phpMyAdmin y extensiones PHP..."
sudo apt update -y
sudo apt install -y phpmyadmin php-mbstring php-zip php-gd php-json php-curl php-cli

# 2-Configuración MySQL
echo "[2/6] Configurando MySQL..."
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';"
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE USER IF NOT EXISTS '${PHPMYADMIN_USER}'@'localhost' IDENTIFIED BY '${PHPMYADMIN_PASS}';"
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON *.* TO '${PHPMYADMIN_USER}'@'localhost' WITH GRANT OPTION;"
sudo mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"


# 3-Detectar versión PHP activa
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
PHP_SOCK="/run/php/php${PHP_VERSION}-fpm.sock"
echo "[3/6] Detectada versión PHP: ${PHP_VERSION}"

# 4-Configurar NGINX
echo "[4/6] Configurando NGINX para phpMyAdmin..."
sudo tee /etc/nginx/sites-available/phpmyadmin >/dev/null <<EOF
server {
    listen 80;
    server_name ${SERVER_DOMAIN};
    root /usr/share/phpmyadmin;
    index index.php index.html index.htm;

    # Protección de acceso
    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/phpmyadmin

# 5-Crear .htpasswd sin apache2-utils
echo "[5/6] Creando archivo de autenticación .htpasswd sin apache..."
HTPASSWD_USER="admin"
HTPASSWD_PASS=$(openssl rand -base64 12)
HTPASSWD_HASH=$(openssl passwd -apr1 "$HTPASSWD_PASS")

echo "${HTPASSWD_USER}:${HTPASSWD_HASH}" | sudo tee /etc/nginx/.htpasswd >/dev/null

echo "Usuario: $HTPASSWD_USER"
echo "Contraseña generada automáticamente: $HTPASSWD_PASS"

# 6-Verificar configuración y reiniciar NGINX
echo "[6/6] Verificando configuración de NGINX..."
sudo nginx -t
sudo systemctl reload nginx

# Guardar copia de la configuración
mkdir -p ~/practica4_phpmyadmin/conf
sudo cp /etc/nginx/sites-available/phpmyadmin ~/practica4_phpmyadmin/conf/phpmyadmin.conf

echo "===================================================="
echo " phpMyAdmin instalado y configurado correctamente"
echo "----------------------------------------------------"
echo " URL:  http://${SERVER_IP}/phpmyadmin"
echo " User: ${PHPMYADMIN_USER}"
echo " Pass: ${PHPMYADMIN_PASS}"
echo " Protegido por autenticación básica (.htpasswd)"
echo "===================================================="
