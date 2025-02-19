#!/bin/sh
# KaliPatriot | TTU CCDC | Landon Byrge

(crontab -l | grep -v '\-F' 2>/dev/null | grep -v '\-d' 2>/dev/null) | crontab -
