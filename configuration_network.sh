#!/bin/bash
# DNS
change_dns(){
    dns=$(dialog --stdout --inputbox "Enter DNS server (temporary):" 8 40)
    dialog --msgbox "You entered DNS: $dns" 6 40
    echo "nameserver $dns" > /etc/resolv.conf

}

# Hostname
change_hostname(){
    new_hostname=$(dialog --stdout --inputbox "Enter new hostname:" 8 40)
    hostnamectl set-hostname $new_hostname

}

# IP Static

# show menu and choice
show_menu() {
    cmd=(dialog --menu "Network Configuration Tool" 22 76 16)
    options=(
        1 "Change DNS"
        2 "Change Hostname"
        3 "Change IP (static)"
        4 "Get IP from DHCP"
        5 "Add route"
        6 "Remove route"
        7 "‌Back"
    )

    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    case $choices in
        1) change_dns ;;
        2) change_hostname ;;
        3) change_ip_static ;;
        4) dhclient eth0 ;;
        5) add_route ;;
        6) remove_route ;;
        7) ./main.sh && exit ;;
    esac
}

while true; do
    show_menu
done