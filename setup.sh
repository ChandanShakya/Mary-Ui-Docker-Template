#!/bin/bash

# KharchaTrack Project Setup Script
# Optimized for low-resource environments (Pentium CPU, <3GB RAM)
# Created: March 27, 2025

set -e  # Exit on error

# Text formatting
BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

echo -e "${BOLD}${GREEN}KharchaTrack Project Setup${RESET}"
echo -e "${YELLOW}Optimized for low-resource environments${RESET}"
echo "---------------------------------------------"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${RESET}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker Compose is not installed. Please install Docker Compose first.${RESET}"
    exit 1
fi

# Set up environment file if it doesn't exist
if [ ! -f ./laravel-project/.env ]; then
    echo -e "${YELLOW}Setting up environment file...${RESET}"
    cp ./laravel-project/.env.example ./laravel-project/.env 2>/dev/null || echo "APP_NAME=KharchaTrack
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

OCTANE_SERVER=frankenphp" > ./laravel-project/.env
fi

# Clean up previous containers and volumes if requested
if [ "$1" = "--clean" ]; then
    echo -e "${YELLOW}Cleaning up previous containers and volumes...${RESET}"
    docker-compose down -v
fi

# Build and start containers
echo -e "${YELLOW}Building and starting Docker containers...${RESET}"
docker-compose build
docker-compose up -d

# Wait for database and Redis to be ready
echo -e "${YELLOW}Waiting for services to be ready...${RESET}"
sleep 10

# Generate application key
echo -e "${YELLOW}Generating application key...${RESET}"
docker-compose exec frankenphp php artisan key:generate --force

# Run migrations
echo -e "${YELLOW}Running database migrations...${RESET}"
docker-compose exec frankenphp php artisan migrate --force

# Optimize for production
echo -e "${YELLOW}Optimizing for production environment...${RESET}"
docker-compose exec frankenphp php artisan config:cache
docker-compose exec frankenphp php artisan route:cache
docker-compose exec frankenphp php artisan view:cache
docker-compose exec frankenphp php artisan event:cache
docker-compose exec frankenphp composer install --optimize-autoloader --no-dev

# Set proper permissions
echo -e "${YELLOW}Setting proper file permissions...${RESET}"
docker-compose exec frankenphp chmod -R 775 storage bootstrap/cache
docker-compose exec frankenphp chown -R www-data:www-data storage bootstrap/cache

# Install NPM dependencies and build frontend assets (if needed)
if [ -f ./laravel-project/package.json ] && [ "$1" != "--skip-npm" ]; then
    echo -e "${YELLOW}Building frontend assets...${RESET}"
    docker-compose run --rm -w /app node npm ci
    docker-compose run --rm -w /app node npm run build
fi

# Check health status
echo -e "${YELLOW}Checking application health...${RESET}"
curl -s http://localhost:9000/health.php || echo -e "${RED}Health check failed. Application may not be fully operational.${RESET}"

# Output information
echo -e "${GREEN}Setup completed successfully!${RESET}"
echo -e "${BOLD}Your KharchaTrack application is now running at: http://localhost:9000${RESET}"
echo
echo -e "Resource Allocation:"
echo -e "- FrankenPHP: ${BOLD}0.8 CPU / 600MB RAM${RESET}"
echo -e "- PostgreSQL (latest): ${BOLD}0.5 CPU / 250MB RAM${RESET}"
echo -e "- Redis:      ${BOLD}0.3 CPU / 150MB RAM${RESET}"
echo
echo -e "Useful commands:"
echo -e "- ${BOLD}docker-compose down${RESET} to stop all services"
echo -e "- ${BOLD}docker-compose up -d${RESET} to start all services"
echo -e "- ${BOLD}docker-compose exec frankenphp php artisan${RESET} to run Laravel commands"
echo -e "- ${BOLD}./setup.sh --skip-npm${RESET} to skip building frontend assets"
echo -e "- ${BOLD}./setup.sh --clean${RESET} to clean up and start fresh"
echo
echo -e "${YELLOW}Documentation can be found in the docs/ directory.${RESET}"