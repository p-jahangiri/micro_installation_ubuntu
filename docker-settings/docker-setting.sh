#!/bin/bash
set -e  # Exit on error

# Function to display error and exit
error_exit() {
    whiptail --title "Error" --msgbox "Error: $1" 8 60
    # Return to main installation manager
    exec "$SCRIPT_DIR/installation-manager.sh"
    exit 1
}

# Get script directory from parent
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Get Docker repository and username from arguments or use defaults
DOCKER_REPO=${1:-"185.89.22.58:8082"}
DOCKER_USER=${2:-"admin"}

# Ask for password using whiptail
DOCKER_PASS=$(whiptail --title "Docker Registry Password" --passwordbox "Enter password for $DOCKER_USER@$DOCKER_REPO:" 10 60 3>&1 1>&2 2>&3)

# Exit if user pressed Cancel
if [ -z "$DOCKER_PASS" ]; then
    error_exit "Password is required."
fi

# Create configuration
CONFIG_DIR="/etc/docker"
CONFIG_FILE="$CONFIG_DIR/daemon.json"
CONFIG_CONTENT=$(cat <<EOF
{
    "insecure-registries": ["$DOCKER_REPO"]
}
EOF
)

# Create directory if it doesn't exist
sudo mkdir -p "$CONFIG_DIR" || error_exit "Failed to create $CONFIG_DIR"

# Write configuration
echo "$CONFIG_CONTENT" | sudo tee "$CONFIG_FILE" > /dev/null || \
error_exit "Failed to write configuration"

# Restart Docker
sudo systemctl restart docker || error_exit "Failed to restart Docker"

# Attempt login
whiptail --title "Docker Login" --infobox "Attempting to login to $DOCKER_REPO..." 8 60
if ! docker login "$DOCKER_REPO" --username "$DOCKER_USER" --password-stdin <<< "$DOCKER_PASS"; then
    whiptail --title "Warning" --msgbox "Warning: Docker login failed (but configuration was applied)" 8 60
else
    whiptail --title "Success" --msgbox "Successfully logged in to $DOCKER_REPO" 8 60
fi

whiptail --title "Success" --msgbox "Successfully configured Docker repository: $DOCKER_REPO" 8 60

# Return to main installation manager
exec "$SCRIPT_DIR/installation-manager.sh"