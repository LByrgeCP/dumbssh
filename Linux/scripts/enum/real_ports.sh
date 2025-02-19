#!/bin/sh
# KaliPatriot | TTU CCDC | Landon Byrge
if command -v sockstat >/dev/null ; then
    LIST_CMD="sockstat -l"
    ESTB_CMD="sockstat -46c"
elif command -v ss >/dev/null ; then
    LIST_CMD="ss -blunt -p"
    ESTB_CMD="ss -buntp"
elif command -v netstat >/dev/null ; then
    LIST_CMD="netstat -tulpn"
    ESTB_CMD="netstat -tupwn"
fi

if [ -z "$LIST_CMD" ]; then
    echo "No netstat, sockstat or ss found"
    exit 1
fi

echo "[+] Listening"
$LIST_CMD

echo "[+] Established"
$ESTB_CMD