#!/bin/bash
################################################################################################
# DNS
change_dns(){
    cmd=(dialog --menu "Change DNS" 22 76 16)
    options=(
        1 "Temporary DNS"
        2 "Permanent DNS"
        3 "Back"
    )
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    case $choices in
        1)  dns=$(dialog --stdout --inputbox "Enter DNS server (temporary):" 8 40) #Temporary DNS
            if ./validate/dns_validate.sh "$dns"; then
                dialog --msgbox "You entered DNS: $dns" 8 40
                echo "nameserver $dns" > /etc/resolv.conf

            else
                dialog --msgbox "Invalid DNS format. Please try again." 8 40
                change_dns && exit
            fi   ;; 
        2)  dns=$(dialog --stdout --inputbox "Enter DNS server (permanent):" 8 40) #Permanent DNS
            if ./validate/dns_validate.sh "$dns"; then
                dialog --msgbox "You entered DNS: $dns" 8 40
                # Check file is valid
                CONFIG_FILE="/etc/systemd/resolved.conf"
                if [ ! -f "$CONFIG_FILE" ]; then
                    dialog --msgbox "Configuration file $CONFIG_FILE not found! (apt install resolvconf)" 8 40
                    change_dns && exit
                fi 
                # Backup configuration
                sudo cp $CONFIG_FILE ${CONFIG_FILE}.bak
                # Update configuration
                sudo sed -i "s/^*DNS=.*DNS=${dns}/" $CONFIG_FILE
                # Restart network services
                sudo systemctl restart systemd-resolved
            else
                dialog --msgbox "Invalid DNS format. Please try again." 8 40
                change_dns && exit
            fi  ;;  
        3) ./configuration_network.sh && exit;;
    esac
    

}
################################################################################################
# Hostname
change_hostname(){
    new_hostname=$(dialog --stdout --inputbox "Enter new hostname:" 8 40)
    if [ -n "$new_hostname" ]; then
        hostnamectl set-hostname $new_hostname
        dialog --msgbox "Hostname changed to: $new_hostname" 6 40
    else
        dialog --msgbox "Hostname not entry" 6 40
    fi
}
################################################################################################
# IP Static

