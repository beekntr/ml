# Auto-Start Setup for ML Application

This guide ensures your ML application starts automatically when your server boots.

## Setup Instructions

Run these commands on your server as user `lester`:

### 1. Copy systemd service file
```bash
cd ~/ml
sudo cp systemd/ml-app.service /etc/systemd/system/ml-app.service
```

### 2. Reload systemd
```bash
sudo systemctl daemon-reload
```

### 3. Enable auto-start
```bash
sudo systemctl enable ml-app.service
```

### 4. Start the service now
```bash
sudo systemctl start ml-app.service
```

### 5. Check status
```bash
sudo systemctl status ml-app.service
```

## Service Management Commands

```bash
# Start application
sudo systemctl start ml-app

# Stop application
sudo systemctl stop ml-app

# Restart application
sudo systemctl restart ml-app

# Check status
sudo systemctl status ml-app

# View logs
sudo journalctl -u ml-app.service -f

# Disable auto-start (if needed)
sudo systemctl disable ml-app

# Re-enable auto-start
sudo systemctl enable ml-app
```

## Test Auto-Start

```bash
# Reboot server to test
sudo reboot

# After reboot, SSH back and check
docker compose ps
curl http://localhost:5000
```

## How It Works

The systemd service:
- ✅ Waits for Docker to be ready
- ✅ Waits for network to be online
- ✅ Runs `docker compose up -d` on boot
- ✅ Automatically restarts on failure
- ✅ Runs as user `lester` (secure)

Your Docker containers already have `restart: unless-stopped` policy, so they'll restart if:
- Container crashes
- Docker daemon restarts
- Server reboots (via systemd service)

## Verify Everything

```bash
# Check Docker auto-starts
sudo systemctl is-enabled docker

# Check ML app auto-starts
sudo systemctl is-enabled ml-app

# Check both are running
sudo systemctl status docker
sudo systemctl status ml-app
```

All should show `enabled` and `active (running)`.

## Troubleshooting

### Service fails to start
```bash
# Check logs
sudo journalctl -u ml-app.service -n 50

# Check Docker is running
sudo systemctl status docker

# Check working directory exists
ls -la /home/lester/ml

# Check permissions
sudo chown -R lester:lester /home/lester/ml
```

### Containers not starting
```bash
# Manual start for debugging
cd ~/ml
docker compose up

# Check logs
docker compose logs -f
```

### After reboot, app not running
```bash
# Check service status
sudo systemctl status ml-app

# Check if enabled
sudo systemctl is-enabled ml-app

# Re-enable if needed
sudo systemctl enable ml-app
sudo systemctl start ml-app
```

## Complete Deployment Checklist

- ✅ Docker installed and enabled: `sudo systemctl enable docker`
- ✅ User in docker group: `groups lester`
- ✅ ML app service enabled: `sudo systemctl enable ml-app`
- ✅ Nginx configured for domain
- ✅ Firewall ports open (22, 80, 443, 5000)
- ✅ DNS configured (ml.kshitijsinghbhati.in)
- ✅ Model files trained and uploaded

Your application will now survive:
- Server reboots
- Power outages
- System updates requiring restart
- Docker daemon restarts
