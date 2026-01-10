#!/bin/bash

###############################################################################
# phpMyAdmin Installation Script for Laravel Forge
# Supports any domain - prompts for configuration
# Run as: sudo bash install-phpmyadmin.sh
###############################################################################

set -e  # Exit on error

echo "=========================================="
echo "phpMyAdmin Installation Script"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run as root: sudo bash install-phpmyadmin.sh"
    exit 1
fi

# Configuration
read -p "Enter domain name (e.g., d0b.cineflix.in): " DOMAIN
if [ -z "$DOMAIN" ]; then
    echo "❌ Domain name is required"
    exit 1
fi

# Validate domain format (basic check)
if [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
    echo "❌ Invalid domain format"
    exit 1
fi

SITE_PATH="/home/forge/$DOMAIN"

read -p "Enter your MySQL root password: " -s MYSQL_ROOT_PASSWORD
echo ""
if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
    echo "❌ MySQL root password is required"
    exit 1
fi

read -p "Enter password for phpMyAdmin user: " -s PMA_PASSWORD
echo ""
if [ -z "$PMA_PASSWORD" ]; then
    echo "❌ phpMyAdmin password is required"
    exit 1
fi

read -p "Enter your IP address to whitelist (press Enter to skip): " WHITELIST_IP
read -p "Enter PHP version (8.1, 8.2, or 8.3) [default: 8.3]: " PHP_VERSION
PHP_VERSION=${PHP_VERSION:-8.3}

# Validate PHP version
if [[ ! "$PHP_VERSION" =~ ^(8.1|8.2|8.3)$ ]]; then
    echo "❌ Invalid PHP version. Must be 8.1, 8.2, or 8.3"
    exit 1
fi

# Check if PHP-FPM is installed
if [ ! -S "/var/run/php/php$PHP_VERSION-fpm.sock" ]; then
    echo "⚠️  Warning: PHP $PHP_VERSION FPM socket not found at /var/run/php/php$PHP_VERSION-fpm.sock"
    read -p "Continue anyway? (y/N): " CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

read -p "Enter your email for Let's Encrypt SSL: " SSL_EMAIL
if [ -z "$SSL_EMAIL" ]; then
    echo "❌ Email is required for SSL certificate"
    exit 1
fi

# Validate email format
if [[ ! "$SSL_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "❌ Invalid email format"
    exit 1
fi

echo ""
echo "🔍 Checking DNS configuration..."

# Check if domain resolves
if command -v dig &> /dev/null; then
    DOMAIN_IP=$(dig +short "$DOMAIN" | tail -n1)
    if [ -z "$DOMAIN_IP" ]; then
        echo "⚠️  Warning: Domain $DOMAIN does not resolve to an IP address"
        echo "   Please add DNS A record before continuing:"
        echo "   Host: ${DOMAIN%%.*} (or full domain)"
        echo "   Type: A"
        echo "   Value: Your server IP"
        read -p "Continue anyway? (y/N): " CONTINUE_DNS
        if [[ ! "$CONTINUE_DNS" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo "✅ Domain resolves to: $DOMAIN_IP"
    fi
fi

echo ""
echo "📦 Installing phpMyAdmin..."

# Install phpMyAdmin non-interactively
export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $PMA_PASSWORD"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $MYSQL_ROOT_PASSWORD"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $PMA_PASSWORD"
debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect"

apt update
if ! apt install -y phpmyadmin php-mbstring php-zip php-gd php-json php-curl; then
    echo "❌ Failed to install phpMyAdmin"
    exit 1
fi

echo "✅ phpMyAdmin installed successfully"

echo ""
echo "📁 Creating site directory..."

# Create site directory structure
mkdir -p "$SITE_PATH"
chown -R forge:forge "$SITE_PATH"

# Create symlink to phpMyAdmin
if [ -d "$SITE_PATH/public" ]; then
    rm -rf "$SITE_PATH/public"
fi
ln -s /usr/share/phpmyadmin "$SITE_PATH/public"

echo ""
echo "🔧 Configuring Nginx..."

# Create Nginx configuration
cat > "/etc/nginx/sites-available/$DOMAIN" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    root $SITE_PATH/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;
    charset utf-8;

EOF

# Add IP whitelist if provided
if [ ! -z "$WHITELIST_IP" ]; then
cat >> "/etc/nginx/sites-available/$DOMAIN" <<EOF
    # IP Whitelist
    allow $WHITELIST_IP;
    deny all;

EOF
fi

cat >> "/etc/nginx/sites-available/$DOMAIN" <<EOF
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/$DOMAIN-error.log error;

    error_page 404 /index.php;

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/var/run/php/php$PHP_VERSION-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

# Enable site
ln -sf "/etc/nginx/sites-available/$DOMAIN" "/etc/nginx/sites-enabled/$DOMAIN"

# Test and reload Nginx
echo ""
echo "🔍 Testing Nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration is valid"
    systemctl reload nginx
    echo "✅ Nginx reloaded"
else
    echo "❌ Nginx configuration has errors"
    exit 1
fi

# Set proper permissions
chown -R www-data:www-data /usr/share/phpmyadmin
chmod -R 755 /usr/share/phpmyadmin

echo ""
echo "🔒 Installing SSL Certificate with Let's Encrypt..."

# Check if certbot is installed
if ! command -v certbot &> /dev/null; then
    echo "📦 Installing certbot..."
    apt update
    if ! apt install -y certbot python3-certbot-nginx; then
        echo "❌ Failed to install certbot"
        exit 1
    fi
fi

# Test if domain is accessible via HTTP first
echo "🔍 Testing HTTP accessibility..."
sleep 2
if command -v curl &> /dev/null; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN" || echo "000")
    if [ "$HTTP_CODE" = "000" ]; then
        echo "⚠️  Warning: Cannot reach http://$DOMAIN"
        echo "   SSL installation may fail if DNS is not properly configured"
        read -p "Continue with SSL installation? (y/N): " CONTINUE_SSL
        if [[ ! "$CONTINUE_SSL" =~ ^[Yy]$ ]]; then
            echo "⚠️  Skipping SSL installation. Run manually later:"
            echo "   certbot --nginx -d $DOMAIN"
            SKIP_SSL=true
        fi
    else
        echo "✅ HTTP accessible (Status: $HTTP_CODE)"
    fi
fi

# Install SSL certificate
if [ "$SKIP_SSL" != "true" ]; then
    if certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$SSL_EMAIL" --redirect; then
        echo "✅ SSL certificate installed successfully"
        SSL_INSTALLED=true
    else
        echo "⚠️  SSL certificate installation failed"
        echo "   This is usually because:"
        echo "   1. DNS is not properly configured"
        echo "   2. Domain is not pointing to this server"
        echo "   3. Port 80/443 is not accessible"
        echo ""
        echo "   You can install SSL manually later:"
        echo "   certbot --nginx -d $DOMAIN"
        SSL_INSTALLED=false
    fi
fi

echo ""
echo "=========================================="
echo "✅ phpMyAdmin Installation Complete!"
echo "=========================================="
echo ""
echo "📝 Installation Summary:"
echo ""
if [ "$SSL_INSTALLED" = "true" ]; then
    echo "🌐 URL: https://$DOMAIN"
    echo "🔒 SSL: ✅ Installed and configured"
else
    echo "🌐 URL: http://$DOMAIN (SSL not installed)"
    echo "🔒 SSL: ⚠️  Not installed - run: certbot --nginx -d $DOMAIN"
fi
echo "👤 Username: root (or your MySQL user)"
echo "🔑 Password: [Your MySQL password]"
echo "🐘 PHP Version: $PHP_VERSION"
if [ ! -z "$WHITELIST_IP" ]; then
    echo "🔐 IP Whitelist: ✅ Enabled for $WHITELIST_IP"
fi
echo ""
echo "📝 Management Commands:"
echo ""
echo "Check Nginx:     nginx -t"
echo "Reload Nginx:    systemctl reload nginx"
echo "Check PHP-FPM:   systemctl status php$PHP_VERSION-fpm"
echo "View Nginx logs: tail -f /var/log/nginx/$DOMAIN-error.log"
echo ""
if [ "$SSL_INSTALLED" != "true" ]; then
    echo "📝 Next Steps:"
    echo ""
    echo "1. Ensure DNS A record is configured:"
    echo "   Host: ${DOMAIN%%.*} (or full domain)"
    echo "   Type: A"
    echo "   Value: Your server IP"
    echo ""
    echo "2. Install SSL Certificate:"
    echo "   certbot --nginx -d $DOMAIN"
    echo ""
fi
echo "⚠️  SECURITY REMINDERS:"
echo "   - SSL certificate is REQUIRED for production use"
echo "   - Keep phpMyAdmin updated: apt update && apt upgrade phpmyadmin"
echo "   - Consider adding HTTP Basic Auth for extra security"
echo "   - Review IP whitelist settings if needed"
echo "   - Use strong MySQL passwords"
echo ""
echo "📚 phpMyAdmin Config: /etc/phpmyadmin/"
echo "📁 Installation Path: /usr/share/phpmyadmin"
echo ""
echo "=========================================="
