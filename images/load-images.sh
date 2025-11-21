#!/bin/bash
set -e  # Exit on error

# Get script directory from parent
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Function to display error and exit
error_exit() {
    whiptail --title "Error" --msgbox "Error: $1" 8 60
    # Return to main installation manager
    exec "$SCRIPT_DIR/installation-manager.sh"
    exit 1
}

# Function to load Docker images
load_images() {
    local image_dir="$/home/micro_installation_ubuntu/images"
    
    # Check if images directory exists
    if [ ! -d "$image_dir" ]; then
        error_exit "Images directory not found: $image_dir"
    fi
    
    # Count total number of .tar files
    local total_images=$(ls -1 "$image_dir"/*.tar.gz 2>/dev/null | wc -l)
    
    if [ "$total_images" -eq 0 ]; then
        error_exit "No image files (.tar.gz) found in $image_dir"
    fi  # <-- FIXED: Changed `}` to `fi`
    
    local current=0
    
    # Show progress dialog
    {
        for image in "$image_dir"/*.tar.gz; do
            echo "XXX"
            echo $((current * 100 / total_images))
            echo "Loading image: $(basename "$image")..."
            echo "XXX"
            
            if ! docker load -i "$image"; then
                error_exit "Failed to load image: $(basename "$image")"
            fi
            
            current=$((current + 1))
        done
        
        echo "XXX"
        echo "100"
        echo "All images loaded successfully!"
        echo "XXX"
        sleep 1
    } | whiptail --title "Loading Docker Images" \
    --gauge "Starting to load images..." \
    8 60 0
    
    whiptail --title "Success" --msgbox "Successfully loaded all Docker images!" 8 60
}  # <-- Closing brace for `load_images()` was missing

# Main execution
load_images

# Return to main installation manager
exec "$SCRIPT_DIR/installation-manager.sh"