#!/bin/bash

# Get the script's directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check if whiptail is installed
if ! command -v whiptail >/dev/null 2>&1; then
    echo "Error: whiptail is not installed. Please install it first."
    exit 1
fi

# Set default image name if not set
if [ -z "${image_name}" ]; then
    export image_name="pcmms"
fi

# Function to check if containers are running
check_containers_status() {
    local status
    status=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep "consul-.*-${image_name}")
    whiptail --title "Container Status" --msgbox "Current Consul containers status:\n\n$status" 15 60
}

# Function to take backup
take_backup() {
    {
        echo "XXX"; echo "Taking backup of Consul data..."; echo "XXX"
        echo "0"
        sh "$SCRIPT_DIR/consul-backup.sh" backup
        echo "100"
    } | whiptail --gauge "Taking Backup" 8 60 0
    
    whiptail --title "Backup Complete" --msgbox "Consul data backup completed successfully." 8 60
}

# Function to stop containers
stop_containers() {
    {
        echo "XXX"; echo "Stopping Consul containers..."; echo "XXX"
        echo "0"
        docker compose -f "$SCRIPT_DIR/docker-compose.yml" down
        echo "100"
    } | whiptail --gauge "Stopping Containers" 8 60 0
    
    whiptail --title "Stop Complete" --msgbox "All Consul containers have been stopped." 8 60
}

# Function to start containers
start_containers() {
    {
        echo "XXX"; echo "Starting Consul containers..."; echo "XXX"
        echo "0"
        docker compose -f "$SCRIPT_DIR/docker-compose.yml" up -d
        echo "50"
        echo "XXX"; echo "Waiting for containers to be ready..."; echo "XXX"
        sleep 10
        echo "100"
    } | whiptail --gauge "Starting Containers" 8 60 0
    
    whiptail --title "Start Complete" --msgbox "All Consul containers have been started." 8 60
}

# Function to apply ACL configuration
apply_acl() {
    {
        echo "0"
        for SERVER in server1 server2 server3 client; do
            CONTAINER="consul-${SERVER}-${image_name}"
            echo "XXX"; echo "Copying ACL config to $CONTAINER..."; echo "XXX"
            docker cp "$SCRIPT_DIR/consul-acl.json" "$CONTAINER:/consul/config/consul-acl.json"
            echo "25"
        done
        
        echo "XXX"; echo "Restarting containers..."; echo "XXX"
        for SERVER in server1 server2 server3 client; do
            CONTAINER="consul-${SERVER}-${image_name}"
            docker restart "$CONTAINER"
            echo "50"
        done
        
        echo "XXX"; echo "Waiting for cluster to stabilize..."; echo "XXX"
        sleep 10
        echo "75"
        
        echo "XXX"; echo "Bootstrapping ACL system..."; echo "XXX"
        BOOTSTRAP_RESULT=$(docker exec -it "consul-server1-${image_name}" consul acl bootstrap 2>&1)
        echo "100"
    } | whiptail --gauge "Applying ACL Configuration" 8 60 0
    
    whiptail --title "ACL Configuration" --msgbox "ACL configuration completed.\n\nBootstrap Result:\n$BOOTSTRAP_RESULT" 15 60
}

# Function to restore backup
restore_backup() {
    # Get list of backups
    BACKUPS=$(sh "$SCRIPT_DIR/consul-backup.sh" list)
    
    # Create array for whiptail menu
    BACKUP_MENU=()
    while IFS= read -r line; do
        BACKUP_MENU+=("$line" "")
    done <<< "$BACKUPS"
    
    # Show backup selection menu
    SELECTED_BACKUP=$(whiptail --title "Select Backup" --menu \
        "Choose a backup to restore:" 15 60 5 \
        "${BACKUP_MENU[@]}" 3>&1 1>&2 2>&3)
    
    if [ $? -eq 0 ]; then
        {
            echo "XXX"; echo "Restoring backup $SELECTED_BACKUP..."; echo "XXX"
            echo "0"
            sh "$SCRIPT_DIR/consul-backup.sh" restore "$SELECTED_BACKUP"
            echo "100"
        } | whiptail --gauge "Restoring Backup" 8 60 0
        
        whiptail --title "Restore Complete" --msgbox "Backup has been restored successfully." 8 60
    fi
}

# Function to perform full cycle
full_cycle() {
    if (whiptail --title "Full Cycle" --yesno "This will perform a full cycle:\n\n1. Backup current data\n2. Stop containers\n3. Start containers\n4. Apply ACL configuration\n\nDo you want to continue?" 15 60); then
        {
            echo "XXX"; echo "Step 1: Taking backup..."; echo "XXX"
            echo "0"
            take_backup
            
            echo "XXX"; echo "Step 2: Stopping containers..."; echo "XXX"
            echo "25"
            stop_containers
            
            echo "XXX"; echo "Step 3: Starting containers..."; echo "XXX"
            echo "50"
            start_containers
            
            echo "XXX"; echo "Step 4: Applying ACL configuration..."; echo "XXX"
            echo "75"
            apply_acl
            echo "100"
        } | whiptail --gauge "Performing Full Cycle" 8 60 0
        
        whiptail --title "Full Cycle Complete" --msgbox "Full cycle has been completed successfully." 8 60
    fi
}

# Main menu
while true; do
    CHOICE=$(whiptail --title "Consul Management" --menu \
        "Choose an operation:" 20 60 8 \
        "1" "Take backup of current Consul data" \
        "2" "Stop all Consul containers" \
        "3" "Start all Consul containers" \
        "4" "Apply ACL configuration" \
        "5" "Full cycle (Backup -> Stop -> Start -> ACL)" \
        "6" "Restore from backup" \
        "7" "Show container status" \
        "8" "Exit" 3>&1 1>&2 2>&3)
    
    if [ $? -ne 0 ]; then
        exit 0
    fi
    
    case $CHOICE in
        1) take_backup ;;
        2) stop_containers ;;
        3) start_containers ;;
        4) apply_acl ;;
        5) full_cycle ;;
        6) restore_backup ;;
        7) check_containers_status ;;
        8) exit 0 ;;
    esac
done 