#!/bin/sh

cat /etc/sudoers | grep -v requiretty > /etc/sudoers.new
echo "root       ALL=(ALL)       ALL" >> /etc/sudoers.new
mv /etc/sudoers.new /etc/sudoers