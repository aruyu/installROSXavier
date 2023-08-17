#!/bin/bash
#==
#   NOTE      - installROS.sh
#   Author    - Aru
#
#   Edited    - 2023.08.09
#   Github    - https://github.com/aruyu
#   Contact   - vine9151@gmail.com
#
# Install Robot Operating System (ROS) on NVIDIA Jetson AGX Xavier
# Maintainer of ARM builds for ROS is http://answers.ros.org/users/1034/ahendrix/
# Information from:
# http://wiki.ros.org/noetic/Installation/UbuntuARM

# Red is 1
# Green is 2
# Reset is sgr0



T_CO_RED='\e[1;31m'
T_CO_YELLOW='\e[1;33m'
T_CO_GREEN='\e[1;32m'
T_CO_BLUE='\e[1;34m'
T_CO_GRAY='\e[1;30m'
T_CO_NC='\e[0m'

CURRENT_PROGRESS=0

function script_print()
{
  echo -ne "$T_CO_BLUE[SCRIPT]$T_CO_NC$1"
}

function script_print_notify()
{
  echo -ne "$T_CO_BLUE[SCRIPT]$T_CO_NC$T_CO_GREEN-Notify- $1$T_CO_NC"
}

function script_print_error()
{
  echo -ne "$T_CO_BLUE[SCRIPT]$T_CO_NC$T_CO_RED-Error- $1$T_CO_NC"
}

function error_exit()
{
  script_print_error "$1\n\n"
  exit 1
}

function usage()
{
  echo "Usage: ./installROS.sh [[-p package] | [-h]]"
  echo "Install ROS Noetic"
  echo "Installs ros-noetic-ros-base as default base package; Use -p to override"
  echo "-p | --package <packagename>  ROS package to install"
  echo "                              Multiple usage allowed"
  echo "                              Must include one of the following:"
  echo "                               ros-noetic-ros-base"
  echo "                               ros-noetic-desktop"
  echo "                               ros-noetic-desktop-full"
  echo "-h | --help  This message"
}

function should_install_packages()
{
  tput setaf 1
  echo "Your package list did not include a recommended base package"
  tput sgr0
  echo "Please include one of the following:"
  echo "   ros-noetic-ros-base"
  echo "   ros-noetic-desktop"
  echo "   ros-noetic-desktop-full"
  echo ""
  script_print_error "Failed to install ROS.\n\n"
}

function setup_repo()
{
  tput setaf 2
  script_print_notify "Adding repository and source list\n"
  tput sgr0
  sudo apt-add-repository universe
  sudo apt-add-repository multiverse
  sudo apt-add-repository restricted

  # Setup sources.lst
  sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
  # Setup keys
  sudo apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
  # If you experience issues connecting to the keyserver, you can try substituting hkp://pgp.mit.edu:80 or hkp://keyserver.ubuntu.com:80 in the previous command.
}

function install_ros()
{
  tput setaf 2
  script_print_notify "Updating apt-get\n"
  tput sgr0
  sudo apt-get update
  tput setaf 2
  script_print_notify "Installing ROS\n"
  tput sgr0
  # This is where you might start to modify the packages being installed, i.e.
  # sudo apt-get install ros-noetic-desktop

  # Here we loop through any packages passed on the command line
  # Install packages ...
  for package in "${packages[@]}"; do
    sudo apt-get install $package -y
  done
}

function install_rosdep()
{
  # Initialize rosdep
  tput setaf 2
  script_print_notify "Installing rosdep\n"
  tput sgr0
  sudo apt-get install python3-rosdep -y

  tput setaf 2
  script_print_notify "Initializaing rosdep\n"
  tput sgr0
  sudo rosdep init
  # To find available packages, use:
  rosdep update
}

function setup_environment()
{
  # Environment Setup - Don't add /opt/ros/noetic/setup.bash if it's already in bashrc
  grep -q -F 'source /opt/ros/noetic/setup.bash' ~/.bashrc || echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
  source ~/.bashrc
}

function install_tools()
{
  tput setaf 2
  script_print_notify "Installing rosinstall tools\n"
  tput sgr0
  sudo apt-get install python3-rosinstall python3-rosinstall-generator python3-wstool build-essential -y
  tput setaf 2
}




#==
#   Starting codes in blew
#/

if [[ $EUID -eq 0 ]]; then
  error_exit "This script must be run as USER!"
fi


# Iterate through command line inputs
packages=()
while [[ "$1" != "" ]]; do
  case $1 in
    -p | --package )        shift
                            packages+=("$1")
                            ;;
    -h | --help )           usage
                            exit
                            ;;
    * )                     usage
                            exit 1
  esac
  shift
done
# Check to see if other packages were specified
# If not, set the default base package
if [[ ${#packages[@]}  -eq 0 ]]; then
  packages+="ros-noetic-ros-base"
fi
script_print_notify "Packages to install: "${packages[@]}"\n"
# Check to see if we have a ROS base kinda thingie
hasBasePackage=false
for package in "${packages[@]}"; do
  if [[ $package == "ros-noetic-ros-base" ]]; then
    hasBasePackage=true
    break
  elif [[ $package == "ros-noetic-desktop" ]]; then
    hasBasePackage=true
    break
  elif [[ $package == "ros-noetic-desktop-full" ]]; then
    hasBasePackage=true
    break
  fi
done
if [[ $hasBasePackage == false ]]; then
  should_install_packages
  exit 1
fi

# Let's start installing!
setup_repo || error_exit "Setup repository failed."

# ROS Installation
install_ros || error_exit "ROS installation failed."


# Add Individual Packages here
# You can install a specific ROS package (replace underscores with dashes of the package name):
# sudo apt-get install ros-noetic-PACKAGE
# e.g.
# sudo apt-get install ros-noetic-navigation
#
# To find available packages:
# apt-cache search ros-noetic
# 
# Certificates are messed up on earlier version Jetson for some reason
# Do not know if it is an issue with the Xavier, test by commenting out
# sudo c_rehash /etc/ssl/certs
# Initialize rosdep
install_rosdep || error_exit "Installation & initialize rosdep failed."


# Environment Setup
setup_environment || error_exit "Setup environment failed."

# Install rosinstall
install_tools || error_exit "Tools installation failed."

script_print_notify "All successfully done.\n\n"
tput sgr0
