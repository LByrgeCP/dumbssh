#!/bin/sh

if [ -z "$BCK" ]; then
    BCK="/root/.cache"
fi

BCK=$BCK/initial
cat /etc/snoopy.ini

if [ -n "$LAST" ] && [ "$LAST" -eq "$LAST" ] 2>/dev/null && [ "$LAST" -gt 0 ]; then
    tail -n "$LAST" "$BCK/snoopy.log"
else
    cat "$BCK/snoopy.log"
fi