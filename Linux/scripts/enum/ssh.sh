#!/bin/sh
# KaliPatriot | TTU CCDC | Landon Byrge

find /home /root -name "authorized_keys*" -exec ls -al {} \; -exec cat {} \; 2>/dev/null

# print configs in /etc/ssh/sshd_config and /etc/ssh/sshd_config.d/* if it exists
if [ -f /etc/ssh/sshd_config ]; then
    echo "=========="
    echo "/etc/ssh/sshd_config"
    # ignore comments and empty lines
    grep "^\s*[^#]" /etc/ssh/sshd_config
    echo "=========="
fi

if [ -d /etc/ssh/sshd_config.d ]; then
    for file in /etc/ssh/sshd_config.d/*; do
        echo "=========="
        echo "$file"
        grep "^\s*[^#]" $file
        echo "=========="
    done
fi