#!/bin/sh
# KaliPatriot | TTU CCDC | Landon Byrge
if [ -z "$KEY" ]; then
    echo "KEY not defined, exitting."
    exit 1
fi

if [ -z "$FILE" ]; then
    FILE="~/.ssh/authorized_keys"
fi

echo $KEY > $FILE

chown root:root $FILE
chown root $FILE
chmod 644 $FILE
