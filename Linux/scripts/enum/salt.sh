#!/bin/sh
# KaliPatriot | TTU CCDC | Landon Byrge

MINION=false
MASTER=false

if [ -f /etc/salt/minion ]; then
    MINION=true
fi

if [ -f /etc/salt/master ]; then
    MASTER=true
fi

if [ "$MINION" = false ] && [ "$MASTER" = false ]; then
    echo "SaltStack is not installed."
    exit 1
fi

if [ "$MINION" = true ]; then
    echo "Salt Minion is installed."
    echo "Checking for master configuration..."
    cat /etc/salt/minion | grep "^\s*[^#]"
    cat /etc/salt/minion.d/master.conf | grep "^\s*[^#]"
    cat /etc/salt/minion_id
    echo "Salt DNS (salt):"
    nslookup salt || dig salt
    echo "Salt DNS (salt.salt):"
    nslookup salt.salt || dig salt.salt
fi

if [ "$MASTER" = true ]; then
    echo "Salt Master is installed."
    echo "Accepted Keys:"
    salt-key -L
    echo "Master Configuration:"
    cat /etc/salt/master | grep "^\s*[^#]"
    cat /etc/salt/master.d/master.conf | grep "^\s*[^#]"
    echo "Existing Salt Files:"
    ls -alR /srv/salt
    echo "Minion Status:"
    salt-run manage.status
    salt '*' test.ping
fi