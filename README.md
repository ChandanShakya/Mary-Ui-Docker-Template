# KharchaTrack

<div align="center">
  <h3>A resource-optimized Laravel expense tracking application</h3>
  <p>Designed to run efficiently on lower-end hardware</p>
</div>

## System Requirements

This Laravel application has been optimized to run on modest hardware:
- CPU: Pentium T4200 (2 core) @ 2.00 GHz or equivalent
- Memory: 3GB RAM
- Storage: 110GB HDD/SSD

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

## Common Commands

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Run Laravel commands
docker-compose exec frankenphp php artisan <command>

# Monitor container resource usage
docker stats
```

## Documentation

Additional documentation can be found in the `docs/` directory.

## License

The Laravel framework is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).