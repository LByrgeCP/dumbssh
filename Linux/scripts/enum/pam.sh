#!/bin/sh
# KaliPatriot | TTU CCDC | Landon Byrge

echo "Checking for execution of arbitrary commands in PAM configuration"
echo "======="
grep -ER "^[^#]*pam_exec.so" /etc/pam.d/
echo ""
echo "======="

echo "Checking for pam_succeed_if in PAM configuration"
echo "======="
grep -ER "^[^#]*pam_succeed_if.so" /etc/pam.d/
echo ""
echo "======="

echo "Checking for nullok in PAM configuration"
echo "======="
grep -ER "^[^#]*nullok" /etc/pam.d/
echo ""
echo "======="

echo "Checking that pam_deny.so has not been tampered with"
echo "======="
MOD=$(find /lib/ /lib64/ /lib32/ /usr/lib/ /usr/lib64/ /usr/lib32/ -name "pam_deny.so" 2>/dev/null)
if [ -z "$MOD" ]; then
    echo "[-] pam_deny.so not found"
else
    for i in $MOD; do
        echo "[+] pam_deny.so found at $i"
        if $(grep -qr "pam_deny.so" $i); then 
            echo "[+] $i is correctly configured"
        else
            echo "[-] $i is TAMPERED WITH | [INVESTIGATE!]"
        fi
    done
fi

echo ""
echo "======="

echo "Checking that pam_permit.so has not been tampered with"
echo "======="
MOD=$(find /lib/ /lib64/ /lib32/ /usr/lib/ /usr/lib64/ /usr/lib32/ -name "pam_permit.so" 2>/dev/null)
if [ -z "$MOD" ]; then
    echo "[-] pam_permit.so not found"
else
    for i in $MOD; do
        echo "[+] pam_permit.so found at $i"
        if $(grep -qr "pam_permit.so" $i); then 
            echo "[+] $i is correctly configured"
        else
            echo "[-] $i is TAMPERED WITH | [INVESTIGATE!]"
        fi
    done
fi

echo ""
echo "======="

echo "Verifying pam authentication properly denies and permits"
echo "======="
files=$(find /etc/pam.d/ -name "*-auth")

for file in $files; do
    if [ ! -f "$file" ]; then
        echo "File not found: $file"
        continue
    fi

    deny_line=$(grep -n 'pam_deny.so' "$file" | cut -d: -f1 | head -n 1)
    permit_line=$(grep -n 'pam_permit.so' "$file" | cut -d: -f1 | head -n 1)

    if [ -z $permit_line ]; then
        echo "pam_permit.so not found in $file. [INVESTIGATE!]"
        continue
    fi


    if [ -z $deny_line ]; then
        echo "pam_deny.so not found in $file. [INVESTIGATE!]"
        continue
    fi

    if ! [ $deny_line -lt $permit_line ]; then
        echo "pam_permit.so comes before pam_deny.so in $file | [INVESTIGATE!]"
    fi
done

echo ""
echo "======="

if [ -z "$BCK" ]; then
    echo "[-] \$BCK not set. Skipping pam_unix.so hash verification"
else
    echo "Verifying pam_unix.so hash"
    echo "======="
    BACKUPBINARYDIR="$BCK/pam_libraries"
    BCKUNIX=$(find $BACKUPBINARYDIR -type f -name "pam_unix.so" 2>/dev/null)
    # check if $BCK/pam_unix.so exists
    if [ -z "$BCKUNIX" ]; then
        echo "[-] No backup of pam_unix.so found at $BACKUPBINARYDIR"
    else
        for i in $BCKUNIX; do
            echo "[+] Backup of pam_unix.so found at $i"
            # Strip $BACKUPBINARYDIR from path
            l=$(echo $i | sed "s|$BACKUPBINARYDIR||g")
            # Compare hashes of i and l
            if [ "$(sha256sum $i | cut -d' ' -f1)" = "$(sha256sum $l | cut -d' ' -f1)" ]; then
                echo "[+] $i hash matches $l"
            else
                echo "[-] $i hash does not match | [INVESTIGATE!]"
                # print hashes
                echo "Hashes:"
                echo "Current: $(sha256sum $i | cut -d' ' -f1)"
                echo "Backup: $(sha256sum $l | cut -d' ' -f1)"
            fi
        done
    fi
fi

echo ""
echo "======="

# if $ENSTR is set and strings is installed, print strings of pam_unix.so
if [ -n "$ENSTR" ]; then
    if command -v strings >/dev/null; then
        MOD=$(find /lib/ /lib64/ /lib32/ /usr/lib/ /usr/lib64/ /usr/lib32/ -name "pam_unix.so" 2>/dev/null)
        if [ -z "$MOD" ]; then
            echo "[-] pam_unix.so not found"
        else
            for i in $MOD; do
                echo "[+] pam_unix.so found at $i"
                echo "[+] Strings:"
                strings $i
            done
        fi
    else
        echo "[-] strings not found. Skipping strings of pam_unix.so"
    fi
fi

echo ""
echo "======="

if [ -n "PRINTAUTH" ]; then
    echo "Printing pam authentication configuration"
    echo "======="
    grep -ER "^\s*[^#]" /etc/pam.d/*-auth
fi