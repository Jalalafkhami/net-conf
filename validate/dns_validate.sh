#!/bin/bash

dns="$1"
# Regex For IP Address. Example: 4.2.2.4
if [[ "$dns" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    IFS='.' read -r -a octets <<< "$dns"
    if (( octets[0] <= 255 && octets[1] <= 255 && octets[2] <= 255 && octets[3] <= 255 )); then
        exit 0 # Valid
    else
        exit 1 # Invalid
    fi
# Regex For Domain. Example: example.com
elif [[ "$dns" =~ ^(([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,})$ ]]; then
    exit 0  # Valid
else
    exit 1 # Invalid
fi
