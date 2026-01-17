# Quick Start - Docker Deployment

## Option 1: Quick Local Test (2 minutes)
```bash
# Build and run
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f

# Access application
# Open browser: http://localhost:5000

# Stop
docker compose down
```

## Option 2: Production Deployment (5 minutes)

### On Your Home Server:
```bash
# 1. Install Docker & setup server
wget https://raw.githubusercontent.com/yourusername/student-type-project/main/scripts/setup-server.sh
chmod +x setup-server.sh
sudo ./setup-server.sh

# 2. Navigate to project
cd ~/student-type-project

# 3. Deploy
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

### On GitHub:
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Add secrets:
   - `HOME_SERVER_HOST`: Your server IP
   - `HOME_SERVER_USER`: SSH username
   - `HOME_SERVER_SSH_KEY`: Your SSH private key
   - `DEPLOY_PATH`: ~/student-type-project

3. Push code to trigger automatic deployment:
```bash
git push origin main
```

## Essential Commands

```bash
# Start application
docker compose up -d

# Stop application
docker compose down

# View logs
docker compose logs -f

# Restart
docker compose restart

# Check health
curl http://localhost:5000/

# Update application
git pull origin main
docker compose down
docker compose build --no-cache
docker compose up -d
```

## Troubleshooting

**Container won't start?**
```bash
docker compose logs ml-app
```

**Port 5000 in use?**
```bash
sudo lsof -i :5000
sudo kill -9 <PID>
```

**Model files missing?**
```bash
# Train model first
jupyter notebook training_notebook.ipynb
# Then restart
docker compose restart
```

For detailed documentation, see [DEPLOYMENT.md](DEPLOYMENT.md)
