

Write-Output "`n####Hostname####"
Hostname


Write-Output "`n#### OS ####" 
(Get-WMIObject win32_operatingsystem).caption

if((Get-WmiObject Win32_ComputerSystem).DomainRole -eq 4 -or  (Get-WmiObject Win32_ComputerSystem).DomainRole -eq 5 -or (Get-WmiObject -Query "select * from Win32_OperatingSystem where ProductType='2'")){$DC = $true}


if ($DC) {
    Write-Output "`nDomain Controller Detected"
    $DomainRole = ((Get-WmiObject Win32_ComputerSystem).DomainRole)
    switch($DomainRole){
        "4" {Write-output "Backup Domain Controller"}
        "5"{Write-Output "Main Domain Controller"}
    
    }
    Write-Output "Domain Role $DomainRole" 
}

Write-Output "`n####IP Address####"
Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IpAddress -ne $null } | ForEach-Object { $_.IPAddress } | Where-Object { [System.Net.IPAddress]::Parse($_).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork }


Write-Output "`n####Gateway####"
Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.DefaultIPGateway -ne $null } | ForEach-Object { $_.DefaultIPGateway }

Write-Output "`n####DNS####"
Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.DNSServerSearchOrder -ne $null } | ForEach-Object { $_.DNSServerSearchOrder }



Write-Output "`n####RAM & Storage####"
$RAM = Get-WmiObject Win32_ComputerSystem | Select-Object TotalPhysicalMemory
$RAM = $RAM.TotalPhysicalMemory / 1GB
$RAM = "{0:N2}" -f $RAM
$RAM = $RAM + " GB RAM"
$RAM

$Storage = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | Select-Object DeviceID, @{Name="Size";Expression={"{0:N2}" -f ($_.Size / 1GB) + " GB"}}, @{Name="FreeSpace";Expression={"{0:N2}" -f ($_.FreeSpace / 1GB) + " GB"}}
$Storage | Format-Table -AutoSize -Wrap


Write-Output "`n#### Services####"
$Services = @()
$CheckServices = @("mssql", "mysql", "mariadb", "pgsql", "apache", "nginx", "tomcat", "httpd", "mongo", "ftp", "filezilla", "ssh", "vnc", "dns", "ntds", "CertSvc", "w3svc", "tvnserver", "MTA", "MEPOC", "SMTP", "hMail", "Exchange")
foreach ($CheckService in $CheckServices) {
    $SvcQuery = Get-WmiObject win32_service | Where-Object { $_.Name -like "*$CheckService*" }
    if ($null -ne $SvcQuery) {
        if ($SvcQuery.GetType().IsArray) {
            foreach ($Svc in $SvcQuery) {
                $Services += $Svc
                
            }
        }
        elseif ($SvcQuery) {
            $Services += $SvcQuery
        }
    }
    
}

$Services | Select-Object Name, DisplayName, State, PathName | Format-Table -AutoSize -Wrap

Write-Output "`n#### ALL Users ####" 
Get-WmiObject win32_useraccount | ForEach-Object { $_.Name }


Write-Output "`n####TCP Connections####"
function Get-TcpConnections {
    $connections = netstat -anop TCP | Where-Object { $_ -match '\s+TCP\s+' }
    $connectionInfo = @()

    foreach ($connection in $connections) {
        $cols = $connection -split '\s+'
        $localAddress = $cols[2].Split(":")[0]
        $localPort = $cols[2].Split(":")[-1]
        $remoteAddress = $cols[3].Split(":")[0]
        $remotePort = $cols[3].Split(":")[-1]
        $state = $cols[4]
        $processpid = $cols[-1]

        $connectionInfo += New-Object PSObject -Property @{
            "LocalAddress"  = $localAddress
            "LocalPort"     = $localPort
            "RemoteAddress" = $remoteAddress
            "RemotePort"    = $remotePort
            "State"         = $state
            "PID"           = $processpid
            "ProcessName"   = (Get-Process -Id $processpid).ProcessName
        }
    }

    return $connectionInfo
}
$TCPConnections = Get-TcpConnections

$TCPConnections | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, PID, ProcessName | Format-Table -AutoSize