#!/bin/bash

get_network_info() {
    NETWORK_INFO=""

    INTERFACES=$(ip -o link show | awk -F': ' '{print $2}')

    for iface in $INTERFACES; do
        STATUS=$(ip link show "$iface" | grep -o 'state [^ ]*' | cut -d' ' -f2)

        TYPE=$(ethtool -i "$iface" | grep "type" | awk '{print $2}')
        if [[ "$TYPE" == "" ]]; then
            TYPE="virtual"
        fi

        SPEED=$(ethtool "$iface" | grep "Speed" | awk '{print $2}' | tr -d 'a-zA-Z')

        NETWORK_INFO+="$iface: Status: $STATUS, Type: $TYPE, Speed: ${SPEED:-N/A}\n"
    done

    echo -e "$NETWORK_INFO"
}

get_traffic_info() {
    TRAFFIC_INFO=""

    INTERFACES=$(ip -o link show | awk -F': ' '{print $2}')

    for iface in $INTERFACES; do
        TRAFFIC_DATA=$(grep "^$iface:" /proc/net/dev | awk '{print $2, $3, $10, $11}')
        RX_BYTES=$(echo $TRAFFIC_DATA | awk '{print $1}')
        RX_PACKETS=$(echo $TRAFFIC_DATA | awk '{print $2}')  
        TX_BYTES=$(echo $TRAFFIC_DATA | awk '{print $3}')  
        TX_PACKETS=$(echo $TRAFFIC_DATA | awk '{print $4}') 

        TRAFFIC_INFO+="$iface: RX: ${RX_BYTES:-0} bytes (${RX_PACKETS:-0} packets), TX: ${TX_BYTES:-0} bytes (${TX_PACKETS:-0} packets)\n"
    done

    echo -e "$TRAFFIC_INFO"
}

get_tcp_udp_info() {
    TCP_CONNECTIONS=$(ss -t | grep ESTAB | wc -l)  
    UDP_PACKETS=$(cat /proc/net/udp | wc -l)  

    echo -e "TCP Connections: $TCP_CONNECTIONS\nUDP Packets Received: $((UDP_PACKETS - 1))"  
}

get_ip_info() {
    IP_INFO=""
    INTERFACES=$(ip -o link show | awk -F': ' '{print $2}')

    for iface in $INTERFACES; do
        IP_ADDRESS=$(ip addr show "$iface" | grep 'inet ' | awk '{print $2}')
        IP_INFO+="$iface: IP Addresses: ${IP_ADDRESS:-None}\n"
    done

    echo -e "$IP_INFO"
}

get_bandwidth_info() {
    INTERFACES=$(ip -o link show | awk -F': ' '{print $2}')
    PREV_RX_BYTES=()
    PREV_TX_BYTES=()

    for iface in $INTERFACES; do
        TRAFFIC_DATA=$(grep "^$iface:" /proc/net/dev | awk '{print $2, $10}')
        PREV_RX_BYTES+=($(echo $TRAFFIC_DATA | awk '{print $1}'))
        PREV_TX_BYTES+=($(echo $TRAFFIC_DATA | awk '{print $2}'))
    done

    while true; do
        sleep 1  
        BANDWIDTH_INFO=""

        for i in "${!INTERFACES[@]}"; do
            iface=${INTERFACES[$i]}
            TRAFFIC_DATA=$(grep "^$iface:" /proc/net/dev | awk '{print $2, $10}')
            RX_BYTES=$(echo $TRAFFIC_DATA | awk '{print $1}')
            TX_BYTES=$(echo $TRAFFIC_DATA | awk '{print $2}')

            RX_BW=$((RX_BYTES - PREV_RX_BYTES[i]))
            TX_BW=$((TX_BYTES - PREV_TX_BYTES[i]))

            PREV_RX_BYTES[i]=$RX_BYTES
            PREV_TX_BYTES[i]=$TX_BYTES

            BANDWIDTH_INFO+="$iface: RX Bandwidth: ${RX_BW:-0} bytes/s, TX Bandwidth: ${TX_BW:-0} bytes/s\n"
        done

        echo -e "$BANDWIDTH_INFO" > /tmp/bandwidth_info.txt
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
        5)     dialog --title "Network Monitoring Tool" --clear --textbox /tmp/bandwidth_info.txt 20 70

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