# Select Interface
select_interface() {
    interfaces=$(ip -o link show | awk -F': ' '{print $2}')

    menu=""
    i=1
    for iface in $interfaces; do
        menu="$menu $i $iface"
        i=$((i + 1))
    done

    selected_iface=$(dialog --menu "Select Interface" 15 50 10 $menu 2>&1 >/dev/tty)
    exit_status=$?
    if [ $exit_status -ne 0 ]; then
        echo "" 
    else
        selected_interface=$(echo "$interfaces" | sed -n "${selected_iface}p")
    
        echo $selected_interface
    fi
    
    
}
change_ip_static() {
    cmd=(dialog --menu "Change IP Static" 22 76 16)
    options=(
        1 "Temporary IP"
        2 "Permanent IP"
        3 "Back"
    )
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    case $choices in
        1)
            interface=$(select_interface)
            if [ -n "$interface" ]; then
                ip=$(dialog --stdout --inputbox "Enter IP address (example 192.168.1.1/24):" 8 40)
                if ./validate/ip_netmask_validate.sh "$ip"; then
                    ip addr add $ip dev $interface
                    dialog --msgbox "Temporary IP set for $interface: $ip" 8 40
                else
                    dialog --msgbox "Invalid IP format. Please try again." 8 40
                    change_ip_static && exit
                fi
            else
                dialog --msgbox "No interface selected!" 8 40
                change_ip_static && exit
            fi
         ;;
        2)
            interface=$(select_interface)
            if [ -n "$interface" ]; then
                ip=$(dialog --stdout --inputbox "Enter IP address (example 192.168.1.1/24):" 8 40)
                if ./validate/ip_netmask_validate.sh "$ip"; then
                    # Check OS
                    if [ -f /etc/network/interfaces ]; then
                        # Debian/Ubuntu
                        sed -i "/iface $interface inet static/!b;n;c\\address $ip" /etc/network/interfaces
                        dialog --msgbox "Permanent IP set for $interface: $ip" 8 40
                    elif [ -f /etc/sysconfig/network-scripts/ifcfg-$interface ]; then
                        # CentOS/RHEL
                        sed -i "s/^IPADDR=.*/IPADDR=$ip/" /etc/sysconfig/network-scripts/ifcfg-$interface
                        dialog --msgbox "Permanent IP set for $interface: $ip" 8 40
                    else
                        dialog --msgbox "Network configuration not supported" 8 40
                    fi
                else
                    dialog --msgbox "Invalid IP format. Please try again." 8 40
                    change_ip_static && exit
                fi
            else
                dialog --msgbox "No interface selected!" 8 40
                change_ip_static && exit
            fi
         ;;
        3) ./configuration_network.sh && exit;;
    esac
}
###############################################################################################
# Show Route Table
show_route_table() {
    interface=$(select_interface)

    if [ -z "$interface" ]; then
        dialog --msgbox "No interface specified!" 8 40
    else
        ROUTE_TABLE=$(ip route show dev "$interface")
        if [ -z "$ROUTE_TABLE" ]; then
            dialog --msgbox "No routes found for $interface" 8 40
        else
            dialog --msgbox "$ROUTE_TABLE" 15 50
        fi
    fi
}
# Add Route
add_route() {
    cmd=(dialog --menu "Add IP Route" 22 76 16)
    options=(
        1 "Temporary"
        2 "Permanent"
        3 "Back"
    )
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    case $choices in
        1)
            ip=$(dialog --stdout --inputbox "Enter the destination network (example:192.168.1.0/24):" 8 40)
            if ./validate/ip_netmask_validate.sh "$ip"; then
                continue
            else
                dialog --msgbox "Invalid IP format. Please try again." 8 40
                add_route && exit
            fi   
            gateway=$(dialog --stdout --inputbox "Enter gateway (example: 192.168.1.1):" 8 40)
            if ./validate/ip_validate.sh "$gateway"; then
                continue
            else
                dialog --msgbox "Invalid IP format. Please try again." 8 40
                add_route && exit
            fi
            interface=$(select_interface)
            if [ -n "$interface" ]; then
                ip route add "$ip" via "$gatway" dev "$interface"
                if [ $? -eq 0 ]; then
                    dialog --msgbox "Temporary route added successfully to $CONFIG_FILE!" 8 40
                else
                    dialog --msgbox "Failed to add Temporary route. Maybe Nexthop has invalid gateway." 8 40
                    add_route && exit
                fi
            else
                dialog --msgbox "No interface selected!" 8 40
                add_route && exit
            fi
            ;;
        2)
            ip=$(dialog --stdout --inputbox "Enter the destination network (example:192.168.1.0/24):" 8 40)
            if ./validate/ip_netmask_validate.sh "$ip"; then
                continue
            else
                dialog --msgbox "Invalid IP format. Please try again." 8 40
                add_route && exit
            fi   
            gateway=$(dialog --stdout --inputbox "Enter gateway (example: 192.168.1.1):" 8 40)
            if ./validate/ip_validate.sh "$gateway"; then
                continue
            else
                dialog --msgbox "Invalid IP format. Please try again." 8 40
                add_route && exit
            fi
            interface=$(select_interface)
            if [ -n "$interface" ]; then
              # Check OS
                if [ -f /etc/network/interfaces ]; then
                    # Debian/Ubuntu
                    echo "uo rote add -net $ip gw $gateway dev $interface"| tee -a "/etc/network/interfaces" > /dev/null
                    dialog --msgbox "Permanent IP set for $interface: $ip" 8 40
                elif [ -f /etc/sysconfig/network-scripts/ifcfg-$interface ]; then
                    # CentOS/RHEL
                    echo "uo rote add -net $ip gw $gateway dev $interface"| tee -a "/etc/sysconfig/network-scripts/ifcfg-$interface" > /dev/null
                    dialog --msgbox "Permanent IP set for $interface: $ip" 8 40
                else
                    dialog --msgbox "Network configuration not supported" 8 40
                fi
                if [ $? -eq 0 ]; then
                    dialog --msgbox "Permanent route added successfully to $CONFIG_FILE!" 8 40
                else
                    dialog --msgbox "Failed to add permanent route. Maybe Nexthop has invalid gateway." 8 40
                fi
            else
                dialog --msgbox "No interface selected!" 8 40
                remove_route && exit
            fi
            ;;
        3) ./configuration_network.sh && exit;;
    esac
}
###############################################################################################
# Remove route
remove_route() {
    cmd=(dialog --menu "Remove IP Route" 22 76 16)
    options=(
        1 "Show Route Table"
        2 "Temporary"
        3 "Permanent"
        4 "Back"
    )
        choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    case $choices in
        1) show_route_table ; remove_route ;;
        2) 
            ip=$(dialog --stdout --inputbox "Enter the destination network (example:192.168.1.0/24):" 8 40)
            if ./validate/ip_netmask_validate.sh "$ip"; then
                continue
            else
                dialog --msgbox "Invalid IP format. Please try again." 8 40
                add_route && exit
            fi   
            gateway=$(dialog --stdout --inputbox "Enter gateway (example: 192.168.1.1):" 8 40)
            if ./validate/ip_validate.sh "$gateway"; then
                continue
            else
                dialog --msgbox "Invalid IP format. Please try again." 8 40
                add_route && exit
            fi
            interface=$(select_interface)
            if [ -n "$interface" ]; then
                ip route del "$ip" via "$gatway" dev "$interface"
                if [ $? -eq 0 ]; then
                    dialog --msgbox "Temporary route deleted successfully!" 8 40
                else
                    dialog --msgbox "Failed to delete temporary route." 8 40
                    remove_route && exit
                fi
            else
                dialog --msgbox "No interface selected!" 8 40
                add_route && exit
            fi
            ;;
        3)
            ip=$(dialog --stdout --inputbox "Enter the destination network (example:192.168.1.0/24):" 8 40)
            if ./validate/ip_netmask_validate.sh "$ip"; then
                continue
            else
                dialog --msgbox "Invalid IP format. Please try again." 8 40
                add_route && exit
            fi   
            gateway=$(dialog --stdout --inputbox "Enter gateway (example: 192.168.1.1):" 8 40)
            if ./validate/ip_validate.sh "$gateway"; then
                continue
            else
                dialog --msgbox "Invalid IP format. Please try again." 8 40
                add_route && exit
            fi
            interface=$(select_interface)
            if [ -n "$interface" ]; then
              # Check OS
                if [ -f /etc/network/interfaces ]; then
                    # Debian/Ubuntu
                    sed -i "/up route add -net $ip gw $interface dev $interface/d" "/etc/network/interfaces"
                    dialog --msgbox "Route Deleted!" 8 40
                elif [ -f /etc/sysconfig/network-scripts/ifcfg-$interface ]; then
                    # CentOS/RHEL
                    sed -i "/up route add -net $ip gw $gateway dev $interface/d" "/etc/sysconfig/network-scripts/ifcfg-$interface"
                    dialog --msgbox "Route Deleted!" 8 40
                else
                    dialog --msgbox "Network configuration not supported" 8 40
                fi
                if [ $? -eq 0 ]; then
                    dialog --msgbox "Permanent route deleted successfully from $CONFIG_FILE!" 8 40
                else
                    dialog --msgbox "Failed to delete permanent route." 8 40
                    add_route && exit
                fi
            else
                dialog --msgbox "No interface selected!" 8 40
                add_route && exit
            fi
            ;;
        4) ./configuration_network.sh && exit;;
    esac
}
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