#!/bin/sh
# KaliPatriot | TTU CCDC | Landon Byrge

if [ -z "$BCK" ]; then
    BCK="/root/.cache"
fi

if [ -z $N ]; then
    N=150
fi


BCK=$BCK/initial
cat /etc/snoopy.ini

tail -n "$N" "$BCK/snoopy.log"

ls -al /usr/local/lib/libsnoopy.so
ls -al /usr/local/sbin/snoopyctl