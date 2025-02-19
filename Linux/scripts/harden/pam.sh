#!/bin/sh
# @d_tranman/Nigel Gerald/Nigerald
# KaliPatriot | TTU CCDC | Landon Byrge
# This pam script sucked @dsu
# I'm going to fix it
# I'm going to make it better
# I'm going to make it great
# I'm going to make it the best
# I'm going to make it the best pam script ever
# I'm going to make it the best pam script ever written
# I'm going to make it the best pam script ever written in the history of the world
# I'm going to make it the best pam script ever written in the history of the world of all time
# I'm going to make it the best pam script ever written in the history of the world of all time in the universe
# I'm going to make it the best pam script ever written in the history of the world of all time in the universe of all universes
# I'm going to make it the best pam script ever written in the history of the world of all time in the universe of all universes of all multiverses
# I'm going to make it the best pam script ever written in the history of the world of all time in the universe of all universes of all multiverses of all omniverses
# I'm going to make it the best pam script ever written in the history of the world of all time in the universe of all universes of all multiverses of all omniverses of all megaverses
# I'm going to make it the best pam script ever written in the history of the world of all time in the universe of all universes of all multiverses of all omniverses of all megaverses of all gigaverses
# I'm going to make it the best pam script ever written in the history of the world of all time in the universe of all universes of all multiverses of all omniverses of all megaverses of all gigaverses of all teraverses
# I'm going to make it the best pam script ever written in the history of the world of all time in the universe of all universes of all multiverses of all omniverses of all megaverses of all gigaverses of all teraverses of all petaverses
# I'm going to make it the best pam script ever written in the history of the world of all time in the universe of all universes of all multiverses of all omniverses of all megaverses of all gigaverses of all teraverses of all petaverses of all exaverses
# I'm going to make it the best pam script ever written in the history of the world of all time in the universe of all universes of all multiverses of all omniverses of all megaverses of all gigaverses of all teraverses of all petaverses of all exaverses of all zettaverses
# I'm going to make it the best pam script ever written in the history of the world of all time in the universe of all universes of all multiverses of all omniverses of all megaverses of all gigaverses of all teraverses of all petaverses of all exaverses of all zettaverses of all yottaverses
# I'm going to make it the best pam script ever written in the history of the world of all time in the universe of all universes of all multiverses of all omniverses of all megaverses of all gigaverses of all teraverses of all petaverses of all exaverses of all zettaverses of all yottaverses of all xennaverses
# I'm going to make it the best pam script ever written in the history of the world of all time in the universe of all universes of all multiverses of all omniverses of all megaverses of all gigaverses of all teraverses of all petaverses of all exaverses of all zettaverses of all yottaverses of all xennaverses of all wekaverses
# I'm going to make it the best pam script ever written in the history of the world of all time in the universe of all universes of all multiverses of all omniverses of all megaverses of all gigaverses of all teraverses of all petaverses of all exaverses of all zettaverses of all yottaverses of all xennaverses of all wekaverses of all vundaverses
# I'm going to make it the best pam script ever written in the history of the world of all time in the universe of all universes of all multiverses of all omniverses of all megaverses of all gigaverses of all teraverses of all petaverses of all exaverses of all zettaverses of all yottaverses of all xennaverses of all wekaverses of all vundaverses of all uqaverses
# I'm going to make it the best pam script ever written in the history of the world of all time in the universe of all universes of all multiverses of all omniverses of all megaverses of all gigaverses of all teraverses of all petaverses of all exaverses of all zettaverses of all yottaverses of all xennaverses of all wekaverses of all vundaverses of all uqaverses of all trelaverses
# okay stop copilot

if [ -z "$BCK" ]; then
    BCK="/root/.cache"
fi

# $REINSTALL=true - reinstall pam

BACKUPCONFDIR="$BCK/pam.d"
BACKUPBINARYDIR="$BCK/pam_libraries"

mkdir -p $BACKUPCONFDIR
mkdir -p $BACKUPBINARYDIR

ipt=$(command -v iptables || command -v /sbin/iptables || command -v /usr/sbin/iptables)
IS_BSD=false

if command -v pkg >/dev/null || command -v pkg_info >/dev/null; then
    IS_BSD=true
fi

ALLOW() {
    if [ -z $DISFW ]; then
        return
    fi
    if [ "$IS_BSD" = true ]; then
        pfctl -d
    else
        $ipt -P OUTPUT ACCEPT
    fi
}

DENY() {
    if [ -z $DISFW ]; then
        return
    fi
    if [ "$IS_BSD" = true ]; then
        pfctl -e
    else
        $ipt -P OUTPUT DROP
    fi
}

