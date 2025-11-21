#!/bin/bash
set -e  # Exit on error

# Get script directory from parent
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Whiptail dialog settings
DIALOG_HEIGHT=20
DIALOG_WIDTH=80
BACKTITLE="🐳 Docker Services Management System"
TITLE="Service Manager"

# Colors for terminal output (when not using whiptail)
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# List of all service directories
SERVICES=(
    "core" "Core Service"
    "hr" "HR Management"
    "eam" "Asset Management"
    "work" "Work Management"
    "workflow" "Workflow Engine"
    "inventory" "Inventory System"
    "financial" "Financial Module"
    "global" "Global Settings"
    "reporting" "Reporting Service"
    "frontend" "Frontend Application"
)

# Log file for operations
LOG_FILE="/tmp/docker_services.log"

# Function to check prerequisites
check_prerequisites() {
    local errors=()
    
    if ! command -v whiptail &> /dev/null; then
        errors+=("Whiptail is not installed. Install with: sudo apt-get install whiptail")
    fi
    
    if ! command -v docker &> /dev/null; then
        errors+=("Docker is not installed")
    fi
    
    
    
    if ! docker info &> /dev/null 2>&1; then
        errors+=("Docker daemon is not running")
    fi
    
    if [ ${#errors[@]} -gt 0 ]; then
        local error_msg=""
        for error in "${errors[@]}"; do
            error_msg="$error_msg• $error\n"
        done
        
        whiptail --title "⚠️  Prerequisites Check Failed" \
                 --msgbox "The following issues were found:\n\n$error_msg\nPlease resolve these issues before continuing." \
                 15 70
        exit 1
    fi
}

# Function to show main menu
show_main_menu() {
    local choice
    choice=$(whiptail --title "$TITLE" \
                     --backtitle "$BACKTITLE" \
                     --menu "Choose an operation:" \
                     $DIALOG_HEIGHT $DIALOG_WIDTH 6 \
                     "1" "📝 Set Service Versions" \
                     "2" "🛑 Stop All Services" \
                     "3" "🚀 Start All Services" \
                     "4" "📋 View Logs" \
                     "5" "❌ Exit" \
                     3>&1 1>&2 2>&3)
    
    case $choice in
        1) set_service_versions ;;
        2) stop_all_services ;;
        3) start_all_services ;;
        4) view_logs ;;
        5) exit_program ;;
        *) show_main_menu ;;
    esac
}

