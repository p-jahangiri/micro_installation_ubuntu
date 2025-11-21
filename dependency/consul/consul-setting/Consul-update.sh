#!/bin/bash

# Load the environment variables from the .env file to load IP_ADDRESS_FRONT from it
if [[ -f connection_parameters.env ]]; then
    set -a
    source connection_parameters.env
    set +a
else
    echo -e "${RED}.env file not found!${NC}"
    exit 1
fi

# Define colors
RED='\033[0;31m'      # Red
GREEN='\033[0;32m'    # Green
YELLOW='\033[0;33m'   # Yellow
NC='\033[0m'          # No Color

# Define the base Consul URL
CONSUL_URL_BASE="$IP_ADDRESS_FRONT:8500/v1/kv/Micro"
CONSUL_TOKEN="4e164673-08e9-db3c-8e8a-caa602a8eeb6"

# Define the folders containing the JSON files
FOLDERS=("Base" "Core" "EAM" "Financial" "HR" "Inventory" "Reporting" "SignalR" "Work" "WorkFlow" "Global")

# Loop through each folder
for FOLDER in "${FOLDERS[@]}"; do
    # Define the path to the JSON file in the current folder
    JSON_FILE="$FOLDER/appsettings.Production.json"
    
    # Check if the JSON file exists
    if [[ -f "$JSON_FILE" ]]; then
        # Construct the full Consul URL for this specific key
        CONSUL_URL="$CONSUL_URL_BASE/$FOLDER/appsettings.Production.json"
        
        # Read the content of the JSON file
        JSON_DATA=$(cat "$JSON_FILE")
        
        # Send the JSON data to Consul using curl
        echo -e "${YELLOW}Updating Consul key for $JSON_FILE...${NC}"
        if curl --header "X-Consul-Token: $CONSUL_TOKEN" --request PUT --data "$JSON_DATA" "$CONSUL_URL"; then
            
            # Print success message for this file
            echo -e "${GREEN}Updated Consul with $JSON_FILE at $CONSUL_URL${NC}"
            
        else
            echo -e "${RED}Failed to update Consul with $JSON_FILE at $CONSUL_URL${NC}"
        fi
    else
        echo -e "${YELLOW}Warning: JSON file '$JSON_FILE' not found!${NC}"
    fi
done

echo -e "${GREEN}All JSON files have been processed and sent to Consul.${NC}"
echo -e "${GREEN}PLEASE RESTART MICROSERVICES FROM PORTAINER.${NC}"

