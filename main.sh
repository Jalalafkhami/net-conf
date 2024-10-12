#!/bin/bash

choice=$(dialog --stdout --menu "Choose an option" 15 50 3 \
    1 "Network Configuration" \
    2 "Exit"
)

case $choice in
    1) ./configuration_network.sh ;;
    2) exit 0 ;;
esac