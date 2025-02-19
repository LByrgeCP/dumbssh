#!/bin/sh
# KaliPatriot | TTU CCDC | Landon Byrge

echo "/etc/crontab:"
cat /etc/crontab

echo "/etc/cron.d/:"
ls -altr /etc/cron.d/

if [ -z $CROND ]; then
    cat /etc/cron.d/*
fi

echo "/var/spool/cron/:"
ls -altr /var/spool/cron/
ls -altr /var/spool/cron/crontabs/
find /var/spool/cron/crontabs/ -type f -exec echo {}\; cat {} \;


echo "crontab -l":
crontab -l