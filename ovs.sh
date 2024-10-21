#!/bin/bash

# show Bridges
list_bridges() {
    BRIDGES=$(ovs-vsctl list-br)
    if [ -n "$BRIDGES" ]; then
        dialog --msgbox "Available OVS Bridges:\n$BRIDGES" 10 40
    else
        dialog --msgbox "No OVS Bridges found." 6 40
    fi
}
# Add Bridge
add_bridge() {
    BRIDGE_NAME=$(dialog --inputbox "Enter new bridge name:" 8 40 3>&1 1>&2 2>&3 3>&-)
    if [ -n "$BRIDGE_NAME" ]; then
        ovs-vsctl add-br $BRIDGE_NAME
        dialog --msgbox "Bridge $BRIDGE_NAME created!" 6 40
    else
        dialog --msgbox "No bridge name entered." 6 40
    fi
}

# Remove Bridge
del_bridge() {
    BRIDGE_NAME=$(dialog --inputbox "Enter bridge name to delete:" 8 40 3>&1 1>&2 2>&3 3>&-)
    if [ -n "$BRIDGE_NAME" ]; then
        ovs-vsctl del-br $BRIDGE_NAME
        dialog --msgbox "Bridge $BRIDGE_NAME deleted!" 6 40
    else
        dialog --msgbox "No bridge name entered." 6 40
    fi
}

# Add Port for each bridge
add_port() {
    BRIDGE_NAME=$(dialog --inputbox "Enter bridge name:" 8 40 3>&1 1>&2 2>&3 3>&-)
    if [ -n "$BRIDGE_NAME" ]; then
        PORT_NAME=$(dialog --inputbox "Enter port name to add:" 8 40 3>&1 1>&2 2>&3 3>&-)
        if [ -n "$PORT_NAME" ]; then
            ovs-vsctl add-port $BRIDGE_NAME $PORT_NAME
            dialog --msgbox "Port $PORT_NAME added to bridge $BRIDGE_NAME!" 6 40
        else
            dialog --msgbox "No port name entered." 6 40
        fi
    else
        dialog --msgbox "No bridge name entered." 6 40
    fi
}

# Remove Port for each bridge
del_port() {
    BRIDGE_NAME=$(dialog --inputbox "Enter bridge name:" 8 40 3>&1 1>&2 2>&3 3>&-)
    if [ -n "$BRIDGE_NAME" ]; then
        PORT_NAME=$(dialog --inputbox "Enter port name to delete:" 8 40 3>&1 1>&2 2>&3 3>&-)
        if [ -n "$PORT_NAME" ]; then
            ovs-vsctl del-port $BRIDGE_NAME $PORT_NAME
            dialog --msgbox "Port $PORT_NAME deleted from bridge $BRIDGE_NAME!" 6 40
        else
            dialog --msgbox "No port name entered." 6 40
        fi
    else
        dialog --msgbox "No bridge name entered." 6 40
    fi
}

# Disable Port
disable_port() {
    PORT_NAME=$(dialog --inputbox "Enter port name to disable:" 8 40 3>&1 1>&2 2>&3 3>&-)
    if [ -n "$PORT_NAME" ]; then
        ip link set $PORT_NAME down
        dialog --msgbox "Port $PORT_NAME disabled!" 6 40
    else
        dialog --msgbox "No port name entered." 6 40
    fi
}

# Enable Port 
enable_port() {
    PORT_NAME=$(dialog --inputbox "Enter port name to enable:" 8 40 3>&1 1>&2 2>&3 3>&-)
    if [ -n "$PORT_NAME" ]; then
        ip link set $PORT_NAME up
        dialog --msgbox "Port $PORT_NAME enabled!" 6 40
    else
        dialog --msgbox "No port name entered." 6 40
    fi
}

# Set Access port
set_access_port() {
    PORT_NAME=$(dialog --inputbox "Enter port name to configure as Access Port:" 8 40 3>&1 1>&2 2>&3 3>&-)
    if [ -n "$PORT_NAME" ]; then
        VLAN_ID=$(dialog --inputbox "Enter VLAN ID for Access Port:" 8 40 3>&1 1>&2 2>&3 3>&-)
        if [ -n "$VLAN_ID" ]; then
            ovs-vsctl set port $PORT_NAME tag=$VLAN_ID
            dialog --msgbox "Port $PORT_NAME set as Access Port for VLAN $VLAN_ID!" 6 40
        else
            dialog --msgbox "No VLAN ID entered." 6 40
        fi
    else
        dialog --msgbox "No port name entered." 6 40
    fi
}

