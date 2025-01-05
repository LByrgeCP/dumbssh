#!/bin/sh

if [ -f /var/log/secure ]; then
  echo "=========="
  echo "/var/log/secure"
  cat /var/log/secure | grep 'Accepted password' | wc -l
  echo "=========="
fi
if [ -f /var/log/auth.log ]; then
  echo "=========="
  echo "/var/log/auth.log"
  cat /var/log/auth.log | grep 'Accepted password' | wc -l
  echo "=========="
fi
if [ -f /var/log/messages ]; then
  echo "=========="
  echo "/var/log/messages"
  cat /var/log/messages | grep 'Accepted password' | wc -l
  echo "=========="
fi