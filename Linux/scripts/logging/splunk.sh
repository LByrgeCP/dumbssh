#!/bin/sh
# Thanks SEMO
# KaliPatriot | TTU CCDC | Landon Byrge

if [ -z "$INDEXER" ] || [ -z "$PASS" ]; then
  echo "ERROR: You must set INDEXER and PASS."
  exit 1
fi

Splunk_Package_TGZ="splunkforwarder-9.4.0-6b4ebe426ca6-linux-amd64.tgz"
Splunk_Download_URL="https://download.splunk.com/products/universalforwarder/releases/9.4.0/linux/splunkforwarder-9.4.0-6b4ebe426ca6-linux-amd64.tgz"
Install_DIR="/opt/splunkforwarder"
Receiver_Port="9997"
Admin_username="admin"

if [ ! -z $PORT ]; then
    Receiver_Port=$PORT
fi

if [ ! -z $USER ]; then
    Admin_username=$USER
fi

GREEN=''
YELLOW=''
BLUE=''
RED=''
NC=''
if [ -n "$COLOR" ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;36m'
    NC='\033[0m'
fi

install_splunk() {
  ( wget --no-check-certificate -O $Splunk_Package_TGZ $Splunk_Download_URL || \
        curl -k -o $Splunk_Package_TGZ $Splunk_Download_URL || \ 
        fetch -o $Splunk_Package_TGZ $Splunk_Download_URL )

  echo "${BLUE}Extracting Splunk Forwarder tarball...${NC}"
  sudo tar -xvzf $Splunk_Package_TGZ -C /opt
  rm -f $Splunk_Package_TGZ

}

set_admin() {
    echo "${BLUE}Setting Splunk admin password...${NC}"
    User_Seed_File="$Install_DIR/etc/system/local/user-seed.conf"
    sudo bash -c "cat > $User_Seed_File" <<EOF
[user_info]
USERNAME = $Admin_username
PASSWORD = $PASS
EOF
    sudo chown root:root $User_Seed_File
    echo "${GREEN}Splunk admin password set.${NC}"
}

setup_monitors() {
    echo "${BLUE}Setting up monitors for $ID...${NC}"
    Monitor_Config="$Install_DIR/etc/system/local/inputs.conf"

    OS_Monitors="
[monitor:///var/log/secure]
index = main
sourcetype = auth

[monitor:///var/log/auth.log]
index = main
sourcetype = syslog

[monitor:///var/log/commands]
index = main
sourcetype = syslog

[monitor:///changeme]
index = main
sourcetype = changeme
"
    sudo bash -c "cat > $Monitor_Config" <<EOL
    
$OS_Monitors
EOL
    sudo chown root:root $Monitor_Config
    echo "${GREEN}Monitors set up for $ID.${NC}"
    

}

configure_forwarder() {
    echo "${BLUE}Configuring Splunk Forwarder to send logs to $INDEXER:$Receiver_Port...${NC}"
    sudo $Install_DIR/bin/splunk add forward-server $INDEXER:$Receiver_Port -auth $Admin_username:$PASS
    echo "${GREEN}Splunk Forwarder configured.${NC}"
}

restart_splunk() {
    local max_atempts=3
    local attempt=1
    local timeout=30

    echo "${BLUE}Restarting Splunk Forwarder...${NC}"

    while [ $attempt -le $max_atempts ]; do
        sudo $Install_DIR/bin/splunk restart &>/dev/null &
        local splunk_pid=$!

        wait $splunk_pid &>/dev/null &
        local wait_pid=$!
        sleep $timeout
        kill $wait_pid &>/dev/null

        if sudo $Install_DIR/bin/splunk status | grep -q "running"; then
            echo "${GREEN}Splunk Forwarder restarted successfully.${NC}"
            return 0
        fi

        echo "${RED}Attempt $attempt: Splunk Forwarder failed to restart. Retrying...${NC}"
        attempt=$((attempt + 1))        
        sleep 5
    done

    echo "${RED}Splunk Forwarder failed to restart after $max_atempts attempts. Please check the logs for more details.${NC}"
    return 1
}

install_splunk

set_admin

if [ -d "$Install_DIR/bin" ]; then
    echo "${BULE}Starting and enabling Splunk Forwarder...${NC}"
    sudo $Install_DIR/bin/splunk start --accept-license --answer-yes --no-prompt
    sudo $Install_DIR/bin/splunk enable boot-start

    setup_monitors

    configure_forwarder

    if ! restart_splunk; then
        echo "${RED}Splunk Forwareder restart failed. Installation incomplete.${NC}"
        exit 1
    else
        echo "${RED}Installation directory not found. Something went wrong.${NC}"
        exit 1
    fi

    sudo $Install_DIR/bin/splunk version

    sudo $Install_DIR/bin/splunk restart

    echo "${YELLOW}Restart complete, forwarder installation complete!${NC}"
    else
        echo "${GREEN}Operating system not recognized, skipping centOS specific configurations.${NC}"
    fi
  exit 0
fi

echo "${GREEN}#########DONE!#########${NC}"
