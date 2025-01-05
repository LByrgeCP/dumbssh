#!/bin/sh
# @d_tranman/Nigel Gerald/Nigerald
sys=$(command -v service || command -v systemctl)
FILE=/etc/ssh/sshd_config
RC=/etc/rc.d/rc.sshd

if [ -f "$FILE" ]; then
    SED="sed -i''"
    if sed --version >/dev/null 2>&1; then
        SED="sed -i"
    fi
    $SED 's/^AllowTcpForwarding/# AllowTcpForwarding/' "$FILE"
    echo 'AllowTcpForwarding no' >> "$FILE"
    $SED 's/^X11Forwarding/# X11Forwarding/' "$FILE"
    echo 'X11Forwarding no' >> "$FILE"
    if [ ! -z "$NOPUB" ]; then
        $SED 's/^PubkeyAuthentication/# PubkeyAuthentication/' "$FILE"
        echo 'PubkeyAuthentication no' >> "$FILE"
    fi
    if [ ! -z "$AUTHKEY" ]; then
        $SED 's/^AuthorizedKeysFile/# AuthorizedKeysFile/' "$FILE"
        echo "AuthorizedKeysFile $AUTHKEY" >> "$FILE"
    fi
    if [ ! -z "$PERMITUSERS" ]; then
        $SED 's/^AllowUsers/# AllowUsers/' "$FILE"
        echo "AllowUsers $PERMITUSERS" >> "$FILE"
    fi
    if [ ! -z "$ROOTPUB" ]; then
        $SED 's/^PubkeyAuthentication/# PubkeyAuthentication/' "$FILE"
        echo 'PubkeyAuthentication no' >> "$FILE"
        echo 'Match User root' >> "$FILE"
        echo '    PubkeyAuthentication yes' >> "$FILE"
    fi

else
    echo "Could not find sshd config"
fi


if [ -z $sys ]; then
  if [ -f "/etc/rc.d/sshd" ]; then
    RC="/etc/rc.d/sshd"
  else
    RC="/etc/rc.d/rc.sshd"
  fi
  $RC restart
else
  $sys restart ssh || $sys ssh restart || $sys restart sshd || $sys sshd restart 
fi
