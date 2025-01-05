#!/bin/sh
# @d_tranman/Nigel Gerald/Nigerald

IS_RHEL=false
IS_DEBIAN=false
IS_ALPINE=false
IS_SLACK=false
IS_BSD=false
IS_SUSE=false
IS_ARCH=false

ORAG=''
GREEN=''
YELLOW=''
BLUE=''
RED=''
NC=''

if echo -e "test" | grep -qE '\-e'; then
    ECHO='echo'
else
    ECHO='echo -e'
fi

if [ -z "$DEBUG" ]; then
    DPRINT() { 
        "$@" 2>/dev/null 
    }
else
    DPRINT() { 
        "$@" 
    }
fi

RHEL(){
  IS_RHEL=true
}

SUSE(){
  IS_SUSE=true
}

DEBIAN(){
  IS_DEBIAN=true
}

UBUNTU(){
  DEBIAN
}

ALPINE(){
  IS_ALPINE=true
}

SLACK(){
  IS_SLACK=true
}

ARCH(){
  IS_ARCH=true
}

BSD(){
  IS_BSD=true
}


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

if [ -n "$COLOR" ]; then
    ORAG='\033[0;33m'
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;36m'
    NC='\033[0m'
fi

${ECHO} "${GREEN}
##################################
#                                #
#         INVENTORY TIME         #
#                                #
##################################
${NC}\n"

${ECHO} "\n${GREEN}#############HOST INFORMATION############${NC}\n"

