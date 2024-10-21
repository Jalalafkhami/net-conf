#!/bin/bash

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

get_network_info() {
    NETWORK_INFO=""

    interface=$(select_interface)

    STATUS=$(ip link show "$interface" | grep -o 'state [^ ]*' | cut -d' ' -f2)

    TYPE=$(ethtool -i "$interface" | grep "type" | awk '{print $2}')
    if [[ "$TYPE" == "" ]]; then
        TYPE="virtual"
    fi

    SPEED=$(ethtool "$interface" | grep "Speed" | awk '{print $2}' | tr -d 'a-zA-Z')

    NETWORK_INFO+="$interface: Status: $STATUS, Type: $TYPE, Speed: ${SPEED:-N/A}\n"

    dialog --msgbox "net info : $NETWORK_INFO" 8 40
    dialog --title "Exit" --yesno "Do you want to refresh the network info?" 7 60
    if [ $? -ne 0 ]; then
        ./monitoring.sh && exit
    else
        get_network_info && exit
    fi
}

get_traffic_info() {
    TRAFFIC_INFO=""

    interface=$(select_interface)

    TRAFFIC_DATA=$(cat /proc/net/dev| grep "$interface"  | awk '{print $2, $3, $10, $11}')
    RX_BYTES=$(echo $TRAFFIC_DATA | awk '{print $1}') # Input bytes
    RX_PACKETS=$(echo $TRAFFIC_DATA | awk '{print $2}')  # Input Pacets
    TX_BYTES=$(echo $TRAFFIC_DATA | awk '{print $3}')  # Output bytes
    TX_PACKETS=$(echo $TRAFFIC_DATA | awk '{print $4}') # 

    TRAFFIC_INFO+="$interface:\n RX: ${RX_BYTES:-0} bytes (${RX_PACKETS:-0} packets)\n TX: ${TX_BYTES:-0} bytes (${TX_PACKETS:-0} packets)\n"

    dialog --msgbox "Traffic info :\n $TRAFFIC_INFO" 12 60
    dialog --title "Exit" --yesno "Do you want to refresh the network info?" 7 60
    if [ $? -ne 0 ]; then
        ./monitoring.sh && exit
    else
        get_traffic_info && exit
    fi
}

get_tcp_udp_info() {
    TCP_CONNECTIONS=$(ss -t | grep ESTAB | wc -l)  
    UDP_PACKETS=$(cat /proc/net/udp | wc -l)  
    dialog --msgbox "TCP Connection: $TCP_CONNECTIONS\nUDP Packets Received: $((UDP_PACKETS -1))" 8 40
    dialog --title "Exit" --yesno "Do you want to refresh the network info?" 7 60
    if [ $? -ne 0 ]; then
        ./monitoring.sh && exit
    else
        get_tcp_udp_info && exit
    fi
}

get_ip_info() {
    IP_INFO=""
    interface=$(select_interface)

    IP_ADDRESS=$(ip addr show "$interface" | grep 'inet ' | awk '{print $2}')
    IP_INFO+="$interface: IP Addresses: ${IP_ADDRESS:-None}\n"

    dialog --msgbox "IP info : $IP_INFO" 8 40
    dialog --title "Exit" --yesno "Do you want to refresh the IP info?" 7 60
    if [ $? -ne 0 ]; then
        ./monitoring.sh && exit
    else
        get_ip_info && exit
    fi
}

get_bandwidth_info() {
    INTERFACES=$(ip -o link show | awk -F': ' '{print $2}')
    PREV_RX_BYTES=()
    PREV_TX_BYTES=()

    for iface in $INTERFACES; do
        TRAFFIC_DATA=$(cat /proc/net/dev | grep "$iface" | awk '{print $2, $10}')
        PREV_RX_BYTES+=($(echo $TRAFFIC_DATA | awk '{print $1}'))
        PREV_TX_BYTES+=($(echo $TRAFFIC_DATA | awk '{print $2}'))
    done

    while true; do
        sleep 1  
        BANDWIDTH_INFO=""

        for i in "${!INTERFACES[@]}"; do
            iface=${INTERFACES[$i]}
            TRAFFIC_DATA=$(cat /proc/net/dev | grep "$iface" | awk '{print $2, $10}')
            RX_BYTES=$(echo $TRAFFIC_DATA | awk '{print $1}')
            TX_BYTES=$(echo $TRAFFIC_DATA | awk '{print $2}')

            RX_BW=$((RX_BYTES - PREV_RX_BYTES[i]))
            TX_BW=$((TX_BYTES - PREV_TX_BYTES[i]))

            PREV_RX_BYTES[i]=$RX_BYTES
            PREV_TX_BYTES[i]=$TX_BYTES

            BANDWIDTH_INFO+="$iface: RX Bandwidth: ${RX_BW:-0} bytes/s, TX Bandwidth: ${TX_BW:-0} bytes/s\n"
        done

        echo -e "$BANDWIDTH_INFO" > ./tmp/bandwidth_info.txt
    done
}
# Running in Background
get_bandwidth_info & 

show_menu() {
    cmd=(dialog --menu "Monitoring" 22 76 16)
    options=(
        1 "Network Info"
        2 "Traffic Info"
        3 "TCP/UDP Info"
        4 "IP Info"
        5 "BandWidth Info(Real-Time)"
        6 "Back"
    )

    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
    case $choices in
        1) get_network_info ;;
        2) get_traffic_info ;;
        3) get_tcp_udp_info ;;
        4) get_ip_info ;;
        5)  while true; do
                OUTPUT="$(cat ./tmp/bandwidth_info.txt)"
                dialog --title "Network Monitoring Tool" --clear --msgbox "$OUTPUT" 20 70
                if [ $? -ne 0 ]; then
                    break 
                fi
            done
            dialog --title "Exit" --yesno "Do you want to refresh the network info?" 7 60
            if [ $? -ne 0 ]; then
                break 
            fi
            ;;
        6) ./main.sh && exit ;;
    esac
}

while true; do
    show_menu
done
