#!/bin/bash
# DNS
change_dns(){
    cmd=(dialog --menu "Network Configuration Tool" 22 76 16)
    options=(
        1 "Temporary"
        2 "Persistent"
        3 "Back"
    )
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    case $choices in
        1)  dns=$(dialog --stdout --inputbox "Enter DNS server (temporary):" 8 40) #Temporary
            if ./dns_validate.sh "$dns"; then
                dialog --msgbox "You entered DNS: $dns" 6 40
                echo "nameserver $dns" > /etc/resolv.conf

            else
                dialog --msgbox "Invalid DNS format. Please try again." 6 40
                change_dns && exit
            fi   ;; 
        2)  dns=$(dialog --stdout --inputbox "Enter DNS server (persistent):" 8 40) #Persistent DNS
            if ./dns_validate.sh "$dns"; then
                dialog --msgbox "You entered DNS: $dns" 6 40
                # Check file is valid
                CONFIG_FILE="/etc/systemd/resolved.conf"
                if [ ! -f "$CONFIG_FILE" ]; then
                    dialog --msgbox "Configuration file $CONFIG_FILE not found!" 6 40
                    change_dns && exit
                fi 
                # Backup configuration
                sudo cp $CONFIG_FILE ${CONFIG_FILE}.bak
                # Update configuration
                sudo sed -i "s/^*DNS=.*DNS=${dns}/" $CONFIG_FILE
                # Restart network services
                sudo systemctl restart systemd-resolved
            else
                dialog --msgbox "Invalid DNS format. Please try again." 6 40
                change_dns && exit
            fi  ;;  
        3) ./configuration_network.sh ;;
    esac
    

}

# Hostname
change_hostname(){
    new_hostname=$(dialog --stdout --inputbox "Enter new hostname:" 8 40)
    hostnamectl set-hostname $new_hostname
    dialog --msgbox "Hostname changed to: $new_hostname" 6 40
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