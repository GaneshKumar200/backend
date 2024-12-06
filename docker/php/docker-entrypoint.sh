#!/bin/sh
set -e

# Function to check and kill process using port 9001
kill_port_9001() {
    echo "Checking for processes using port 9001..."
    
    # Alternative method to find and kill processes using port 9001
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

# Run port conflict resolution
kill_port_9001

# Start cron
cron

# Start supervisord
supervisord --configuration /etc/supervisord.conf

# Handle additional command-line arguments
if [ "${1#-}" != "$1" ]; then
    set -- php-fpm "$@"
fi

# Execute the final command
exec "$@"
