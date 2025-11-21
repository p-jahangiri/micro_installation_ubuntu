#!/bin/bash

# Whiptail dimensions
HEIGHT=20
WIDTH=80
LIST_HEIGHT=12

# Environment file path
ENV_FILE="/home/micro_installation_ubuntu/dependency/consul/consul-setting/connection_parameters.env"

# Function to show error message
show_error() {
    whiptail --title "Error" --msgbox "$1" 10 60
}

# Function to show success message
show_success() {
    whiptail --title "Success" --msgbox "$1" 10 60
}

# Function to show info message
show_info() {
    whiptail --title "Information" --infobox "$1" 8 50
    sleep 2
}

# Function to show progress
show_progress() {
    local message="$1"
    local percent="$2"
    echo "$percent" | whiptail --gauge "$message" 8 60 0
}

# Function to display environment variables
display_env_vars() {
    local env_content=""
    
    # Load environment variables
    if [ -f "$ENV_FILE" ]; then
        source "$ENV_FILE"
        
        env_content="Environment Variables Loaded:\n\n"
        env_content+="IP_ADDRESS_FRONT: ${IP_ADDRESS_FRONT:-'Not Set'}\n"
        env_content+="IP_DATABASE: ${IP_DATABASE:-'Not Set'}\n"
        env_content+="DB_PORT: ${DB_PORT:-'Not Set'}\n"
        env_content+="DB_NAME_CORE: ${DB_NAME_CORE:-'Not Set'}\n"
        env_content+="DB_NAME_LOG: ${DB_NAME_LOG:-'Not Set'}\n"
        env_content+="DB_NAME_AUDITLOG: ${DB_NAME_AUDITLOG:-'Not Set'}\n"
        env_content+="DB_USER: ${DB_USER:-'Not Set'}\n"
        env_content+="DB_PASSWORD: ${DB_PASSWORD:+'***Hidden***'}\n"
        env_content+="IDENTITY_SERVER_URL: ${IDENTITY_SERVER_URL:-'Not Set'}\n"
        env_content+="IDS_Issuer_URl: ${IDENTITY_SERVER_URL:-'Not Set'}\n"
        env_content+="IDS_API_URL: ${USERS_URL:-'Not Set'}"

    else
        env_content="Environment file not found at: $ENV_FILE"
    fi
    
    whiptail --title "Environment Variables" --msgbox "$env_content" 18 80
}

# Function to validate environment variables
validate_env_vars() {
    if [[ -z "$IP_ADDRESS_FRONT" || -z "$IP_DATABASE" || -z "$DB_PORT" || -z "$DB_NAME_CORE" || -z "$DB_NAME_LOG" || -z "$DB_USER" || -z "$DB_PASSWORD" || -z "$IDENTITY_SERVER_URL" || -z "$USERS_URL" ]]; then
        show_error "One or more required environment variables are empty!\n\nPlease run get-consul-setting.sh first to configure the environment variables."
        return 1
    fi
    return 0
}

