#!/bin/sh

if [ -z "$BCK" ]; then
    BCK="/root/.cache"
fi

BCK=$BCK/initial

# check our ports
if command -v sockstat >/dev/null ; then
    LIST_CMD="sockstat -l"
    ESTB_CMD="sockstat -46c"
elif command -v netstat >/dev/null ; then
    LIST_CMD="netstat -tulpn"
    ESTB_CMD="netstat -tupwn"
elif command -v ss >/dev/null ; then
    LIST_CMD="ss -blunt -p"
    ESTB_CMD="ss -buntp"
else 
    echo "No netstat, sockstat or ss found"
    LIST_CMD="echo 'No netstat, sockstat or ss found'"
    ESTB_CMD="echo 'No netstat, sockstat or ss found'"
fi

$LIST_CMD > /tmp/listen
$ESTB_CMD > /tmp/estab

echo "Listen ports diff:"
diff $BCK/listen /tmp/listen
echo "=================="
echo "Established ports diff:"
diff $BCK/estab /tmp/estab

rm /tmp/listen
rm /tmp/estab
