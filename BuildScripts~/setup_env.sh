#!/bin/bash -eu
# https://chrisjean.com/fix-apt-get-update-the-following-signatures-couldnt-be-verified-because-the-public-key-is-not-available/

# Setup logging - redirect all output to both console and file
LOG_FILE="setup_env.log"
# Clear previous log file
> "$LOG_FILE"
# Redirect stdout and stderr to both console and file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting environment setup at $(date '+%Y-%m-%d %H:%M:%S')"

# Install pkg-config, zip
sudo apt install -y pkg-config zip

# Download Android NDK r21b
wget https://dl.google.com/android/repository/android-ndk-r21b-linux-x86_64.zip

# Unzip the downloaded NDK file to home directory
unzip android-ndk-r21b-linux-x86_64.zip -d ~/

# Set Android NDK root path to `ANDROID_NDK` environment variable
echo "export ANDROID_NDK=~/android-ndk-r21b/" >> ~/.profile


# Install clang 11
echo "Installing Clang 11..."
wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key|sudo apt-key add -
sudo apt-add-repository "deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-11 main"
sudo apt update
sudo apt install -y clang-11 lld-11

# Install stdlibc++9 for support GLIBCXX_3.4.26
sudo add-apt-repository ppa:ubuntu-toolchain-r/test
sudo apt update
sudo apt install -y gcc-9-base libgcc1=1:9.4.0-1ubuntu1~16.04 libgomp1=9.4.0-1ubuntu1~16.04 libitm1=9.4.0-1ubuntu1~16.04 libatomic1=9.4.0-1ubuntu1~16.04 liblsan0=9.4.0-1ubuntu1~16.04 libtsan0=9.4.0-1ubuntu1~16.04 libquadmath0=9.4.0-1ubuntu1~16.04 libstdc++6=9.4.0-1ubuntu1~16.04 libcc1-0=9.4.0-1ubuntu1~16.04 libgcc-9-dev libstdc++-9-dev gcc-9 g++-9
sudo ln -sf g++-9 /usr/bin/g++

# Install other packages
echo "Installing additional dependencies..."
sudo apt install -y vulkan-utils libvulkan1 libvulkan-dev libglfw3-dev ninja-build curl gnupg

# Install Python 3.8 and pip
echo "Installing Python 3.8..."
sudo apt install -y python3.8 python3.8-dev python3.8-distutils
echo "Installing pip for Python 3.8..."
curl -sS https://bootstrap.pypa.io/get-pip.py | sudo python3.8
echo "Installing glad2..."
sudo -H python3.8 -m pip install git+https://github.com/dav1dde/glad.git@glad2#egg=glad2

# Install CUDA SDK
echo "Installing CUDA SDK..."
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-ubuntu1604.pin
sudo mv cuda-ubuntu1604.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub
sudo apt-key add 7fa2af80.pub
sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/ /"

echo "Updating package lists..."
sudo apt update
echo "Installing CUDA toolkit..."
sudo apt install -y cuda-toolkit-11-0

# Install CMake 3.22.3
echo "Installing CMake dependencies..."
sudo apt install -y libssl-dev
sudo apt purge -y cmake

echo "Downloading and building CMake..."
wget https://github.com/Kitware/CMake/releases/download/v3.24.3/cmake-3.24.3.tar.gz
tar xvf cmake-3.24.3.tar.gz
cd cmake-3.24.3

# Set compiler flags for CMake bootstrap
export CC=gcc
export CXX=g++
export CXXFLAGS="-std=c++11"

echo "Building CMake with CC=$CC, CXX=$CXX, CXXFLAGS=$CXXFLAGS"
./bootstrap && make && sudo make install

echo "Environment setup completed at $(date '+%Y-%m-%d %H:%M:%S')"
