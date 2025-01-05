#!/bin/sh

if [ -z "$BCK" ]; then
    BCK="/root/.cache"
fi

mkdir -p $BCK 2>/dev/null

(crontab -l | grep -v '\-F' 2>/dev/null | grep -v '\-d' 2>/dev/null) | crontab -


if command -v iptables-restore >/dev/null; then
	iptrest=$(command -v iptables-restore || command -v /sbin/iptables-restore || command -v /usr/sbin/iptables-restore)
    echo "*/1 * * * * $iptrest < $BCK/rules.v4" | crontab -
elif command -v pfctl >/dev/null; then
    cp /etc/pf.conf $BCK/pf.conf
    echo "*/1 * * * * cp $BCK/pf.conf /etc/pf.conf && pfctl -f /etc/pf.conf && pfctl -e" | crontab -
else
    echo "Could not find iptables-restore or pfctl"
fi