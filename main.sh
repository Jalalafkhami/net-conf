#!/bin/bash
# Add Theme for Dialog
export DIALOGRC=./Theme/sourcemage.rc

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root: Permission denied"
  exit
fi

# Menu  
choice=$(dialog --stdout --menu "Choose an option" 15 50 3 \
    1 "Network Configuration" \
    2 "Nftables" \
    3 "Manage OVS" \
    4 "Exit" 
)

case $choice in
    1) ./configuration_network.sh ;;
    2) ./nftables.sh ;;
    3) ./ovs.sh ;;
    4) exit 0 ;;
esac