# Function to update JSON files
update_json_files() {
    local total_files=11
    local current_file=0
    
    # Define JSON files and corresponding substitutions
    declare -A substitutions
    
    # Customize substitutions for each JSON file
    substitutions["/home/micro_installation_ubuntu/dependency/consul/consul-setting/Base/appsettings.Production.json"]="
      s|\${IP_ADDRESS_FRONT}|$IP_ADDRESS_FRONT|g;
      s|\${IP_DATABASE}|$IP_DATABASE|g;
      s|\${DB_PORT}|$DB_PORT|g;
      s|\${DB_NAME_LOG}|$DB_NAME_LOG|g;
      s|\${DB_USER}|$DB_USER|g;
      s|\${DB_PASSWORD}|$DB_PASSWORD|g;
      s|\${IDENTITY_SERVER_URL}|$IDENTITY_SERVER_URL|g;
      s|\${USERS_URL}|$USERS_URL|g;
      s|\${IDENTITY_SERVER_URL}|$IDENTITY_SERVER_URL|g;
    "
    
    substitutions["/home/micro_installation_ubuntu/dependency/consul/consul-setting/Core/appsettings.Production.json"]="
      s|\${IP_DATABASE}|$IP_DATABASE|g;
      s|\${DB_PORT}|$DB_PORT|g;
      s|\${DB_NAME_CORE}|$DB_NAME_CORE|g;
      s|\${DB_NAME_LOG}|$DB_NAME_LOG|g;
      s|\${DB_NAME_AUDITLOG}|$DB_NAME_AUDITLOG|g;
      s|\${DB_USER}|$DB_USER|g;
      s|\${DB_PASSWORD}|$DB_PASSWORD|g;
    "
    
    substitutions["/home/micro_installation_ubuntu/dependency/consul/consul-setting/EAM/appsettings.Production.json"]="
      s|\${IP_DATABASE}|$IP_DATABASE|g;
      s|\${DB_PORT}|$DB_PORT|g;
      s|\${DB_NAME_CORE}|$DB_NAME_CORE|g;
      s|\${DB_NAME_LOG}|$DB_NAME_LOG|g;
      s|\${DB_NAME_AUDITLOG}|$DB_NAME_AUDITLOG|g;
      s|\${DB_USER}|$DB_USER|g;
      s|\${DB_PASSWORD}|$DB_PASSWORD|g;
    "
    
    substitutions["/home/micro_installation_ubuntu/dependency/consul/consul-setting/Financial/appsettings.Production.json"]="
      s|\${IP_DATABASE}|$IP_DATABASE|g;
      s|\${DB_PORT}|$DB_PORT|g;
      s|\${DB_NAME_CORE}|$DB_NAME_CORE|g;
      s|\${DB_NAME_LOG}|$DB_NAME_LOG|g;
      s|\${DB_NAME_AUDITLOG}|$DB_NAME_AUDITLOG|g;
      s|\${DB_USER}|$DB_USER|g;
      s|\${DB_PASSWORD}|$DB_PASSWORD|g;
    "
    
    substitutions["/home/micro_installation_ubuntu/dependency/consul/consul-setting/HR/appsettings.Production.json"]="
      s|\${IP_DATABASE}|$IP_DATABASE|g;
      s|\${DB_PORT}|$DB_PORT|g;
      s|\${DB_NAME_CORE}|$DB_NAME_CORE|g;
      s|\${DB_NAME_LOG}|$DB_NAME_LOG|g;
      s|\${DB_NAME_AUDITLOG}|$DB_NAME_AUDITLOG|g;
      s|\${DB_USER}|$DB_USER|g;
      s|\${DB_PASSWORD}|$DB_PASSWORD|g;
    "
    
    substitutions["/home/micro_installation_ubuntu/dependency/consul/consul-setting/Inventory/appsettings.Production.json"]="
      s|\${IP_DATABASE}|$IP_DATABASE|g;
      s|\${DB_PORT}|$DB_PORT|g;
      s|\${DB_NAME_CORE}|$DB_NAME_CORE|g;
      s|\${DB_NAME_LOG}|$DB_NAME_LOG|g;
      s|\${DB_NAME_AUDITLOG}|$DB_NAME_AUDITLOG|g;
      s|\${DB_USER}|$DB_USER|g;
      s|\${DB_PASSWORD}|$DB_PASSWORD|g;
    "
    
    substitutions["/home/micro_installation_ubuntu/dependency/consul/consul-setting/Work/appsettings.Production.json"]="
      s|\${IP_DATABASE}|$IP_DATABASE|g;
      s|\${DB_PORT}|$DB_PORT|g;
      s|\${DB_NAME_CORE}|$DB_NAME_CORE|g;
      s|\${DB_NAME_LOG}|$DB_NAME_LOG|g;
      s|\${DB_NAME_AUDITLOG}|$DB_NAME_AUDITLOG|g;
      s|\${DB_USER}|$DB_USER|g;
      s|\${DB_PASSWORD}|$DB_PASSWORD|g;
    "
    
    substitutions["/home/micro_installation_ubuntu/dependency/consul/consul-setting/WorkFlow/appsettings.Production.json"]="
      s|\${IP_DATABASE}|$IP_DATABASE|g;
      s|\${DB_PORT}|$DB_PORT|g;
      s|\${DB_NAME_CORE}|$DB_NAME_CORE|g;
      s|\${DB_NAME_LOG}|$DB_NAME_LOG|g;
      s|\${DB_NAME_AUDITLOG}|$DB_NAME_AUDITLOG|g;
      s|\${DB_USER}|$DB_USER|g;
      s|\${DB_PASSWORD}|$DB_PASSWORD|g;
    "
    
    substitutions["/home/micro_installation_ubuntu/dependency/consul/consul-setting/Reporting/appsettings.Production.json"]="
      s|\${IP_DATABASE}|$IP_DATABASE|g;
      s|\${DB_PORT}|$DB_PORT|g;
      s|\${DB_NAME_CORE}|$DB_NAME_CORE|g;
      s|\${DB_NAME_LOG}|$DB_NAME_LOG|g;
      s|\${DB_NAME_AUDITLOG}|$DB_NAME_AUDITLOG|g;
      s|\${DB_USER}|$DB_USER|g;
      s|\${DB_PASSWORD}|$DB_PASSWORD|g;
    "
    
    substitutions["/home/micro_installation_ubuntu/dependency/consul/consul-setting/SignalR/appsettings.Production.json"]="
      s|\${IP_DATABASE}|$IP_DATABASE|g;
      s|\${DB_PORT}|$DB_PORT|g;
      s|\${DB_NAME_CORE}|$DB_NAME_CORE|g;
      s|\${DB_NAME_LOG}|$DB_NAME_LOG|g;
      s|\${DB_NAME_AUDITLOG}|$DB_NAME_AUDITLOG|g;
      s|\${DB_USER}|$DB_USER|g;
      s|\${DB_PASSWORD}|$DB_PASSWORD|g;
    "
    
    # Results tracking
    local updated_files=()
    local missing_files=()
    local failed_files=()
    
    # Loop through each JSON file and update with its specific substitutions
    for file in "${!substitutions[@]}"; do
        current_file=$((current_file + 1))
        local progress=$((current_file * 100 / total_files))
        local filename=$(basename "$file")
        
        # Show progress
        (
            echo "$progress"
            sleep 0.5
        ) | whiptail --gauge "Processing: $filename" 8 60 0
        
        if [ -f "$file" ]; then
            if sed -i "${substitutions[$file]}" "$file" 2>/dev/null; then
                updated_files+=("$filename")
            else
                failed_files+=("$filename")
            fi
        else
            missing_files+=("$filename")
        fi
    done
    
    # Show results summary
    local summary="JSON Update Results:\n\n"
    summary+="✓ Successfully Updated: ${#updated_files[@]} files\n"
    summary+="✗ Missing Files: ${#missing_files[@]} files\n"
    summary+="⚠ Failed Updates: ${#failed_files[@]} files\n\n"
    
    if [ ${#updated_files[@]} -gt 0 ]; then
        summary+="Updated Files:\n"
        for file in "${updated_files[@]}"; do
            summary+="  • $file\n"
        done
        summary+="\n"
    fi
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        summary+="Missing Files:\n"
        for file in "${missing_files[@]}"; do
            summary+="  • $file\n"
        done
        summary+="\n"
    fi
    
    if [ ${#failed_files[@]} -gt 0 ]; then
        summary+="Failed Files:\n"
        for file in "${failed_files[@]}"; do
            summary+="  • $file\n"
        done
    fi
    
    whiptail --title "Update Summary" --msgbox "$summary" 20 80
    
    # Return success if at least one file was updated
    [ ${#updated_files[@]} -gt 0 ]
}

# Main function
main() {
    # Show welcome message
    if whiptail --title "JSON Configuration Updater" --yesno "This tool will update JSON configuration files with environment variables.\n\nDo you want to continue?" 10 60; then
        
        # Load environment variables
        show_info "Loading environment variables..."
        
        if [ -f "$ENV_FILE" ]; then
            set -a
            source "$ENV_FILE"
            set +a
        else
            show_error "Environment file not found!\nPath: $ENV_FILE\n\nPlease run get-consul-setting.sh first."
            exit 1
        fi
        
        # Show environment variables
        if whiptail --title "Review Settings" --yesno "Would you like to review the loaded environment variables before proceeding?" 8 60; then
            display_env_vars
        fi
        
        # Validate environment variables
        show_info "Validating environment variables..."
        if ! validate_env_vars; then
            exit 1
        fi
        
        # Confirm update
        if whiptail --title "Confirmation" --yesno "All environment variables are set.\n\nProceed with updating JSON files?" 10 50; then
            show_info "Starting JSON file updates..."
            
            if update_json_files; then
                show_success "JSON configuration files have been updated successfully!"
            else
                show_error "Some errors occurred during the update process. Please check the summary for details."
                exit 1
            fi
        else
            show_info "Operation cancelled by user."
        fi
    else
        show_info "Operation cancelled by user."
    fi
}

# Run main function
main

clear
echo "JSON update script completed."