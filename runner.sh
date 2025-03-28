#!/bin/bash

#===========================================
# maryDock Server CLI Runner
# CLI tool for managing the application via SSH
# Created: March 28, 2025
# Last updated: March 28, 2025
#===========================================

# ANSI color codes for prettier output
BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
WHITE="\033[0;37m"
BG_BLUE="\033[44m"
BG_GREEN="\033[42m"
BG_RED="\033[41m"
RESET="\033[0m"

# Root directory of the project
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to check if containers are running
check_status() {
    # Check if docker compose is able to connect
    if ! docker-compose ps &>/dev/null; then
        echo "stopped"
        return
    fi
    
    local running_containers=$(docker-compose ps --services --filter "status=running" 2>/dev/null | wc -l)
    if [ $running_containers -gt 0 ]; then
        echo "running"
    else
        echo "stopped"
    fi
}

# Function to check if Xdebug is enabled
check_xdebug() {
    # Check if container is running first
    if [ "$(check_status)" != "running" ]; then
        echo "disabled"
        return
    fi
    
    # Get xdebug mode - properly handle "no value" or empty value cases
    local xdebug_mode=$(docker-compose exec -T frankenphp php -r 'echo ini_get("xdebug.mode");' 2>/dev/null)
    
    # For debug purposes
    # echo "Raw xdebug mode: '$xdebug_mode'"
    
    # Check if mode is empty, "no value", or "off"
    if [ -z "$xdebug_mode" ] || [ "$xdebug_mode" = "no value" ] || [ "$xdebug_mode" = "off" ]; then
        echo "disabled"
    else
        echo "enabled"
        echo "$xdebug_mode" > /tmp/xdebug_mode.txt
    fi
}

# Function to start all services
start_services() {
    echo -e "${YELLOW}Starting maryDock services...${RESET}"
    docker-compose up -d
    sleep 2
    if [ "$(check_status)" == "running" ]; then
        echo -e "${GREEN}✓ maryDock started successfully!${RESET}"
        echo -e "${BLUE}Server is running at: http://localhost:9000${RESET}"
    else
        echo -e "${RED}✗ Failed to start services. Check logs with: docker-compose logs${RESET}"
        exit 1
    fi
}

# Function to stop all services
stop_services() {
    echo -e "${YELLOW}Stopping maryDock services...${RESET}"
    
    # Check for and stop any running Node container first
    local node_container=$(docker ps -q --filter "name=vite_dev_server" --filter "name=mary-ui-docker-template-node")
    if [ -n "$node_container" ]; then
        echo -e "${YELLOW}Stopping Node.js development server...${RESET}"
        docker stop $node_container
        docker rm $node_container 2>/dev/null
    fi
    
    docker-compose down
    
    # Give a moment for network cleanup
    sleep 2
    
    # Just check if any containers are still running
    if [ -n "$(docker ps -q --filter "name=laravel_")" ]; then
        echo -e "${RED}✗ Failed to stop services. Try: docker-compose down --remove-orphans${RESET}"
        exit 1
    else
        echo -e "${GREEN}✓ maryDock stopped successfully!${RESET}"
    fi
}

# Function to stop node development server only
stop_node() {
    echo -e "${YELLOW}Stopping Node.js development server...${RESET}"
    
    # Check for and stop any running Node container
    node_container=$(docker ps -q --filter "name=vite_dev_server" --filter "name=mary-ui-docker-template-node")
    if [ -n "$node_container" ]; then
        docker stop $node_container
        docker rm $node_container 2>/dev/null
        echo -e "${GREEN}✓ Node.js development server stopped.${RESET}"
    else
        echo -e "${YELLOW}No running Node.js development server found.${RESET}"
    fi
}

