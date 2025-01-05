param(
    [string]$IPAddress,
    [string]$OutputFile = "nmap_out"
)

$LinuxFingerprints = @("ubuntu 24.04", "ubuntu 22.04", "ubuntu 20.04", "ubuntu 18.04", "ubuntu 16.04", "ubuntu 14.04", "ubuntu 12.04", "debian 11", "debian 10", "debian 9", "debian 8", "fedora 34", "fedora 33", "fedora 32", "fedora 31", "fedora 30", "centos 8", "centos 7", "centos 6", "redhat 8", "redhat 7", "redhat 6", "ubuntu", "debian", "fedora", "centos", "redhat", "freebsd", "openbsd", "netbsd", "suse", "opensuse", "arch", "gentoo", "slackware", "alpine", "rhel", "linux", "samba")
$WindowsFingerprints = @("windows server 2022", "windows server 2019", "windows server 2016", "windows server 2012", "windows server 2008", "windows server 2003", "windows 11", "windows 10", "windows 8", "windows 7", "windows vista", "windows xp", "windows 2000", "windows workstation 10", "windows workstation 8", "windows workstation 7", "windows workstation vista", "windows workstation xp", "windows workstation 2000", "windows workstation", "windows server", "microsoft", "msrpc", "ms-sql", "winrm")
$ServiceFingerprints = @{ 
    "Domain Controller" = @("kerberos", "ldap")
    "FTP" = @("proftpd", "vsftpd", "pure-ftpd", "ftp", "sftp", "ftps")
    "Mail" = @("exim", "sendmail", "postfix", "dovecot", "qmail", "squirrelmail", "smtp", "pop3", "imap")
    "HTTP" = @("apache", "nginx", "iis", "http-proxy", "flask", "tomcat", "jboss", "weblogic", "websphere", "glassfish", "jetty", "resin", "tomee", "wildfly", "jenkins", "gitlab", "drupal", "wordpress", "joomla", "magento", "prestashop", "opencart", "oscommerce", "zencart", "mediawiki", "phpmyadmin", "webmin", "cpanel", "plesk", "roundcube")
    "Database" = @("mysql", "mssql", "postgresql", "oracle")
    "Remote" = @("tightvnc", "realvnc", "ultravnc", "tigervnc", "nomachine", "ms-wbt-server", "ultr@vnc", "xrdp", "x11", "xorg", "rdp", "vnc", "ssh")
}

if (-not (Test-Path $OutputFile)) {
    if (-not $IPAddress) {
        $IPAddress = Read-Host "Enter the IP address of the target"
    }

    $NmapOutput = & nmap -A -oN $OutputFile $IPAddress 2>&1

    if (!$NmapOutput) {
        Write-Error "Failed to execute nmap. Ensure it is installed and in the PATH."
        exit 1
    }
} else {
    Write-Host "Reading existing output file: $OutputFile" -ForegroundColor Green
}

$Hosts = @{}
$CurrentHost = $null

Get-Content $OutputFile | ForEach-Object {
    $Line = $_.Trim()

    if ($Line -match "^Nmap scan report for (.+)") {
        $IP = $Matches[1]
        $CurrentHost = [PSCustomObject]@{
            IP = $IP
            OSMarkers = @{Linux = 0; Windows = 0}
            Services = @()
            OS = "Unknown"
        }
        $Hosts[$IP] = $CurrentHost
    } elseif ($CurrentHost) {
        $LineLower = $Line.ToLower()

        foreach ($Fingerprint in $WindowsFingerprints) {
            if ($LineLower.Contains($Fingerprint.ToLower())) {
                $CurrentHost.OSMarkers.Windows++
            }
        }

        foreach ($Fingerprint in $LinuxFingerprints) {
            if ($LineLower.Contains($Fingerprint.ToLower())) {
                $CurrentHost.OSMarkers.Linux++
            }
        }

        foreach ($Service in $ServiceFingerprints.Keys) {
            foreach ($Fingerprint in $ServiceFingerprints[$Service]) {
                if ($LineLower.Contains($Fingerprint.ToLower()) -and $Service -notin $CurrentHost.Services) {
                    $CurrentHost.Services += "$Service ($Fingerprint)"
                }
            }
        }
    }
}

# Determine OS
$Hosts.Values | ForEach-Object {
    if ($_.OSMarkers.Linux -gt $_.OSMarkers.Windows) {
        $_.OS = "Linux"
    } elseif ($_.OSMarkers.Windows -gt $_.OSMarkers.Linux) {
        $_.OS = "Windows"
    } else {
        $_.OS = "Unknown"
    }
}

# Display summary
Write-Host "`nSummary of Hosts:`n" -ForegroundColor Cyan
$Hosts.Values | ForEach-Object {
    Write-Host "Host: $($_.IP)"
    Write-Host "  OS: $($_.OS)"
    Write-Host "  Services: $([string]::Join(', ', $_.Services))"
    Write-Host ("-" * 50)
}
