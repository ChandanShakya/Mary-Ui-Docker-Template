#!/bin/bash

#===========================================
# maryDock Project Setup Script
# Optimized for low-resource environments
# Created: March 27, 2025
# Last updated: March 28, 2025
#===========================================

# Exit on any error to prevent partial setups
set -e

#===========================================
# ANSI color codes for prettier output
#===========================================
BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
RESET="\033[0m"

#===========================================
# Header and introduction
#===========================================
echo -e "${BOLD}${BLUE}╔════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${BLUE}║         maryDock Setup               ║${RESET}"
echo -e "${BOLD}${BLUE}╚════════════════════════════════════════╝${RESET}"
echo -e "${YELLOW}Optimized for low-resource environments${RESET}"
echo -e "${GREEN}▶ Starting setup process...${RESET}\n"

#===========================================
# Check prerequisites
#===========================================
echo -e "${BOLD}[1/7]${RESET} ${YELLOW}Checking prerequisites...${RESET}"

# Check if Docker is installed
if ! command -v docker &>/dev/null; then
  echo -e "${RED}✗ Error: Docker is not installed.${RESET}"
  echo -e "${YELLOW}▶ Please install Docker first: https://docs.docker.com/get-docker/${RESET}"
  exit 1
fi
echo -e "${GREEN}✓ Docker is installed.${RESET}"

# Check if Docker Compose is installed
if ! command -v docker-compose &>/dev/null; then
  echo -e "${RED}✗ Error: Docker Compose is not installed.${RESET}"
  echo -e "${YELLOW}▶ Please install Docker Compose first: https://docs.docker.com/compose/install/${RESET}"
  exit 1
fi
echo -e "${GREEN}✓ Docker Compose is installed.${RESET}"

#===========================================
# Environment setup
#===========================================
echo -e "\n${BOLD}[2/7]${RESET} ${YELLOW}Setting up environment...${RESET}"

# Set up environment file if it doesn't exist
if [ ! -f ./laravel-project/.env ]; then
  echo -e "${YELLOW}▶ Creating .env file...${RESET}"
  cp ./laravel-project/.env.example ./laravel-project/.env 2>/dev/null || echo "APP_NAME=maryDock
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=http://localhost:9000

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=error

DB_CONNECTION=pgsql
DB_HOST=postgres
DB_PORT=5432
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret

BROADCAST_DRIVER=log
CACHE_DRIVER=redis
FILESYSTEM_DISK=local
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
SESSION_LIFETIME=120

MEMCACHED_HOST=127.0.0.1

REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379
REDIS_CLIENT=phpredis

MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="${APP_NAME}"

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=
AWS_USE_PATH_STYLE_ENDPOINT=false

PUSHER_APP_ID=
PUSHER_APP_KEY=
PUSHER_APP_SECRET=
PUSHER_HOST=
PUSHER_PORT=443
PUSHER_SCHEME=https
PUSHER_APP_CLUSTER=mt1

VITE_APP_NAME="${APP_NAME}"
VITE_PUSHER_APP_KEY="${PUSHER_APP_KEY}"
VITE_PUSHER_HOST="${PUSHER_HOST}"
VITE_PUSHER_PORT="${PUSHER_PORT}"
VITE_PUSHER_SCHEME="${PUSHER_SCHEME}"
VITE_PUSHER_APP_CLUSTER="${PUSHER_APP_CLUSTER}"

OCTANE_SERVER=frankenphp" >./laravel-project/.env
  echo -e "${GREEN}✓ Environment file created.${RESET}"
else
  echo -e "${GREEN}✓ Environment file already exists.${RESET}"
fi

#===========================================
# Container preparation
#===========================================
echo -e "\n${BOLD}[3/7]${RESET} ${YELLOW}Preparing containers...${RESET}"
# Clean up previous containers and volumes if requested
if [ "$1" = "--clean" ]; then
  echo -e "${YELLOW}▶ Cleaning up previous containers and volumes...${RESET}"
  
  # Check for and stop any running Node containers first
  node_containers=$(docker ps -q --filter "name=vite_dev_server" --filter "name=mary-ui-docker-template-node")
  if [ -n "$node_containers" ]; then
    echo -e "${YELLOW}▶ Stopping Node.js development server...${RESET}"
    docker stop $node_containers
    docker rm $node_containers 2>/dev/null
  fi
  
  docker-compose down -v
  echo -e "${GREEN}✓ Previous setup cleaned.${RESET}"
else
  echo -e "${YELLOW}▶ Using existing setup (use --clean to start fresh).${RESET}"
fi

# Build and start containers
echo -e "${YELLOW}▶ Building Docker containers...${RESET}"
docker-compose build

echo -e "${YELLOW}▶ Starting Docker containers...${RESET}"
docker-compose up -d

# Wait for database and Redis to be ready
echo -e "${YELLOW}▶ Waiting for services to initialize (10s)...${RESET}"
sleep 10
echo -e "${GREEN}✓ Services ready.${RESET}"

#===========================================
# Laravel initialization
#===========================================
echo -e "\n${BOLD}[4/7]${RESET} ${YELLOW}Initializing Laravel application...${RESET}"

# Generate application key
echo -e "${YELLOW}▶ Generating application key...${RESET}"
docker-compose exec frankenphp php artisan key:generate --force
echo -e "${GREEN}✓ Application key generated.${RESET}"

