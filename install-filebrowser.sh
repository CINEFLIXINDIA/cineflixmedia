#!/bin/bash

###############################################################################
# FileBrowser Installation Script for Laravel Forge
# Supports any domain - prompts for configuration
# Run as: sudo bash install-filebrowser.sh
###############################################################################

set -e  # Exit on error

echo "=========================================="
echo "FileBrowser Installation Script"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run as root: sudo bash install-filebrowser.sh"
    exit 1
fi

# Configuration
read -p "Enter domain name (e.g., f0l.cineflix.in): " DOMAIN
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
FB_PORT=8080
FB_CONFIG_DIR="/etc/filebrowser"
FB_DATABASE="$FB_CONFIG_DIR/filebrowser.db"

read -p "Enter FileBrowser admin username [default: admin]: " FB_USERNAME
FB_USERNAME=${FB_USERNAME:-admin}
read -p "Enter FileBrowser admin password: " -s FB_PASSWORD
echo ""
read -p "Enter root directory for FileBrowser [default: /home/forge]: " FB_ROOT_DIR
FB_ROOT_DIR=${FB_ROOT_DIR:-/home/forge}
read -p "Enter your email for Let's Encrypt SSL: " SSL_EMAIL

echo ""
echo "📦 Installing FileBrowser..."

# Download and install FileBrowser
curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

echo ""
echo "📁 Creating configuration directory..."

# Check for existing installation
if [ -f "$FB_DATABASE" ]; then
    echo "⚠️  Warning: FileBrowser database already exists at $FB_DATABASE"
    read -p "Do you want to remove existing installation and start fresh? (y/N): " CLEAN_INSTALL
    if [[ "$CLEAN_INSTALL" =~ ^[Yy]$ ]]; then
        echo "🗑️  Removing existing FileBrowser installation..."
        systemctl stop filebrowser 2>/dev/null || true
        systemctl disable filebrowser 2>/dev/null || true
        rm -f /etc/systemd/system/filebrowser.service
        rm -rf "$FB_CONFIG_DIR"
        rm -f /var/log/filebrowser.log
        systemctl daemon-reload
        echo "✅ Cleaned up existing installation"
    else
        echo "❌ Installation cancelled. Please remove existing installation manually or choose a different configuration."
        exit 1
    fi
fi

# Create configuration directory
mkdir -p "$FB_CONFIG_DIR"
mkdir -p "$SITE_PATH"

# Configure FileBrowser
echo ""
echo "🔧 Configuring FileBrowser..."

# Initialize FileBrowser database and config in one go
filebrowser config init --database "$FB_DATABASE"
filebrowser config set --address 127.0.0.1 --database "$FB_DATABASE"
filebrowser config set --port $FB_PORT --database "$FB_DATABASE"
filebrowser config set --root "$FB_ROOT_DIR" --database "$FB_DATABASE"
filebrowser config set --baseurl "" --database "$FB_DATABASE"
filebrowser config set --log /var/log/filebrowser.log --database "$FB_DATABASE"

# Create admin user
filebrowser users add "$FB_USERNAME" "$FB_PASSWORD" --perm.admin --database "$FB_DATABASE"

echo ""
echo "🔧 Creating systemd service..."

# Create systemd service
cat > /etc/systemd/system/filebrowser.service <<EOF
[Unit]
Description=FileBrowser
After=network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/local/bin/filebrowser --database $FB_DATABASE
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Enable and start FileBrowser service
systemctl daemon-reload
systemctl enable filebrowser
systemctl start filebrowser

# Wait for service to start
sleep 2

# Check if service is running
if systemctl is-active --quiet filebrowser; then
    echo "✅ FileBrowser service started successfully"
else
    echo "❌ FileBrowser service failed to start"
    journalctl -u filebrowser -n 20 --no-pager
    exit 1
fi

echo ""
echo "🔧 Configuring Nginx..."

# Create Nginx configuration
cat > "/etc/nginx/sites-available/$DOMAIN" <<'NGINX_EOF'
server {
    listen 80;
    listen [::]:80;
    server_name DOMAIN_PLACEHOLDER;

    client_max_body_size 100M;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # WebSocket support
        proxy_read_timeout 86400;
    }
}
NGINX_EOF

# Replace placeholder with actual domain
sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" "/etc/nginx/sites-available/$DOMAIN"

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

echo ""
echo "🔒 Installing SSL Certificate with Let's Encrypt..."

# Check if certbot is installed
if ! command -v certbot &> /dev/null; then
    echo "📦 Installing certbot..."
    apt update
    apt install -y certbot python3-certbot-nginx
fi

# Install SSL certificate
certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$SSL_EMAIL" --redirect

if [ $? -eq 0 ]; then
    echo "✅ SSL certificate installed successfully"
else
    echo "⚠️  SSL certificate installation failed. You may need to:"
    echo "   1. Ensure DNS is properly configured"
    echo "   2. Run manually: certbot --nginx -d $DOMAIN"
fi

echo ""
echo "=========================================="
echo "✅ FileBrowser Installation Complete!"
echo "=========================================="
echo ""
echo "📝 Installation Summary:"
echo ""
echo "🌐 URL: https://$DOMAIN"
echo "👤 Username: $FB_USERNAME"
echo "🔑 Password: [hidden]"
echo "📁 Root Directory: $FB_ROOT_DIR"
echo ""
echo "📝 Management Commands:"
echo ""
echo "Check status:    systemctl status filebrowser"
echo "Restart:         systemctl restart filebrowser"
echo "Stop:            systemctl stop filebrowser"
echo "View logs:       journalctl -u filebrowser -f"
echo "View log file:   tail -f /var/log/filebrowser.log"
echo ""
echo "🔧 Configuration:"
echo "Database:        $FB_DATABASE"
echo ""
echo "⚠️  SECURITY REMINDERS:"
echo "   - SSL certificate is installed and auto-renews"
echo "   - Change default password after first login"
echo "   - Review user permissions in FileBrowser settings"
echo "   - Consider adding IP whitelist in Nginx if needed"
echo ""
echo "📚 Documentation: https://filebrowser.org/configuration"
echo ""
echo "=========================================="
