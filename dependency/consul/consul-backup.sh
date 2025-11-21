#!/bin/sh

# Get the current date for backup file naming
DATE=$(date +%Y%m%d_%H%M%S)

# Directory for storing backups
BACKUP_DIR="./consul_backups"
mkdir -p "$BACKUP_DIR"

# Function to show usage
show_usage() {
    echo "Usage: $0 [backup|restore] [backup_file_for_restore]"
    echo "Examples:"
    echo "  Backup:  $0 backup"
    echo "  Restore: $0 restore consul_server1_backup_20240315_123456.tar.gz"
}

# Check if docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo "Error: Docker is not running or not accessible"
        exit 1
    fi
}

# Get image name from environment or try to detect it
get_image_name() {
    # If image_name is already set, use it
    if [ -n "${image_name}" ]; then
        return 0
    fi

    # Try to get image_name from running container
    image_name=$(docker ps --format '{{.Names}}' | grep '^consul-server1-' | sed 's/^consul-server1-//')
    
    if [ -z "${image_name}" ]; then
        # Try to get from docker-compose.yml
        if [ -f "docker-compose.yml" ]; then
            image_name=$(grep 'container_name.*consul-server1-' docker-compose.yml | sed 's/.*consul-server1-${image_name}.*/pcmms/')
        fi
    fi

    if [ -z "${image_name}" ]; then
        echo "Error: Could not determine image_name. Please set it manually:"
        echo "export image_name=pcmms"
        exit 1
    fi

    export image_name
    echo "Using image_name: ${image_name}"
}

# Create volume if it doesn't exist
ensure_volume_exists() {
    volume_name=$1
    if ! docker volume inspect "$volume_name" >/dev/null 2>&1; then
        echo "Creating volume $volume_name..."
        if ! docker volume create "$volume_name"; then
            echo "Error: Failed to create volume $volume_name"
            return 1
        fi
    fi
    return 0
}

# Check if container exists and is running
check_container() {
    container_name=$1
    if ! docker ps -q -f name="^/${container_name}$" >/dev/null 2>&1; then
        echo "Error: Container $container_name is not running"
        return 1
    fi
    return 0
}

# List available backups
list_backups() {
    echo "Available backup files:"
    if [ -d "$BACKUP_DIR" ]; then
        ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null || echo "No backup files found in $BACKUP_DIR"
    else
        echo "No backup directory found"
    fi
}

