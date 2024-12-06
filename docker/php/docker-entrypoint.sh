#!/bin/sh
set -e

# Function to check and kill process using port 9001
kill_port_9001() {
    echo "Checking for processes using port 9001..."
    
    # Use netstat to find processes on port 9001
    PORT_PIDS=$(netstat -tlpn | grep ':9001 ' | awk '{print $7}' | cut -d'/' -f1)
    
    if [ ! -z "$PORT_PIDS" ]; then
        echo "Found processes using port 9001: $PORT_PIDS"
        for pid in $PORT_PIDS; do
            echo "Killing process $pid"
            kill -9 "$pid" || true
        done
        
        # Wait a moment to ensure processes are terminated
        sleep 2
    fi
    
    # Additional cleanup
    rm -f /var/run/supervisor.sock || true
    rm -f /var/run/supervisord.pid || true
}

# Source environment variables
if [ -f .env ]; then
    echo "Sourcing environment variables from .env file"
    export $(cat .env | xargs)
fi

# Install Composer dependencies
if [ -f "composer.json" ]; then
    echo "Installing Composer dependencies..."
    composer install --no-interaction --no-scripts --no-progress
fi

# Run database migrations (optional, uncomment if using migrations)
# php artisan migrate --force

# Run port conflict resolution
kill_port_9001

# Start cron
cron

# Execute the final command (usually supervisord)
exec "$@"