# Run migrations
echo -e "${YELLOW}▶ Running database migrations...${RESET}"
docker-compose exec frankenphp php artisan migrate --force
echo -e "${GREEN}✓ Migrations completed.${RESET}"

#===========================================
# Performance optimizations
#===========================================
echo -e "\n${BOLD}[5/7]${RESET} ${YELLOW}Applying performance optimizations...${RESET}"

echo -e "${YELLOW}▶ Caching configurations...${RESET}"
docker-compose exec frankenphp php artisan config:cache
docker-compose exec frankenphp php artisan route:cache
docker-compose exec frankenphp php artisan view:cache
docker-compose exec frankenphp php artisan event:cache
echo -e "${GREEN}✓ Configuration caching complete.${RESET}"

echo -e "${YELLOW}▶ Optimizing Composer autoloader...${RESET}"
docker-compose run --rm composer install --optimize-autoloader --no-dev
echo -e "${GREEN}✓ Composer optimized.${RESET}"

#===========================================
# Set file permissions
#===========================================
echo -e "\n${BOLD}[6/7]${RESET} ${YELLOW}Setting file permissions...${RESET}"
docker-compose exec frankenphp chmod -R 775 storage bootstrap/cache
docker-compose exec frankenphp chown -R www-data:www-data storage bootstrap/cache
echo -e "${GREEN}✓ File permissions set.${RESET}"

#===========================================
# Frontend assets
#===========================================
echo -e "\n${BOLD}[7/7]${RESET} ${YELLOW}Setting up frontend assets...${RESET}"

# Install NPM dependencies and build frontend assets (if needed)
if [ -f ./laravel-project/package.json ]; then
  # Production build or development mode
  if [ "$1" != "--skip-npm" ]; then
    echo -e "${YELLOW}▶ Installing frontend dependencies...${RESET}"
    docker-compose run --rm node install
    echo -e "${GREEN}✓ Dependencies installed.${RESET}"

    echo -e "${YELLOW}▶ Building frontend assets for production...${RESET}"
    docker-compose run --rm node build
    echo -e "${GREEN}✓ Frontend assets built.${RESET}"
  else
    echo -e "${YELLOW}▶ Skipping frontend build (--skip-npm flag detected).${RESET}"
  fi

  # Start development server if --dev flag is passed
  if [ "$1" = "--dev" ]; then
    echo -e "\n${BLUE}▶ Starting Vite development server with Livewire hot reload...${RESET}"
    docker-compose run --rm -d -p 5173:5173 --name vite_dev_server --entrypoint "yarn dev --host 0.0.0.0" node
    echo -e "${GREEN}✓ Vite development server started at: http://localhost:5173${RESET}"
  fi
else
  echo -e "${YELLOW}▶ No package.json found. Skipping frontend setup.${RESET}"
fi

#===========================================
# Health check
#===========================================
echo -e "\n${BOLD}[FINAL]${RESET} ${YELLOW}Performing health check...${RESET}"
health_check=$(curl -s http://localhost:9000/health.php)

if [ -n "$health_check" ]; then
  echo -e "${GREEN}✓ Health check passed. Application is operational.${RESET}"
else
  echo -e "${RED}✗ Health check failed. Application may not be fully operational.${RESET}"
  echo -e "${YELLOW}▶ Check logs with: docker-compose logs frankenphp${RESET}"
fi

#===========================================
# Success message and instructions
#===========================================
echo -e "\n${BOLD}${GREEN}╔════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}║       Setup completed successfully!     ║${RESET}"
echo -e "${BOLD}${GREEN}╚════════════════════════════════════════╝${RESET}"

echo -e "\n${BOLD}Your maryDock application is now running at:${RESET}"
echo -e "${BOLD}${BLUE}http://localhost:9000${RESET}"

echo -e "\n${YELLOW}Resource Allocation:${RESET}"
echo -e "- FrankenPHP: ${BOLD}0.8 CPU / 600MB RAM${RESET}"
echo -e "- PostgreSQL: ${BOLD}0.5 CPU / 250MB RAM${RESET}"
echo -e "- Redis:      ${BOLD}0.3 CPU / 150MB RAM${RESET}"

echo -e "\n${YELLOW}Quick Management:${RESET}"
echo -e "- Run ${BOLD}./runner.sh${RESET} for a simple GUI to manage your application."

echo -e "\n${YELLOW}Useful commands:${RESET}"
echo -e "- ${BOLD}docker-compose down${RESET} to stop all services"
echo -e "- ${BOLD}docker-compose up -d${RESET} to start all services"
echo -e "- ${BOLD}docker-compose exec frankenphp php artisan${RESET} to run Laravel commands"
echo -e "- ${BOLD}docker-compose run --rm node dev${RESET} to start Vite development server"

echo -e "\n${YELLOW}Setup options:${RESET}"
echo -e "- ${BOLD}./setup.sh --skip-npm${RESET} to skip building frontend assets"
echo -e "- ${BOLD}./setup.sh --clean${RESET} to clean up and start fresh"
echo -e "- ${BOLD}./setup.sh --dev${RESET} to start with development environment"

echo -e "\n${YELLOW}Documentation can be found in the docs/ directory.${RESET}"
echo -e "${GREEN}Happy coding!${RESET}\n"
