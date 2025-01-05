#!/bin/sh
# thanks @d_tranman/Nigel Gerald/Nigerald
# KaliPatriot was here, but can someone tell me what the hell is going on here?

ipt=$(command -v iptables || command -v /sbin/iptables || command -v /usr/sbin/iptables)
IS_BSD=false

if command -v pkg >/dev/null || command -v pkg_info >/dev/null; then
    IS_BSD=true
fi

ALLOW() {
    if [ "$IS_BSD" = true ]; then
        pfctl -d
        pfctl -F all
    else
        $ipt -P INPUT ACCEPT; $ipt -P OUTPUT ACCEPT ; $ipt -P FORWARD ACCEPT ; $ipt -F; $ipt -X
    fi
}

CHECKERR() {
    if [ ! $? -eq 0 ]; then
        echo "ERROR, EXITTING TO PREVENT LOCKOUT"
        ALLOW
        exit 1
    fi
}

if [ -z "$ipt" ] && [ "$IS_BSD" = false ]; then
    echo "NO IPTABLES ON THIS SYSTEM, NOT BSD, GOOD LUCK"
    exit 1
fi

if [ -z "$DISPATCHER" ]; then
    echo "DISPATCHER not defined."
    exit 1
fi

if [ -z "$LOCALNETWORK" ]; then
    echo "LOCALNETWORK not defined."
    exit 1
fi

if [ -z "$CCSHOST" ] && [ -z "$NOTNATS" ]; then
    echo "CCSHOST not defined and WE ARE AT NATS BRO!"
    exit 1
fi

if [ -z "$BCK" ]; then
    BCK="/root/.cache"
else 
    mkdir -p $BCK 2>/dev/null
fi

if [ -f /etc/ufw/ufw.conf ]; then
    ufw disable
fi

if [ -f /etc/firewalld/firewalld.conf ]; then
    systemctl stop firewalld
    systemctl disable firewalld
fi

if [ ! -z "$ipt" ]; then
    iptables-save > /opt/rules.v4
    iptables-save > $BCK/rules.v4.old
    ALLOW

    $ipt -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    $ipt -A OUTPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

    if [ -n "$CCSHOST" ]; then
        $ipt -A OUTPUT -d $CCSHOST -j ACCEPT
        CHECKERR
        $ipt -A INPUT -s $CCSHOST -j ACCEPT
        CHECKERR
    fi

    # Allow local network
    $ipt -A INPUT -s $LOCALNETWORK -j ACCEPT
    CHECKERR
    $ipt -A OUTPUT -d $LOCALNETWORK -j ACCEPT
    CHECKERR

    # Allow loopback
    $ipt -A INPUT -i lo -j ACCEPT
    CHECKERR
    $ipt -A OUTPUT -o lo -j ACCEPT
    CHECKERR

    # Allow in SSH from dispatcher
    $ipt -A INPUT -s $DISPATCHER -p tcp --dport 22 -j ACCEPT
    CHECKERR
    $ipt -A OUTPUT -d $DISPATCHER -p tcp --sport 22 -j ACCEPT
    CHECKERR


    # create a cron job to open the firewall every 5 minutes
    (crontab -l 2>/dev/null; echo "*/5 * * * * $ipt -P INPUT ACCEPT; $ipt -P OUTPUT ACCEPT ; $ipt -P FORWARD ACCEPT ; $ipt -F") | crontab -

    # Block everything else
    $ipt -P INPUT DROP
    CHECKERR
    $ipt -P OUTPUT DROP
    CHECKERR
    $ipt -P FORWARD DROP
    CHECKERR

    # Save rules
    iptables-save > /opt/rules.v4
    iptables-save > $BCK/rules.v4
elif [ "$IS_BSD" = true ]; then
    ALLOW

    mv /etc/pf.conf "$BCK/pf.conf.old"

    echo "set skip on lo" > /etc/pf.conf

    for i in $(echo "$DISPATCHER" | tr ',' ' '); do
        echo "pass in quick proto tcp from $i to any port 22" >> /etc/pf.conf
    done

    for i in $(echo "$LOCALNETWORK" | tr ',' ' '); do
        echo "pass in quick from $i to any" >> /etc/pf.conf
        echo "pass out quick from any to $i" >> /etc/pf.conf
    done

    for i in $(echo "$CCSHOST" | tr ',' ' '); do
        echo "pass out quick from any to $i" >> /etc/pf.conf
        echo "pass in quick from $i to any" >> /etc/pf.conf
    done

    echo "block all" >> /etc/pf.conf

    cat /etc/pf.conf

    (crontab -l 2>/dev/null; echo "*/5 * * * * pfctl -d") | crontab -

    kldload pf
    pfctl -f /etc/pf.conf
    pfctl -e
fi