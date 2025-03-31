#!/bin/bash -eu
# https://chrisjean.com/fix-apt-get-update-the-following-signatures-couldnt-be-verified-because-the-public-key-is-not-available/

# Setup logging - redirect all output to both console and file
LOG_FILE="setup_env.log"
# Clear previous log file
> "$LOG_FILE"
# Redirect stdout and stderr to both console and file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting environment setup at $(date '+%Y-%m-%d %H:%M:%S')"

Install pkg-config, zip
sudo apt install -y pkg-config zip
sudo apt install -y openjdk-8-jdk git patch

# Download Android NDK r21b
wget https://dl.google.com/android/repository/android-ndk-r21b-linux-x86_64.zip

# Unzip the downloaded NDK file to home directory
unzip android-ndk-r21b-linux-x86_64.zip -d ~/

Set Android NDK root path to `ANDROID_NDK` environment variable
echo "export ANDROID_NDK=~/android-ndk-r21b/" >> ~/.profile


# Install clang 11
echo "Installing Clang 11..."
wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key|sudo apt-key add -
sudo apt-add-repository "deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-11 main"
sudo apt update
sudo apt install -y clang-11 lld-11

# Install stdlibc++9 for support GLIBCXX_3.4.26
echo "Installing g++-9..."
sudo add-apt-repository ppa:ubuntu-toolchain-r/test
sudo apt update
sudo apt install -y g++-9
sudo ln -sf g++-9 /usr/bin/g++

# Install other packages
echo "Installing other packages..."
sudo apt install -y vulkan-utils libvulkan1 libvulkan-dev libglfw3-dev ninja-build

# Install pip for Python 3
echo "Installing pip..."
sudo apt install -y python3-pip

# Upgrade pip and setuptools
echo "Upgrading pip and setuptools..."
sudo pip3 install --upgrade pip setuptools

# Install glad2
echo "Installing glad2..."
sudo pip3 install glad2

# Install CUDA SDK
echo "Installing CUDA SDK..."
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin
sudo mv cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600
sudo apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub
sudo apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/ /"
sudo apt update
sudo apt install -y cuda-toolkit-11-0

# Install CMake 3.22.3
echo "Installing CMake 3.22.3..."
sudo apt install -y libssl-dev
sudo apt purge -y cmake
wget https://github.com/Kitware/CMake/releases/download/v3.24.3/cmake-3.24.3.tar.gz
tar xvf cmake-3.24.3.tar.gz
cd cmake-3.24.3
./bootstrap && make && sudo make install

echo "Environment setup completed at $(date '+%Y-%m-%d %H:%M:%S')"
