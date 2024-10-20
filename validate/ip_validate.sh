#!/bin/bash

ip="$1"
# Regex For IP Address. 
if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    IFS='.' read -r -a octets <<< "$ip"
    if (( octets[0] <= 255 && octets[1] <= 255 && octets[2] <= 255 && octets[3] <= 255 )); then
        exit 0 # Valid
    else
        exit 1 # Invalid
    fi
else
    exit 1
fi