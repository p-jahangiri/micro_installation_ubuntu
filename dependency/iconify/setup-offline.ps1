# Iconify Offline Setup Script for Windows
# This script downloads all necessary icon data for offline use

Write-Host "Starting Iconify offline setup..."

# Create directories
New-Item -ItemType Directory -Path "iconify-data\icons" -Force
New-Item -ItemType Directory -Path "iconify-data\custom-icons" -Force
New-Item -ItemType Directory -Path "iconify-data\cache\npm\@iconify\json\package\json" -Force
New-Item -ItemType Directory -Path "iconify-data\cache\storage" -Force

# Download @iconify/json package
Write-Host "Downloading @iconify/json package..."
npm pack @iconify/json

# Extract the package
Write-Host "Extracting package..."
# Get the name of the downloaded tgz file
$tgzFile = Get-ChildItem -Path . -Filter "iconify-json-*.tgz" | Select-Object -First 1

if ($tgzFile) {
    # Use tar to extract (available in Windows 10/11)
    tar -xzf $tgzFile.Name
    
    # Move package directory to correct location
    Move-Item -Path "package" -Destination "iconify-data\cache\npm\@iconify\json\package" -Force
    
    # Copy JSON files to icons directory
    Write-Host "Copying JSON files to icons directory..."
    $jsonFiles = Get-ChildItem -Path "iconify-data\cache\npm\@iconify\json\package\json" -Filter "*.json"
    foreach ($file in $jsonFiles) {
        Copy-Item -Path $file.FullName -Destination "iconify-data\icons\" -Force
    }
    
    # Create versions.json file
    Write-Host "Creating versions.json..."
    $versionsContent = @{
        "@iconify/json" = @{
            "downloadType" = "npm"
            "rootDir" = "cache/npm/@iconify/json"
            "contentsDir" = "cache/npm/@iconify/json/package"
            "version" = "latest"
        }
    } | ConvertTo-Json
    
    $versionsContent | Out-File -FilePath "iconify-data\versions.json" -Encoding UTF8
    
    # Create a simple test icon set
    Write-Host "Creating test icon set..."
    $testContent = @{
        "prefix" = "test"
        "icons" = @{
            "test-icon" = @{
                "body" = "<path d=`"M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z`"/>"
                "width" = 24
                "height" = 24
            }
        }
    } | ConvertTo-Json -Depth 3
    
    $testContent | Out-File -FilePath "iconify-data\icons\test.json" -Encoding UTF8
    
    # Clean up
    Write-Host "Cleaning up..."
    Remove-Item -Path $tgzFile.Name -Force
    Remove-Item -Path "package" -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Host "Iconify offline setup complete!" -ForegroundColor Green
    Write-Host "All icon data has been downloaded and organized for offline use." -ForegroundColor Green
    Write-Host "You can now run the Iconify API in offline mode." -ForegroundColor Green
} else {
    Write-Host "Failed to download @iconify/json package" -ForegroundColor Red
}