# Set Trunk Port
set_trunk_port() {
    PORT_NAME=$(dialog --inputbox "Enter port name to configure as Trunk Port:" 8 40 3>&1 1>&2 2>&3 3>&-)
    if [ -n "$PORT_NAME" ]; then
        VLAN_IDS=$(dialog --inputbox "Enter VLAN IDs for Trunk Port (comma separated):" 8 40 3>&1 1>&2 2>&3 3>&-)
        if [ -n "$VLAN_IDS" ]; then
            ovs-vsctl set port $PORT_NAME trunks=$VLAN_IDS
            dialog --msgbox "Port $PORT_NAME set as Trunk Port for VLANs $VLAN_IDS!" 6 40
        else
            dialog --msgbox "No VLAN IDs entered." 6 40
        fi
    else
        dialog --msgbox "No port name entered." 6 40
    fi
}

# Show Ports
show_ports() {
    # نام بریج OVS
    BRIDGE_NAME=$(dialog --inputbox "Enter the OVS Bridge name to show ports:" 8 40 3>&1 1>&2 2>&3 3>&-)

    if [ -n "$BRIDGE_NAME" ]; then
        PORTS=$(ovs-vsctl list port | grep -B2 -E "name|tag|ofport" | grep -A2 "$BRIDGE_NAME")

        if [ -n "$PORTS" ]; then
            dialog --msgbox "Ports on Bridge $BRIDGE_NAME:\n\n$PORTS" 15 60
        else
            dialog --msgbox "No ports found on bridge $BRIDGE_NAME." 6 40
        fi
    else
        dialog --msgbox "Bridge name cannot be empty." 6 40
    fi
}

# Create Vlan
create_vlan() {
    # نام بریج OVS
    BRIDGE_NAME=$(dialog --inputbox "Enter the OVS Bridge name:" 8 40 3>&1 1>&2 2>&3 3>&-)
    
    # VLAN ID
    VLAN_ID=$(dialog --inputbox "Enter VLAN ID (e.g., 100):" 8 40 3>&1 1>&2 2>&3 3>&-)
    
    # نام اینترفیس VLAN (اختیاری)
    VLAN_NAME=$(dialog --inputbox "Enter VLAN Interface Name (optional, e.g., vlan100):" 8 40 3>&1 1>&2 2>&3 3>&-)

    if [ -n "$BRIDGE_NAME" ] && [ -n "$VLAN_ID" ]; then
        # ساخت اینترفیس VLAN
        if [ -n "$VLAN_NAME" ]; then
            # اگر نام اینترفیس مشخص شده باشد، آن را با نام دلخواه ایجاد می‌کنیم
            ovs-vsctl add-port $BRIDGE_NAME $VLAN_NAME -- set interface $VLAN_NAME type=internal
            ovs-vsctl set port $VLAN_NAME tag=$VLAN_ID
            dialog --msgbox "VLAN $VLAN_ID created on bridge $BRIDGE_NAME with interface $VLAN_NAME!" 6 60
        else
            # اگر نام اینترفیس مشخص نشده باشد، از VLAN ID به عنوان نام استفاده می‌کنیم
            VLAN_NAME="vlan$VLAN_ID"
            ovs-vsctl add-port $BRIDGE_NAME $VLAN_NAME -- set interface $VLAN_NAME type=internal
            ovs-vsctl set port $VLAN_NAME tag=$VLAN_ID
            dialog --msgbox "VLAN $VLAN_ID created on bridge $BRIDGE_NAME with interface $VLAN_NAME!" 6 60
        fi
    else
        dialog --msgbox "Bridge name or VLAN ID cannot be empty." 6 40
    fi
}

# Delete Vlan
delete_vlan() {
    # نام بریج OVS
    BRIDGE_NAME=$(dialog --inputbox "Enter the OVS Bridge name to delete VLAN from:" 8 40 3>&1 1>&2 2>&3 3>&-)

    # نام یا ID VLAN
    VLAN_NAME=$(dialog --inputbox "Enter the VLAN Interface Name or VLAN ID to delete:" 8 40 3>&1 1>&2 2>&3 3>&-)

    if [ -n "$BRIDGE_NAME" ] && [ -n "$VLAN_NAME" ]; then
        # حذف VLAN
        if ovs-vsctl --if-exists del-port "$BRIDGE_NAME" "$VLAN_NAME"; then
            dialog --msgbox "VLAN $VLAN_NAME deleted from bridge $BRIDGE_NAME!" 6 60
        else
            dialog --msgbox "Failed to delete VLAN $VLAN_NAME from bridge $BRIDGE_NAME. Please check if it exists." 6 60
        fi
    else
        dialog --msgbox "Bridge name and VLAN name cannot be empty." 6 40
    fi
}

