#!/bin/sh
# thanks @d_tranman/Nigel Gerald/Nigerald
# Kalipatriot!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
sys=$(command -v service || command -v systemctl)
FILE=/etc/ssh/sshd_config
RC=/etc/rc.d/rc.sshd

if [ -f $FILE ]; then
    SED="sed -i''"  # Default for BSD
    if sed --version >/dev/null 2>&1; then
        SED="sed -i"  # Override for GNU sed
    fi
	$SED 's/^PermitRootLogin/# PermitRootLogin/' $FILE; echo 'PermitRootLogin yes' >> $FILE
else
	echo "[!] Could not find sshd config"
fi

if [ -z $sys ]; then
	if [ -f "/etc/rc.d/sshd" ]; then
		RC="/etc/rc.d/sshd"
	else
		RC="/etc/rc.d/rc.sshd"
	fi
	$RC restart
else
	systemctl daemon-reload 2>/dev/null
	$sys restart ssh || $sys ssh restart || $sys restart sshd || $sys sshd restart 2>/dev/null
	if [ $? -eq 0 ]; then
		echo "[+] SSH service restarted successfully."
	else
		echo "[!] SSH service failed to restart."
	fi
fi

## if sshd -T contains PermitRootLogin yes, then we're good
if sshd -T | grep -iq "PermitRootLogin yes"; then
  echo "[+] PermitRootLogin successfully set to yes."
else
  echo "[!] PermitRootLogin could not be set to yes."
fi