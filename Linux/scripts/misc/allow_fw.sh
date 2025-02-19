#!/bin/sh
# KaliPatriot | TTU CCDC | Landon Byrge
if command -v pfctl >/dev/null; then
    pfctl -d
    pfctl -F all
else
    ipt=$(command -v iptables || command -v /sbin/iptables || command -v /usr/sbin/iptables)
    if [ -z "$ipt" ]; then
        echo "NO IPTABLES OR PFCTL ON THIS SYSTEM, GOOD LUCK"
        exit 1
    fi
    $ipt -P INPUT ACCEPT; $ipt -P OUTPUT ACCEPT ; $ipt -P FORWARD ACCEPT ; $ipt -F; $ipt -X
fi