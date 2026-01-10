#!/bin/bash

###############################################################################
# FileBrowser Cleanup Script
# Run this to remove a failed/existing FileBrowser installation
# Run as: sudo bash cleanup-filebrowser.sh
###############################################################################

set -e

echo "=========================================="
echo "FileBrowser Cleanup Script"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run as root: sudo bash cleanup-filebrowser.sh"
    exit 1
fi

echo "🗑️  Removing FileBrowser installation..."

# Stop and disable service
systemctl stop filebrowser 2>/dev/null || true
systemctl disable filebrowser 2>/dev/null || true

# Remove service file
rm -f /etc/systemd/system/filebrowser.service

# Remove configuration and database
rm -rf /etc/filebrowser

# Remove log file
rm -f /var/log/filebrowser.log

# Remove Nginx configs (optional - will prompt)
if [ -d /etc/nginx/sites-available ]; then
    echo ""
    echo "Found Nginx configuration files:"
    ls -1 /etc/nginx/sites-available/f*.* 2>/dev/null || echo "No f*.* files found"
    echo ""
    read -p "Remove FileBrowser Nginx configs? (y/N): " REMOVE_NGINX
    if [[ "$REMOVE_NGINX" =~ ^[Yy]$ ]]; then
        read -p "Enter domain to remove (e.g., f0l.cineflixmusic.in): " DOMAIN
        if [ ! -z "$DOMAIN" ]; then
            rm -f "/etc/nginx/sites-available/$DOMAIN"
            rm -f "/etc/nginx/sites-enabled/$DOMAIN"
            nginx -t && systemctl reload nginx
            echo "✅ Removed Nginx config for $DOMAIN"
        fi
    fi
fi

# Reload systemd
systemctl daemon-reload

echo ""
echo "✅ FileBrowser cleanup complete!"
echo ""
echo "You can now run the installation script again:"
echo "sudo bash install-filebrowser.sh"
echo ""
