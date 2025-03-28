#!/bin/bash -eu

export SOLUTION_DIR=$(pwd)/Plugin~
export PLUGIN_DIR=$(pwd)/Runtime/Plugins/Android
export ARTIFACTS_DIR=$(pwd)/artifacts

# Use local WebRTC build
if [ ! -f "$ARTIFACTS_DIR/webrtc-android.zip" ]; then
    echo "Error: webrtc-android.zip not found in artifacts directory. Please run build_libwebrtc_android.sh first."
    exit 1
fi

# Extract local WebRTC build
unzip -d $SOLUTION_DIR/webrtc $ARTIFACTS_DIR/webrtc-android.zip
cp -f $SOLUTION_DIR/webrtc/lib/libwebrtc.aar $PLUGIN_DIR

# Update plugin namespaces
echo "Updating plugin namespaces..."
cd "$SOLUTION_DIR"

# Update C++ JNI function names
find . -type f -name "*.txt" -exec sed -i 's/Java_org_webrtc/Java_xyz_webrtc/g' {} +

# Update C++ files in WebRTCPlugin
find ./WebRTCPlugin -type f -name "*.cc" -exec sed -i 's/org\/webrtc/xyz\/webrtc/g' {} +
find ./WebRTCPlugin -type f -name "*.h" -exec sed -i 's/org\/webrtc/xyz\/webrtc/g' {} +

# Build UnityRenderStreaming Plugin 
for ARCH_ABI in "arm64-v8a" "x86_64"
do
  cmake . \
    -B build \
    -D CMAKE_SYSTEM_NAME=Android \
    -D CMAKE_ANDROID_API_MIN=24 \
    -D CMAKE_ANDROID_API=24 \
    -D CMAKE_ANDROID_ARCH_ABI=$ARCH_ABI \
    -D CMAKE_ANDROID_NDK=$ANDROID_NDK \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_ANDROID_STL_TYPE=c++_static

  cmake \
    --build build \
    --target WebRTCPlugin

  # libwebrtc.so move into libwebrtc.aar
  pushd $PLUGIN_DIR
  mkdir -p jni/$ARCH_ABI
  mv libwebrtc.so jni/$ARCH_ABI
  zip -g libwebrtc.aar jni/$ARCH_ABI/libwebrtc.so
  rm -r jni
  popd
  rm -rf build
done