# Function to select services
# Function to select services
select_services() {
    local selected_services=()
    local checklist_items=()
    
    # Build checklist items with all services ON by default
    for ((i=0; i<${#SERVICES[@]}; i+=2)); do
        local service_name="${SERVICES[i]}"
        local service_desc="${SERVICES[i+1]}"
        
        if [ -d "$service_name" ]; then
            checklist_items+=("$service_name" "$service_desc" "ON")
        else
            checklist_items+=("$service_name" "$service_desc (Not Found)" "OFF")
        fi
    done
    
    local selected
    selected=$(whiptail --title "🎯 Select Services" \
                       --backtitle "$BACKTITLE" \
                       --checklist "Select services to manage (all selected by default):" \
                       20 70 10 \
                       "${checklist_items[@]}" \
                       3>&1 1>&2 2>&3)
    
    if [ $? -eq 0 ]; then
        # Remove quotes and convert to array
        selected=$(echo "$selected" | tr -d '"')
        if [ -z "$selected" ]; then
            # If user deselected all, return all available services
            for ((i=0; i<${#SERVICES[@]}; i+=2)); do
                service_name="${SERVICES[i]}"
                if [ -d "$service_name" ]; then
                    selected_services+=("$service_name")
                fi
            done
        else
            IFS=' ' read -ra selected_services <<< "$selected"
        fi
        echo "${selected_services[@]}"
    else
        # If user pressed Cancel, return all available services
        for ((i=0; i<${#SERVICES[@]}; i+=2)); do
            service_name="${SERVICES[i]}"
            if [ -d "$service_name" ]; then
                selected_services+=("$service_name")
            fi
        done
        echo "${selected_services[@]}"
    fi
}

# Function to set service versions
set_service_versions() {
    local services=($(select_services))
    
    if [ ${#services[@]} -eq 0 ]; then
        whiptail --title "ℹ️  Information" --msgbox "No services selected." 8 40
        show_main_menu
        return
    fi
    
    local progress=0
    local total=${#services[@]}
    
    {
        for service in "${services[@]}"; do
            if [ -d "$service" ]; then
                # Show current version if exists
                local current_version="Not Set"
                if [ -f "$service/.env" ] && grep -q "^VERSION=" "$service/.env"; then
                    current_version=$(grep "^VERSION=" "$service/.env" | cut -d'=' -f2)
                fi
                
                # For progress dialog, we need to handle input differently
                echo "XXX"
                echo $((progress * 100 / total))
                echo "Processing $service (Current: $current_version)..."
                echo "XXX"
                
                # Create backup
                if [ -f "$service/.env" ]; then
                    cp "$service/.env" "$service/.env.backup"
                fi
                
                echo "$(date): Processing version for $service" >> "$LOG_FILE"
                
                sleep 1  # Small delay for visual effect
            fi
            
            progress=$((progress + 1))
        done
    } | whiptail --title "📝 Processing Services" \
                 --backtitle "$BACKTITLE" \
                 --gauge "Preparing services for version input..." \
                 8 60 0
    
    # Now get versions for each service
    for service in "${services[@]}"; do
        if [ -d "$service" ]; then
            local current_version="Not Set"
            if [ -f "$service/.env" ] && grep -q "^VERSION=" "$service/.env"; then
                current_version=$(grep "^VERSION=" "$service/.env" | cut -d'=' -f2)
            fi
            
            local new_version
            new_version=$(whiptail --title "📝 Set Version for $service" \
                                  --backtitle "$BACKTITLE" \
                                  --inputbox "Current version: $current_version\n\nEnter new version for $service:" \
                                  12 60 "$current_version" \
                                  3>&1 1>&2 2>&3)
            
            if [ $? -eq 0 ] && [ -n "$new_version" ]; then
                # Update version
                touch "$service/.env.tmp"
                if [ -f "$service/.env" ]; then
                    grep -v "^VERSION=" "$service/.env" > "$service/.env.tmp" || true
                fi
                echo "VERSION=$new_version" >> "$service/.env.tmp"
                mv "$service/.env.tmp" "$service/.env"
                
                echo "$(date): Version set for $service: $new_version" >> "$LOG_FILE"
            fi
        fi
    done
    
    whiptail --title "✅ Complete" --msgbox "Service versions have been updated successfully!" 8 50
    show_main_menu
}

# Function to stop all services
stop_all_services() {
    local services=($(select_services))
    
    if [ ${#services[@]} -eq 0 ]; then
        whiptail --title "ℹ️  Information" --msgbox "No services selected." 8 40
        show_main_menu
        return
    fi
    
    if whiptail --title "🛑 Stop Services" \
                --backtitle "$BACKTITLE" \
                --yesno "Are you sure you want to stop selected services?\n\nThis will run 'docker-compose down' for each service." \
                10 60; then
        
        local progress=0
        local total=${#services[@]}
        local failed_services=()
        
        {
            for service in "${services[@]}"; do
                if [ -d "$service" ] && [ -f "$service/docker-compose.yml" ]; then
                    echo "XXX"
                    echo $((progress * 100 / total))
                    echo "Stopping $service..."
                    echo "XXX"
                    
                    cd "$service" || continue
                    
                    if docker compose down >> "$LOG_FILE" 2>&1; then
                        echo "$(date): Successfully stopped $service" >> "$LOG_FILE"
                    else
                        failed_services+=("$service")
                        echo "$(date): Failed to stop $service" >> "$LOG_FILE"
                    fi
                    
                    cd .. || exit 1
                fi
                
                progress=$((progress + 1))
            done
        } | whiptail --title "🛑 Stopping Services" \
                     --backtitle "$BACKTITLE" \
                     --gauge "Shutting down Docker containers..." \
                     8 60 0
        
        if [ ${#failed_services[@]} -gt 0 ]; then
            local failed_list=$(printf "%s\n" "${failed_services[@]}")
            whiptail --title "⚠️  Partial Success" \
                     --msgbox "Stop completed with some failures:\n\n$failed_list\n\nCheck logs for details." \
                     12 60
        else
            whiptail --title "✅ Complete" --msgbox "All selected services stopped successfully!" 8 50
        fi
    fi
    
    show_main_menu
}

# Function to start all services
start_all_services() {
    local services=($(select_services))
    
    if [ ${#services[@]} -eq 0 ]; then
        whiptail --title "ℹ️  Information" --msgbox "No services selected." 8 40
        show_main_menu
        return
    fi
    
    if whiptail --title "🚀 Start Services" \
                --backtitle "$BACKTITLE" \
                --yesno "Start selected services?\n\nThis will run 'docker-compose up -d' for each service." \
                10 60; then
        
        local progress=0
        local total=${#services[@]}
        local failed_services=()
        
        {
            for service in "${services[@]}"; do
                if [ -d "$service" ] && [ -f "$service/docker-compose.yml" ]; then
                    echo "XXX"
                    echo $((progress * 100 / total))
                    echo "Starting $service..."
                    echo "XXX"
                    
                    cd "$service" || continue
                    
                    if docker compose up -d >> "$LOG_FILE" 2>&1; then
                        echo "$(date): Successfully started $service" >> "$LOG_FILE"
                    else
                        failed_services+=("$service")
                        echo "$(date): Failed to start $service" >> "$LOG_FILE"
                    fi
                    
                    cd .. || exit 1
                fi
                
                progress=$((progress + 1))
            done
        } | whiptail --title "🚀 Starting Services" \
                     --backtitle "$BACKTITLE" \
                     --gauge "Launching Docker containers..." \
                     8 60 0
        
        if [ ${#failed_services[@]} -gt 0 ]; then
            local failed_list=$(printf "%s\n" "${failed_services[@]}")
            whiptail --title "⚠️  Partial Success" \
                     --msgbox "Startup completed with some failures:\n\n$failed_list\n\nCheck logs for details." \
                     12 60
        else
            whiptail --title "✅ Complete" --msgbox "All selected services started successfully!" 8 50
        fi
    fi
    
    show_main_menu
}

# Function to view logs
view_logs() {
    if [ -f "$LOG_FILE" ]; then
        whiptail --title "📋 Operation Logs" \
                 --backtitle "$BACKTITLE" \
                 --textbox "$LOG_FILE" \
                 20 80
    else
        whiptail --title "📋 Logs" \
                 --msgbox "No log file found. No operations have been performed yet." \
                 8 50
    fi
    
    show_main_menu
}

# Function to exit program
exit_program() {
    if whiptail --title "❌ Exit" \
                --backtitle "$BACKTITLE" \
                --yesno "Are you sure you want to exit?" \
                8 40; then
        clear
        echo -e "${GREEN}Thank you for using Docker Services Management System!${NC}"
        exit 0
    else
        show_main_menu
    fi
}

# Main execution
main() {
    # Clear screen and show welcome
    clear
    
    # Initialize log file
    echo "$(date): Docker Services Management started" > "$LOG_FILE"
    
    # Check prerequisites
    check_prerequisites
    
    # Show welcome message
    whiptail --title "🐳 Welcome" \
             --backtitle "$BACKTITLE" \
             --msgbox "Welcome to Docker Services Management System!\n\nThis tool will help you manage your microservices:\n\n✓ Set service versions\n✓ Stop services (docker-compose down)\n✓ Start services (docker-compose up -d)\n✓ View operation logs" \
             15 60
    
    # Show main menu
    show_main_menu
}

# Run main function
main

# Return to main installation manager
exec "$SCRIPT_DIR/installation-manager.sh"