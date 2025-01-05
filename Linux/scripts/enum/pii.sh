#!/bin/sh

if ! [ -z "$1" ]; then
    find_path="$1"
fi

if ! [ -z "$PATH" ]; then
    find_path="$PATH"
fi

grep_for_phone_numbers() {
    grep -RPo '(\([0-9]{3}\) |[0-9]{3}-)[0-9]{3}-[0-9]{4}' $1 2>/dev/null
}

grep_for_email_addresses() {
    grep -RPo '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}' $1 2>/dev/null
}

grep_for_social_security_numbers() {
    grep -RPo '[0-9]{3}-[0-9]{2}-[0-9]{4}' $1 2>/dev/null
}

grep_for_credit_card_numbers() {
    grep -RPo '(?:\d{4}-?){3}\d{4}|(?:\d{4}\s?){3}\d{4}|(?:\d{4}){4}' $1 2>/dev/null
}

grep_for_vehicle_regisration_numbers() {
    if ! [ -z "$VH"]; then
        grep -RPo '[A-Z]{1,2}[0-9]{1,2}\s?[A-Z]{1,3}\s?[0-9]{1,4}' $1 2>/dev/null
    fi
}

find_interesting_files_by_extension() {
    find $1 -type f -name '*.doc' -o -name '*.docx' -o -name '*.xls' -o -name '*.xlsx' -o -name '*.pdf' -o -name '*.ppt' -o -name '*.pptx' -o -name '*.txt' -o -name '*.rtf' -o -name '*.csv' -o -name '*.odt' -o -name '*.ods' -o -name '*.odp' -o -name '*.odg' -o -name '*.odf' -o -name '*.odc' -o -name '*.odb' -o -name '*.odm' -o -name '*.docm' -o -name '*.dotx' -o -name '*.dotm' -o -name '*.dot' -o -name '*.wbk' -o -name '*.xltx' -o -name '*.xltm' -o -name '*.xlt' -o -name '*.xlam' -o -name '*.xlsb' -o -name '*.xla' -o -name '*.xll' -o -name '*.pptm' -o -name '*.potx' -o -name '*.potm' -o -name '*.pot' -o -name '*.ppsx' -o -name '*.ppsm' -o -name '*.pps' -o -name '*.ppam' -o -name '*.pptx' 2>/dev/null
}

search() {
    grep_for_phone_numbers $1
    grep_for_email_addresses $1
    grep_for_social_security_numbers $1
    find_interesting_files_by_extension $1
    grep_for_credit_card_numbers $1
    grep_for_vehicle_regisration_numbers $1
}

if ! [ -z "$find_path" ]; then
    echo "[+] Searching $find_path for PII."
    search $find_path
fi

# look in /home
echo "[+] Searching /home for PII."
search /home

# look in /var/www
echo "[+] Searching /var/www for PII."
search /var/www

# if there is vsftpd installed, look in the anon_root and local_root directories
check_vsftpd_config() {
    if [ -f $1 ] ; then
        echo "[+] VSFTPD config file found at $1. Checking for anon_root and local_root directories."
        if [ -n "$(grep -E '^\s*anon_root' $1)" ]; then
            echo -e "[+] anon_root found. Checking for PII."
            anon_root=$(grep -E '^\s*anon_root' $1 | awk '{print $2}')
            search $anon_root
        fi

        if [ -n "$(grep -E '^\s*local_root' $1)" ]; then
            echo -e "[+] local_root found. Checking for PII."
            local_root=$(grep -E '^\s*local_root' $1 | awk '{print $2}')
            search $local_root
        fi
    fi
}

# Check for vsftpd.conf in common locations
check_vsftpd_config /etc/vsftpd.conf
check_vsftpd_config /etc/vsftpd/vsftpd.conf
check_vsftpd_config /usr/local/etc/vsftpd.conf
check_vsftpd_config /usr/local/vsftpd/vsftpd.conf

#proftpd
if [ -f /etc/proftpd/proftpd.conf ]; then
    echo "[+] ProFTPD config file found. Checking for anon_root and local_root directories."
    if [ -n "$(grep -E '^\s*DefaultRoot' /etc/proftpd/proftpd.conf)" ]; then
        echo -e "[+] DefaultRoot found. Checking for PII."
        default_root=$(grep -E '^\s*DefaultRoot' /etc/proftpd/proftpd.conf | awk '{print $2}')
        search $default_root
    fi
fi

# samba
if [ -f /etc/samba/smb.conf ]; then
    echo "[+] Samba config file found. Checking for shares."
    shares=$(grep -E '^\s*path' /etc/samba/smb.conf | awk '{print $3}' | sed 's/"//g')
    for share in $shares; do
        echo -e "[+] Checking $share for PII."
        search $share
    done
fi


# $USER and $PASS
# check mysql non default databases for PII
if [ -n "$USER" ] && [ -n "$PASS" ]; then
    echo "[+] Checking MySQL databases for PII."
    databases=$(mysql -u $USER -p$PASS -e "SHOW DATABASES;" 2>/dev/null | grep -v Database)
    for db in $databases; do
        if [ "$db" != "information_schema" ] && [ "$db" != "performance_schema" ] && [ "$db" != "mysql" ] && [ "$db" != "test" ] && [ "$db" != "sys" ]; then
            echo -e "[+] Checking $db for PII."
            tables=$(mysql -u $USER -p$PASS -e "SHOW TABLES FROM $db;" 2>/dev/null | grep -v Tables)
            for table in $tables; do
				mysql -u $USER -p$PASS -e "SELECT * FROM $db.$table;" 2>/dev/null | grep -v Field >> /tmp/pii.txt
            done
            search /tmp/pii.txt
            rm /tmp/pii.txt
        fi
    done
fi