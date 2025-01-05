#!/usr/bin/env python3
import os
import re
import sys
import json
import subprocess

class Host:
    def __init__(self, ip):
        self.ip = ip
        self.services = []
        self.os_markers = {"windows": 0, "linux": 0}
        self.os = "Unknown"

    def add_service(self, service):
        if service not in self.services:
            self.services.append(service)

    def add_os_marker(self, os_type):
        if os_type in self.os_markers:
            self.os_markers[os_type] += 1

    def determine_os(self):
        if self.os_markers["linux"] > self.os_markers["windows"]:
            self.os = "Linux"
        elif self.os_markers["windows"] > self.os_markers["linux"]:
            self.os = "Windows"
        else:
            self.os = "Unknown"

    def summary(self):
        return {
            "ip": self.ip,
            "os": self.os,
            "services": self.services
        }

def execute(command):
    output = ""
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

    while True:
        nextline = process.stdout.readline().decode('utf-8')
        if nextline == '' and process.poll() is not None:
            break
        output += nextline
        sys.stdout.write(nextline)
        sys.stdout.flush()

    exitCode = process.returncode

    if exitCode == 0:
        return output
    else:
        raise Exception(command, exitCode, output)

LINUX_FINGERPRINTS = [ "ubuntu 24.04", "ubuntu 22.04", "ubuntu 20.04", "ubuntu 18.04", "ubuntu 16.04", "ubuntu 14.04", "ubuntu 12.04", "debian 11", "debian 10", "debian 9", "debian 8", "fedora 34", "fedora 33", "fedora 32", "fedora 31", "fedora 30", "centos 8", "centos 7", "centos 6", "redhat 8", "redhat 7", "redhat 6", "ubuntu", "debian", "fedora", "centos", "redhat", "freebsd", "openbsd", "netbsd", "suse", "opensuse", "arch", "gentoo", "slackware", "alpine", "rhel", "linux", "samba" ]
WINDOWS_FINGERPRINTS = [ "windows server 2022", "windows server 2019", "windows server 2016", "windows server 2012", "windows server 2008", "windows server 2003", "windows 11", "windows 10", "windows 8", "windows 7", "windows vista", "windows xp", "windows 2000", "windows workstation 10", "windows workstation 8", "windows workstation 7", "windows workstation vista", "windows workstation xp", "windows workstation 2000", "windows workstation", "windows server", "microsoft", "msrpc", "ms-sql", "winrm" ]
DC_FINGERPRINTS = [ "kerberos", "ldap" ]
FTP_FINGERPRINTS = [ "proftpd", "vsftpd", "pure-ftpd", "ftp", "sftp", "ftps" ]
MAIL_FINGERPRINTS = [ "exim", "sendmail", "postfix", "dovecot", "qmail", "squirrelmail", "smtp", "pop3", "imap" ]
HTTP_FINGERPRINTS = [ "apache", "nginx", "iis", "http-proxy", "flask", "tomcat", "jboss", "weblogic", "websphere", "glassfish", "jetty", "resin", "tomee", "wildfly", "jenkins", "gitlab", "drupal", "wordpress", "joomla", "magento", "prestashop", "opencart", "oscommerce", "zencart", "mediawiki", "phpmyadmin", "webmin", "cpanel", "plesk" ]
DB_FINGERPRINTS = [ "mysql", "mssql", "postgresql", "oracle" ]
REMOTE_FINGERPRINTS = [ "tightvnc", "realvnc", "ultravnc", "tigervnc", "nomachine", "ms-wbt-server", "ultr@vnc", "xrdp", "x11", "xorg", "rdp", "vnc", "ssh" ]

if len(sys.argv) > 1:
    ip = sys.argv[1]
else:
    ip = input("Enter the IP address of the target: ")
cmd = f"sudo nmap -A -oN nmap_out {ip}"

print(f"Running: {cmd}")

try:
    output = execute(cmd)
except Exception as e:
    print(f"Error running nmap: {e}")
    sys.exit(1)

hosts = {}
current_host = None

print("*" * 50)
print("Identifying OS and services...")
print("*" * 50)

output = output.split("\n")
for line in output:
    if "Nmap scan report for" in line:
        ip = line.split(" ")[-1]
        current_host = Host(ip)
        hosts[ip] = current_host
    elif current_host:
        line_lower = line.lower()
        for windows_fingerprint in WINDOWS_FINGERPRINTS:
            if windows_fingerprint in line_lower:
                current_host.add_os_marker("windows")
        for linux_fingerprint in LINUX_FINGERPRINTS:
            if linux_fingerprint in line_lower:
                current_host.add_os_marker("linux")
        for dc_fingerprint in DC_FINGERPRINTS:
            if dc_fingerprint in line_lower:
                current_host.add_service(f"Domain Controller ({dc_fingerprint})")
        for ftp_fingerprint in FTP_FINGERPRINTS:
            if ftp_fingerprint in line_lower:
                current_host.add_service(f"FTP ({ftp_fingerprint})")
        for mail_fingerprint in MAIL_FINGERPRINTS:
            if mail_fingerprint in line_lower:
                current_host.add_service(f"Mail ({mail_fingerprint})")
        for http_fingerprint in HTTP_FINGERPRINTS:
            if http_fingerprint in line_lower:
                current_host.add_service(f"HTTP ({http_fingerprint})")
        for db_fingerprint in DB_FINGERPRINTS:
            if db_fingerprint in line_lower:
                current_host.add_service(f"Database ({db_fingerprint})")
        for remote_fingerprint in REMOTE_FINGERPRINTS:
            if remote_fingerprint in line_lower:
                current_host.add_service(f"Remote ({remote_fingerprint})")

for host_ip, host_data in hosts.items():
    host_data.determine_os()

print("\n" + "=" * 50)
print("Summary of Hosts:")
print("=" * 50)
for host_ip, host_data in hosts.items():
    summary = host_data.summary()
    print(f"Host: {summary['ip']}")
    print(f"  OS: {summary['os']}")
    print(f"  Services: {', '.join(summary['services'])}")
    print("-" * 50)