HOST=$( DPRINT hostname || DPRINT cat /etc/hostname )
OS=$( cat /etc/*-release  | grep PRETTY_NAME | sed 's/PRETTY_NAME=//' | sed 's/"//g' )
if command -v 'ip' > /dev/null ; then
    IP=$( DPRINT ip a | grep -oE '([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}/[[:digit:]]{1,2}' | grep -v '127.0.0.1' )
    GATEWAY=$( DPRINT ip route | grep default | awk '{print $3}' )
elif command -v 'ifconfig' > /dev/null ; then 
    if [ $IS_BSD = true ]; then
        IP=$( DPRINT ifconfig | grep -oE 'inet.+([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}' | grep -v '127.0.0.1' | awk '{print $2}' )
        GATEWAY=$( DPRINT netstat -rn | grep default | awk '{print $2}' )
    else
        IP=$( DPRINT ifconfig | grep -oE 'inet.+([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}' | grep -v '127.0.0.1' )
        GATEWAY=$( DPRINT route -n | grep 'UG' | awk '{print $2}' )
    fi
else
    IP="ip a and ifconfig command not found"
    GATEWAY="ip route and route command not found"
fi
RAM=$( DPRINT free -h --si | grep Mem | awk '{print $2}' )
if [ -z "$RAM" ]; then
    RAM=$( sysctl -n hw.realmem | awk '{ byte =$1 /1024/1024/1024; print byte " GB" }' )
fi
STORAGE=$( DPRINT df -h | grep -E '\s/\s*$' | awk '{print $2}' )
USERS=$( cat /etc/passwd | grep -vE '(false|nologin|sync)$' | grep -E '/.*sh$' )
SUDOERS=$( DPRINT cat /etc/sudoers /etc/sudoers.d/* | grep -vE '#|Defaults|^\s*$' | grep -vE '(Cmnd_Alias|\\)' )
NOAUTHSUDOERS=$( DPRINT cat /etc/sudoers /etc/sudoers.d/* | grep -E '^\s*Defaults\s+[^\s]authenticate' )
SUIDS=$(find /bin /sbin /usr -perm -u=g+s -type f -exec ls -la {} \; | grep -E '(s7z|aa-exec|ab|agetty|alpine|ansible-playbook|ansible-test|aoss|apt|apt-get|ar|aria2c|arj|arp|as|ascii85|ascii-xfr|ash|aspell|at|atobm|awk|aws|base32|base58|base64|basenc|basez|bash|batcat|bc|bconsole|bpftrace|bridge|bundle|bundler|busctl|busybox|byebug|bzip2|c89|c99|cabal|cancel|capsh|cat|cdist|certbot|check_by_ssh|check_cups|check_log|check_memory|check_raid|check_ssl_cert|check_statusfile|chmod|choom|chown|chroot|clamscan|cmp|cobc|column|comm|composer|cowsay|cowthink|cp|cpan|cpio|cpulimit|crash|crontab|csh|csplit|csvtool|cupsfilter|curl|cut|dash|date|dd|debugfs|dialog|diff|dig|distcc|dmesg|dmidecode|dmsetup|dnf|docker|dos2unix|dosbox|dotnet|dpkg|dstat|dvips|easy_install|eb|ed|efax|elvish|emacs|enscript|env|eqn|espeak|ex|exiftool|expand|expect|facter|file|find|finger|fish|flock|fmt|fold|fping|ftp|gawk|gcc|gcloud|gcore|gdb|gem|genie|genisoimage|ghc|ghci|gimp|ginsh|git|grc|grep|gtester|gzip|hd|head|hexdump|highlight|hping3|iconv|iftop|install|ionice|ip|irb|ispell|jjs|joe|join|journalctl|jq|jrunscript|jtag|julia|knife|ksh|ksshell|ksu|kubectl|latex|latexmk|ldconfig|ld.so|less|lftp|ln|loginctl|logsave|look|lp|ltrace|lua|lualatex|luatex|lwp-download|lwp-request|mail|make|man|mawk|minicom|more|mosquitto|msfconsole|msgattrib|msgcat|msgconv|msgfilter|msgmerge|msguniq|mtr|multitime|mv|mysql|nano|nasm|nawk|nc|ncftp|neofetch|nft|nice|nl|nm|nmap|node|nohup|npm|nroff|nsenter|octave|od|openssl|openvpn|openvt|opkg|pandoc|paste|pax|pdb|pdflatex|pdftex|perf|perl|perlbug|pexec|pg|php|pic|pico|pidstat|pip|pkexec|pkg|posh|pr|pry|psftp|psql|ptx|puppet|pwsh|python|rake|rc|readelf|red|redcarpet|redis|restic|rev|rlogin|rlwrap|rpm|rpmdb|rpmquery|rpmverify|rsync|rtorrent|ruby|run-mailcap|run-parts|runscript|rview|rvim|sash|scanmem|scp|screen|script|scrot|sed|service|setarch|setfacl|setlock|sftp|sg|shuf|slsh|smbclient|snap|socat|socket|soelim|softlimit|sort|split|sqlite3|sqlmap|ss|ssh|ssh-agent|ssh-keygen|ssh-keyscan|sshpass|start-stop-daemon|stdbuf|strace|strings|sysctl|systemctl|systemd-resolve|tac|tail|tar|task|taskset|tasksh|tbl|tclsh|tcpdump|tdbtool|tee|telnet|terraform|tex|tftp|tic|time|timedatectl|timeout|tmate|tmux|top|torify|torsocks|troff|tshark|ul|unexpand|uniq|unshare|unsquashfs|unzip|update-alternatives|uudecode|uuencode|vagrant|valgrind|vi|view|vigr|vim|vimdiff|vipw|virsh|volatility|w3m|wall|watch|wc|wget|whiptail|whois|wireshark|wish|xargs|xdg-user-dir|xdotool|xelatex|xetex|xmodmap|xmore|xpad|xxd|xz|yarn|yash|yelp|yum|zathura|zip|zsh|zsoelim|zypper)$')
WORLDWRITEABLES=$( DPRINT find /usr /bin/ /sbin /var/www /lib -perm -o=w -type f -exec ls {} -la \; )
SUDOGROUP_LINES=$(grep -E "^(sudo|wheel|root):" /etc/group | sed 's/x:.*:/ /')

${ECHO} "${BLUE}[+] Hostname:${NC} $HOST"
${ECHO} "${BLUE}[+] OS:${NC} $OS"
${ECHO} "${BLUE}[+] RAM:${NC} $RAM"
${ECHO} "${BLUE}[+] Storage:${NC} $STORAGE"
${ECHO} "${BLUE}[+] IP Addresses and interfaces${NC}"
${ECHO} "$IP"
${ECHO} "${BLUE}[+] Gateway:${NC} $GATEWAY\n"
${ECHO} "${GREEN}#############Listening Ports############${NC}"
echo ""
if command -v sockstat >/dev/null; then
    DPRINT sockstat -l | tail -n +3 | grep 'tcp\|udp' | awk '{print $1 " " $2 " " $6 }' | DPRINT column -t
fi
if command -v netstat >/dev/null; then
    DPRINT netstat -tlpn | tail -n +3 | awk '{print $1 " " $4 " " $6 " " $7}'| DPRINT column -t
elif command -v ss > /dev/null; then
    DPRINT ss -blunt -p | tail -n +2 | awk '{print $1 " " $5 " " $7}' | DPRINT column -t 
else
    echo "Netstat and ss commands do not exist"
fi
echo ""
${ECHO} "${GREEN}#############SERVICE INFORMATION############${NC}"
if [ $IS_ALPINE = true ]; then
    SERVICES=$( rc-status -s | grep started | awk '{print $1}' )
elif [ $IS_SLACK = true ]; then
    SERVICES=$( ls -la /etc/rc.d | grep rwx | awk '{print $9}' ) 
elif [ $IS_BSD = true ]; then
    SERVICES=$( cat /etc/rc.conf /etc/rc.conf.d/* | grep -i "_enable" | grep -i "yes" | awk -F "_enable" '{print $1}' )
else
    SERVICES=$( DPRINT systemctl --type=service | grep active | awk '{print $1}' || service --status-all | grep -E '(+|is running)' )
fi
APACHE2=false
NGINX=false
checkService()
{
    serviceList=$1
    serviceToCheckExists=$2
    serviceAlias=$3                

	serviceGrep="$serviceToCheckExists"
	if [ -n "$serviceAlias" ]; then
		serviceGrep="$serviceAlias\|$serviceToCheckExists"
	fi

	if echo "$serviceList" | grep -qi "$serviceGrep"; then
		${ECHO} "\n${BLUE}[+] $serviceToCheckExists is on this machine${NC}\n"

		if [ "$( DPRINT sockstat -l | grep -i "$serviceGrep" )" ]; then
			${ECHO} "Active on port(s) ${YELLOW}$(sockstat -l | grep -i "$serviceGrep" | grep -i ":" | awk 'BEGIN {ORS=" and " } {print $6}' | sed 's/\(.*\)and /\1\n/')${NC}\n"
		elif [ "$( DPRINT netstat -tulpn | grep -i "$serviceGrep" )" ]; then
			${ECHO} "Active on port(s) ${YELLOW}$(netstat -tulpn | grep -i "$serviceGrep" | awk 'BEGIN {ORS=" and "} {print $1, $4}' | sed 's/\(.*\)and /\1\n/')${NC}\n"
		elif [ "$( DPRINT ss -blunt -p | grep -i "$serviceGrep" )" ]; then
			${ECHO} "Active on port(s) ${YELLOW}$(ss -blunt -p | grep -i "$serviceGrep" | awk 'BEGIN {ORS=" and " } {print $1,$5}' | sed 's/\(.*\)and /\1\n/')${NC}\n"
		fi
	fi

}

if checkService "$SERVICES"  'ssh' | grep -qi "is on this machine"; then checkService "$SERVICES" 'ssh' ; SSH=true ;fi
if checkService "$SERVICES"  'docker' | grep -qi "is on this machine"; then
    checkService "$SERVICES"  'docker'

    ACTIVECONTAINERS=$( docker ps )
    if [ -n "$ACTIVECONTAINERS" ]; then
        echo "Current Active Containers"
        ${ECHO} "${ORAG}$ACTIVECONTAINERS${NC}\n"
    fi

    ANONMOUNTS=$( docker ps -q | DPRINT xargs -n 1 docker inspect --format '{{if .Mounts}}{{.Name}}: {{range .Mounts}}{{.Source}} -> {{.Destination}}{{end}}{{end}}' | grep -vE '^$' | sed 's/^\///g' )
    if [ -n "$ANONMOUNTS" ]; then
        echo "Anonymous Container Mounts (host -> container)"
        ${ECHO} "${ORAG}$ANONMOUNTS${NC}\n"
    fi

    VOLUMES="$( DPRINT docker volume ls --format "{{.Name}}" )"
    if [ -n "$VOLUMES" ]; then
        echo "Volumes"
        for v in $VOLUMES; do
            container=$( DPRINT docker ps -a --filter volume=$v --format '{{.Names}}' | tr '\n' ',' | sed 's/,$//g' )
            if [ -n "$container" ]; then
                mountpoint=$( echo $( DPRINT docker volume inspect --format '{{.Name}}: {{.Mountpoint}}' $v ) | awk -F ': ' '{print $2}' )
                ${ECHO} "${ORAG}$v -> $mountpoint used by $container${NC}"
            fi
        done
        echo ""
    fi
fi

if checkService "$SERVICES"  'cockpit' | grep -qi "is on this machine"; then
    checkService "$SERVICES"  'cockpit'
    ${ECHO} "${ORAG}[!] WE PROBABLY SHOULD KILL COCKPIT${NC}"
fi

if checkService "$SERVICES" 'apache2' 'httpd' | grep -qi "is on this machine"; then
    checkService "$SERVICES" 'apache2' 'httpd'

    if [ $IS_BSD = true ]; then
        APACHE2VHOSTS=$(tail -n +1 /usr/local/etc/apache24/httpd.conf /usr/local/etc/apache24/extra/httpd-vhosts.conf |
            grep -v '#' |
            grep -E '==>|VirtualHost|ServerName|DocumentRoot|ServerAlias|Proxy')
    else
        if [ -d "/etc/httpd" ]; then
            APACHE2VHOSTS=$(tail -n +1 /etc/httpd/conf.d/* /etc/httpd/conf/httpd.conf |
                grep -v '#' |
                grep -E '==>|VirtualHost|ServerName|DocumentRoot|ServerAlias|Proxy')
        else
            APACHE2VHOSTS=$(tail -n +1 /etc/apache2/sites-enabled/* /etc/apache2/apache2.conf |
                grep -v '#' |
                grep -E '==>|VirtualHost|ServerName|DocumentRoot|ServerAlias|Proxy')
        fi
    fi

    ${ECHO} "\n[!] Configuration Details\n"
    ${ECHO} "${ORAG}$APACHE2VHOSTS${NC}"
    APACHE2=true
fi

if checkService "$SERVICES"  'ftp' | grep -qi "is on this machine"; then
    checkService "$SERVICES"  'ftp'
    FTPCONF=$(cat /etc/*ftp* | grep -v '#' | grep -E 'anonymous_enable|guest_enable|no_anon_password|write_enable')
    ${ECHO} "\n[!] Configuration Details\n"
    ${ECHO} "${ORAG}$FTPCONF${NC}"
fi


if checkService "$SERVICES"  'nginx' | grep -qi "is on this machine"; then
    checkService "$SERVICES"  'nginx'
    NGINXCONFIG=$(tail -n +1 /etc/nginx/sites-enabled/* /etc/nginx/nginx.conf| grep -v '#'  | grep -E '==>|server|listen|root|server_name|proxy_')
    ${ECHO} "\n[!] Configuration Details\n"
    ${ECHO} "${ORAG}$NGINXCONFIG${NC}"
    NGINX=true
fi

sql_test(){

    if [ -f /lib/systemd/system/mysql.service ]; then
        SQL_SYSD=/lib/systemd/system/mysql.service
    elif [ -f /lib/systemd/system/mariadb.service ]; then
        SQL_SYSD=/lib/systemd/system/mariadb.service
    fi
    
    if [ -n "$SQL_SYSD" ]; then
        SQL_SYSD_INFO=$( grep -RE '^(User=|Group=)' $SQL_SYSD )
    fi
    
    if [ -d /etc/mysql ]; then
        SQLDIR=/etc/mysql
    elif [ -d /etc/my.cnf.d/ ]; then
        SQLDIR=/etc/my.cnf.d/
    fi

    if [ -n "$SQLDIR" ]; then
        SQLCONFINFO=$( DPRINT find $SQLDR *sql*.cnf *-server.cnf | sed 's/:user\s*/ ===> user /' | sed 's/bind-address\s*/ ===> bind-address /' )
    fi

    if [ -n "$SQLCONFINFO" ]; then
        ${ECHO} "${ORAG}$SQLCONFINFO${NC}"
    fi

    if [ -n "$SQL_SYSD_INFO" ]; then
        ${ECHO} "${ORAG}$SQL_SYSD:\n$SQL_SYSD_INFO${NC}\n"
    fi

    SQL_AUTH=1

    if mysql -uroot -e 'bruh' 2>&1 >/dev/null | grep -v '\[Warning\]' | grep -q 'bruh'; then
        ${ECHO} "${RED}Can login as root, with root and no password${NC}\n"
        SQLCMD="mysql -uroot"
    fi

    if mysql -uroot -proot -e 'bruh' 2>&1 >/dev/null | grep -v '\[Warning\]' | grep -q 'bruh'; then
        ${ECHO} "${RED}Can login with root:root${NC}\n"
        SQLCMD="mysql -uroot -proot"
    fi

    if mysql -uroot -ppassword -e 'bruh' 2>&1 >/dev/null | grep -v '\[Warning\]' | grep -q 'bruh'; then
        ${ECHO} "${RED}Can login with root:password${NC}\n"
        SQLCMD="mysql -uroot -ppassword"
    fi

    if [ -n "$DEFAULT_PASS" ]; then
        if mysql -uroot -p"$DEFAULT_PASS" -e 'bruh' 2>&1 >/dev/null | grep -v '\[Warning\]' | grep -q 'bruh'; then
            ${ECHO} "${RED}Can login with root:$DEFAULT_PASS${NC}\n"
            SQLCMD="mysql -uroot -p$DEFAULT_PASS"
        fi
    fi

    if [ -z "$SQLCMD" ]; then
        SQL_AUTH=0
    fi
    
    if [ "$SQL_AUTH" = 1 ]; then
        echo "SQL User Information"
        ${ECHO} "${ORAG}$( DPRINT $SQLCMD -t -e 'select user,host,plugin,authentication_string from mysql.user where password_expired="N";' )${NC}\n" 
        DATABASES=$( DPRINT $SQLCMD -t -e 'show databases' | grep -vE '^\|\s(mysql|information_schema|performance_schema|sys|test)\s+\|' )
        if [ -n "$DATABASES" ]; then
            echo "SQL Databases"
            ${ECHO} "${ORAG}$DATABASES${NC}\n"
        fi
    else
        echo "Cannot login with weak creds or default credentials"
    fi
}
if checkService "$SERVICES"  'mysql' | grep -qi "is on this machine"; then 
    MYSQL=true
    checkService "$SERVICES"  'mysql' 
    sql_test
