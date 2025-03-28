# maryDock

<div align="center">
  <h3>A resource-optimized Laravel expense tracking application</h3>
  <p>Designed to run efficiently on lower-end hardware</p>
</div>

## System Requirements

This Laravel application has been optimized to run on modest hardware:
- CPU: Pentium T4200 (2 core) @ 2.00 GHz or equivalent
- Memory: 3GB RAM
- Storage: 110GB HDD/SSD

## Dependencies & Technologies

This project leverages the following key technologies:

### Backend
- **Laravel 11**: Modern PHP framework for web applications
- **FrankenPHP**: High-performance PHP runtime
- **Laravel Octane**: Boost performance with application state caching
- **PostgreSQL**: Optimized relational database 
- **Redis**: In-memory data structure store for caching and sessions
- **Livewire v3**: Full-stack framework for dynamic interfaces
- **Xdebug**: PHP debugging and profiling tool (disabled by default)

### Frontend
- **Vite**: Next-generation frontend tooling
- **@defstudio/vite-livewire-plugin**: Hot reload Livewire components without losing state
- **TailwindCSS**: Utility-first CSS framework
- **Mary UI**: Tailwind components for Livewire

### Development Tools
- **Docker**: Containerization for consistent environments
- **Docker Compose**: Multi-container Docker applications

## Setup Instructions

### Using as a GitHub Template
1. Click the "Use this template" button on the GitHub repository page
2. Clone your new repository:
   ```bash
   git clone https://github.com/your-username/your-repo-name.git
   cd your-repo-name
   ```
3. Run the setup script:
   ```bash
   ./setup.sh
   ```

The setup script will:
- Check for Docker and Docker Compose
- Configure the environment file
- Build and start the Docker containers
- Set up the database and run migrations
- Apply all performance optimizations
- Build frontend assets

### Setup Options

- Skip building frontend assets:
  ```bash
  ./setup.sh --skip-npm
  ```
- Start with development environment (includes Vite dev server):
  ```bash
  ./setup.sh --dev
  ```
- Clean up and start fresh:
  ```bash
  ./setup.sh --clean
  ```

## Development Features

### Livewire Hot Reload

This project includes the Vite Livewire Plugin for an enhanced development experience:
- Hot reload of Livewire components without losing state
- Automatic refresh when component PHP classes or Blade templates change
- CSS refresh on component changes

To start the development server with Livewire hot reload:
```bash
./runner.sh dev
```

### Xdebug Integration for SSH Remote Development

The application includes Xdebug support for debugging via SSH:
- **Disabled by default**: Xdebug is turned off by default for optimal performance
- **On-demand activation**: Enable Xdebug via the CLI runner.sh tool when needed
- **Multiple modes**: Support for debug, develop, profile, trace, and coverage modes
- **IDE Integration**: Preconfigured for VS Code Remote SSH (idekey=VSCODE, port=9003)
- **Trigger-based**: Uses trigger mechanism to only debug when explicitly requested

To set up remote debugging:

1. Connect to your server with SSH port forwarding:
   ```bash
   ssh -L 9003:localhost:9003 username@your-server
   ```

2. Enable Xdebug in debug mode:
   ```bash
   ./runner.sh enable-xdebug debug
   ```

3. Configure VS Code:
   - Install the PHP Debug extension in VS Code
   - Create `.vscode/launch.json` with:
     ```json
     {
       "version": "0.2.0",
       "configurations": [
         {
           "name": "Listen for Xdebug",
           "type": "php",
           "request": "launch",
           "port": 9003,
           "pathMappings": {
             "/app": "${workspaceRoot}/laravel-project"
           }
         }
       ]
     }
     ```

4. Start debugging in VS Code and use the XDEBUG_TRIGGER query parameter in URLs

## Server Management via SSH

The project includes a CLI-based runner.sh script designed to work over SSH connections:

```bash
./runner.sh [command] [options]
```

### Available Commands

```
start                Start all services
stop                 Stop all services
stop-node            Stop only the Node.js development server
restart              Restart all services
status               Show status of all containers and resources
logs [service]       View logs for a specific service
dev                  Start Vite development server (foreground)
dev-bg               Start Vite development server (background)
enable-xdebug [mode] Enable Xdebug with specific mode
disable-xdebug       Disable Xdebug
postgres             Connect to PostgreSQL database
clear-cache          Clear all Laravel caches
optimize             Optimize Laravel for production
artisan [command]    Run Laravel Artisan commands
build                Build frontend assets for production
help                 Show this help message
```

