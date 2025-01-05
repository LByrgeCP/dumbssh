#!/bin/sh
if command -v pkg >/dev/null || command -v pkg_info >/dev/null; then
    pfctl -s rules
    pfctl -s info
else
    ipt=$(command -v iptables || command -v /sbin/iptables || command -v /usr/sbin/iptables)
    $ipt -L
fi