fi

if checkService "$SERVICES"  'mariadb' | grep -qi "is on this machine"; then 
    MARIADB=true
    checkService "$SERVICES"  'mariadb'
    sql_test
fi
if checkService "$SERVICES" 'mssql-server' | grep -qi "is on this machine" ; then
    sqlserver=true
    checkService "$SERVICES" 'mssql-server' 'sqlservr'
fi
if checkService "$SERVICES"  'postgres' | grep -qi "is on this machine" ; then
    POSTGRESQL=true
    checkService "$SERVICES" 'postgres' || checkService "$SERVICES" 'postgres' 'postmaster'
    PSQLHBA=$( grep -REvh '(#|^\s*$|replication)' $( DPRINT find /etc/postgresql/ /var/lib/pgsql/ /var/lib/postgres* -name pg_hba.conf | head -n 1 ) )
    ${ECHO} "PostgreSQL Authentication Details\n"
    ${ECHO} "${ORAG}$PSQLHBA${NC}\n"

    if DPRINT psql -U postgres -c '\q'; then
        AUTH=1
        DB_CMD=" psql -U postgres -c \l "
    elif DPRINT sudo -u postgres psql -c '\q'; then
        AUTH=1
        DB_CMD=" sudo -u postgres psql -c \l "
    fi
    if [ "$AUTH" = 1 ]; then
        DATABASES="$( DPRINT $DB_CMD | grep -vE '^\s(postgres|template0|template1|\s+)\s+\|' | head -n -2 )"
        if [ "$( echo "$DATABASES" | wc -l )" -gt 2 ]; then
            echo "PostgreSQL Databases"
            ${ECHO} "${ORAG}$DATABASES${NC}\n"
        fi
    fi
