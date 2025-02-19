#!/bin/sh
# KaliPatriot | TTU CCDC | Landon Byrge

if [ -z $N ]; then
    N=150
fi

if [ -f /var/log/secure ]; then
    echo "=========="
    echo "/var/log/secure"
    tail -n $N /var/log/secure
    if [ -z $SESSION ]; then
        cat /var/log/secure | grep "$SESSION"
    fi
    echo "=========="
fi
if [ -f /var/log/auth.log ]; then
    echo "=========="
    echo "/var/log/auth.log"
    tail -n $N /var/log/auth.log
    if [ -z $SESSION ]; then
        cat /var/log/auth.log | grep "$SESSION"
    fi
  echo "=========="
fi
if [ -f /var/log/messages ]; then
    echo "=========="
    echo "/var/log/messages"
    tail -n $N /var/log/messages
    if [ -z $SESSION ]; then
        cat /var/log/messages | grep "$SESSION"
    fi
    echo "=========="
fi