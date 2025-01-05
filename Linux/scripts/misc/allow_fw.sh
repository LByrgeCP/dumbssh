#!/bin/sh
if command -v pkg >/dev/null || command -v pkg_info >/dev/null; then
    pfctl -d
    pfctl -F all
else
    ipt=$(command -v iptables || command -v /sbin/iptables || command -v /usr/sbin/iptables)
    $ipt -P INPUT ACCEPT; $ipt -P OUTPUT ACCEPT ; $ipt -P FORWARD ACCEPT ; $ipt -F; $ipt -X
fi