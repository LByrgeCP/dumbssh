#!/bin/sh
# KaliPatriot | TTU CCDC | Landon Byrge

if [ -z "$WAZUH_MANAGER" ] || [ -z "$DOWNLOAD_URL" ]; then
  echo "ERROR: You must set WAZUH_MANAGER and DOWNLOAD_URL."
  exit 1
fi

if [ -z "$WAZUH_REGISTRATION_PASSWORD" ]; then
  WAZUH_REGISTRATION_PASSWORD=""
fi

ARCH=$(uname -m)


ipt=$(command -v iptables || command -v /sbin/iptables || command -v /usr/sbin/iptables)
sys=$(command -v systemctl || command -v service || command -v rc-service)

# If wazuh-manager service is running, exit
if $sys status wazuh-manager >/dev/null 2>&1 || $sys wazuh-manager status >/dev/null 2>&1; then
  echo "ERROR: Wazuh manager is running. You cannot install the agent on the same host."
  exit 1
fi

DPKG() {
  if [ $ARCH = x86_64 ]; then
    ARCH_PKG="amd64"
  elif [ $ARCH = i386 ] || [ ARCH = i686 ]; then
    ARCH_PKG="i386"
  else
    echo "ERROR: Unsupported architecture."
    exit 1
  fi

  package="wazuh-agent_4.9.2-1_${ARCH_PKG}.deb"

  ( wget -O $package $DOWNLOAD_URL/$package || \
    curl -o $package $DOWNLOAD_URL/$package || \
    fetch -o $package $DOWNLOAD_URL/$package )

  if ( test -f $package ); then
    InstallCommand="WAZUH_MANAGER=$WAZUH_MANAGER dpkg -i $package"
    if [ -n $WAZUH_REGISTRATION_PASSWORD ]; then
      InstallCommand="WAZUH_REGISTRATION_PASSWORD=$WAZUH_REGISTRATION_PASSWORD $InstallCommand"
    fi
    eval "$InstallCommand"
  else
    echo "ERROR: Failed to download the package."
    exit 1
  fi
}

RPM() {
  if [ $ARCH = x86_64 ]; then
    ARCH_PKG="x86_64"
  elif [ $ARCH = i386 ] || [ ARCH = i686 ]; then
    ARCH_PKG="i386"
  else
    echo "ERROR: Unsupported architecture."
    exit 1
  fi

  package="wazuh-agent-4.9.2-1.${ARCH_PKG}.rpm"

  ( wget -O $package $DOWNLOAD_URL/$package || \
    curl -o $package $DOWNLOAD_URL/$package || \
    fetch -o $package $DOWNLOAD_URL/$package )

  if ( test -f $package ); then
    InstallCommand="WAZUH_MANAGER=$WAZUH_MANAGER rpm -vi $package"
    if [ -n $WAZUH_REGISTRATION_PASSWORD ]; then
      InstallCommand="WAZUH_REGISTRATION_PASSWORD=$WAZUH_REGISTRATION_PASSWORD $InstallCommand"
    fi
	 eval "$InstallCommand"
  else
    echo "ERROR: Failed to download the package."
    exit 1
  fi
}

enable_and_start() {
  $sys daemon-reload 2>/dev/null
  $sys enable wazuh-agent 2>/dev/null || $sys wazuh-agent enable 2>/dev/null
  $sys start wazuh-agent 2>/dev/null || $sys wazuh-agent start 2>/dev/null
}

is_agent_running() {
  # check if wazuh-agent service is up, if so, print 3 lines of equals, then Wazuh Agent is running, three more lines of equals and exit
  if $sys status wazuh-agent 2>/dev/null || $sys wazuh-agent status 2>/dev/null; then
    echo "==================================================================="
    echo "==================================================================="
    echo "==================================================================="
    echo "Wazuh Agent is running"
  else
    echo "==================================================================="
    echo "==================================================================="
    echo "==================================================================="
    echo "Wazuh Agent is NOT running"
  fi
  echo "==================================================================="
  echo "==================================================================="
  echo "==================================================================="
}

if command -v dpkg >/dev/null ; then
  DPKG
elif command -v rpm >/dev/null ; then
  RPM
else
  echo "ERROR: Unsupported package manager."
  exit 1
fi

enable_and_start
is_agent_running