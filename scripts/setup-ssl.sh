#!/bin/bash

###############################################################################
# SSL Certificate Setup Script for ml.kshitijsinghbhati.in
# Uses Let's Encrypt (Certbot) for free SSL certificates
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOMAIN="ml.kshitijsinghbhati.in"
EMAIL="your-email@example.com"  # Change this!

echo "=================================================="
echo "  SSL Certificate Setup for $DOMAIN"
echo "=================================================="
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run with sudo${NC}"
    exit 1
fi

# Step 1: Install Certbot
echo -e "${BLUE}[1/5]${NC} Installing Certbot..."
apt-get update
apt-get install -y certbot python3-certbot-nginx

# Step 2: Get email if not changed
if [ "$EMAIL" = "your-email@example.com" ]; then
    echo -e "${YELLOW}Enter your email for SSL certificate notifications:${NC}"
    read -r EMAIL
fi

# Step 3: Obtain SSL certificate
echo -e "${BLUE}[2/5]${NC} Obtaining SSL certificate for $DOMAIN..."
certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email $EMAIL --redirect

# Step 4: Setup auto-renewal
echo -e "${BLUE}[3/5]${NC} Setting up automatic renewal..."
systemctl enable certbot.timer
systemctl start certbot.timer

# Test renewal
certbot renew --dry-run

# Step 5: Verify SSL
echo -e "${BLUE}[4/5]${NC} Verifying SSL certificate..."
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo -e "${GREEN}✓${NC} SSL certificate installed successfully"
    openssl x509 -in /etc/letsencrypt/live/$DOMAIN/fullchain.pem -noout -dates
else
    echo -e "${RED}✗${NC} SSL certificate not found"
    exit 1
fi

# Step 6: Restart Nginx
echo -e "${BLUE}[5/5]${NC} Restarting Nginx..."
systemctl restart nginx

echo ""
echo "=================================================="
echo -e "${GREEN}✓ SSL Certificate Setup Complete!${NC}"
echo "=================================================="
echo ""
echo "Your site is now secured with HTTPS:"
echo "  https://$DOMAIN"
echo ""
echo "Certificate details:"
echo "  Certificate: /etc/letsencrypt/live/$DOMAIN/fullchain.pem"
echo "  Private Key: /etc/letsencrypt/live/$DOMAIN/privkey.pem"
echo "  Expires: $(openssl x509 -in /etc/letsencrypt/live/$DOMAIN/fullchain.pem -noout -enddate | cut -d= -f2)"
echo ""
echo "Auto-renewal is enabled and will run twice daily."
echo "Check status: sudo systemctl status certbot.timer"
echo ""
