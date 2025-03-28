#!/bin/bash

# Install clang 11
wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key|sudo apt-key add -
sudo apt-add-repository "deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-11 main"
sudo apt update
sudo apt install -y clang-11 lld-11

# Install stdlibc++9 for support GLIBCXX_3.4.26
sudo add-apt-repository ppa:ubuntu-toolchain-r/test
sudo apt update
sudo apt install -y g++-9
sudo ln -sf g++-9 /usr/bin/g++

# Install other packages
sudo apt install -y vulkan-utils libvulkan1 libvulkan-dev libglfw3-dev ninja-build

# Install glad2
sudo pip install git+https://github.com/dav1dde/glad.git@glad2#egg=glad2

# Install CUDA SDK
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-ubuntu1604.pin
sudo mv cuda-ubuntu1604.pin /etc/apt/preferences.d/cuda-repository-pin-600
sudo apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub
sudo apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/ /"
sudo apt update
sudo apt install -y cuda-toolkit-11-0

# Install CMake 3.22.3
sudo apt install -y libssl-dev
sudo apt purge -y cmake
wget https://github.com/Kitware/CMake/releases/download/v3.24.3/cmake-3.24.3.tar.gz
tar xvf cmake-3.24.3.tar.gz
cd cmake-3.24.3
./bootstrap && make && sudo make install