# Function to restart all services
restart_services() {
    echo -e "${YELLOW}Restarting maryDock services...${RESET}"
    
    # Check for and stop any running Node container first
    local node_container=$(docker ps -q --filter "name=vite_dev_server" --filter "name=mary-ui-docker-template-node")
    if [ -n "$node_container" ]; then
        echo -e "${YELLOW}Stopping Node.js development server...${RESET}"
        docker stop $node_container
        docker rm $node_container 2>/dev/null
    fi
    
    docker-compose down
    sleep 2
    docker-compose up -d
    sleep 2
    if [ "$(check_status)" == "running" ]; then
        echo -e "${GREEN}✓ maryDock restarted successfully!${RESET}"
        echo -e "${BLUE}Server is running at: http://localhost:9000${RESET}"
    else
        echo -e "${RED}✗ Failed to restart services. Check logs with: docker-compose logs${RESET}"
        exit 1
    fi
}

# Function to show container status
show_status() {
    echo -e "${BLUE}=== Container Status ===${RESET}"
    docker-compose ps
    echo
    echo -e "${BLUE}=== Resource Usage ===${RESET}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
    
    # Check Xdebug status
    if [ "$(check_status)" == "running" ]; then
        local xdebug_status=$(check_xdebug)
        if [ "$xdebug_status" == "enabled" ]; then
            echo -e "\n${GREEN}Xdebug is enabled${RESET}"
            # Get the mode directly through PHP to handle edge cases better
            local xdebug_mode=$(docker-compose exec -T frankenphp php -r 'echo ini_get("xdebug.mode");' 2>/dev/null)
            echo -e "Mode: ${YELLOW}${xdebug_mode}${RESET}"
        else
            echo -e "\n${RED}Xdebug is disabled${RESET}"
        fi
    fi
}

# Function to view logs
view_logs() {
    local service=$1
    
    if [ -z "$service" ]; then
        echo -e "${YELLOW}Available services:${RESET}"
        docker-compose config --services | cat -n
        echo
        echo -e "${YELLOW}Usage: $0 logs [service-name]${RESET}"
        echo -e "${YELLOW}Example: $0 logs frankenphp${RESET}"
        exit 1
    fi
    
    echo -e "${BLUE}=== Logs for $service ===${RESET}"
    docker-compose logs "$service"
}

# Function to start development server
start_dev_mode() {
    echo -e "${YELLOW}Starting Vite development server with Livewire hot reload...${RESET}"
    echo -e "${YELLOW}Note: This will run in the foreground. Press Ctrl+C to stop.${RESET}"
    sleep 2
    docker-compose run --rm -p 5173:5173 node dev
}

# Function to run dev server in background
start_dev_background() {
    echo -e "${YELLOW}Starting Vite development server with Livewire hot reload in background...${RESET}"
    docker-compose run -d --rm -p 5173:5173 --name vite_dev_server --entrypoint "yarn dev --host 0.0.0.0" node
    echo -e "${GREEN}✓ Development server started in background${RESET}"
    echo -e "${BLUE}Vite server is running at: http://localhost:5173${RESET}"
}

# Function to enable Xdebug
enable_xdebug() {
    local mode=$1
    
    if [ -z "$mode" ]; then
        echo -e "${YELLOW}Available Xdebug modes:${RESET}"
        echo "  debug     - Debug mode for step debugging"
        echo "  develop   - Development mode (includes debug+trace)"
        echo "  profile   - Profiling mode for performance analysis"
        echo "  trace     - Tracing for function calls analysis"
        echo "  coverage  - Code coverage analysis"
        echo
        echo -e "${YELLOW}Usage: $0 enable-xdebug [mode]${RESET}"
        echo -e "${YELLOW}Example: $0 enable-xdebug debug${RESET}"
        exit 1
    fi
    
    if [ "$(check_status)" != "running" ]; then
        echo -e "${RED}✗ Server is not running. Please start it first with: $0 start${RESET}"
        exit 1
    fi
    
    # Validate mode
    case $mode in
        debug|develop|profile|trace|coverage)
            # Valid mode
            ;;
        *)
            echo -e "${RED}✗ Invalid Xdebug mode: $mode${RESET}"
            echo -e "${YELLOW}Available modes: debug, develop, profile, trace, coverage${RESET}"
            exit 1
            ;;
    esac
    
    echo -e "${YELLOW}Enabling Xdebug in $mode mode...${RESET}"
    
    # Get current Xdebug status before changes
    echo -e "${YELLOW}Checking current Xdebug status...${RESET}"
    docker-compose exec frankenphp php -v | grep -i xdebug
    
    # First, make sure the PHP installation has the necessary packages
    echo -e "${YELLOW}Ensuring Xdebug is properly installed...${RESET}"
    
    # Update both potential Xdebug config files
    echo -e "${YELLOW}Creating Xdebug configuration in container...${RESET}"
    
    # Update the main xdebug.ini file
    docker-compose exec frankenphp bash -c "echo 'zend_extension=xdebug.so
