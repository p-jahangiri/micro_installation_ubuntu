#!/bin/bash

# Whiptail dialog settings
DIALOG_HEIGHT=20
DIALOG_WIDTH=80
BACKTITLE="🚀 Installation Management System"
TITLE="Installation Manager"

# Colors for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Log file for operations
LOG_FILE="/tmp/installation_manager.log"

# Installation steps array (step_script step_name step_description status)
INSTALL_STEPS=(
    "docker-settings/docker-setting.sh" "Docker Configuration" "Configure Docker registry and settings" "pending"
    "images/load-images.sh" "Load All Docker Images" "Load all required Docker images" "pending"
    "dependency/dependency-manager.sh" "Dependency Management" "Configure and start dependency services" "pending"
    "microservices/services-manager.sh" "Microservices Management" "Configure and start microservices" "pending"
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

# Function to show installation progress
show_progress() {
    local status_text=""
    for ((i=0; i<${#INSTALL_STEPS[@]}; i+=4)); do
        local step_name="${INSTALL_STEPS[i+1]}"
        local step_status="${INSTALL_STEPS[i+3]}"
        
        case $step_status in
            "pending") status_symbol="⏳" ;;
            "completed") status_symbol="✅" ;;
            "failed") status_symbol="❌" ;;
            *) status_symbol="⏳" ;;
        esac
        
        status_text="$status_text\n$status_symbol $step_name"
    done
    
    whiptail --title "📊 Installation Progress" \
             --backtitle "$BACKTITLE" \
             --msgbox "Current installation status:$status_text" \
             15 60
}

# Function to run installation step
run_step() {
    local step_script="$1"
    local step_name="$2"
    local step_desc="$3"
    local step_index="$4"
    
    if [ ! -f "$SCRIPT_DIR/$step_script" ]; then
        whiptail --title "❌ Error" \
                 --msgbox "Script not found: $step_script" \
                 8 60
        INSTALL_STEPS[step_index+3]="failed"
        return 1
    fi
    
    if whiptail --title "🔄 Run Step" \
                --backtitle "$BACKTITLE" \
                --yesno "Run $step_name?\n\n$step_desc" \
                10 60; then
        
        echo "$(date): Starting $step_name" >> "$LOG_FILE"
        
        # Make script executable
        chmod +x "$SCRIPT_DIR/$step_script"
        
        # Run the script
        if bash "$SCRIPT_DIR/$step_script"; then
            INSTALL_STEPS[step_index+3]="completed"
            whiptail --title "✅ Success" \
                     --msgbox "$step_name completed successfully!" \
                     8 60
            return 0
        else
            INSTALL_STEPS[step_index+3]="failed"
            whiptail --title "❌ Error" \
                     --msgbox "$step_name failed. Check logs for details." \
                     8 60
            return 1
        fi
    else
        return 2  # User skipped
    fi
}

# Function to show main menu
show_main_menu() {
    local choice
    choice=$(whiptail --title "$TITLE" \
                     --backtitle "$BACKTITLE" \
                     --menu "Choose an operation:" \
                     $DIALOG_HEIGHT $DIALOG_WIDTH 10 \
                     "1" "🐳 Docker Configuration" \
                     "2" "📦 Load All Docker Images" \
                     "3" "🔧 Dependency Management" \
                     "4" "⚙️  Microservices Management" \
                     "5" "📊 Show Progress" \
                     "6" "📋 View Logs" \
                     "7" "🔄 Reset Status" \
                     "8" "❌ Exit" \
                     3>&1 1>&2 2>&3)
    
    case $choice in
        1) run_step "${INSTALL_STEPS[0]}" "${INSTALL_STEPS[1]}" "${INSTALL_STEPS[2]}" "0"; show_main_menu ;;
        2) run_step "${INSTALL_STEPS[4]}" "${INSTALL_STEPS[5]}" "${INSTALL_STEPS[6]}" "4"; show_main_menu ;;
        3) run_step "${INSTALL_STEPS[8]}" "${INSTALL_STEPS[9]}" "${INSTALL_STEPS[10]}" "8"; show_main_menu ;;
        4) run_step "${INSTALL_STEPS[12]}" "${INSTALL_STEPS[13]}" "${INSTALL_STEPS[14]}" "12"; show_main_menu ;;
        5) show_progress; show_main_menu ;;
        6) view_logs ;;
        7) reset_status ;;
        8) exit_program ;;
        *) show_main_menu ;;
    esac
}


# Function to run specific step
run_specific_step() {
    local menu_items=()
    for ((i=0; i<${#INSTALL_STEPS[@]}; i+=4)); do
        local step_num=$((i/4 + 1))
        local step_name="${INSTALL_STEPS[i+1]}"
        local step_status="${INSTALL_STEPS[i+3]}"
        menu_items+=("$step_num" "$step_name [$step_status]")
    done
    
    local choice
    choice=$(whiptail --title "🎯 Select Step" \
                     --backtitle "$BACKTITLE" \
                     --menu "Choose a step to run:" \
                     15 60 6 \
                     "${menu_items[@]}" \
                     3>&1 1>&2 2>&3)
    
    if [ $? -eq 0 ]; then
        local index=$(((choice-1) * 4))
        run_step "${INSTALL_STEPS[index]}" "${INSTALL_STEPS[index+1]}" "${INSTALL_STEPS[index+2]}" "$index"
    fi
    
    show_main_menu
}

# Function to view logs
view_logs() {
    if [ -f "$LOG_FILE" ]; then
        whiptail --title "📋 Installation Logs" \
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

# Function to reset status
reset_status() {
    if whiptail --title "🔄 Reset Status" \
                --backtitle "$BACKTITLE" \
                --yesno "Are you sure you want to reset all step statuses?" \
                8 50; then
        for ((i=0; i<${#INSTALL_STEPS[@]}; i+=4)); do
            INSTALL_STEPS[i+3]="pending"
        done
        whiptail --title "✅ Reset Complete" \
                 --msgbox "All step statuses have been reset to pending." \
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
        echo -e "${GREEN}Thank you for using Installation Management System!${NC}"
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
    echo "$(date): Installation Management System started" > "$LOG_FILE"
    
    # Check prerequisites
    check_prerequisites
    
    # Show welcome message
    whiptail --title "🚀 Welcome" \
             --backtitle "$BACKTITLE" \
             --msgbox "Welcome to Installation Management System!\n\nThis tool will guide you through the installation process:\n\n✓ Docker Configuration\n✓ Load Docker Images\n✓ Setup Dependency Services\n✓ Configure Microservices\n\nYou can run all steps in order or choose specific steps to run." \
             16 60
    
    # Show main menu
    show_main_menu
}

# Make script executable
chmod +x "$0"

# Run main function
main