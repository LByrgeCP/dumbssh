#!/bin/sh
# KaliPatriot | TTU CCDC | Landon Byrge

echo pong

echo "SSH IP: $(echo $SSH_CLIENT | awk '{print $1}')"

echo "USER: $(id)"