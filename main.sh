#!/bin/bash

choice=$(dialog --stdout --menu "Choose an option" 15 50 3 \
    1 "Exit"
)

case $choice in
    1) exit 0 ;;
esac