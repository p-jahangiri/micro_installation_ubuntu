# Iconify API Offline Setup

This directory contains all the necessary files and scripts to run the Iconify API in offline mode.

## Directory Structure

- `iconify-data/` - Contains all icon data for offline use
  - `icons/` - JSON files for individual icon sets
  - `custom-icons/` - Directory for custom icon sets
  - `cache/` - Cache directory for API operation
  - `versions.json` - Version information for icon sets

## Setup Instructions

### For Offline Use (No Internet Required)

1. Ensure the `iconify-data` directory and its subdirectories are populated with icon data
2. Run the Docker container with the provided configuration

### For Initial Setup (Internet Required)

If you need to download the latest icon data:

1. Run the setup script:

   - On Windows: `.\setup-offline.ps1`
   - On Linux/Mac: `./setup-offline.sh`

2. The script will download all necessary icon data and organize it for offline use

## Configuration

The Docker container is configured with the following environment variables for offline operation:

- `ICONIFY_SOURCE=none` - Disables downloading icons from external sources
- `ALLOW_UPDATE=false` - Disables automatic updates
- `ENABLE_ICON_LISTS=false` - Disables icon lists that require external connections
- `ENABLE_SEARCH_ENGINE=false` - Disables search engine that requires external connections

## Testing

To test if the setup is working correctly:

1. Start the Docker container: `docker-compose up -d`
2. Access an icon endpoint: `http://localhost:3000/test/test-icon`
3. You should receive SVG data for the test icon

## Adding Custom Icons

To add custom icon sets:

1. Create a JSON file in the `iconify-data/custom-icons/` directory
2. Follow the Iconify JSON format for icon sets
3. The API will automatically serve icons from this directory
