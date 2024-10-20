#!/bin/bash

ip_netmask="$1"

if [[ "$ip_netmask" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]{1,2})$ ]]; then
    IFS='/' read -r ip netmask <<< "$ip_netmask" # برای جدا کردن ip از netmask 
    IFS='.' read -r -a octets <<< "$ip" 
    if (( octets[0] <= 255 && octets[1] <= 255 && octets[2] <= 255 && octets[3] <= 255 )); then
        if (( netmask >= 0 && netmask <= 32 )); then
            exit 0 
        else
            exit 1 
        fi
    else
        exit 1 
    fi
else
    exit 1 
fi                    