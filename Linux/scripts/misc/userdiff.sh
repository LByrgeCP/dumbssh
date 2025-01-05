#!/bin/sh

if [ -z "$BCK" ]; then
    BCK="/root/.cache"
fi

BCK=$BCK/initial

diff /etc/passwd $BCK/users
diff /etc/group $BCK/groups