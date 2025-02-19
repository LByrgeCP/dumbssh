#!/bin/sh
# KaliPatriot | TTU CCDC | Landon Byrge

# get hashes of all shells in /etc/passwd

echo "Checking for hashes of all shells in /etc/passwd"
echo "======="
for shell in $(cat /etc/passwd | cut -f7 -d':' | sort -u); do
    if [ -f "$shell" ]; then
        echo "[+] $shell hash: $(sha256sum $shell)"
    fi
done
echo "======="

# get hashes of all shells in /etc/shells, check for other files with same hash

echo "Checking for hashes of all shells in /etc/shells"
echo "======="
for shell in $(cat /etc/shells); do
    if [ -f "$shell" ]; then
        echo "[+] $shell hash: $(sha256sum $shell)"
        filesize=$(stat -c%s "$shell" 2>/dev/null)
        if [ $? -ne 0 ]; then
            filesize=$(stat -f%z "$shell" 2>/dev/null)
            if [ $? -ne 0 ]; then
                echo "Error getting filesize for $shell"
                continue
            fi
        fi
        matches=$(find / -type f -size ${filesize}c -exec sha256sum {} \; 2>/dev/null | grep $(sha256sum $shell | cut -d' ' -f1) | grep -v $shell)
        if [ -n "$matches" ]; then
            echo "Other files with same hash:"
            echo "$matches"
        fi
    fi
done

echo "======="
