#!/bin/bash

# Path to the configuration file
PARAM_FILE="/home/micro_installation_ubuntu/dependency/consul/consul-setting/connection_parameters.env"

# Whiptail dimensions
HEIGHT=20
WIDTH=80
INPUT_HEIGHT=10

# Function to show success message
show_success() {
    whiptail --title "Success" --msgbox "$1" 8 60
}

# Function to show error message
show_error() {
    whiptail --title "Error" --msgbox "$1" 8 60
}

# Function to get input with default value
get_input() {
    local prompt="$1"
    local default="$2"
    local result
    
    result=$(whiptail --title "Input Required" \
        --inputbox "$prompt" \
        $INPUT_HEIGHT $WIDTH "$default" \
    3>&1 1>&2 2>&3)
    
    if [ $? -eq 0 ]; then
        echo "$result"
    else
        return 1
    fi
}

# Function to get password input
get_password() {
    local prompt="$1"
    local result
    
    result=$(whiptail --title "Password Input" \
        --passwordbox "$prompt" \
        $INPUT_HEIGHT $WIDTH \
    3>&1 1>&2 2>&3)
    
    if [ $? -eq 0 ]; then
        echo "$result"
    else
        return 1
    fi
}

# Function to handle IP address input
handle_ip_input() {
    whiptail --title "IP Configuration" --msgbox "You chose to configure parameters using IP address.\n\nPlease enter the required information in the following steps." 10 60
    
    # Get all required inputs for the DESIRED format
    new_ip_front=$(get_input "Enter Frontend IP Address (IP_ADDRESS_FRONT):" "185.89.22.58")
    [ $? -ne 0 ] && return 1
    
    new_db=$(get_input "Enter Database IP Address (IP_DATABASE):" "$new_ip_front") # Default to same as frontend
    [ $? -ne 0 ] && return 1
    
    new_port=$(get_input "Enter Database Port (DB_PORT):" "1433")
    [ $? -ne 0 ] && return 1
    
    db_name_core=$(get_input "Enter Core Database Name (DB_NAME_CORE):" "NetParseh")
    [ $? -ne 0 ] && return 1
    
    db_name_log=$(get_input "Enter Log Database Name (DB_NAME_LOG):" "NetParsehLogManagement")
    [ $? -ne 0 ] && return 1
    
    db_name_auditlog=$(get_input "Enter Audit log Database Name (DB_NAME_AUDITLOG):" "AuditLog") # Added this key
    [ $? -ne 0 ] && return 1
    
    new_user=$(get_input "Enter Database Username (DB_USER):" "sa")
    [ $? -ne 0 ] && return 1
    
    new_password=$(get_password "Enter Database Password (DB_PASSWORD):")
    [ $? -ne 0 ] && return 1
    
    new_identity_url=$(get_input "Enter Identity Server URL (IDENTITY_SERVER_URL):" "http://$new_ip_front")
    [ $? -ne 0 ] && return 1
    
    new_users_url=$(get_input "Enter Users API URL (USERS_URL):" "http://$new_ip_front") # Added this key
    [ $? -ne 0 ] && return 1
    
    domain=$(get_input "Enter Domain (optional, for IP mode):" "$new_ip_front") # Added this key, default to IP
    [ $? -ne 0 ] && return 1
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$PARAM_FILE")"
    
    # Save the new parameters in the DESIRED format
    cat <<EOL > "$PARAM_FILE"
IP_ADDRESS_FRONT=$new_ip_front
IP_DATABASE=$new_db
DB_PORT=$new_port
DB_NAME_CORE=$db_name_core
DB_NAME_LOG=$db_name_log
DB_NAME_AUDITLOG=$db_name_auditlog
DB_USER=$new_user
DB_PASSWORD=$new_password
IDENTITY_SERVER_URL=$new_identity_url
USERS_URL=$new_users_url
DOMAIN=$domain
EOL
    
    if [ $? -eq 0 ]; then
        show_success "IP configuration parameters saved successfully to:\n$PARAM_FILE"
    else
        show_error "Failed to save IP configuration parameters!"
        return 1
    fi
}

