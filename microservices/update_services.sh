#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# List of all service directories
SERVICES=(
    "core"
    "hr"
    "eam"
    "work"
    "workflow"
    "inventory"
    "financial"
    "global"
    "reporting"
   # "signalr"
    "frontend"
)

# Function to check if docker is installed and running
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed${NC}"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        echo -e "${RED}Error: Docker daemon is not running${NC}"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}Error: Docker Compose is not installed${NC}"
        exit 1
    fi
}

# Function to handle errors
handle_error() {
    echo -e "${RED}Error occurred in service: $1${NC}"
    echo -e "${YELLOW}Do you want to continue with other services? (y/n)${NC}"
    read -p "" continue_choice
    if [[ $continue_choice != "y" && $continue_choice != "Y" ]]; then
        exit 1
    fi
}

echo -e "${BLUE}Checking prerequisites...${NC}"
check_docker
echo -e "${GREEN}Docker and Docker Compose are available${NC}"
echo ""

echo -e "${BLUE}Step 1: Setting versions for each service${NC}"
echo "----------------------------------------"

# Step 1: Update versions in .env files
for service in "${SERVICES[@]}"; do
    if [ -d "$service" ]; then
        echo -e "${GREEN}Setting version for $service${NC}"
        
        # Show current version if exists
        if [ -f "$service/.env" ] && grep -q "^VERSION=" "$service/.env"; then
            current_version=$(grep "^VERSION=" "$service/.env" | cut -d'=' -f2)
            echo "Current version: $current_version"
        fi
        
        read -p "Enter version for $service (or press Enter to skip): " version
        
        # Skip if no version entered
        if [ -z "$version" ]; then
            echo "Skipping version update for $service"
            echo "----------------------------------------"
            continue
        fi
        
        # Create backup of original .env
        if [ -f "$service/.env" ]; then
            cp "$service/.env" "$service/.env.backup"
        fi
        
        # Create temp file
        touch "$service/.env.tmp"
        
        # If .env exists, copy all lines except VERSION to temp file
        if [ -f "$service/.env" ]; then
            grep -v "^VERSION=" "$service/.env" > "$service/.env.tmp" || true
        fi
        
        # Add new VERSION line
        echo "VERSION=$version" >> "$service/.env.tmp"
        
        # Replace original .env with temp file
        mv "$service/.env.tmp" "$service/.env"
        
        echo "Version set for $service: $version"
        echo "----------------------------------------"
    else
        echo -e "${YELLOW}Warning: Directory $service not found${NC}"
    fi
done

echo -e "\n${BLUE}Step 2: Pulling Docker images for all services${NC}"
echo "----------------------------------------"

# Step 2: Docker compose pull for all services
for service in "${SERVICES[@]}"; do
    if [ -d "$service" ] && [ -f "$service/docker-compose.yml" ]; then
        echo -e "${GREEN}Pulling Docker images for $service${NC}"
        cd "$service" || { handle_error "$service (cd failed)"; continue; }
        
        if ! docker-compose pull; then
            handle_error "$service (pull failed)"
        fi
        
        cd .. || exit 1
    else
        echo -e "${YELLOW}Warning: $service directory or docker-compose.yml not found${NC}"
    fi
done

echo -e "\n${BLUE}Step 3: Starting all services${NC}"
echo "----------------------------------------"

# Step 3: Docker compose up for all services
for service in "${SERVICES[@]}"; do
    if [ -d "$service" ] && [ -f "$service/docker-compose.yml" ]; then
        echo -e "${GREEN}Starting $service${NC}"
        cd "$service" || { handle_error "$service (cd failed)"; continue; }
        
        if ! docker-compose up -d; then
            handle_error "$service (startup failed)"
        else
            echo -e "${GREEN}$service started successfully${NC}"
        fi
        
        cd .. || exit 1
    fi
done

echo -e "\n${GREEN}Script execution completed!${NC}"
echo -e "${BLUE}You can check service status with: docker-compose ps${NC}"