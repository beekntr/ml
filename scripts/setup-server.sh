#!/bin/bash

###############################################################################
# Home Server Setup Script
# Description: Prepares home server for ML application deployment
###############################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=================================================="
echo "  Home Server Setup for ML Application"
echo "=================================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}[WARNING]${NC} This script should be run with sudo privileges for some operations."
fi

# Update system
echo -e "${BLUE}[1/8]${NC} Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker
echo -e "${BLUE}[2/8]${NC} Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo -e "${GREEN}✓${NC} Docker installed successfully"
else
    echo -e "${GREEN}✓${NC} Docker already installed"
fi

# Install Docker Compose
echo -e "${BLUE}[3/8]${NC} Installing Docker Compose..."
if ! command -v docker compose &> /dev/null; then
    sudo apt-get install docker-compose-plugin -y
    echo -e "${GREEN}✓${NC} Docker Compose installed successfully"
else
    echo -e "${GREEN}✓${NC} Docker Compose already installed"
fi

# Install Git
echo -e "${BLUE}[4/8]${NC} Installing Git..."
if ! command -v git &> /dev/null; then
    sudo apt-get install git -y
    echo -e "${GREEN}✓${NC} Git installed successfully"
else
    echo -e "${GREEN}✓${NC} Git already installed"
fi

# Install essential tools
echo -e "${BLUE}[5/8]${NC} Installing essential tools..."
sudo apt-get install -y curl wget vim htop net-tools ufw fail2ban

# Setup firewall
echo -e "${BLUE}[6/8]${NC} Configuring firewall..."
sudo ufw --force enable
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw allow 5000/tcp    # Flask app (optional, for testing)
echo -e "${GREEN}✓${NC} Firewall configured"

# Setup SSH for CI/CD
echo -e "${BLUE}[7/8]${NC} Setting up SSH for CI/CD..."
if [ ! -d ~/.ssh ]; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
fi

if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo -e "${YELLOW}Generating SSH key for CI/CD...${NC}"
    ssh-keygen -t ed25519 -C "ci-cd-deployment" -f ~/.ssh/id_ed25519 -N ""
    echo -e "${GREEN}✓${NC} SSH key generated"
    echo -e "${YELLOW}Add this public key to GitHub secrets:${NC}"
    cat ~/.ssh/id_ed25519.pub
else
    echo -e "${GREEN}✓${NC} SSH key already exists"
fi

# Create project directory
echo -e "${BLUE}[8/8]${NC} Creating project directory..."
PROJECT_DIR="$HOME/student-type-project"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Clone repository (user needs to provide URL)
echo -e "${YELLOW}Repository URL is needed to clone the project.${NC}"
read -p "Enter GitHub repository URL (or press Enter to skip): " REPO_URL

if [ ! -z "$REPO_URL" ]; then
    if [ -d "$PROJECT_DIR/.git" ]; then
        echo -e "${YELLOW}Repository already cloned, pulling latest changes...${NC}"
        git pull
    else
        git clone "$REPO_URL" .
    fi
    echo -e "${GREEN}✓${NC} Repository cloned/updated"
else
    echo -e "${YELLOW}Skipped repository cloning. You can clone manually later.${NC}"
fi

# Setup log rotation
echo -e "${BLUE}Setting up log rotation...${NC}"
sudo tee /etc/logrotate.d/ml-app > /dev/null <<EOF
$PROJECT_DIR/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 $USER $USER
    sharedscripts
}
EOF

# Setup systemd service for auto-start (optional)
echo -e "${BLUE}Creating systemd service...${NC}"
sudo tee /etc/systemd/system/ml-app.service > /dev/null <<EOF
[Unit]
Description=ML Student Type Predictor
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$PROJECT_DIR
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
User=$USER

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable ml-app.service

