#!/bin/sh
# KaliPatriot | TTU CCDC | Landon Byrge

echo "Running 'ps -ef --forest'..."
ps -ef --forest 2>/dev/null

echo "Running 'ps auxw'..."
ps auxw 2>/dev/null

echo "Running 'ps -ef'..."
ps -ef 2>/dev/null