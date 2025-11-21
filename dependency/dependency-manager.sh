#!/bin/bash
set -e  # Exit on error

# Whiptail dialog settings
DIALOG_HEIGHT=20
DIALOG_WIDTH=80
BACKTITLE="🛠️ Dependency Services Management System"
TITLE="Dependency Manager"

# Colors for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory from parent
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Log file for operations
LOG_FILE="/tmp/dependency_services.log"

# Service start order
START_ORDER=(
    "portainer" "Portainer Container Management"
    "nginx" "Nginx Web Server"
    "redis" "Redis Database"
    "grafana" "Grafana Monitoring"
    "consul" "Consul Service Mesh"
    "iconify" "Iconify Service"
    "minio" "Minio Service"
)

# Service stop order (reverse of start)
STOP_ORDER=(
    "minio" "Minio Service"
    "iconify" "Iconify Service"
    "consul" "Consul Service Mesh"
    "grafana" "Grafana Monitoring"
    "redis" "Redis Database"
    "nginx" "Nginx Web Server"
    "portainer" "Portainer Container Management"
)

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
                     $DIALOG_HEIGHT $DIALOG_WIDTH 7 \
                     "1" "🚀 Start All Tools " \
                     "2" "🛑 Stop All Tools " \
                     "3" "⚙️  Configure Consul Settings" \
                     "4" "🔧 Open Consul Manager" \
                     "5" "📋 View Logs" \
                     "6" "❌ Exit" \
                     3>&1 1>&2 2>&3)
    
    case $choice in
        1) start_all_services ;;
        2) stop_all_services ;;
        3) configure_consul ;;
        4) run_consul_manager ;;
        5) view_logs ;;
        6) exit_program ;;
        *) show_main_menu ;;
    esac
}

# Function to start all services
start_all_services() {
    local progress=0
    local total=$((${#START_ORDER[@]} / 2))
    local failed_services=()
    
    {
        for ((i=0; i<${#START_ORDER[@]}; i+=2)); do
            local service="${START_ORDER[i]}"
            local description="${START_ORDER[i+1]}"
            
            echo "XXX"
            echo $((progress * 100 / total))
            echo "Starting $description..."
            echo "XXX"
            
            if [ -d "$SCRIPT_DIR/dependency/$service" ] && [ -f "$SCRIPT_DIR/dependency/$service/docker-compose.yml" ]; then
                cd "$SCRIPT_DIR/dependency/$service" || continue
                
                if docker compose up -d >> "$LOG_FILE" 2>&1; then
                    echo "$(date): Successfully started $service" >> "$LOG_FILE"
                else
                    failed_services+=("$service")
                    echo "$(date): Failed to start $service" >> "$LOG_FILE"
                fi
                
                cd "$SCRIPT_DIR/dependency" || exit 1
            else
                failed_services+=("$service (missing docker-compose.yml)")
                echo "$(date): $service directory or docker-compose.yml not found" >> "$LOG_FILE"
            fi
            
            progress=$((progress + 1))
            sleep 1
        done
    } | whiptail --title "🚀 Starting Services" \
                 --backtitle "$BACKTITLE" \
                 --gauge "Launching services in order..." \
                 8 60 0
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        local failed_list=$(printf "%s\n" "${failed_services[@]}")
        whiptail --title "⚠️  Partial Success" \
                 --msgbox "Startup completed with some failures:\n\n$failed_list\n\nCheck logs for details." \
                 15 70
    else
        whiptail --title "✅ Complete" --msgbox "All services started successfully!" 8 50
    fi
    
    show_main_menu
}

# Function to stop all services
stop_all_services() {
    local progress=0
    local total=$((${#STOP_ORDER[@]} / 2))
    local failed_services=()
    
    {
        for ((i=0; i<${#STOP_ORDER[@]}; i+=2)); do
            local service="${STOP_ORDER[i]}"
            local description="${STOP_ORDER[i+1]}"
            
            echo "XXX"
            echo $((progress * 100 / total))
            echo "Stopping $description..."
            echo "XXX"
            
            if [ -d "$SCRIPT_DIR/dependency/$service" ] && [ -f "$SCRIPT_DIR/dependency/$service/docker-compose.yml" ]; then
                cd "$SCRIPT_DIR/dependency/$service" || continue
                
                if docker compose down >> "$LOG_FILE" 2>&1; then
                    echo "$(date): Successfully stopped $service" >> "$LOG_FILE"
                else
                    failed_services+=("$service")
                    echo "$(date): Failed to stop $service" >> "$LOG_FILE"
                fi
                
                cd "$SCRIPT_DIR/dependency" || exit 1
            else
                failed_services+=("$service (missing docker-compose.yml)")
                echo "$(date): $service directory or docker-compose.yml not found" >> "$LOG_FILE"
            fi
            
            progress=$((progress + 1))
            sleep 1
        done
    } | whiptail --title "🛑 Stopping Services" \
                 --backtitle "$BACKTITLE" \
                 --gauge "Shutting down services in reverse order..." \
                 8 60 0
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        local failed_list=$(printf "%s\n" "${failed_services[@]}")
        whiptail --title "⚠️  Partial Success" \
                 --msgbox "Shutdown completed with some failures:\n\n$failed_list\n\nCheck logs for details." \
                 15 70
    else
        whiptail --title "✅ Complete" --msgbox "All services stopped successfully!" 8 50
    fi
    
    show_main_menu
}

# Function to configure Consul
configure_consul() {
    if [ -f "$SCRIPT_DIR/dependency/consul/consul-setting/installConsul.sh" ]; then
        cd "$SCRIPT_DIR/dependency/consul/consul-setting" || exit 1
        bash installConsul.sh
        cd "$SCRIPT_DIR" || exit 1
    else
        whiptail --title "❌ Error" \
                 --msgbox "Consul installation script not found at expected location:\n$SCRIPT_DIR/dependency/consul/consul-setting/installConsul.sh" \
                 10 70
    fi
    
    show_main_menu
}

# Function to run Consul manager
run_consul_manager() {
    if [ -f "$SCRIPT_DIR/dependency/consul/consul-manager.sh" ]; then
        cd "$SCRIPT_DIR/dependency/consul" || exit 1
        bash consul-manager.sh
        cd "$SCRIPT_DIR" || exit 1
    else
        whiptail --title "❌ Error" \
                 --msgbox "Consul manager script not found at expected location:\n$SCRIPT_DIR/dependency/consul/consul-manager.sh" \
                 10 70
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
        echo -e "${GREEN}Thank you for using Dependency Services Management System!${NC}"
        exit 0
    else
        show_main_menu
    fi
}

# Main execution
main() {
    # Clear screen
    clear
    
    # Initialize log file
    echo "$(date): Dependency Services Management started" > "$LOG_FILE"
    
    # Check prerequisites
    check_prerequisites
    
    # Show welcome message
    whiptail --title "🛠️ Welcome" \
             --backtitle "$BACKTITLE" \
             --msgbox "Welcome to Dependency Services Management System!\n\nThis tool will help you manage your dependency services:\n\n✓ Start services in correct order\n✓ Stop services in reverse order\n✓ Configure Consul settings\n✓ Access Consul manager\n✓ View operation logs" \
             16 60
    
    # Show main menu
    show_main_menu
}

# Make script executable
chmod +x "$0"

# Run main function
main

# Return to main installation manager
exec "$SCRIPT_DIR/installation-manager.sh" 