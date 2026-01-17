#!/bin/bash

###############################################################################
# Deployment Script for Student Type Predictor ML Application
# Author: DevOps Team
# Description: Automated deployment with health checks and rollback capability
###############################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$PROJECT_DIR/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$PROJECT_DIR/logs/deploy_$TIMESTAMP.log"

# Functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Create necessary directories
mkdir -p "$BACKUP_DIR" "$PROJECT_DIR/logs" "$PROJECT_DIR/model"

# Banner
echo "=================================================="
echo "  Student Type Predictor - Deployment Script"
echo "=================================================="
echo ""

# Step 1: Pre-deployment checks
log "Running pre-deployment checks..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker compose &> /dev/null; then
    error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if model files exist
if [ ! -f "$PROJECT_DIR/model/model.pkl" ]; then
    warning "Model file not found. Please train the model first by running training_notebook.ipynb"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

success "Pre-deployment checks passed"

# Step 2: Backup existing deployment
log "Creating backup of existing deployment..."

if [ "$(docker ps -q -f name=student-type-predictor)" ]; then
    docker commit student-type-predictor "student-type-predictor-backup:$TIMESTAMP" || true
    success "Backup created: student-type-predictor-backup:$TIMESTAMP"
else
    warning "No existing container to backup"
fi

# Step 3: Build Docker image
log "Building Docker image..."
cd "$PROJECT_DIR"

if docker compose build --no-cache; then
    success "Docker image built successfully"
else
    error "Failed to build Docker image"
    exit 1
fi

# Step 4: Stop existing containers
log "Stopping existing containers..."

if docker compose down; then
    success "Existing containers stopped"
else
    warning "No existing containers to stop"
fi

# Step 5: Start new containers
log "Starting new containers..."

if docker compose up -d; then
    success "Containers started successfully"
else
    error "Failed to start containers"
    
    # Rollback
    log "Attempting rollback..."
    if [ "$(docker images -q student-type-predictor-backup:$TIMESTAMP 2> /dev/null)" ]; then
        docker tag "student-type-predictor-backup:$TIMESTAMP" student-type-predictor:latest
        docker compose up -d
        error "Deployment failed. Rolled back to previous version."
    fi
    exit 1
fi

# Step 6: Health check
log "Running health checks..."
HEALTH_CHECK_RETRIES=10
HEALTH_CHECK_INTERVAL=5

for i in $(seq 1 $HEALTH_CHECK_RETRIES); do
    log "Health check attempt $i/$HEALTH_CHECK_RETRIES..."
    
    if curl -f http://localhost:5000/ > /dev/null 2>&1; then
        success "Application is healthy!"
        break
    else
        if [ $i -eq $HEALTH_CHECK_RETRIES ]; then
            error "Health check failed after $HEALTH_CHECK_RETRIES attempts"
            
            # Show logs
            log "Container logs:"
            docker compose logs --tail=50
            
            # Rollback
            log "Attempting rollback..."
            docker compose down
            if [ "$(docker images -q student-type-predictor-backup:$TIMESTAMP 2> /dev/null)" ]; then
                docker tag "student-type-predictor-backup:$TIMESTAMP" student-type-predictor:latest
                docker compose up -d
                error "Deployment failed. Rolled back to previous version."
            fi
            exit 1
        fi
        sleep $HEALTH_CHECK_INTERVAL
    fi
done

# Step 7: Cleanup
log "Cleaning up old images..."
docker image prune -f || true
success "Cleanup completed"

# Step 8: Display status
echo ""
echo "=================================================="
success "Deployment completed successfully!"
echo "=================================================="
echo ""
echo "Application is running at: http://localhost:5000"
echo "View logs: docker compose logs -f"
echo "Stop application: docker compose down"
echo ""

# Display container status
docker compose ps

# Save deployment info
cat > "$PROJECT_DIR/logs/deployment_info.txt" << EOF
Deployment Timestamp: $TIMESTAMP
Status: SUCCESS
Image: student-type-predictor:latest
Backup: student-type-predictor-backup:$TIMESTAMP
Log File: $LOG_FILE
EOF

exit 0
