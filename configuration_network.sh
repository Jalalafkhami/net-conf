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
                dialog --msgbox "You entered DNS: $dns" 6 40
                echo "nameserver $dns" > /etc/resolv.conf

            else
                dialog --msgbox "Invalid DNS format. Please try again." 6 40
                change_dns && exit
            fi   ;; 
        2)  dns=$(dialog --stdout --inputbox "Enter DNS server (permanent):" 8 40) #Permanent DNS
            if ./validate/dns_validate.sh "$dns"; then
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
    # جمع‌آوری لیست اینترفیس‌ها
    interfaces=$(ip -o link show | awk -F': ' '{print $2}')

    # آماده‌سازی فرمت برای dialog
    menu=""
    i=1
    for iface in $interfaces; do
        menu="$menu $i $iface"
        i=$((i + 1))
    done

    # نمایش منوی اینترفیس‌ها با dialog و دریافت انتخاب کاربر
    selected_iface=$(dialog --menu "Select Interface" 15 50 10 $menu 2>&1 >/dev/tty)
    exit_status=$?
    if [ $exit_status -ne 0 ]; then
        # اگر کاربر Cancel یا ESC را زده باشد
        echo "" 
    else
        selected_interface=$(echo "$interfaces" | sed -n "${selected_iface}p")
    
       # بازگشت نام اینترفیس انتخاب شده
        echo $selected_interface
    fi
    
    # تبدیل شماره انتخاب شده به نام اینترفیس
    
}
change_ip_static() {
    cmd=(dialog --menu "Change IP Static" 22 76 16)
    options=(
        1 "Temporary"
        2 "Persistent"
        3 "Back"
    )
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    case $choices in
        1) # Temporarily
            interface=$(select_interface)
            if [ -n "$interface" ]; then
                ip=$(dialog --inputbox "Enter IP address (e.g., 192.168.1.100/24):" 8 40 2>&1 >/dev/tty)
                if ./validate/ip_netmask.sh "$ip"; then
                    ip addr add $ip dev $interface
                    dialog --msgbox "Temporary IP set for $interface: $ip" 6 40
                else
                    dialog --msgbox "Invalid IP format. Please try again." 6 40
                    change_ip_static && exit
                fi
            else
                dialog --msgbox "No interface selected!" 6 40
                change_ip_static && exit
            fi
         ;;
        2) # Permanently
            interface=$(select_interface)
            if [ -n "$interface" ]; then
                ip=$(dialog --inputbox "Enter IP address (e.g., 192.168.1.100/24):" 8 40 2>&1 >/dev/tty)
                if ./validate/ip_netmask.sh "$ip"; then
                    # Check OS
                    if [ -f /etc/network/interfaces ]; then
                        # Debian/Ubuntu
                        sudo sed -i "/iface $interface inet static/!b;n;c\\address $ip" /etc/network/interfaces
                        dialog --msgbox "Permanent IP set for $interface: $ip" 6 40
                    elif [ -f /etc/sysconfig/network-scripts/ifcfg-$interface ]; then
                        # CentOS/RHEL
                        sudo sed -i "s/^IPADDR=.*/IPADDR=$ip/" /etc/sysconfig/network-scripts/ifcfg-$interface
                        dialog --msgbox "Permanent IP set for $interface: $ip" 6 40
                    else
                        dialog --msgbox "Network configuration not supported" 6 40
                    fi
                else
                    dialog --msgbox "Invalid IP format. Please try again." 6 40
                    change_ip_static && exit
                fi
            else
                dialog --msgbox "No interface selected!" 6 40
                change_ip_static && exit
            fi
         ;;
        3) ./configuration_network.sh ;;
    esac
}
############################################################################################
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