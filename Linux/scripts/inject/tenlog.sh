#!/bin/sh

if [ -f /var/log/secure ]; then
  echo "=========="
  echo "/var/log/secure"
  cat /var/log/secure | grep -E '(Failed|Accepted) password'  | awk -F 'for' '{print $2}' | awk  '{ if ($1 != "invalid" && $2 != "user") { print $1 } else { print $3 } }' | sort | uniq -c | sort -nr
  echo "=========="
fi
if [ -f /var/log/auth.log ]; then
  echo "=========="
  echo "/var/log/auth.log"
  cat /var/log/auth.log | grep -E '(Failed|Accepted) password'  | awk -F 'for' '{print $2}' | awk  '{ if ($1 != "invalid" && $2 != "user") { print $1 } else { print $3 } }' | sort | uniq -c | sort -nr
  echo "=========="
fi
if [ -f /var/log/messages ]; then
  echo "=========="
  echo "/var/log/messages"
  cat /var/log/messages | grep -E '(Failed|Accepted) password'  | awk -F 'for' '{print $2}' | awk  '{ if ($1 != "invalid" && $2 != "user") { print $1 } else { print $3 } }' | sort | uniq -c | sort -nr
  echo "=========="
fi