#!/bin/bash

# Iconify Offline Setup Script
# This script downloads all necessary icon data for offline use

echo "Starting Iconify offline setup..."

# Create directories
mkdir -p iconify-data/icons
mkdir -p iconify-data/custom-icons
mkdir -p iconify-data/cache/npm/@iconify/json/package/json
mkdir -p iconify-data/cache/storage

# Download @iconify/json package
echo "Downloading @iconify/json package..."
npm pack @iconify/json

# Extract the package
echo "Extracting package..."
tar -xzf iconify-json-*.tgz
mv package iconify-data/cache/npm/@iconify/json/package

# Copy JSON files to icons directory
echo "Copying JSON files to icons directory..."
cp -r iconify-data/cache/npm/@iconify/json/package/json/* iconify-data/icons/

# Create versions.json file
echo "Creating versions.json..."
cat > iconify-data/versions.json << EOF
{
	"@iconify/json": {
		"downloadType": "npm",
		"rootDir": "cache/npm/@iconify/json",
		"contentsDir": "cache/npm/@iconify/json/package",
		"version": "latest"
	}
}
EOF

# Create a simple test icon set
echo "Creating test icon set..."
cat > iconify-data/icons/test.json << EOF
{
  "prefix": "test",
  "icons": {
    "test-icon": {
      "body": "<path d=\"M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z\"/>",
      "width": 24,
      "height": 24
    }
  }
}
EOF

# Clean up
echo "Cleaning up..."
rm -f iconify-json-*.tgz
rm -rf package

echo "Iconify offline setup complete!"
echo "All icon data has been downloaded and organized for offline use."
echo "You can now run the Iconify API in offline mode."