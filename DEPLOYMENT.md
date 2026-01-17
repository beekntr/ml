# Deployment Guide - DevOps Implementation

## 📋 Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Local Development Setup](#local-development-setup)
4. [Docker Deployment](#docker-deployment)
5. [CI/CD Pipeline](#cicd-pipeline)
6. [Home Server Deployment](#home-server-deployment)
7. [Monitoring & Maintenance](#monitoring--maintenance)
8. [Troubleshooting](#troubleshooting)

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Repository                        │
│                   (Source Code + CI/CD)                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ Push triggers GitHub Actions
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   GitHub Actions CI/CD                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Test    │─▶│  Build   │─▶│  Push    │─▶│  Deploy  │   │
│  │  & Lint  │  │  Docker  │  │  Image   │  │  to Home │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└────────────────────────┬────────────────────────────────────┘
                         │ SSH Deployment
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                      Home Server                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Docker Compose Stack                     │  │
│  │  ┌──────────────┐           ┌──────────────┐        │  │
│  │  │    Nginx     │◀─────────▶│  Flask App   │        │  │
│  │  │ (Port 80/443)│           │ (Port 5000)  │        │  │
│  │  └──────────────┘           └──────────────┘        │  │
│  │        │                            │                 │  │
│  │        │                            ▼                 │  │
│  │        │                     ┌──────────────┐        │  │
│  │        │                     │ Model Files  │        │  │
│  │        │                     │   (.pkl)     │        │  │
│  │        │                     └──────────────┘        │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Components:
- **GitHub Actions**: Automated CI/CD pipeline
- **Docker**: Containerization for consistent deployments
- **Docker Compose**: Multi-container orchestration
- **Nginx**: Reverse proxy & load balancer (optional)
- **Flask App**: ML prediction service
- **Home Server**: Self-hosted deployment environment

---

## ✅ Prerequisites

### Required Software
- **Docker** (v20.10+)
- **Docker Compose** (v2.0+)
- **Git** (v2.30+)
- **Python** (3.10+ for local development)

### Optional Tools
- **kubectl** (for Kubernetes deployment)
- **Ansible** (for configuration management)
- **Prometheus** (for monitoring)

### GitHub Secrets Required
Configure these in your GitHub repository settings:
```
HOME_SERVER_HOST      # Your server IP/domain (e.g., 192.168.1.100)
HOME_SERVER_USER      # SSH username
HOME_SERVER_SSH_KEY   # SSH private key (entire content)
HOME_SERVER_PORT      # SSH port (default: 22)
DEPLOY_PATH           # Deployment directory (e.g., ~/student-type-project)
```

---

## 💻 Local Development Setup

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/student-type-project.git
cd student-type-project
```

### 2. Install Dependencies
```bash
# Using virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 3. Train Model
```bash
# Open Jupyter Notebook
jupyter notebook training_notebook.ipynb

# Execute all cells to train and save models
```

### 4. Run Flask App
```bash
python app.py
# Visit: http://localhost:5000
```

---

## 🐳 Docker Deployment

### Option 1: Docker Compose (Recommended)

```bash
# Build and start all services
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down
```

### Option 2: Docker Only

```bash
# Build image
docker build -t student-type-predictor .

# Run container
docker run -d \
  --name ml-app \
  -p 5000:5000 \
  -v $(pwd)/model:/app/model \
  student-type-predictor

# View logs
docker logs -f ml-app

# Stop container
docker stop ml-app
```

### Docker Commands Cheat Sheet
```bash
# View running containers
docker ps

# View all containers
docker ps -a

# Remove stopped containers
docker container prune

# Remove unused images
docker image prune -a

# View system resource usage
docker stats

# Execute command in container
docker exec -it student-type-predictor bash
```

---

## 🔄 CI/CD Pipeline

### Pipeline Stages

#### 1️⃣ **Test & Lint** (Automated)
- Code formatting check (Black)
- Static analysis (Pylint, Flake8)
- Security scanning (Bandit)
- Unit tests (pytest)

#### 2️⃣ **Build** (Automated)
- Docker image build
- Multi-stage optimization
- Push to GitHub Container Registry
- Vulnerability scanning (Trivy)

#### 3️⃣ **Deploy** (Automated on `main` branch)
- SSH to home server
- Pull latest code & image
- Docker Compose orchestration
- Health check validation

#### 4️⃣ **Validate** (Automated)
- Post-deployment smoke tests
- API endpoint verification
- Performance checks

### Triggering Pipeline

**Automatic Triggers:**
```bash
# Push to main or develop branch
git push origin main

# Create pull request
gh pr create --base main
```

**Manual Trigger:**
- Go to GitHub Actions tab
- Select "CI/CD Pipeline"
- Click "Run workflow"

### Pipeline Configuration
Located in `.github/workflows/ci-cd.yml`

**Key Features:**
- ✅ Parallel test execution
- ✅ Docker layer caching
- ✅ Automated rollback on failure
- ✅ Security scanning
- ✅ Multi-environment support

---

## 🏠 Home Server Deployment

### Initial Server Setup

#### 1. Run Setup Script
```bash
# On your home server
wget https://raw.githubusercontent.com/yourusername/student-type-project/main/scripts/setup-server.sh
chmod +x setup-server.sh
sudo ./setup-server.sh
```

This script will:
- ✅ Install Docker & Docker Compose
- ✅ Configure firewall (UFW)
- ✅ Setup SSH keys for CI/CD
- ✅ Create project directory
- ✅ Configure systemd service
- ✅ Setup log rotation

#### 2. Configure GitHub Secrets

**Get your SSH private key:**
```bash
cat ~/.ssh/id_ed25519
```

**Get your server IP:**
```bash
hostname -I | awk '{print $1}'
```

Add these to GitHub: **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

#### 3. Enable Systemd Service
```bash
sudo systemctl enable ml-app.service
sudo systemctl start ml-app.service
```

### Manual Deployment

```bash
# Navigate to project directory
cd ~/student-type-project

# Make deploy script executable
chmod +x scripts/deploy.sh

# Run deployment
./scripts/deploy.sh
```

### Deployment Script Features
- ✅ Pre-deployment validation
- ✅ Automatic backup creation
- ✅ Zero-downtime deployment
- ✅ Health checks
- ✅ Automatic rollback on failure
- ✅ Detailed logging

---

## 📊 Monitoring & Maintenance

### Health Checks

```bash
# Application health
curl http://localhost:5000/

# Container status
docker compose ps

# Resource usage
docker stats
```

### Viewing Logs

```bash
# Real-time application logs
docker compose logs -f ml-app

# Last 100 lines
docker compose logs --tail=100

# Deployment logs
tail -f logs/deploy_*.log

# Nginx logs (if using)
docker compose logs -f nginx
```

### System Monitoring

```bash
# Disk usage
docker system df

# Container resource usage
docker stats

# System resources
htop
df -h
free -h
```

### Log Rotation
Logs are automatically rotated using logrotate:
- **Frequency**: Daily
- **Retention**: 14 days
- **Compression**: Yes
- **Location**: `logs/*.log`

### Backup Strategy

```bash
# Backup model files
tar -czf backup_models_$(date +%Y%m%d).tar.gz model/

# Backup entire project
tar -czf backup_project_$(date +%Y%m%d).tar.gz ~/student-type-project/

# Automated backup (add to crontab)
0 2 * * * cd ~/student-type-project && tar -czf backups/backup_$(date +\%Y\%m\%d).tar.gz model/
```

### Updating Application

```bash
# Pull latest changes
git pull origin main

# Rebuild and restart
docker compose down
docker compose build --no-cache
docker compose up -d

# Or use deployment script
./scripts/deploy.sh
```

---

## 🔧 Troubleshooting

### Common Issues

#### ❌ Port Already in Use
```bash
# Find process using port 5000
sudo lsof -i :5000

# Kill process
sudo kill -9 <PID>

# Or use different port
docker compose up -d --env PORT=5001
```

#### ❌ Model Files Missing
```bash
# Train model first
jupyter notebook training_notebook.ipynb

# Copy model files to correct location
cp model/*.pkl ~/student-type-project/model/

# Restart application
docker compose restart
```

#### ❌ Container Won't Start
```bash
# Check logs
docker compose logs ml-app

# Remove and recreate
docker compose down
docker compose up -d --force-recreate

# Check disk space
df -h
```

#### ❌ Permission Denied Errors
```bash
# Fix file permissions
sudo chown -R $USER:$USER ~/student-type-project

# Fix Docker socket permissions
sudo chmod 666 /var/run/docker.sock
```

#### ❌ CI/CD Pipeline Fails
```bash
# Check GitHub Actions logs
# Go to: https://github.com/yourusername/repo/actions

# Common fixes:
# 1. Verify GitHub secrets are correct
# 2. Check SSH connectivity: ssh user@server-ip
# 3. Ensure deploy path exists on server
# 4. Check server disk space
```

#### ❌ Health Check Fails
```bash
# Check application logs
docker compose logs -f ml-app

# Test manually
curl -v http://localhost:5000/

# Restart application
docker compose restart ml-app
```

### Performance Optimization

```bash
# Clear Docker cache
docker builder prune

# Remove unused volumes
docker volume prune

# Optimize images
docker image prune -a

# Check resource limits
docker stats
```

---

## 🚀 Advanced Deployment Options

### Option 1: Kubernetes Deployment
```bash
# Create deployment
kubectl apply -f k8s/deployment.yaml

# Expose service
kubectl expose deployment ml-app --type=LoadBalancer --port=5000
```

### Option 2: Docker Swarm
```bash
# Initialize swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker-compose.yml ml-stack
```

### Option 3: Cloud Deployment
- **AWS ECS/Fargate**
- **Google Cloud Run**
- **Azure Container Instances**
- **DigitalOcean App Platform**

---

## 📚 Additional Resources

### Documentation
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Flask Deployment](https://flask.palletsprojects.com/en/2.3.x/deploying/)

### Best Practices
- ✅ Use multi-stage Docker builds
- ✅ Implement health checks
- ✅ Setup monitoring & alerting
- ✅ Regular backups
- ✅ Security scanning
- ✅ Log aggregation
- ✅ Auto-scaling for production

---

## 🆘 Support

For issues or questions:
1. Check [Troubleshooting](#troubleshooting) section
2. Review deployment logs
3. Check GitHub Issues
4. Consult SERVER_SETUP.md

---

**Last Updated**: January 2026  
**Version**: 1.0.0  
**Maintainer**: DevOps Team
