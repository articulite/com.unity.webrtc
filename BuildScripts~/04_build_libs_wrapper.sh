#!/bin/bash -eu
# File: 04_build_libs_wrapper.sh
# This is the main script that manages Python version switching

# Get the absolute path to the common script
SCRIPT_DIR=$(dirname $(readlink -f $0))
COMMON_SCRIPT="$SCRIPT_DIR/00_common.sh"

# Source common variables and functions
source "$COMMON_SCRIPT"

# Phase 1: GN generation (requires Python 3.6)
echo "Setting up Python 3.6 environment for GN generation..."
sudo update-alternatives --set python3 /usr/bin/python3.6

# Create a separate script for the GN generation part
cat > /tmp/gn_generate.sh << EOF
#!/bin/bash -eu

# Source common variables and functions
source "$COMMON_SCRIPT"

generate_ninja() {
  local target_cpu=\$1
  local is_debug=\$2
  
  echo "Generating ninja files for target_cpu=\${target_cpu}, is_debug=\${is_debug}..."
  
  mkdir -p "\$ARTIFACTS_DIR/lib/\${target_cpu}"
  
  gn gen "\$OUTPUT_DIR" --root="src" \\
    --args="is_debug=\${is_debug} \\
    is_java_debug=\${is_debug} \\
    target_os=\\\"android\\\" \\
    target_cpu=\\\"\${target_cpu}\\\" \\
    rtc_use_h264=false \\
    rtc_include_tests=false \\
    rtc_build_examples=false \\
    is_component_build=false \\
    use_rtti=true \\
    use_custom_libcxx=false \\
    treat_warnings_as_errors=false \\
    use_errorprone_java_compiler=false \\
    use_cxx17=true"
  check_result "GN generation for \${target_cpu} (debug=\${is_debug})"
}

# Generate for all configurations
generate_ninja "arm64" "true"
generate_ninja "arm64" "false"
generate_ninja "x64" "true"
generate_ninja "x64" "false"

echo "All ninja files generated successfully"
EOF

chmod +x /tmp/gn_generate.sh
/tmp/gn_generate.sh

# Phase 2: Build with ninja (can use either Python version, but use 3.5 to be safe)
echo "Switching to Python 3.5 for building..."
sudo update-alternatives --set python3 /usr/bin/python3.5

# Create a separate script for the build part
cat > /tmp/build_libs.sh << EOF
#!/bin/bash -eu

# Source common variables and functions
source "$COMMON_SCRIPT"

build_lib() {
  local target_cpu=\$1
  local is_debug=\$2
  
  echo "Building static library for target_cpu=\${target_cpu}, is_debug=\${is_debug}..."
  
  ninja -C "\$OUTPUT_DIR" webrtc
  check_result "Ninja build for \${target_cpu} (debug=\${is_debug})"
  
  filename="libwebrtc.a"
  if [ \$is_debug = "true" ]; then
    filename="libwebrtcd.a"
  fi
  
  echo "Copying static library to artifacts directory..."
  cp "\$OUTPUT_DIR/obj/libwebrtc.a" "\$ARTIFACTS_DIR/lib/\${target_cpu}/\${filename}"
  check_result "Copying static library for \${target_cpu} (debug=\${is_debug})"
  
  echo "Build for \${target_cpu} (debug=\${is_debug}) completed"
}

echo "Building WebRTC static libraries..."

# Build for arm64
build_lib "arm64" "true"   # Debug
build_lib "arm64" "false"  # Release

# Build for x64
build_lib "x64" "true"     # Debug
build_lib "x64" "false"    # Release

echo "All WebRTC static libraries built successfully"
EOF

chmod +x /tmp/build_libs.sh
/tmp/build_libs.sh

echo "Build process completed successfully"