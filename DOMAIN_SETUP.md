# Domain Setup Guide for ml.kshitijsinghbhati.in

## Step 1: DNS Configuration

### Option A: Home Server with Public IP
If your home server has a static public IP:

1. **Get your public IP**:
   ```bash
   curl ifconfig.me
   ```

2. **Add DNS A Record** in your domain registrar (where you bought kshitijsinghbhati.in):
   ```
   Type: A
   Name: ml
   Value: YOUR_PUBLIC_IP
   TTL: 3600
   ```

3. **Wait for DNS propagation** (5-30 minutes):
   ```bash
   nslookup ml.kshitijsinghbhati.in
   ```

### Option B: Home Server Behind Router (NAT)
If your home server is behind a router:

1. **Get your public IP**:
   ```bash
   curl ifconfig.me
   ```

2. **Setup Port Forwarding** on your router:
   - Login to router admin panel (usually 192.168.1.1 or 192.168.0.1)
   - Find "Port Forwarding" or "Virtual Server" section
   - Add rules:
     - External Port: 80 → Internal Port: 80 → Internal IP: YOUR_SERVER_LOCAL_IP
     - External Port: 443 → Internal Port: 443 → Internal IP: YOUR_SERVER_LOCAL_IP

3. **Add DNS A Record** pointing to your public IP (same as Option A step 2)

### Option C: Cloudflare Tunnel (No Port Forwarding Needed)
Best option if you can't configure router:

1. **Install Cloudflare Tunnel**:
   ```bash
   # On your server
   wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
   sudo dpkg -i cloudflared-linux-amd64.deb
   ```

2. **Authenticate**:
   ```bash
   cloudflared tunnel login
   ```

3. **Create tunnel**:
   ```bash
   cloudflared tunnel create ml-app
   ```

4. **Configure tunnel**:
   ```bash
   cat > ~/.cloudflared/config.yml << EOF
   tunnel: ml-app
   credentials-file: /home/lester/.cloudflared/<TUNNEL-ID>.json

   ingress:
     - hostname: ml.kshitijsinghbhati.in
       service: http://localhost:5000
     - service: http_status:404
   EOF
   ```

5. **Route DNS**:
   ```bash
   cloudflared tunnel route dns ml-app ml.kshitijsinghbhati.in
   ```

6. **Run tunnel**:
   ```bash
   cloudflared tunnel run ml-app
   ```

## Step 2: Deploy with Domain Support

### On Your Server:

**Without Nginx (Direct Access):**
```bash
cd ~/ml
docker compose up -d ml-app
# Access: http://ml.kshitijsinghbhati.in:5000
```

**With Nginx (Port 80, Recommended):**
```bash
cd ~/ml
git pull origin main
docker compose up -d
# Access: http://ml.kshitijsinghbhati.in (no port needed!)
```

Nginx will:
- ✅ Handle requests on port 80
- ✅ Forward to Flask app on port 5000
- ✅ Add security headers
- ✅ Enable compression
- ✅ Cache static files

## Step 3: Enable HTTPS with SSL (Optional but Recommended)

### Using Let's Encrypt (Free SSL):

1. **Install Certbot**:
   ```bash
   sudo apt install certbot python3-certbot-nginx
   ```

2. **Stop Nginx temporarily**:
   ```bash
   docker compose down nginx
   ```

3. **Get SSL certificate**:
   ```bash
   sudo certbot certonly --standalone -d ml.kshitijsinghbhati.in
   ```

4. **Copy certificates to project**:
   ```bash
   sudo mkdir -p ~/ml/nginx/ssl
   sudo cp /etc/letsencrypt/live/ml.kshitijsinghbhati.in/fullchain.pem ~/ml/nginx/ssl/cert.pem
   sudo cp /etc/letsencrypt/live/ml.kshitijsinghbhati.in/privkey.pem ~/ml/nginx/ssl/key.pem
   sudo chown -R lester:lester ~/ml/nginx/ssl
   ```

5. **Update docker-compose.yml** to use full nginx.conf:
   ```yaml
   volumes:
     - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro  # Change from nginx-simple.conf
     - ./nginx/ssl:/etc/nginx/ssl:ro
   ```

6. **Restart with SSL**:
   ```bash
   docker compose up -d
   ```

7. **Setup auto-renewal**:
   ```bash
   sudo certbot renew --dry-run
   # Add to crontab for auto-renewal
   (crontab -l 2>/dev/null; echo "0 0 * * 0 certbot renew --quiet && cp /etc/letsencrypt/live/ml.kshitijsinghbhati.in/*.pem ~/ml/nginx/ssl/ && docker compose restart nginx") | crontab -
   ```

## Step 4: Testing

### Check DNS:
```bash
nslookup ml.kshitijsinghbhati.in
ping ml.kshitijsinghbhati.in
```

### Check HTTP:
```bash
curl http://ml.kshitijsinghbhati.in
curl -I http://ml.kshitijsinghbhati.in
```

### Check HTTPS (if configured):
```bash
curl https://ml.kshitijsinghbhati.in
```

### Browser Test:
Open in browser: `http://ml.kshitijsinghbhati.in`

## Troubleshooting

### Domain doesn't resolve
```bash
# Check DNS propagation
dig ml.kshitijsinghbhati.in
nslookup ml.kshitijsinghbhati.in 8.8.8.8

# Wait 30 minutes for DNS to propagate globally
```

### Can't access from outside network
```bash
# Check if port 80 is open
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Check router port forwarding
# Verify public IP matches DNS record
curl ifconfig.me
```

### Nginx not starting
```bash
# Check logs
docker compose logs nginx

# Check config syntax
docker compose exec nginx nginx -t

# Check if port 80 is already in use
sudo lsof -i :80
sudo netstat -tulpn | grep :80
```

### SSL certificate issues
```bash
# Check certificate validity
openssl x509 -in ~/ml/nginx/ssl/cert.pem -text -noout

# Renew certificate
sudo certbot renew --force-renewal
```

## Architecture Diagram

```
Internet → ml.kshitijsinghbhati.in (DNS)
    ↓
Your Public IP (Router)
    ↓
Port Forwarding (80→80, 443→443)
    ↓
Home Server (Nginx on port 80)
    ↓
Docker Network (ml-network)
    ↓
Flask App Container (port 5000)
```

## Quick Commands Reference

```bash
# Check everything is running
docker compose ps

# View all logs
docker compose logs -f

# Restart everything
docker compose restart

# Stop everything
docker compose down

# Start with fresh build
docker compose down && docker compose build --no-cache && docker compose up -d

# Check Nginx config
docker compose exec nginx nginx -t

# Reload Nginx (after config changes)
docker compose exec nginx nginx -s reload
```

## Security Checklist

- ✅ Firewall configured (ufw)
- ✅ Only necessary ports open (22, 80, 443)
- ✅ SSH key authentication (no password)
- ✅ Fail2ban installed
- ✅ SSL certificate (HTTPS)
- ✅ Security headers in Nginx
- ✅ Regular system updates

## Support

If you encounter issues:
1. Check logs: `docker compose logs`
2. Verify DNS: `nslookup ml.kshitijsinghbhati.in`
3. Test locally: `curl http://localhost:5000`
4. Check firewall: `sudo ufw status`
5. Verify port forwarding in router settings
