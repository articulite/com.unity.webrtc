#!/bin/bash -eu

# Setup logging - redirect all output to both console and file
LOG_FILE="rename_namespace.log"
# Clear previous log file
> "$LOG_FILE"
# Redirect stdout and stderr to both console and file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting namespace renaming process at $(date '+%Y-%m-%d %H:%M:%S')"

SRC_DIR=$(pwd)/src
SDK_DIR=$SRC_DIR/sdk/android
RTC_BASE_DIR=$SRC_DIR/rtc_base
MODULES_DIR=$SRC_DIR/modules

# Function to rename directories and update content
rename_namespace() {
    local dir=$1
    local pattern=$2
    
    echo "Processing directory: $dir"
    
    # Rename Java package directories if source exists
    if [ -d "$dir/org/webrtc" ]; then
        echo "Renaming $dir/org/webrtc to $dir/xyz/webrtc"
        mkdir -p "$dir/xyz" # Ensure target parent directory exists
        mv "$dir/org/webrtc" "$dir/xyz/webrtc"
    else
        echo "Directory $dir/org/webrtc not found, skipping rename."
    fi
    
    # Update BUILD.gn files
    find "$dir" -name "BUILD.gn" -type f -exec sed -i 's/org\/webrtc/xyz\/webrtc/g' {} +
    
    # Update Java files
    find "$dir" -name "*.java" -type f -exec sed -i 's/org\.webrtc/xyz\.webrtc/g' {} +
    
    # Update C++ files
    if [ "$pattern" = "true" ]; then
        find "$dir" -name "*.cc" -type f -exec sed -i 's/org\.webrtc/xyz\.webrtc/g' {} +
        find "$dir" -name "*.h" -type f -exec sed -i 's/org\.webrtc/xyz\.webrtc/g' {} +
        find "$dir" -name "*.cc" -type f -exec sed -i 's/org_webrtc/xyz_webrtc/g' {} +
        find "$dir" -name "*.h" -type f -exec sed -i 's/org_webrtc/xyz_webrtc/g' {} +
    fi
}

# Stash any changes and clean working directory
cd "$SRC_DIR"
echo "Stashing changes and cleaning working directory..."
git stash
git clean -fd
cd ..

# Apply jsoncpp patch first
# echo "Applying jsoncpp patch..."
# patch -N "src/BUILD.gn" < "patches/add_jsoncpp.patch"

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

echo "Namespace renaming complete at $(date '+%Y-%m-%d %H:%M:%S')!" 