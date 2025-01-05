#!/bin/sh
# @d_tranman/Nigel Gerald/Nigerald

if [ -z "$BCK" ]; then
    BCK="/root/.cache"
fi

BCK=$BCK/initial

sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
setenforce 0 2>/dev/null

ipt=$(command -v iptables || command -v /sbin/iptables || command -v /usr/sbin/iptables)
IS_BSD=false

if command -v pkg >/dev/null || command -v pkg_info >/dev/null; then
    IS_BSD=true
fi

ALLOW() {
    if [ "$IS_BSD" = true ]; then
        pfctl -d
    else
        $ipt -P OUTPUT ACCEPT
    fi
}

DENY() {
    if [ "$IS_BSD" = true ]; then
        pfctl -e
    else
        $ipt -P OUTPUT DROP
    fi
}

RHEL(){
    yum check-update -y >/dev/null
    yum install net-tools iproute sed curl wget bash gcc gzip make procps socat tar -y > /dev/null

    yum install auditd -y > /dev/null
    yum install rsyslog -y > /dev/null
}

SUSE(){
    zypper -n install -y net-tools iproute2 sed curl wget bash gcc gzip make procps socat tar >/dev/null
    
    zypper -n install -y audit rsyslog >/dev/null
}

DEBIAN(){
    apt-get -qq update >/dev/null
    apt-get -qq install net-tools iproute2 sed curl wget bash gcc gzip make procps socat tar tcpdump -y >/dev/null

    apt-get -qq install auditd rsyslog -y >/dev/null
}

UBUNTU(){
    DEBIAN
}

ALPINE(){
    echo "http://mirrors.ocf.berkeley.edu/alpine/v3.16/community" >> /etc/apk/repositories
    apk update >/dev/null
    apk add iproute2 net-tools curl wget bash iptables util-linux-misc gcc gzip make procps socat tar tcpdump >/dev/null

    apk add audit rsyslog >/dev/null
}

SLACK(){
    slapt-get --update
    slapt-get --install net-tools iproute2 sed curl wget bash gcc gzip make procps socat tar tcpdump >/dev/null

    slapt-get --install auditd rsyslog >/dev/null
}

ARCH(){
    pacman -Syu --noconfirm >/dev/null
    pacman -S --noconfirm net-tools iproute2 sed curl wget bash gcc gzip make procps socat tar tcpdump >/dev/null

    pacman -S --noconfirm auditd rsyslog >/dev/null
}

BSD(){
    pkg update -f >/dev/null
	pkg install -y wget
    pkg install -y curl bash gcc gmake gzip socat iftop rsyslog tcpdump >/dev/null
}

ALLOW

if command -v yum >/dev/null ; then
  RHEL
elif command -v zypper >/dev/null ; then
  SUSE
elif command -v apt-get >/dev/null ; then
  if $( cat /etc/os-release | grep -qi Ubuntu ); then
      UBUNTU
  else
      DEBIAN
  fi
elif command -v apk >/dev/null ; then
  ALPINE
elif command -v slapt-get >/dev/null || ( cat /etc/os-release | grep -i slackware ) ; then
  SLACK
elif command -v pacman >/dev/null ; then
  ARCH
elif command -v pkg >/dev/null || command -v pkg_info >/dev/null; then
    BSD
fi

ALLOW

( wget -O install-snoopy.sh https://github.com/a2o/snoopy/raw/install/install/install-snoopy.sh || \
  curl -o install-snoopy.sh https://github.com/a2o/snoopy/raw/install/install/install-snoopy.sh || \
  fetch -o install-snoopy.sh https://github.com/a2o/snoopy/raw/install/install/install-snoopy.sh ) && \
chmod 755 install-snoopy.sh && sudo ./install-snoopy.sh stable


# change /etc/snoopy.ini to point to $BCK/snoopy.log
echo "[snoopy]" > /etc/snoopy.ini
echo "output = file:$BCK/snoopy.log" >> /etc/snoopy.ini
touch $BCK/snoopy.log
chmod 666 $BCK/snoopy.log

DENY

# backup /etc/passwd
mkdir $BCK
cp /etc/passwd $BCK/users
cp /etc/group $BCK/groups

# check our ports
if command -v sockstat >/dev/null ; then
    LIST_CMD="sockstat -l"
    ESTB_CMD="sockstat -46c"
elif command -v netstat >/dev/null ; then
    LIST_CMD="netstat -tulpn"
    ESTB_CMD="netstat -tupwn"
elif command -v ss >/dev/null ; then
    LIST_CMD="ss -blunt -p"
    ESTB_CMD="ss -buntp"
else 
    echo "No netstat, sockstat or ss found"
    LIST_CMD="echo 'No netstat, sockstat or ss found'"
    ESTB_CMD="echo 'No netstat, sockstat or ss found'"
fi

$LIST_CMD > $BCK/listen
$ESTB_CMD > $BCK/estab

# pam
mkdir -p $BCK/pam/conf
mkdir -p $BCK/pam/pam_libraries
cp -R /etc/pam.d/ $BCK/pam/conf/
MOD=$(find /lib/ /lib64/ /lib32/ /usr/lib/ /usr/lib64/ /usr/lib32/ -name "pam_unix.so" 2>/dev/null)
for m in $MOD; do
    moddir=$(dirname $m)
    mkdir -p $BCK/pam/pam_libraries/$moddir
    cp $moddir/pam*.so $BCK/pam/pam_libraries/$moddir
done

# profiles
for f in '.profile' '.*shrc' '.*sh_login'; do
    find /home -name "$f" -exec rm {} \;
done

# php
# Thanks UCI

sys=$(command -v service || command -v systemctl || command -v rc-service)

for file in $(find / -name 'php.ini' 2>/dev/null); do
	echo "disable_functions = 1e, exec, system, shell_exec, passthru, popen, curl_exec, curl_multi_exec, parse_file_file, show_source, proc_open, pcntl_exec/" >> $file
	echo "track_errors = off" >> $file
	echo "html_errors = off" >> $file
	echo "max_execution_time = 3" >> $file
	echo "display_errors = off" >> $file
	echo "short_open_tag = off" >> $file
	echo "session.cookie_httponly = 1" >> $file
	echo "session.use_only_cookies = 1" >> $file
	echo "session.cookie_secure = 1" >> $file
	echo "expose_php = off" >> $file
	echo "magic_quotes_gpc = off " >> $file
	echo "allow_url_fopen = off" >> $file
	echo "allow_url_include = off" >> $file
	echo "register_globals = off" >> $file
	echo "file_uploads = off" >> $file

	echo $file changed

done;

if [ -d /etc/nginx ]; then
	$sys nginx restart || $sys restart nginx
	echo nginx restarted
fi

if [ -d /etc/apache2 ]; then
	$sys apache2 restart || $sys restart apache2
	echo apache2 restarted
fi

if [ -d /etc/httpd ]; then
	$sys httpd restart || $sys restart httpd
	echo httpd restarted
fi

if [ -d /etc/lighttpd ]; then
	$sys lighttpd restart || $sys restart lighttpd
	echo lighttpd restarted
fi

if [ -d /etc/ssh ]; then
    $sys ssh restart || $sys restart ssh || $sys restart sshd || $sys sshd restart
    echo ssh restarted
fi

file=$(find /etc -maxdepth 2 -type f -name 'php-fpm*' -print -quit)

if [ -d /etc/php/*/fpm ] || [ -n "$file" ]; then
        $sys *php* restart || $sys restart *php*
        echo php-fpm restarted
fi