fi
if checkService "$SERVICES"  'php' | grep -qi "is on this machine"; then
    checkService "$SERVICES"  'php'
    PHP=true
    PHPINILOC=$( find / -name php.ini 2> /dev/null )
    ${ECHO} "\n[!] php.ini location(s): "
    ${ECHO} "${ORAG}$PHPINILOC${NC}"
    for ini in $PHPINILOC; do
        DISABLEDFUNCTIONS=$( grep -i 'disable_functions' $ini | grep -vE '^;|^$' )
        if [ -n "$DISABLEDFUNCTIONS" ]; then
            ${ECHO} "\n[!] Disabled Functions in $ini"
            ${ECHO} "${ORAG}$DISABLEDFUNCTIONS${NC}"
        else
            ${ECHO} "\n${RED}[!] No disabled functions found in $ini${NC}"
        fi
    done
fi

# idk about any of these
if checkService "$SERVICES"  'python' | grep -qi "is on this machine"; then checkService "$SERVICES"  'python' ; PYTHON=true; fi
if checkService "$SERVICES"  'dropbear' | grep -qi "is on this machine"; then checkService "$SERVICES"  'dropbear' ; DROPBEAR=true; fi
if checkService "$SERVICES"  'vsftpd' | grep -qi "is on this machine"; then checkService "$SERVICES"  'vsftpd' ; VSFTPD=true; fi
if checkService "$SERVICES"  'pure-ftpd' | grep -qi "is on this machine"; then checkService "$SERVICES"  'pure-ftpd' ; PUREFTPD=true; fi
if checkService "$SERVICES"  'proftpd' | grep -qi "is on this machine"; then checkService "$SERVICES"  'proftpd' ; PROFTPD=true; fi
if checkService "$SERVICES"  'xinetd' | grep -qi "is on this machine"; then checkService "$SERVICES"  'xinetd' ; XINETD=true; fi
if checkService "$SERVICES"  'inetd' | grep -qi "is on this machine"; then checkService "$SERVICES"  'inetd' ; INETD=true; fi
if checkService "$SERVICES"  'tftpd' | grep -qi "is on this machine"; then checkService "$SERVICES"  'tftpd' ; TFTPD=true; fi
if checkService "$SERVICES"  'atftpd' | grep -qi "is on this machine"; then checkService "$SERVICES"  'atftpd' ; ATFTPD=true; fi
if checkService "$SERVICES"  'smbd' | grep -qi "is on this machine"; then checkService "$SERVICES"  'smbd' ; SMBD=true; fi
if checkService "$SERVICES"  'nmbd' | grep -qi "is on this machine"; then checkService "$SERVICES"  'nmbd' ; NMBD=true; fi
if checkService "$SERVICES"  'snmpd' | grep -qi "is on this machine"; then checkService "$SERVICES"  'snmpd' ; SNMPD=true; fi
if checkService "$SERVICES"  'ypbind' | grep -qi "is on this machine"; then checkService "$SERVICES"  'ypbind' ; YPBIND=true; fi
if checkService "$SERVICES"  'rshd' | grep -qi "is on this machine"; then checkService "$SERVICES"  'rshd' ; RSHD=true; fi
if checkService "$SERVICES"  'rexecd' | grep -qi "is on this machine"; then checkService "$SERVICES"  'rexecd' ; REXECD=true; fi
if checkService "$SERVICES"  'rlogin' | grep -qi "is on this machine"; then checkService "$SERVICES"  'rlogin' ; RLOGIN=true; fi
if checkService "$SERVICES"  'telnet' | grep -qi "is on this machine"; then checkService "$SERVICES"  'telnet' ; TELNET=true; fi
if checkService "$SERVICES"  'squid' | grep -qi "is on this machine"; then checkService "$SERVICES"  'squid' ; SQUID=true; fi

