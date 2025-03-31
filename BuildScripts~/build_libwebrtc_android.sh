#!/bin/bash -eu

# Setup logging - redirect all output to both console and file
LOG_FILE="build_libwebrtc_android.log"
# Clear previous log file
> "$LOG_FILE"
# Redirect stdout and stderr to both console and file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting WebRTC Android build process at $(date '+%Y-%m-%d %H:%M:%S')"



# if [ ! -e "$(pwd)/depot_tools" ]
# then
#   echo "Cloning depot_tools..."
#   git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git
# fi

export COMMAND_DIR=$(cd $(dirname $0); pwd)
export PATH="$(pwd)/depot_tools:$PATH"
export WEBRTC_VERSION=5845
export OUTPUT_DIR="$(pwd)/out"
export ARTIFACTS_DIR="$(pwd)/artifacts"
export PYTHON3_BIN="$(pwd)/depot_tools/python-bin/python3"

# bootstrap vpython3
./depot_tools/vpython3 --version

if [ ! -e "$(pwd)/src" ]
then
  echo "Excluding examples from fetch config..."
  patch -N "depot_tools/fetch_configs/webrtc.py" < "$COMMAND_DIR/patches/fetch_exclude_examples.patch"
  echo "Fetching webrtc_android..."
  fetch --nohooks webrtc_android
  cd src
  echo "Configuring git settings..."
  sudo sh -c 'echo 127.0.1.1 $(hostname) >> /etc/hosts'
  sudo git config --system core.longpaths true
  echo "Checking out WebRTC version ${WEBRTC_VERSION}..."
  git checkout "refs/remotes/branch-heads/$WEBRTC_VERSION"
  cd ..
  echo "Running gclient sync..."
  gclient sync -D --force --reset
fi

echo "Executing namespace renaming..."
chmod +x BuildScripts~/rename_namespace.sh
./BuildScripts~/rename_namespace.sh

echo "Adding jsoncpp..."
patch -N "src/BUILD.gn" < "$COMMAND_DIR/patches/add_jsoncpp.patch"

echo "Adding visibility libunwind..."
patch -N "src/buildtools/third_party/libunwind/BUILD.gn" < "$COMMAND_DIR/patches/add_visibility_libunwind.patch"

echo "Adding deps libunwind..."
patch -N "src/build/config/BUILD.gn" < "$COMMAND_DIR/patches/add_deps_libunwind.patch"

echo "Adding -mno-outline-atomics flag..."
patch -N "src/build/config/compiler/BUILD.gn" < "$COMMAND_DIR/patches/add_nooutlineatomics_flag.patch"

echo "Downgrading to JDK8 - patching compile_java.py..."
patch -N "src/build/android/gyp/compile_java.py" < "$COMMAND_DIR/patches/downgradeJDKto8_compile_java.patch"
echo "Downgrading to JDK8 - patching turbine.py..."
patch -N "src/build/android/gyp/turbine.py" < "$COMMAND_DIR/patches/downgradeJDKto8_turbine.patch"

echo "Fixing SetRawImagePlanes in LibvpxVp8Encoder..."
patch -N "src/modules/video_coding/codecs/vp8/libvpx_vp8_encoder.cc" < "$COMMAND_DIR/patches/libvpx_vp8_encoder.patch"

pushd src
echo "Fixing AdaptedVideoTrackSource::video_adapter..."
patch -p1 < "$COMMAND_DIR/patches/fix_adaptedvideotracksource.patch"
echo "Fixing Android video encoder..."
patch -p1 < "$COMMAND_DIR/patches/fix_android_videoencoder.patch"
popd

echo "Creating artifacts directory..."
mkdir -p "$ARTIFACTS_DIR/lib"


for target_cpu in "arm64" "x64"
do
  mkdir -p "$ARTIFACTS_DIR/lib/${target_cpu}"

  for is_debug in "true" "false"
  do
    # generate ninja files
    # use `treat_warnings_as_errors` option to avoid deprecation warnings
    gn gen "$OUTPUT_DIR" --root="src" \
      --args="is_debug=${is_debug} \
      is_java_debug=${is_debug} \
      target_os=\"android\" \
      target_cpu=\"${target_cpu}\" \
      rtc_use_h264=false \
      rtc_include_tests=false \
      rtc_build_examples=false \
      is_component_build=false \
      use_rtti=true \
      use_custom_libcxx=false \
      treat_warnings_as_errors=false \
      use_errorprone_java_compiler=false \
      use_cxx17=true"

    # build static library
    ninja -C "$OUTPUT_DIR" webrtc

    filename="libwebrtc.a"
    if [ $is_debug = "true" ]; then
      filename="libwebrtcd.a"
    fi

    # copy static library
    cp "$OUTPUT_DIR/obj/libwebrtc.a" "$ARTIFACTS_DIR/lib/${target_cpu}/${filename}"
  done
done

pushd src

for is_debug in "true" "false"
do
  # use `treat_warnings_as_errors` option to avoid deprecation warnings
  "$PYTHON3_BIN" tools_webrtc/android/build_aar.py \
    --build-dir $OUTPUT_DIR \
    --output $OUTPUT_DIR/libwebrtc.aar \
    --arch arm64-v8a x86_64 \
    --extra-gn-args "is_debug=${is_debug} \
      is_java_debug=${is_debug} \
      rtc_use_h264=false \
      rtc_include_tests=false \
      rtc_build_examples=false \
      is_component_build=false \
      use_rtti=true \
      use_custom_libcxx=false \
      treat_warnings_as_errors=false \
      use_errorprone_java_compiler=false \
      use_cxx17=true"

  filename="libwebrtc.aar"
  if [ $is_debug = "true" ]; then
    filename="libwebrtc-debug.aar"
  fi
  # copy aar
  cp "$OUTPUT_DIR/libwebrtc.aar" "$ARTIFACTS_DIR/lib/${filename}"
done

popd

"$PYTHON3_BIN" "./src/tools_webrtc/libs/generate_licenses.py" \
  --target :webrtc "$OUTPUT_DIR" "$OUTPUT_DIR"

cd src
find . -name "*.h" -print | cpio -pd "$ARTIFACTS_DIR/include"

cp "$OUTPUT_DIR/LICENSE.md" "$ARTIFACTS_DIR"

# create zip
cd "$ARTIFACTS_DIR"
zip -r webrtc-android.zip lib include LICENSE.md
