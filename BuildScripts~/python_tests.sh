#!/bin/bash

# 1. Make sure you are in the correct directory (containing depot_tools)
# cd /home/ubuntu/fresh_unity_webrtc/com.unity.webrtc 

# 2. Ensure depot_tools is in the PATH for this session
export PATH="$(pwd)/depot_tools:$PATH"

# 3. Explicitly bootstrap/verify the internal Python environment
echo "--- Bootstrapping/Verifying vpython3 ---"
./depot_tools/vpython3 -c "import sys; print(f'vpython3 check: OK - Python {sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.minor}')" || echo "vpython3 check: FAILED"
echo "----------------------------------------"

# 4. Check gclient
echo "--- Checking gclient ---"
./depot_tools/gclient --version || echo "gclient check: FAILED"
echo "------------------------"

# 5. Check fetch (often wraps gclient)
echo "--- Checking fetch ---"
./depot_tools/fetch --help > /dev/null || echo "fetch check: FAILED (Note: --help used, output discarded)" # --version might not exist
echo "(fetch check successful if no FAILED message)"
echo "--------------------"

# 6. Check gn
echo "--- Checking gn ---"
./depot_tools/gn --version || echo "gn check: FAILED"
# You can also try 'gn help' which might use Python more internally
./depot_tools/gn help > /dev/null || echo "gn help check: FAILED (Output discarded)"
echo "(gn checks successful if no FAILED messages)"
echo "-------------------"

# 7. Check ninja
echo "--- Checking ninja ---"
./depot_tools/ninja --version || echo "ninja check: FAILED"
echo "----------------------"

# 8. Check cipd (used internally by vpython3/gclient)
echo "--- Checking cipd ---"
./depot_tools/cipd --version || echo "cipd check: FAILED"
echo "---------------------"

# 9. Final Check: which python3 (to see what the PATH finds by default)
echo "--- Checking 'which python3' (default PATH resolution) ---"
which python3
echo "--------------------------------------------------------"