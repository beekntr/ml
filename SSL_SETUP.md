# SSL Certificate Setup Guide

## Quick Setup (Automatic)

Run this single command on your server:

```bash
cd ~/ml
sudo bash scripts/setup-ssl.sh
```

The script will:
1. ✅ Install Certbot
2. ✅ Obtain SSL certificate for ml.kshitijsinghbhati.in
3. ✅ Configure Nginx automatically
4. ✅ Setup auto-renewal
5. ✅ Enable HTTPS redirect

**Access your site:** https://ml.kshitijsinghbhati.in

---

## Manual Setup (Step by Step)

If you prefer manual installation:

### Step 1: Install Certbot

```bash
sudo apt update
sudo apt install certbot python3-certbot-nginx -y
```

### Step 2: Obtain SSL Certificate

```bash
sudo certbot --nginx -d ml.kshitijsinghbhati.in
```

You'll be asked:
- Email address (for renewal notifications)
- Agree to Terms of Service (Y)
- Redirect HTTP to HTTPS (Y - recommended)

### Step 3: Verify Installation

```bash
# Check certificate
sudo certbot certificates

# View certificate details
sudo openssl x509 -in /etc/letsencrypt/live/ml.kshitijsinghbhati.in/fullchain.pem -noout -dates

# Test HTTPS
curl -I https://ml.kshitijsinghbhati.in
```

### Step 4: Setup Auto-Renewal

Certbot automatically sets up renewal. Verify:

```bash
# Check renewal timer
sudo systemctl status certbot.timer

# Test renewal process (dry run)
sudo certbot renew --dry-run
```

### Step 5: Open HTTPS Port

```bash
# Allow HTTPS through firewall
sudo ufw allow 443/tcp
sudo ufw status
```

---

## What Certbot Does

Certbot automatically:
1. Validates domain ownership
2. Generates SSL certificate (free, valid 90 days)
3. Modifies your Nginx config (`/etc/nginx/sites-available/ml`)
4. Adds SSL configuration
5. Sets up HTTP → HTTPS redirect
6. Configures auto-renewal

Your Nginx config will be updated to:
```nginx
server {
    listen 443 ssl;
    server_name ml.kshitijsinghbhati.in;
    
    ssl_certificate /etc/letsencrypt/live/ml.kshitijsinghbhati.in/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/ml.kshitijsinghbhati.in/privkey.pem;
    
    # ... rest of config
}

server {
    listen 80;
    server_name ml.kshitijsinghbhati.in;
    return 301 https://$server_name$request_uri;
}
```

---

## SSL Certificate Management

### View Certificate Info

```bash
# List all certificates
sudo certbot certificates

# Check expiry date
sudo certbot certificates | grep -A 1 "Expiry Date"
```

### Renew Certificate

```bash
# Manual renewal (normally automatic)
sudo certbot renew

# Force renewal
sudo certbot renew --force-renewal
```

### Check Auto-Renewal

```bash
# Check renewal timer status
sudo systemctl status certbot.timer

# View renewal logs
sudo journalctl -u certbot.timer

# Test renewal process
sudo certbot renew --dry-run
```

### Revoke Certificate

```bash
# If you need to revoke
sudo certbot revoke --cert-path /etc/letsencrypt/live/ml.kshitijsinghbhati.in/fullchain.pem
```

---

## Troubleshooting

### Certificate Issuance Failed

**Error:** Domain validation failed

**Solution:**
```bash
# Ensure domain resolves correctly
nslookup ml.kshitijsinghbhati.in

# Ensure port 80 is accessible from internet
sudo ufw status
curl -I http://ml.kshitijsinghbhati.in

# Check Nginx is running
sudo systemctl status nginx

# Try again with verbose output
sudo certbot --nginx -d ml.kshitijsinghbhati.in -v
```

### Rate Limit Error

Let's Encrypt has rate limits (5 certificates/week per domain).

**Solution:**
```bash
# Use staging environment for testing
sudo certbot --nginx -d ml.kshitijsinghbhati.in --staging

# Once working, get real certificate
sudo certbot --nginx -d ml.kshitijsinghbhati.in --force-renewal
```

### Certificate Renewal Fails

```bash
# Check renewal timer
sudo systemctl status certbot.timer

# Check logs
sudo journalctl -u certbot.timer -n 50

# Restart timer
sudo systemctl restart certbot.timer

# Manual renewal test
sudo certbot renew --dry-run
```

### Mixed Content Warnings

After enabling HTTPS, ensure all resources use HTTPS:

```bash
# Update Flask app to use HTTPS for static files
# In app.py, no changes needed - relative URLs work fine
```

### Port 443 Not Accessible

```bash
# Open firewall
sudo ufw allow 443/tcp
sudo ufw status

# Check if Nginx is listening
sudo netstat -tulpn | grep :443

# Check router port forwarding (if behind NAT)
# Forward external 443 → internal 443
```

---

## Testing SSL Configuration

### SSL Labs Test

Visit: https://www.ssllabs.com/ssltest/analyze.html?d=ml.kshitijsinghbhati.in

Should score **A** or **A+**

### Command Line Tests

```bash
# Test HTTPS connection
curl -I https://ml.kshitijsinghbhati.in

# Check SSL certificate
openssl s_client -connect ml.kshitijsinghbhati.in:443 -servername ml.kshitijsinghbhati.in

# Test HTTP → HTTPS redirect
curl -I http://ml.kshitijsinghbhati.in
# Should show: Location: https://ml.kshitijsinghbhati.in/

# Verify TLS version
nmap --script ssl-enum-ciphers -p 443 ml.kshitijsinghbhati.in
```

---

## Certificate Files Location

```
/etc/letsencrypt/
├── live/
│   └── ml.kshitijsinghbhati.in/
│       ├── fullchain.pem      # Certificate + Chain
│       ├── privkey.pem        # Private Key
│       ├── cert.pem           # Certificate only
│       └── chain.pem          # Chain only
├── renewal/
│   └── ml.kshitijsinghbhati.in.conf  # Renewal config
└── archive/
    └── ml.kshitijsinghbhati.in/      # Certificate history
```

---

## Security Best Practices

After SSL setup:

```bash
# 1. Enable HTTP Strict Transport Security (HSTS)
# Add to Nginx config:
# add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

# 2. Disable TLS 1.0 and 1.1
# Add to Nginx config:
# ssl_protocols TLSv1.2 TLSv1.3;

# 3. Use strong ciphers
# Add to Nginx config:
# ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
# ssl_prefer_server_ciphers on;

# 4. Enable OCSP Stapling
# Add to Nginx config:
# ssl_stapling on;
# ssl_stapling_verify on;
```

---

## Automatic Renewal Details

Certbot installs systemd timer for auto-renewal:

```bash
# Timer runs twice daily
sudo systemctl list-timers | grep certbot

# View timer schedule
sudo systemctl cat certbot.timer

# Renewal configuration
cat /etc/letsencrypt/renewal/ml.kshitijsinghbhati.in.conf
```

Renewal happens automatically when certificate is within 30 days of expiry.

---

## Summary

✅ **Certificate:** Free from Let's Encrypt  
✅ **Validity:** 90 days (auto-renews at 60 days)  
✅ **Cost:** $0  
✅ **Maintenance:** Automatic  
✅ **Security:** Industry standard (TLS 1.2+)  

Your site is now secured with HTTPS! 🔒

**Access:** https://ml.kshitijsinghbhati.in