### Common SSH Workflows

#### Starting the Server
```bash
./runner.sh start
```

#### Running the Development Server
```bash
# Run in foreground (you can see output but will block the terminal)
./runner.sh dev

# Run in background (frees up your terminal)
./runner.sh dev-bg
```

#### Managing Laravel Cache
```bash
# Clear all caches during development
./runner.sh clear-cache

# Optimize all caches for production
./runner.sh optimize
```

#### Running Artisan Commands
```bash
./runner.sh artisan migrate
./runner.sh artisan make:model Post --all
```

## Database Access

PostgreSQL is accessible from outside Docker for use with database tools:

### Connection Details
- **Host**: localhost (or your server's IP address)
- **Port**: 5432
- **Database**: laravel
- **Username**: laravel
- **Password**: secret

### Using with Database Tools
1. Connect using any database GUI tool like DBeaver, TablePlus, or pgAdmin
2. Enter the connection details above
3. If accessing remotely, you may need to set up SSH tunneling:
   ```bash
   ssh -L 5432:localhost:5432 username@your-server
   ```

## Redis Access

Redis is also configured for external connections, allowing you to use tools like DBeaver to monitor and manage your cache:

### Connection Details
- **Host**: localhost (or your server's IP address)
- **Port**: 6379
- **Password**: None (No authentication configured by default)

### Using with DBeaver
1. Install the Redis extension in DBeaver if not already installed
2. Create a new Redis connection
3. Enter the connection details above
4. For remote connections, you may need to set up SSH tunneling:
   ```bash
   ssh -L 6379:localhost:6379 username@your-server
   ```

### Redis Security Note
The current configuration allows unauthenticated access to Redis for easier development. For production environments, consider adding password protection by modifying the Redis command in `docker-compose.yml` to include `--requirepass your_secure_password`.

## Performance Optimizations

This application includes the following performance optimizations for low-resource environments:

### FrankenPHP + Laravel Octane
- Reduced memory consumption using shared application state
- Configured for only 2 workers to minimize memory usage

### PHP Optimizations
- Configured OPcache for optimal performance
- Enabled JIT compilation with conservative memory limits
- Reduced memory limit to 256MB
- APCu for local caching
- Aggressive garbage collection

### Database
- PostgreSQL optimized for low memory usage (128MB shared buffers)
- Connection pooling to reduce overhead
- Redis with memory limits and optimized eviction policies

### Laravel
- Production-mode optimizations:
  - Config caching
  - Route caching
  - View caching
  - Event caching
  - Composer optimized autoloader

## Application URL

After running the setup script, the application will be available at:
```
http://localhost:9000
```

## Resource Allocation

| Service    | CPU  | Memory |
|------------|------|--------|
| FrankenPHP | 0.8  | 600MB  |
| PostgreSQL | 0.5  | 250MB  |
| Redis      | 0.3  | 150MB  |

## Management Tools

The project includes tools to simplify management:

- **setup.sh**: Initial setup script
- **runner.sh**: CLI tool for managing the application over SSH
  - Manage server status (start/stop/restart)
  - Enable/disable Xdebug with multiple modes
  - View logs and container status
  - Start Vite development server with Livewire hot reload

You can access the runner help information with:
```bash
./runner.sh help
```

## Common Commands

```bash
# Start all services
./runner.sh start

# Stop all services (including any Node development server)
./runner.sh stop

# Start Vite development server in the background
./runner.sh dev-bg

# Stop only the Node.js development server without affecting other services
./runner.sh stop-node

# Run Laravel commands
./runner.sh artisan <command>

# Start Vite development server with Livewire hot reload
./runner.sh dev

# Enable Xdebug (debug mode)
./runner.sh enable-xdebug debug

# Disable Xdebug
./runner.sh disable-xdebug

# Monitor container resource usage
./runner.sh status
```

## Documentation

Additional documentation can be found in the `docs/` directory.

## License

The Laravel framework is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).