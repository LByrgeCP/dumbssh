#!/bin/sh
# @d_tranman/Nigel Gerald/Nigerald
# KaliPatriot | TTU CCDC | Landon Byrge

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

${ECHO} "\n${GREEN}##########################End of Output#########################${NC}"