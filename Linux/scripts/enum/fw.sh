#!/bin/sh
# KaliPatriot | TTU CCDC | Landon Byrge

if command -v pfctl >/dev/null; then
    pfctl -s rules
    pfctl -s info
else
    ipt=$(command -v iptables || command -v /sbin/iptables || command -v /usr/sbin/iptables)
    if [ -z "$ipt" ]; then
        echo "NO IPTABLES OR PFCTL ON THIS SYSTEM, GOOD LUCK"
        exit 1
    fi
    $ipt -vnL
fi