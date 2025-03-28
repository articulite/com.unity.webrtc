#!/bin/bash -eu

# Script to rename WebRTC namespaces from org.webrtc to org.unityrtc

echo "Starting namespace renaming process..."

SRC_DIR=$(pwd)/src
SDK_DIR=$SRC_DIR/sdk/android
RTC_BASE_DIR=$SRC_DIR/rtc_base
MODULES_DIR=$SRC_DIR/modules

# Function to rename directories and update content
rename_namespace() {
    local dir=$1
    local pattern=$2
    
    echo "Processing directory: $dir"
    
    # Rename Java package directories
    if [ -d "$dir/org/webrtc" ]; then
        mv "$dir/org/webrtc" "$dir/org/unityrtc"
    fi
    
    # Update BUILD.gn files
    find "$dir" -name "BUILD.gn" -type f -exec sed -i 's/org\/webrtc/org\/unityrtc/g' {} +
    
    # Update Java files
    find "$dir" -name "*.java" -type f -exec sed -i 's/org\.webrtc/org\.unityrtc/g' {} +
    
    # Update C++ files
    if [ "$pattern" = "true" ]; then
        find "$dir" -name "*.cc" -type f -exec sed -i 's/org\.webrtc/org\.unityrtc/g' {} +
        find "$dir" -name "*.h" -type f -exec sed -i 's/org\.webrtc/org\.unityrtc/g' {} +
        find "$dir" -name "*.cc" -type f -exec sed -i 's/org_webrtc/org_unityrtc/g' {} +
        find "$dir" -name "*.h" -type f -exec sed -i 's/org_webrtc/org_unityrtc/g' {} +
    fi
}

# Stash any changes and clean working directory
cd "$SRC_DIR"
git stash
git clean -fd
cd ..

# Apply jsoncpp patch first
patch -N "src/BUILD.gn" < "patches/add_jsoncpp.patch"

# Process Android SDK directory
echo "Processing Android SDK..."
rename_namespace "$SDK_DIR/api" false
rename_namespace "$SDK_DIR/src/java" false

# Process RTC Base directory
echo "Processing RTC Base..."
rename_namespace "$RTC_BASE_DIR/java/src" false

# Process Modules directory
echo "Processing Modules..."
rename_namespace "$MODULES_DIR/audio_device/android/java/src" false

# Process all C++ files in source directory
echo "Processing C++ files..."
rename_namespace "$SRC_DIR" true

echo "Namespace renaming complete!" 