# Function to handle domain input
handle_domain_input() {
    whiptail --title "Domain Configuration" --msgbox "You chose to configure parameters using domain.\n\nPlease enter the required information in the following steps." 10 60
    
    # Get all required inputs for the DESIRED format
    domain=$(get_input "Enter the Domain (DOMAIN)\n(e.g., example.com):" "")
    [ $? -ne 0 ] && return 1
    
    new_identity_url=$(get_input "Enter Identity Server URL (IDENTITY_SERVER_URL):" "http://$domain")
    [ $? -ne 0 ] && return 1
    
    new_users_url=$(get_input "Enter Users API URL (USERS_URL):" "http://$domain")
    [ $? -ne 0 ] && return 1
    
    new_ip_front=$(get_input "Enter Frontend IP Address (IP_ADDRESS_FRONT):" "185.89.22.58")
    [ $? -ne 0 ] && return 1
    
    new_db=$(get_input "Enter Database IP Address (IP_DATABASE):" "$new_ip_front") # Often same as frontend IP
    [ $? -ne 0 ] && return 1
    
    new_port=$(get_input "Enter Database Port (DB_PORT):" "1433")
    [ $? -ne 0 ] && return 1
    
    db_name_core=$(get_input "Enter Core Database Name (DB_NAME_CORE):" "NetParseh")
    [ $? -ne 0 ] && return 1
    
    db_name_log=$(get_input "Enter Log Database Name (DB_NAME_LOG):" "NetParsehLogManagement")
    [ $? -ne 0 ] && return 1
    
    db_name_auditlog=$(get_input "Enter Audit log Database Name (DB_NAME_AUDITLOG):" "AuditLog")
    [ $? -ne 0 ] && return 1
    
    new_user=$(get_input "Enter Database Username (DB_USER):" "sa")
    [ $? -ne 0 ] && return 1
    
    new_password=$(get_password "Enter Database Password (DB_PASSWORD):")
    [ $? -ne 0 ] && return 1
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$PARAM_FILE")"
    
    # Save the new parameters in the DESIRED format
    cat <<EOL > "$PARAM_FILE"
IP_ADDRESS_FRONT=$new_ip_front
IP_DATABASE=$new_db
DB_PORT=$new_port
DB_NAME_CORE=$db_name_core
DB_NAME_LOG=$db_name_log
DB_NAME_AUDITLOG=$db_name_auditlog
DB_USER=$new_user
DB_PASSWORD=$new_password
IDENTITY_SERVER_URL=$new_identity_url
USERS_URL=$new_users_url
DOMAIN=$domain
EOL
    
    if [ $? -eq 0 ]; then
        show_success "Domain configuration parameters saved successfully to:\n$PARAM_FILE"
    else
        show_error "Failed to save domain configuration parameters!"
        return 1
    fi
}

# Function to show configuration summary
show_config_summary() {
    if [ -f "$PARAM_FILE" ]; then
        # Use sed to hide the password value in the summary view
        local content=$(sed 's/DB_PASSWORD=.*/DB_PASSWORD=*******/g' "$PARAM_FILE")
        whiptail --title "Configuration Summary" \
        --textbox <(echo "$content") \
        20 80
    else
        show_error "Configuration file not found: $PARAM_FILE"
    fi
}

# Main menu
main_menu() {
    while true; do
        CHOICE=$(whiptail --clear \
            --backtitle "Configuration Tool" \
            --title "Configuration Method Selection" \
            --menu "Choose your configuration method:" \
            15 70 4 \
            "1" "Configure using IP Address" \
            "2" "Configure using Domain" \
            "3" "View Current Config" \
            "4" "Exit" \
        3>&1 1>&2 2>&3)
        
        exitstatus=$?
        if [ $exitstatus != 0 ]; then
            # If they press Cancel, ask if they want to exit
            whiptail --title "Confirmation" --yesno "Are you sure you want to exit?" 8 40
            if [ $? = 0 ]; then
                break
            fi
            continue
        fi
        
        case $CHOICE in
            1)
                handle_ip_input
                # Offer to show the summary after saving
                if [ -f "$PARAM_FILE" ]; then
                    whiptail --title "View Summary?" --yesno "Configuration saved. Would you like to view the summary?" 8 50
                    if [ $? = 0 ]; then
                        show_config_summary
                    fi
                fi
            ;;
            2)
                handle_domain_input
                # Offer to show the summary after saving
                if [ -f "$PARAM_FILE" ]; then
                    whiptail --title "View Summary?" --yesno "Configuration saved. Would you like to view the summary?" 8 50
                    if [ $? = 0 ]; then
                        show_config_summary
                    fi
                fi
            ;;
            3)
                show_config_summary
            ;;
            4)
                whiptail --title "Confirmation" --yesno "Are you sure you want to exit?" 8 40
                if [ $? = 0 ]; then
                    whiptail --title "Goodbye" --msgbox "Thank you for using the Configuration Tool!" 8 50
                    break
                fi
            ;;
        esac
    done
}

# Check if whiptail is installed
if ! command -v whiptail &> /dev/null; then
    echo "Error: whiptail is not installed. Please install it first:"
    echo "Ubuntu/Debian: sudo apt-get install whiptail"
    echo "CentOS/RHEL: sudo yum install newt"
    exit 1
fi

# Start the main menu
main_menu

clear
echo "Exiting Configuration Tool..."