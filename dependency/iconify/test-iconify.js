// Simple test script to verify Iconify API configuration
const fs = require("fs");
const path = require("path");

// Check if the config file exists
const configFile = "/data/iconify-api/config.json";
if (fs.existsSync(configFile)) {
  console.log("Config file found:", configFile);
  const config = JSON.parse(fs.readFileSync(configFile, "utf8"));
  console.log("Config:", config);
} else {
  console.log("Config file not found:", configFile);
}

// Check if the icons directory exists
const iconsDir = "/data/iconify-api/icons";
if (fs.existsSync(iconsDir)) {
  console.log("Icons directory found:", iconsDir);
  const files = fs.readdirSync(iconsDir);
  console.log("Icon files:", files);
} else {
  console.log("Icons directory not found:", iconsDir);
}

// Check if the cache directory exists
const cacheDir = "/data/iconify-api/cache";
if (fs.existsSync(cacheDir)) {
  console.log("Cache directory found:", cacheDir);
  // Check if JSON files exist in cache
  const jsonDir = path.join(
    cacheDir,
    "npm",
    "@iconify",
    "json",
    "package",
    "json"
  );
  if (fs.existsSync(jsonDir)) {
    console.log("JSON directory found:", jsonDir);
    const jsonFiles = fs.readdirSync(jsonDir);
    console.log("Number of JSON files:", jsonFiles.length);
  } else {
    console.log("JSON directory not found:", jsonDir);
  }
} else {
  console.log("Cache directory not found:", cacheDir);
}