${ECHO} "\n${GREEN}#############USER INFORMATION############${NC}\n"
${ECHO} "${BLUE}[+] Users${NC}"
${ECHO} "${YELLOW}$USERS${NC}\n"
${ECHO} "${BLUE}[+] /etc/sudoers and /etc/sudoers.d/*${NC}"
${ECHO} "${YELLOW}$SUDOERS${NC}\n"
${ECHO} "${YELLOW}$NOAUTHSUDOERS${NC}\n"
${ECHO} "${BLUE}[+] Sudo group${NC}"
${ECHO} "${YELLOW}$SUDOGROUP${NC}\n"
${ECHO} "${BLUE}[+] Funny SUIDs${NC}"
${ECHO} "${YELLOW}$SUIDS${NC}\n"
${ECHO} "${BLUE}[+] World Writeable Files${NC}"
${ECHO} "${YELLOW}$WORLDWRITEABLES${NC}\n"

${ECHO} "\n${GREEN}#############HASHES######################${NC}\n"

MOD=$(find /lib/ /lib64/ /lib32/ /usr/lib/ /usr/lib64/ /usr/lib32/ -name "pam_unix.so" 2>/dev/null)
if [ -z "$MOD" ]; then
    ${ECHO} "${RED}[-] pam_unix.so not found${NC}"
