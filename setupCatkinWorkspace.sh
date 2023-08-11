#!/bin/bash
#==
#   NOTE      - setupCatkinWorkspace.sh
#   Author    - Aru
#
#   Edited    - 2023.08.09
#   Github    - https://github.com/aruyu
#   Contact   - vine9151@gmail.com
#
# Create a Catkin Workspace and setup ROS environment variables
# Usage setupCatkinWorkspace.sh dirName



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

function setup_workspace()
{
  #source /opt/ros/noetic/setup.bash
  eval "$(cat /opt/ros/noetic/setup.bash)"

  echo "$DEFAULTDIR"/src
  mkdir -p "$DEFAULTDIR"/src
  cd "$DEFAULTDIR"/src
  catkin_init_workspace
  cd "$DEFAULTDIR"
  catkin_make
}

function setup_enviroments()
{
  grep -q -F ' ROS_MASTER_URI' ~/.bashrc ||  echo 'export ROS_MASTER_URI=http://localhost:11311' | tee -a ~/.bashrc
  grep -q -F ' ROS_IP' ~/.bashrc ||  echo "export ROS_IP=$(hostname -I)" | tee -a ~/.bashrc
  echo "export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH" >> ~/.bashrc
  eval "$(cat ~/.bashrc | tail -n +10)"
}




#==
#   Starting codes in blew
#/

if [[ $EUID -eq 0 ]]; then
  error_exit "This script must be run as USER!"
fi


DEFAULTDIR=~/catkin_ws
CLDIR="$1"

if [ ! -z "$CLDIR" ]; then 
  DEFAULTDIR=~/"$CLDIR"
fi
if [ -e "$DEFAULTDIR" ] ; then
  error_exit "$DEFAULTDIR already exists; No action taken."
else 
  script_print_notify "Creating Catkin Workspace: $DEFAULTDIR\n"
fi


#setup ROS Workspace
setup_workspace || error_exit "Setup ROS workspace failed."

#setup ROS Environment variables
setup_enviroments || error_exit "Setup ROS environment failed."

script_print "The Catkin Workspace has been created.\n"
script_print "Please modify the placeholders for ROS_MASTER_URI and ROS_IP placed into the file ${HOME}/.bashrc\n"
script_print "to suit your environment.\n"
script_print_notify "All successfully done.\n\n"