# Display summary
echo ""
echo "=================================================="
echo -e "${GREEN}✓ Home Server Setup Completed!${NC}"
echo "=================================================="
echo ""
echo "Server Information:"
echo "  - Docker: $(docker --version)"
echo "  - Docker Compose: $(docker compose version)"
echo "  - Git: $(git --version)"
echo "  - Project Directory: $PROJECT_DIR"
echo "  - Firewall: $(sudo ufw status | grep Status)"
echo ""
echo "Next Steps:"
echo "  1. Add SSH public key to GitHub repository secrets"
echo "  2. Configure GitHub Actions secrets:"
echo "     - HOME_SERVER_HOST: $(hostname -I | awk '{print $1}')"
echo "     - HOME_SERVER_USER: $USER"
echo "     - HOME_SERVER_SSH_KEY: (your private key from ~/.ssh/id_ed25519)"
echo "     - DEPLOY_PATH: $PROJECT_DIR"
echo "  3. Push code to GitHub to trigger CI/CD pipeline"
echo "  4. Or run manually: cd $PROJECT_DIR && ./scripts/deploy.sh"
echo ""
echo "Useful Commands:"
echo "  - Start app: sudo systemctl start ml-app"
echo "  - Stop app: sudo systemctl stop ml-app"
echo "  - View logs: docker compose logs -f"
echo "  - Manual deploy: ./scripts/deploy.sh"
echo ""

# Create a README for the server setup
cat > "$PROJECT_DIR/SERVER_SETUP.md" <<'EOF'
# Server Setup Documentation

## Overview
This document contains information about the home server setup for the ML application.

## Installed Components
- Docker & Docker Compose
- Git
- UFW Firewall
- Fail2ban (security)
- Systemd service for auto-start

## Configuration

### GitHub Actions Secrets Required
```
HOME_SERVER_HOST: Your server IP address
HOME_SERVER_USER: Your SSH username
HOME_SERVER_SSH_KEY: Your SSH private key
HOME_SERVER_PORT: 22 (default)
DEPLOY_PATH: ~/student-type-project
```

### Firewall Rules
- Port 22: SSH
- Port 80: HTTP
- Port 443: HTTPS
- Port 5000: Flask app (optional)

### Systemd Service
Service Name: `ml-app.service`

Commands:
```bash
sudo systemctl start ml-app    # Start application
sudo systemctl stop ml-app     # Stop application
sudo systemctl status ml-app   # Check status
sudo systemctl restart ml-app  # Restart application
```

### Manual Deployment
```bash
cd ~/student-type-project
./scripts/deploy.sh
```

### Viewing Logs
```bash
# Docker logs
docker compose logs -f

# Application logs
tail -f logs/deploy_*.log

# Nginx logs (if using nginx)
docker compose logs -f nginx
```

### Troubleshooting

#### Container won't start
```bash
docker compose down
docker compose up -d
docker compose logs
```

#### Model files missing
```bash
# Train model first
jupyter notebook training_notebook.ipynb
# Then redeploy
./scripts/deploy.sh
```

#### Port already in use
```bash
# Check what's using port 5000
sudo lsof -i :5000
# Kill the process if needed
sudo kill -9 <PID>
```

## Monitoring

### Health Check
```bash
curl http://localhost:5000/
```

### Container Status
```bash
docker compose ps
docker stats
```

### System Resources
```bash
htop
df -h
docker system df
```

## Maintenance

### Update Application
```bash
cd ~/student-type-project
git pull origin main
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Cleanup Old Images
```bash
docker image prune -a
docker system prune
```

### Backup
```bash
# Backup model files
tar -czf backup_$(date +%Y%m%d).tar.gz model/

# Backup entire project
tar -czf project_backup_$(date +%Y%m%d).tar.gz ~/student-type-project/
```

## Security Notes
- SSH keys are used for authentication (no password)
- Fail2ban monitors for brute force attacks
- UFW firewall restricts incoming connections
- Regular system updates recommended
- Use HTTPS in production (configure SSL certificates)
EOF

echo -e "${GREEN}✓${NC} Server setup documentation created at $PROJECT_DIR/SERVER_SETUP.md"