xdebug.mode=$mode
xdebug.start_with_request=trigger
xdebug.client_host=host.docker.internal
xdebug.discover_client_host=true
xdebug.client_port=9003
xdebug.log=/tmp/xdebug.log
xdebug.idekey=VSCODE' > /usr/local/etc/php/conf.d/xdebug.ini"

    # Also update the docker-php-ext-xdebug.ini file if it exists
    docker-compose exec frankenphp bash -c "if [ -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini ]; then
        echo 'zend_extension=xdebug.so
xdebug.mode=$mode
xdebug.start_with_request=trigger
xdebug.client_host=host.docker.internal
xdebug.discover_client_host=true
xdebug.client_port=9003
xdebug.log=/tmp/xdebug.log
xdebug.idekey=VSCODE' > /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
    fi"

    # Use a more effective way to restart PHP processes
    echo -e "${YELLOW}Restarting PHP to apply Xdebug settings...${RESET}"
    docker-compose restart frankenphp
    sleep 3
    
    # Verify that Xdebug is enabled with the correct mode
    local xdebug_mode=$(docker-compose exec -T frankenphp php -r 'echo ini_get("xdebug.mode");' 2>/dev/null)
    echo -e "${YELLOW}Detected Xdebug mode: $xdebug_mode${RESET}"
    
    if [[ "$xdebug_mode" == *"$mode"* ]]; then
        echo -e "${GREEN}✓ Xdebug has been successfully enabled in $mode mode.${RESET}"
    else
        echo -e "${RED}✗ Failed to enable Xdebug in $mode mode. Current mode: $xdebug_mode${RESET}"
        echo -e "${YELLOW}Trying to debug the issue...${RESET}"
        docker-compose exec frankenphp bash -c "php -v | grep -i xdebug || echo 'Xdebug not showing in PHP version'"
        docker-compose exec frankenphp bash -c "ls -la /usr/local/etc/php/conf.d/ | grep xdebug"
        docker-compose exec frankenphp bash -c "cat /usr/local/etc/php/conf.d/xdebug.ini"
        [ -n "$(docker-compose exec -T frankenphp bash -c "ls -la /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini 2>/dev/null")" ] && \
            docker-compose exec frankenphp bash -c "cat /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini"
        echo -e "${YELLOW}=== PHP Modules ===${RESET}"
        docker-compose exec frankenphp bash -c "php -m | grep -i xdebug"
        echo -e "${YELLOW}=== Xdebug Info ===${RESET}"
        docker-compose exec frankenphp php -i | grep -i xdebug
    fi
    
    echo -e "${YELLOW}To trigger debugging:${RESET}"
    echo "  1. Use XDEBUG_TRIGGER query parameter in URLs"
    echo "    Example: http://localhost:9000/?XDEBUG_TRIGGER"
    echo "  2. Set XDEBUG_TRIGGER cookie"
    echo "  3. Set XDEBUG_TRIGGER environment variable"
    echo
    echo -e "${YELLOW}VS Code Configuration:${RESET}"
    echo "  - In VS Code over SSH, ensure port 9003 is forwarded"
    echo "  - Setup path mappings in launch.json: /app -> ./laravel-project"
    echo -e "${YELLOW}IDEKey: VSCODE, Client Port: 9003${RESET}"
}

