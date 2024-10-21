#!/bin/bash

################################################################################################
# display the access control menu
show_access_control_menu() {
  choice=$(dialog --stdout --menu "Select an option:" 15 50 3 \
    1 "Connection Tracking Rule" \
    2 "TCP/UDP Filter Rule" \
    3 "ICMP Filter Rule" \
    4 "Back")

  case $choice in
    1) create_connection_tracking_rule ;;
    2) create_tcp_udp_filter_rule ;;
    3) create_icmp_filter_rule ;;
    4) show_menu ;;
    *) show_menu ;;
  esac
}
################################################################################################
# display the NAT menu
show_nat_menu() {
  choice=$(dialog --stdout --menu "Select an option:" 15 50 2 \
    1 "Masquerade Rule" \
    2 "DNAT Rule" \
    3 "Back")

  case $choice in
    1) create_masquerade_rule ;;
    2) create_dnat_rule ;;
    3) show_menu ;;
    *) show_menu ;;
  esac
}
########################################### CREATE TEMPLATE #####################################################
# create connection tracking rule (ct state {established/related/invalid/new} {accept/drop/reject} )
create_connection_tracking_rule() {
  state_choice=$(dialog --stdout --menu "Select Connection State:" 15 60 4 \
    1 "established" \
    2 "related" \
    3 "invalid" \
    4 "new" \
    5 "Back")

  case $state_choice in
    1) state="established" ;;
    2) state="related" ;;
    3) state="invalid" ;;
    4) state="new" ;;
    5) show_access_control_menu && exit ;;
    *) show_access_control_menu && exit ;;
  esac

  action_choice=$(dialog --stdout --menu "Select Action:" 15 60 4 \
    1 "accept" \
    2 "drop" \
    3 "reject" \
    4 "Back")

  case $action_choice in
    1) action="accept" ;;
    2) action="drop" ;;
    3) action="reject" ;;
    4) create_connection_tracking_rule && exit ;;
    *) show_access_control_menu && exit ;;
  esac

  nft add rule inet filter input ct state $state $action
  dialog --msgbox "Rule added: ct state $state -> $action" 6 50
  show_access_control_menu
}

# create TCP/UDP filter rule (ip saddr SOURCE ip daddr DEST {udp/tcp} dport DEST_PORT {accept/reject/drop} )
create_tcp_udp_filter_rule() {
  source_ip=$(dialog --stdout --inputbox "Enter Source IP:" 8 40)
  if ./validate/ip_validate.sh "$source_ip"; then
    continue
  else
    dialog --msgbox "Invalid IP address. Please try again." 6 50
    show_access_control_menu && exit
  fi
  dest_ip=$(dialog --stdout --inputbox "Enter Destination IP:" 8 40)
  if ./validate/ip_validate.sh "$dest_ip"; then
    continue
  else
    dialog --msgbox "Invalid IP address. Please try again." 6 50
    create_tcp_udp_filter_rule && exit
  fi
  port=$(dialog --stdout --inputbox "Enter Destination Port:" 8 40)

  protocol_choice=$(dialog --stdout --menu "Select Protocol:" 10 40 2 \
    1 "TCP" \
    2 "UDP")

  case $protocol_choice in
    1) protocol="tcp" ;;
    2) protocol="udp" ;;
  esac

  action_choice=$(dialog --stdout --menu "Select Action:" 10 40 3 \
    1 "accept" \
    2 "drop" \
    3 "reject")

  case $action_choice in
    1) action="accept" ;;
    2) action="drop" ;;
    3) action="reject" ;;
  esac

  nft add rule inet filter input ip saddr $source_ip ip daddr $dest_ip $protocol dport $port $action
  dialog --msgbox "Rule added: $source_ip -> $dest_ip on port $port ($protocol) -> $action" 6 50
  show_access_control_menu
}