else
    for i in $MOD; do
        i=$(echo $i | sed 's/\/pam_unix.so//g')
        ${ECHO} "${YELLOW}$i/pam_unix.so hash: ${NC}$(sha256sum $i/pam_unix.so | cut -d' ' -f1)""\n"
        ${ECHO} "${YELLOW}$i/pam_permit.so hash: ${NC}$(sha256sum $i/pam_permit.so | cut -d' ' -f1)""\n"
        ${ECHO} "${YELLOW}$i/pam_deny.so hash: ${NC}$(sha256sum $i/pam_deny.so | cut -d' ' -f1)""\n"
    done
fi

NOLOGIN=$(find /bin /sbin /usr -name nologin 2>/dev/null)
if [ -z "$NOLOGIN" ]; then
    ${ECHO} "${RED}[-] nologin not found${NC}"
else
    for i in $NOLOGIN; do
        ${ECHO} "${YELLOW}$i hash: ${NC}$(sha256sum $i | cut -d' ' -f1)""\n"
    done
fi

FALSE=$(find /bin /sbin /usr -name false 2>/dev/null)
if [ -z "$FALSE" ]; then
    ${ECHO} "${RED}[-] false not found${NC}"
else
    for i in $FALSE; do
        ${ECHO} "${YELLOW}$i hash: ${NC}$(sha256sum $i | cut -d' ' -f1)""\n"
    done
fi

TRUE=$(find /bin /sbin /usr -name true 2>/dev/null)
if [ -z "$TRUE" ]; then
    ${ECHO} "${RED}[-] true not found${NC}"
else
    for i in $TRUE; do
        ${ECHO} "${YELLOW}$i hash: ${NC}$(sha256sum $i | cut -d' ' -f1)""\n"
    done
fi


${ECHO} "\n${GREEN}##########################End of Output#########################${NC}"