handle_pam() {
    if [ ! -z "$REVERT" ]; then
        echo "[+] Reverting PAM binaries from backup..."
        if [ -d "$BACKUPBINARYDIR" ]; then
            find "$BACKUPBINARYDIR" -type f | while read -r file; do
                ORIGINAL_DIR=$(echo "$file" | sed "s|$BACKUPBINARYDIR||g" | xargs dirname)
                echo "Restoring $file to $ORIGINAL_DIR"
                mkdir -p "$ORIGINAL_DIR"
                cp "$file" "$ORIGINAL_DIR"
            done
        else
            echo "[-] Backup directory $BACKUPBINARYDIR does not exist. Cannot revert."
            exit 1
        fi

        echo "[+] Reverting PAM configuration files..."
        if [ -d "$BACKUPCONFDIR" ]; then
            cp -R "$BACKUPCONFDIR"/* /etc/pam.d/
        else
            echo "[-] Backup directory $BACKUPCONFDIR does not exist. Cannot revert."
            exit 1
        fi

        echo "[+] Reversion complete."
    else
        echo "[+] Backing up PAM configuration files and binaries..."

        # Backup configuration directory
        mkdir -p "$BACKUPCONFDIR"
        cp -R /etc/pam.d/* "$BACKUPCONFDIR/"

        # Backup PAM-related binaries
        mkdir -p "$BACKUPBINARYDIR"
        MOD=$(find /lib/ /lib64/ /lib32/ /usr/lib/ /usr/lib64/ /usr/lib32/ -name "pam_unix.so" 2>/dev/null)

        if [ -z "$MOD" ]; then
            echo "[-] pam_unix.so not found"
        else
            echo "[+] Found the following pam_unix.so files:"
            echo "$MOD"
            for i in $MOD; do
                BINARY_DIR=$(dirname "$i")
                DEST="$BACKUPBINARYDIR$BINARY_DIR"
                echo "Backing up all binaries from $BINARY_DIR to $DEST"
                mkdir -p "$DEST"
                cp "$BINARY_DIR"/pam* "$DEST/"
            done
        fi

        echo "[+] Backup complete."
    fi
}

DEBIAN() {
    if [ ! -z "$REINSTALL" ]; then
        echo "[+] Reinstalling PAM-related packages..."
        DEBIAN_FRONTEND=noninteractive
        pam-auth-update --package --force
        apt-get -y --reinstall install libpam-runtime libpam-modules
        echo "[+] Reinstallation complete."
    fi

    handle_pam
}

RHEL() {
    if [ ! -z "$REINSTALL" ]; then
        echo "[+] Reinstalling PAM-related packages..."
        yum -y reinstall pam
        echo "[+] Reinstallation complete."
		if command -v authconfig >/dev/null; then
			authconfig --updateall
		fi
    fi

    handle_pam
}
SUSE() {
    if [ ! -z "$REINSTALL" ]; then
        echo "[+] Reinstalling PAM-related packages..."
        zypper install -f -y pam
        pam-config --update
        echo "[+] Reinstallation complete."
    fi

    handle_pam
}

UBUNTU(){
  DEBIAN
}

ALPINE() {
    if [ -z "$UNTESTED" ]; then
        echo "[-] Alpine Linux is untested. Please test manually first."
        exit 1
    fi
    if [ ! -z "$REINSTALL" ]; then
        echo "[+] Reinstalling PAM-related packages for Alpine..."
        apk fix --reinstall --purge linux-pam
        for file in $( find /etc/pam.d -name *.apk-new | xargs -0 echo ); do
            mv $file $( echo $file | sed 's/.apk-new//g' )
        done
        echo "[+] Reinstallation complete."
    fi

    handle_pam
}

SLACK() {
    if [ -z "$UNTESTED" ]; then
        echo "[-] Alpine Linux is untested. Please test manually first."
        exit 1
    fi
    if [ ! -z "$REINSTALL" ]; then
        echo "[+] Slackware does not support automatic reinstallation of packages. Please reinstall PAM manually."
    fi

    handle_pam
}

ARCH() {
    if [ -z "$UNTESTED" ]; then
        echo "[-] Alpine Linux is untested. Please test manually first."
        exit 1
    fi
    if [ ! -z "$REINSTALL" ]; then
        echo "[+] Reinstalling PAM-related packages for Arch..."
        pacman -S --noconfirm pam
        echo "[+] Reinstallation complete."
    fi

    handle_pam
}

BSD() {
    if [ ! -z "$REINSTALL" ]; then
        echo "[+] Reinstalling PAM-related packages for BSD..."
        pkg install -f pam || pkg_add -f pam
        echo "[+] Reinstallation complete."
    fi

    handle_pam
}


ALLOW

if command -v yum >/dev/null ; then
  RHEL
elif command -v zypper >/dev/null ; then
  SUSE
elif command -v apt-get >/dev/null ; then
  if $( cat /etc/os-release | grep -qi Ubuntu ); then
      UBUNTU
  else
      DEBIAN
  fi
elif command -v apk >/dev/null ; then
  ALPINE
elif command -v slapt-get >/dev/null || ( cat /etc/os-release | grep -i slackware ) ; then
  SLACK
elif command -v pacman >/dev/null ; then
  ARCH
elif command -v pkg >/dev/null || command -v pkg_add >/dev/null; then
    BSD
fi

DENY