# Backup function
do_backup() {
    echo "Starting Consul backup..."
    
    check_docker
    get_image_name
    
    # Remove old backups
    if [ -d "$BACKUP_DIR" ]; then
        echo "Removing old backups..."
        rm -f "$BACKUP_DIR"/*.tar.gz
    fi
    
    backup_count=0
    
    # Create backup of each server's data
    for SERVER in server1 server2 server3 client; do
        CONTAINER_NAME="consul-${SERVER}-${image_name}"
        VOLUME_NAME="consul-${SERVER}-data-${image_name}"
        
        echo "Backing up $CONTAINER_NAME data..."
        
        # Ensure volume exists
        ensure_volume_exists "$VOLUME_NAME" || continue
        
        # Check if container exists
        if ! check_container "$CONTAINER_NAME"; then
            echo "Warning: Container $CONTAINER_NAME is not running, but will try to backup volume"
        fi
        
        # Create a temporary directory for the backup
        TEMP_DIR="/tmp/consul_backup_${SERVER}_${DATE}"
        mkdir -p "$TEMP_DIR"
        
        # Copy data from the volume to temporary directory using tar (no external image needed)
        if ! docker run --rm -v "$VOLUME_NAME:/data" -v "$TEMP_DIR:/backup" busybox tar -cf - -C /data . | tar -xf - -C "$TEMP_DIR"; then
            # Fallback: use ubuntu image if busybox not available
            if ! docker run --rm -v "$VOLUME_NAME:/data" -v "$TEMP_DIR:/backup" ubuntu:20.04 bash -c "cp -r /data/. /backup/"; then
                echo "Error: Failed to copy data from volume $VOLUME_NAME"
                rm -rf "$TEMP_DIR"
                continue
            fi
        fi
        
        # Check if directory is empty
        if [ -z "$(ls -A "$TEMP_DIR")" ]; then
            echo "Warning: No data found in volume $VOLUME_NAME"
            rm -rf "$TEMP_DIR"
            continue
        fi
        
        # Create tar archive
        BACKUP_FILE="$BACKUP_DIR/consul_${SERVER}_backup_${DATE}.tar.gz"
        if ! tar -czf "$BACKUP_FILE" -C "$TEMP_DIR" .; then
            echo "Error: Failed to create backup archive for $SERVER"
            rm -rf "$TEMP_DIR"
            continue
        fi
        
        # Cleanup
        rm -rf "$TEMP_DIR"
        echo "Successfully backed up $CONTAINER_NAME to $BACKUP_FILE"
        backup_count=$((backup_count + 1))
    done
    
    echo ""
    if [ $backup_count -gt 0 ]; then
        echo "Backup completed successfully!"
        echo "$backup_count volumes backed up."
        echo "Files are stored in: $BACKUP_DIR"
        echo ""
        list_backups
    else
        echo "Warning: No backups were created!"
    fi
}

# Restore function
do_restore() {
    if [ -z "$1" ]; then
        echo "Error: Backup file not specified for restore"
        show_usage
        list_backups
        exit 1
    fi
    
    check_docker
    get_image_name
    
    # Handle both with and without BACKUP_DIR prefix
    if [ -f "$1" ]; then
        BACKUP_FILE="$1"
    elif [ -f "$BACKUP_DIR/$1" ]; then
        BACKUP_FILE="$BACKUP_DIR/$1"
    else
        echo "Error: Backup file not found at $1 or $BACKUP_DIR/$1"
        list_backups
        exit 1
    fi
    
    echo "Starting Consul restore from $BACKUP_FILE..."
    
    # Extract server name from backup file
    SERVER_NAME=$(echo "$BACKUP_FILE" | grep -o 'consul_[^_]*_backup' | cut -d'_' -f2)
    if [ -z "$SERVER_NAME" ]; then
        echo "Error: Could not determine server name from backup file"
        exit 1
    fi
    
    CONTAINER_NAME="consul-${SERVER_NAME}-${image_name}"
    VOLUME_NAME="consul-${SERVER_NAME}-data-${image_name}"
    
    # Ensure volume exists
    ensure_volume_exists "$VOLUME_NAME" || exit 1
    
    # Check if container exists
    if ! check_container "$CONTAINER_NAME"; then
        echo "Warning: Container $CONTAINER_NAME is not running, but will try to restore volume"
    fi
    
    # Create temporary directory for restore
    TEMP_DIR="/tmp/consul_restore_${DATE}"
    mkdir -p "$TEMP_DIR"
    
    # Extract backup
    if ! tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"; then
        echo "Error: Failed to extract backup file"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    # Stop the container if it's running
    if check_container "$CONTAINER_NAME"; then
        echo "Stopping container $CONTAINER_NAME..."
        if ! docker stop "$CONTAINER_NAME"; then
            echo "Error: Failed to stop container $CONTAINER_NAME"
            rm -rf "$TEMP_DIR"
            exit 1
        fi
    fi
    
    # Restore data to volume using tar (no external image needed)
    echo "Restoring data to volume $VOLUME_NAME..."
    if ! tar -cf - -C "$TEMP_DIR" . | docker run --rm -i -v "$VOLUME_NAME:/data" busybox tar -xf - -C /data; then
        # Fallback: use ubuntu image if busybox not available
        if ! docker run --rm -v "$VOLUME_NAME:/data" -v "$TEMP_DIR:/backup" ubuntu:20.04 bash -c "cp -r /backup/. /data/"; then
            echo "Error: Failed to restore data to volume $VOLUME_NAME"
            rm -rf "$TEMP_DIR"
            # Try to restart container if it was stopped
            if docker ps -a -q -f name="^/${CONTAINER_NAME}$" >/dev/null 2>&1; then
                docker start "$CONTAINER_NAME" 2>/dev/null || true
            fi
            exit 1
        fi
    fi
    
    # Start the container if it was stopped
    if docker ps -a -q -f name="^/${CONTAINER_NAME}$" >/dev/null 2>&1; then
        if ! docker ps -q -f name="^/${CONTAINER_NAME}$" >/dev/null 2>&1; then
            echo "Starting container $CONTAINER_NAME..."
            if ! docker start "$CONTAINER_NAME"; then
                echo "Error: Failed to start container $CONTAINER_NAME"
                rm -rf "$TEMP_DIR"
                exit 1
            fi
        fi
    fi
    
    # Cleanup
    rm -rf "$TEMP_DIR"
    
    echo "Restore completed successfully!"
}

# Main script logic
case "$1" in
    "backup")
        do_backup
        ;;
    "restore")
        do_restore "$2"
        ;;
    *)
        show_usage
        list_backups
        exit 1
        ;;
esac