# create ICMP filter rule (ip saddr SOURCE ip daddr DEST ip protocol icmp type {echo-request/destination-unreachable} {accept/drop})
create_icmp_filter_rule() {
  source_ip=$(dialog --stdout --inputbox "Enter Source IP:" 8 40)
  if ./validate/ip_validate.sh "$source_ip"; then
    continue
  else
    dialog --msgbox "Invalid IP address. Please try again." 6 50
    create_tcp_udp_filter_rule && exit
  fi
  dest_ip=$(dialog --stdout --inputbox "Enter Destination IP:" 8 40)
  if ./validate/ip_validate.sh "$dest_ip"; then
    continue
  else
    dialog --msgbox "Invalid IP address. Please try again." 6 50
    create_tcp_udp_filter_rule && exit
  fi

  icmp_type_choice=$(dialog --stdout --menu "Select ICMP Type:" 10 40 2 \
    1 "echo-request" \
    2 "destination-unreachable")

  case $icmp_type_choice in
    1) icmp_type="echo-request" ;;
    2) icmp_type="destination-unreachable" ;;
  esac

  action_choice=$(dialog --stdout --menu "Select Action:" 10 40 3 \
    1 "accept" \
    2 "drop")

  case $action_choice in
    1) action="accept" ;;
    2) action="drop" ;;
  esac

  nft add rule inet filter input ip saddr $source_ip ip daddr $dest_ip ip protocol icmp icmp type $icmp_type $action
  dialog --msgbox "Rule added: ICMP from $source_ip to $dest_ip type $icmp_type -> $action" 6 50
  show_access_control_menu
}

# create Masquerade rule (ip saddr SOURCE ip dadde DEST masquerade)
create_masquerade_rule() {
  source_ip=$(dialog --stdout --inputbox "Enter Source IP:" 8 40)
  if ./validate/ip_validate.sh "$source_ip"; then
    continue
  else
    dialog --msgbox "Invalid IP address. Please try again." 6 50
    create_tcp_udp_filter_rule && exit
  fi

  dest_ip=$(dialog --stdout --inputbox "Enter Destination IP:" 8 40)
  if ./validate/ip_validate.sh "$dest_ip"; then
    continue
  else
    dialog --msgbox "Invalid IP address. Please try again." 6 50
    create_tcp_udp_filter_rule && exit
  fi

  nft add rule ip nat POSTROUTING ip saddr $source_ip ip daddr $dest_ip masquerade
  dialog --msgbox "Masquerade rule added for $source_ip to $dest_ip" 6 50
  show_nat_menu
}

# create DNAT rule (ip saddr SOURCE ip daddr DEST tcp dport PORT dnat to IP:PORT)
create_dnat_rule() {
  source_ip=$(dialog --stdout --inputbox "Enter Source IP:" 8 40)
  if ./validate/ip_validate.sh "$source_ip"; then
    continue
  else
    dialog --msgbox "Invalid IP address. Please try again." 6 50
    create_tcp_udp_filter_rule && exit
  fi
  
  dest_ip=$(dialog --stdout --inputbox "Enter Destination IP:" 8 40)
   if ./validate/ip_validate.sh "$dest_ip"; then
    continue
  else
    dialog --msgbox "Invalid IP address. Please try again." 6 50
    create_tcp_udp_filter_rule && exit
  fi 

  port=$(dialog --stdout --inputbox "Enter Destination Port:" 8 40)
  target_ip=$(dialog --stdout --inputbox "Enter Target IP:" 8 40)
  if ./validate/ip_validate.sh "$target_ip"; then
    continue
  else
    dialog --msgbox "Invalid IP address. Please try again." 6 50
    create_tcp_udp_filter_rule && exit
  fi

  target_port=$(dialog --stdout --inputbox "Enter Target Port:" 8 40)

  nft add rule ip nat PREROUTING ip saddr $source_ip ip daddr $dest_ip tcp dport $port dnat to $target_ip:$target_port
  dialog --msgbox "DNAT rule added: $dest_ip:$port -> $target_ip:$target_port" 6 50
  show_nat_menu
}
# show menu and choice
show_menu() {
  choice=$(dialog --stdout --menu "Select an option:" 15 50 3 \
    1 "Access Control Rules" \
    2 "NAT Rules" \
    3 "Back")

  case $choice in
    1) show_access_control_menu ;;
    2) show_nat_menu ;;
    3) ./main.sh && exit ;;
  esac
}

while true; do
    show_menu
done