# Function to disable Xdebug
disable_xdebug() {
    if [ "$(check_status)" != "running" ]; then
        echo -e "${RED}✗ Server is not running. Please start it first with: $0 start${RESET}"
        exit 1
    fi
    
    echo -e "${YELLOW}Disabling Xdebug...${RESET}"
    
    # Create Xdebug INI file directly in the app container that disables Xdebug
    echo -e "${YELLOW}Creating Xdebug configuration in container...${RESET}"
    docker-compose exec frankenphp bash -c "echo 'zend_extension=xdebug.so
xdebug.mode=off' > /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini"
    
    # Restart PHP FPM to apply the configuration
    echo -e "${YELLOW}Restarting PHP to apply Xdebug settings...${RESET}"
    docker-compose exec frankenphp bash -c "kill -USR2 \$(ps -o pid= -C php-fpm) 2>/dev/null || killall -USR2 php-fpm 2>/dev/null || echo 'PHP-FPM not running, trying Octane'"
    docker-compose exec frankenphp bash -c "kill -USR2 \$(ps -o pid= -C php) 2>/dev/null || echo 'No PHP processes found'"
    sleep 2
    
    # Verify that Xdebug is disabled
    local xdebug_mode=$(docker-compose exec -T frankenphp php -r 'echo ini_get("xdebug.mode");' 2>/dev/null)
    if [ "$xdebug_mode" == "off" ] || [ -z "$xdebug_mode" ] || [ "$xdebug_mode" == "no value" ]; then
        echo -e "${GREEN}✓ Xdebug has been disabled. This improves application performance.${RESET}"
    else
        echo -e "${RED}✗ Failed to disable Xdebug. Current mode: $xdebug_mode${RESET}"
    fi
}

# Function to connect to PostgreSQL
connect_postgres() {
    echo -e "${YELLOW}Connecting to PostgreSQL...${RESET}"
    echo -e "${BLUE}Database connection details:${RESET}"
    echo -e "  Host: ${BOLD}localhost${RESET}"
    echo -e "  Port: ${BOLD}5432${RESET}"
    echo -e "  User: ${BOLD}laravel${RESET}"
    echo -e "  Password: ${BOLD}secret${RESET}"
    echo -e "  Database: ${BOLD}laravel${RESET}"
    echo
    echo -e "${YELLOW}Connecting to PostgreSQL CLI...${RESET}"
    docker-compose exec postgres psql -U laravel -d laravel
}

# Function to clear Laravel cache
clear_cache() {
    if [ "$(check_status)" != "running" ]; then
        echo -e "${RED}✗ Server is not running. Please start it first with: $0 start${RESET}"
        exit 1
    fi
    
    echo -e "${YELLOW}Clearing Laravel cache...${RESET}"
    docker-compose exec frankenphp php artisan cache:clear
    echo -e "${GREEN}✓ Application cache cleared${RESET}"
    
    echo -e "${YELLOW}Clearing config cache...${RESET}"
    docker-compose exec frankenphp php artisan config:clear
    echo -e "${GREEN}✓ Config cache cleared${RESET}"
    
    echo -e "${YELLOW}Clearing route cache...${RESET}"
    docker-compose exec frankenphp php artisan route:clear
    echo -e "${GREEN}✓ Route cache cleared${RESET}"
    
    echo -e "${YELLOW}Clearing view cache...${RESET}"
    docker-compose exec frankenphp php artisan view:clear
    echo -e "${GREEN}✓ View cache cleared${RESET}"
    
    echo -e "${YELLOW}Clearing compiled classes...${RESET}"
    docker-compose exec frankenphp php artisan clear-compiled
    echo -e "${GREEN}✓ Compiled classes cleared${RESET}"
    
    echo -e "${GREEN}✓ All caches have been cleared!${RESET}"
}

# Function to optimize Laravel for production
optimize_cache() {
    if [ "$(check_status)" != "running" ]; then
        echo -e "${RED}✗ Server is not running. Please start it first with: $0 start${RESET}"
        exit 1
    fi
    
    echo -e "${YELLOW}Optimizing Laravel for production...${RESET}"
    
    echo -e "${YELLOW}Optimizing Composer's autoloader...${RESET}"
    docker-compose exec frankenphp composer install --optimize-autoloader --no-dev
    echo -e "${GREEN}✓ Composer autoloader optimized${RESET}"
    
    echo -e "${YELLOW}Caching configuration...${RESET}"
    docker-compose exec frankenphp php artisan config:cache
    echo -e "${GREEN}✓ Configuration cached${RESET}"
    
    echo -e "${YELLOW}Caching routes...${RESET}"
    docker-compose exec frankenphp php artisan route:cache
    echo -e "${GREEN}✓ Routes cached${RESET}"
    
    echo -e "${YELLOW}Caching views...${RESET}"
    docker-compose exec frankenphp php artisan view:cache
    echo -e "${GREEN}✓ Views cached${RESET}"
    
    echo -e "${YELLOW}Caching events...${RESET}"
    docker-compose exec frankenphp php artisan event:cache
    echo -e "${GREEN}✓ Events cached${RESET}"
    
    echo -e "${GREEN}✓ Laravel application optimized for production!${RESET}"
}

