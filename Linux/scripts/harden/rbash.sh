#!/bin/sh
# @d_tranman/Nigel Gerald/Nigerald

if [ -z "BCK" ]; then
    BCK="/root/.cache"
fi

if [ ! -z "$REVERT" ]; then
    cp $BCK/passwd.bak /etc/passwd
else
    cp /etc/passwd $BCK/passwd.bak
	cp /etc/passwd /etc/passwd.bak
    chmod 644 $BCK/passwd.bak
	chmod 644 /etc/passwd.bak

    if ! which rbash 1> /dev/null 2>& 1 ; then
        ln -sf /bin/bash /bin/rbash
    fi

    if command -v bash 1> /dev/null 2>& 1 ; then
        head -1 /etc/passwd > /etc/pw
        sed -n '1!p' /etc/passwd | sed 's/\/bin\/.*sh$/\/bin\/rbash/g' >> /etc/pw
        mv /etc/pw /etc/passwd
        chmod 644 /etc/passwd
    fi
fi