# show Vlan interface
show_vlans() {
    # نام بریج OVS
    BRIDGE_NAME=$(dialog --inputbox "Enter the OVS Bridge name to show VLANs:" 8 40 3>&1 1>&2 2>&3 3>&-)

    if [ -n "$BRIDGE_NAME" ]; then
        VLAN_LIST=$(ovs-vsctl list port | grep -E "name|tag" | grep -B1 "$BRIDGE_NAME")

        if [ -n "$VLAN_LIST" ]; then
            dialog --msgbox "VLANs on Bridge $BRIDGE_NAME:\n\n$VLAN_LIST" 15 50
        else
            dialog --msgbox "No VLANs found on bridge $BRIDGE_NAME." 6 40
        fi
    else
        dialog --msgbox "Bridge name cannot be empty." 6 40
    fi
}

# setup vlan IP
set_vlan_ip() {
    VLAN_NAME=$(dialog --inputbox "Enter VLAN Interface Name (e.g., vlan100):" 8 40 3>&1 1>&2 2>&3 3>&-)
    if [ -n "$VLAN_NAME" ]; then
        IP_ADDR=$(dialog --inputbox "Enter IP Address (e.g., 192.168.100.1/24):" 8 40 3>&1 1>&2 2>&3 3>&-)
        if [ -n "$IP_ADDR" ]; then
            ip addr add $IP_ADDR dev $VLAN_NAME
            ip link set dev $VLAN_NAME up
            dialog --msgbox "IP $IP_ADDR set on VLAN interface $VLAN_NAME!" 6 40
        else
            dialog --msgbox "No IP Address entered." 6 40
        fi
    else
        dialog --msgbox "No VLAN Interface Name entered." 6 40
    fi
}

# delete vlan IP
del_vlan_ip() {
    VLAN_NAME=$(dialog --inputbox "Enter VLAN Interface Name (e.g., vlan100):" 8 40 3>&1 1>&2 2>&3 3>&-)
    if [ -n "$VLAN_NAME" ]; then
        IP_ADDR=$(dialog --inputbox "Enter IP Address to Remove (e.g., 192.168.100.1/24):" 8 40 3>&1 1>&2 2>&3 3>&-)
        if [ -n "$IP_ADDR" ]; then
            ip addr del $IP_ADDR dev $VLAN_NAME
            dialog --msgbox "IP $IP_ADDR removed from VLAN interface $VLAN_NAME!" 6 40
        else
            dialog --msgbox "No IP Address entered." 6 40
        fi
    else
        dialog --msgbox "No VLAN Interface Name entered." 6 40
    fi
}

# show menu Add and Remove Bridge 
show_menu_add_remove_bridge(){
    choice=$(dialog --stdout --menu "Select an option:" 15 50 3 \
    1 "Add Bridge" \
    2 "Delete Bridge" \
    3 "Back")

  case $choice in
    1) add_bridge ;;
    2) del_bridge ;;
    3) show_menu ;;
    *) show_menu ;;
  esac
}

# show menu manage Port
show_menu_port(){
    choice=$(dialog --stdout --menu "Select an option:" 15 50 3 \
    1 "Add Port" \
    2 "Remove Port" \
    3 "Enable Port" \
    4 "Disable Port" \
    5 "Access Port" \
    6 "Trunk Port" \
    7 "Show Port" \
    7 "Back")

  case $choice in
    1) add_port ;;
    2) del_port ;;
    3) enable_port ;;
    4) disable_port ;;
    5) set_access_port ;;
    6) set_trunk_port ;;
    7) show_ports ;;
    8) show_menu ;;
    *) show_menu ;;
  esac
}

# show menu vlan
show_menu_vlan(){
    choice=$(dialog --stdout --menu "Select an option:" 15 50 3 \
    1 "Create Vlan" \
    2 "Delete Vlan" \
    3 "Set Vlan IP" \
    4 "Delete Vlan IP" \
    5 "Show Vlans" \
    6 "Back")

    case $choice in
    1) create_vlan ;;
    2) delete_vlan;;
    3) set_vlan_ip ;;
    4) del_vlan_ip ;;
    5) show_vlans ;;
    6) show_menu ;;
    *) show_menu ;;
    esac
}
# show main menu
show_menu() {
    cmd=(dialog --menu "Network Configuration Tool" 22 76 16)
    options=(
        1 "Show List of Bridge"
        2 "Add or Delete Bridge"
        3 "Manage Port"
        4 "Manage Vlan"
        5 "Back"
    )

    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    case $choices in
        1) list_bridges ;;
        2) show_menu_add_remove_bridge ;;
        3) show_menu_port ;;
        4) show_menu_vlan ;;
        5) ./main.sh && exit ;;
    esac
}

while true; do
    show_menu
done