# Function to run artisan commands
run_artisan() {
    if [ "$(check_status)" != "running" ]; then
        echo -e "${RED}✗ Server is not running. Please start it first with: $0 start${RESET}"
        exit 1
    fi
    
    if [ -z "$1" ]; then
        echo -e "${YELLOW}Usage: $0 artisan [command]${RESET}"
        echo -e "${YELLOW}Example: $0 artisan migrate${RESET}"
        exit 1
    fi
    
    echo -e "${YELLOW}Running artisan command: ${BOLD}$*${RESET}"
    docker-compose exec frankenphp php artisan "$@"
}

# Function to build frontend assets for production
build_assets() {
    echo -e "${YELLOW}Building frontend assets for production...${RESET}"
    docker-compose run --rm node build
    echo -e "${GREEN}✓ Frontend assets built successfully!${RESET}"
}

# Function to show help
show_help() {
    echo -e "${BOLD}${BLUE}maryDock Server CLI Runner${RESET}"
    echo -e "${YELLOW}Usage: $0 [command] [options]${RESET}"
    echo
    echo -e "${BOLD}Available commands:${RESET}"
    echo -e "  ${GREEN}start${RESET}                Start all services"
    echo -e "  ${GREEN}stop${RESET}                 Stop all services"
    echo -e "  ${GREEN}stop-node${RESET}            Stop only the Node.js development server"
    echo -e "  ${GREEN}restart${RESET}              Restart all services"
    echo -e "  ${GREEN}status${RESET}               Show status of all containers and resources"
    echo -e "  ${GREEN}logs [service]${RESET}       View logs for a specific service"
    echo -e "  ${GREEN}dev${RESET}                  Start Vite development server (foreground)"
    echo -e "  ${GREEN}dev-bg${RESET}               Start Vite development server (background)"
    echo -e "  ${GREEN}enable-xdebug [mode]${RESET} Enable Xdebug with specific mode (debug, develop, profile, trace, coverage)"
    echo -e "  ${GREEN}disable-xdebug${RESET}       Disable Xdebug"
    echo -e "  ${GREEN}postgres${RESET}             Connect to PostgreSQL database"
    echo -e "  ${GREEN}clear-cache${RESET}          Clear all Laravel caches"
    echo -e "  ${GREEN}optimize${RESET}             Optimize Laravel for production"
    echo -e "  ${GREEN}artisan [command]${RESET}    Run Laravel Artisan commands"
    echo -e "  ${GREEN}build${RESET}                Build frontend assets for production"
    echo -e "  ${GREEN}help${RESET}                 Show this help message"
}

# Check if docker-compose exists
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Error: docker-compose is not installed.${RESET}"
    exit 1
fi

# Handle commands
case "$1" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    stop-node)
        stop_node
        ;;
    restart)
        restart_services
        ;;
    status)
        show_status
        ;;
    logs)
        view_logs "$2"
        ;;
    dev)
        start_dev_mode
        ;;
    dev-bg)
        start_dev_background
        ;;
    enable-xdebug)
        enable_xdebug "$2"
        ;;
    disable-xdebug)
        disable_xdebug
        ;;
    postgres)
        connect_postgres
        ;;
    clear-cache)
        clear_cache
        ;;
    optimize)
        optimize_cache
        ;;
    artisan)
        shift
        run_artisan "$@"
        ;;
    build)
        build_assets
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        show_help
        exit 1
        ;;
esac

exit 0