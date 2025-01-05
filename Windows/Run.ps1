param(
    # $Script: The path to the script that will be run on the remote computers
    [Parameter(Mandatory=$false)]
    [String]$Script = '',

    # $Out: The directory where the output of the scripts will be saved
    [Parameter(Mandatory=$false)]
    [String]$Out = '',

    # $Connect: A switch parameter. If present, the script will connect to the remote computers
    [Parameter(Mandatory=$false)]
    [switch]$Connect,

    # $Repair: A switch parameter. If present, the script will attempt to repair any broken or disconnected sessions
    [Parameter(Mandatory=$false)]
    [switch]$Repair,

    # $Include: An array of computer names to include in the operation
    [Parameter(Mandatory=$false)]
    [string[]]$Include,

    # $Exclude: An array of computer names to exclude from the operation
    [Parameter(Mandatory=$false)]
    [string[]]$Exclude,

    # $NonDomain: A switch parameter. If present, the script will operate on non-domain computers
    [Parameter(Mandatory=$false)]
    [switch]$NonDomain,

    # $Hosts: The path to a file containing a list of hosts (one per line) to operate on
    [Parameter(Mandatory=$false)]
    [String]$Hosts = '',

    # $File: File to be copied to the remote computers
    [Parameter(Mandatory=$false)]
    [String]$File = '',

    # $Path: The path to the directory where the file will be copied to on the remote computers
    [Parameter(Mandatory=$false)]
    [String]$Path = '',

    [Parameter(Mandatory=$false)]
    [String]$ScriptArgs = ''
)

class Host {
    [string]$IP
    [string]$Username
    [string]$Password
    [string]$Comment

    Host([string]$ip, [string]$username, [string]$password, [string]$comment) {
        $this.IP = $ip
        $this.Username = $username
        $this.Password = $password
        $this.Comment = $comment
    }
}

$ErrorActionPreference = "Continue"

if ($Connect) {

    if (!$Repair) {
        Remove-Variable -Name Sessions -Scope Global -ErrorAction SilentlyContinue;
        Remove-Variable -Name Denied -Scope Global -ErrorAction SilentlyContinue;
        Remove-Variable -Name Computers -Scope Global -ErrorAction SilentlyContinue;
        $global:Sessions = @()
        $global:Denied = @()
        $global:Computers = @()
        Get-PSSession | Remove-PSSession
    }

    if ($NonDomain) {

        if ($Repair) {
            $global:Cred = Get-Credential
            if ($global:Sessions.Count -eq 0) {
                Write-Host "[ERROR] No sessions" -ForegroundColor Red
                exit
            }
            else {
                for ($i = 0; $i -lt $global:Sessions.count; $i++) {
                    if ($Sessions[$i].State -eq "Broken" -or $Sessions[$i].State -eq "Disconnected") {
                        $global:Sessions[$i] = New-PSSession -ComputerName $global:Sessions[$i].ComputerName -Credential $global:Cred
                        Write-Host "[INFO] Reconnected: $($global:Sessions[$i].ComputerName)" -ForegroundColor Green
                    }
                }
            }
        } else {
            try {
                $CSVContent = Import-Csv -Path $Hosts
                foreach ($Row in $CSVContent) {
                    $global:Computers += [Host]::new($Row.IP, $Row.Username, $Row.Password, $Row.Comment)
                }
            }
            catch {
                Write-Host "[ERROR] Failed to get computers from file" -ForegroundColor Red
                exit
            }
    
            # Current directory we're in, so that it can pull TestPort.ps1
            $CurrentDirectory = $PWD | Select-Object -ExpandProperty Path

            foreach ($Computer in $global:Computers) {
                Start-Job -ScriptBlock { cd $Using:CurrentDirectory; Import-Module .\TestPort.ps1; Test-Port -Ip $Using:Computer.IP -Port 5985 } > $null 2>&1
            }

            $5985Table = Receive-Job * -Wait

            foreach ($Computer in $global:Computers) {
                Start-Job -ScriptBlock { cd $Using:CurrentDirectory; Import-Module .\TestPort.ps1; Test-Port -Ip $Using:Computer.IP -Port 5986 } > $null 2>&1
            }

            $5986Table = Receive-Job * -Wait

            # if any of the computers are missing a username or password, we'll create a credential object to share across all sessions that need it
            foreach ($Computer in $global:Computers) {
                if ($Computer.Username -eq '' -or $Computer.Password -eq '') {
                    $global:Cred = Get-Credential
                    break
                }
            }

            foreach ($Computer in $global:Computers) {
                if ($5985Table.$($Computer.IP)) {
                    if ($Computer.Username -eq '' -or $Computer.Password -eq '') {
                        $TestSession = New-PSSession -ComputerName $Computer.IP -Credential $global:Cred
                    }
                    else {
                        $TestSession = New-PSSession -ComputerName $Computer.IP -Credential (New-Object System.Management.Automation.PSCredential ($Computer.Username, (ConvertTo-SecureString $Computer.Password -AsPlainText -Force)))
                    }
                    if ($TestSession) {
                        $global:Sessions += $TestSession
                        Write-Host "[INFO] Connected: $($Computer.IP)" -ForegroundColor Green
                    }
                    else {
                        $global:Denied += $Computer
                        Write-Host "[ERROR] WinRM Port 5985 Failed: $($Computer.IP)" -ForegroundColor Red
                    }
                }
                elseif ($5986Table.$($Computer.IP)) {
                    if ($Computer.Username -eq '' -or $Computer.Password -eq '') {
                        $TestSession = New-PSSession -ComputerName $Computer.IP -UseSSL -Credential $global:Cred -SessionOption @{SkipCACheck=$true;SkipCNCheck=$true;SkipRevocationCheck=$true}
                    }
                    else {
                        $TestSession = New-PSSession -ComputerName $Computer.IP -UseSSL -Credential (New-Object System.Management.Automation.PSCredential ($Computer.Username, (ConvertTo-SecureString $Computer.Password -AsPlainText -Force))) -SessionOption @{SkipCACheck=$true;SkipCNCheck=$true;SkipRevocationCheck=$true}
                    }
                    if ($TestSession) {
                        $global:Sessions += $TestSession
                        Write-Host "[INFO] Connected via SSL: $($Computer.IP)" -ForegroundColor Green
                    }
                    else {
                        $global:Denied += $Computer
                        Write-Host "[ERROR] WinRM Port 5986 Failed: $($Computer.IP)" -ForegroundColor Red
                    }                    
                }
                else {
                    $global:Denied += $Computer
                    Write-Host "[ERROR] WinRM Ports Closed: $($Computer.IP)" -ForegroundColor Red
                }
            }
        }
    }
    else {
        if ($Repair) {
            if ($global:Sessions.Count -eq 0) {
                Write-Host "[ERROR] No sessions" -ForegroundColor Red
                exit
            }
            else {
                for ($i = 0; $i -lt $global:Sessions.count; $i++) {
                    if ($Session.State -eq "Broken" -or $Session.State -eq "Disconnected") {
                        $global:Sessions[$i] = New-PSSession -ComputerName $global:Sessions[$i].ComputerName
                        Write-Host "[INFO] Reconnected: $($global:Sessions[$i].ComputerName)" -ForegroundColor Green
                    }
                }
            }
        } else {
            try {
                $global:Computers = Get-ADComputer -filter * -Properties * | Where-Object {$_.OperatingSystem -Like "*Windows*"} | Sort-Object | Select-Object -ExpandProperty Name
            }
            catch {
                Write-Host "[ERROR] Failed to get computers from AD" -ForegroundColor Red
                exit
            }
    
            Write-Host "[INFO] Found the following servers:" -ForegroundColor Green
            foreach ($Computer in $global:Computers) {
                Write-Host "$Computer"
            }

            $CurrentDirectory = $PWD | Select-Object -ExpandProperty path

            foreach ($Computer in $global:Computers) {
                Start-Job -ScriptBlock { cd $Using:CurrentDirectory; Import-Module .\TestPort.ps1; Test-Port -Ip $Using:Computer -Port 5985 } > $null 2>&1
            }
            $5985Table = Receive-Job * -Wait

            foreach ($Computer in $global:Computers) {
                Start-Job -ScriptBlock { cd $Using:CurrentDirectory; Import-Module .\TestPort.ps1; Test-Port -Ip $Using:Computer -Port 5986 } > $null 2>&1
            }
            $5986Table = Receive-Job * -Wait

            foreach ($Computer in $global:Computers) {
                if ($5985Table.$Computer) {
                    $TestSession = New-PSSession -ComputerName $Computer
                    if ($TestSession) {
                        $global:Sessions += $TestSession
                        Write-Host "[INFO] Connected: $Computer" -ForegroundColor Green
                    }
                    else {
                        $global:Denied += $Computer
                        Write-Host "[ERROR] WinRM Port 5985 Failed: $Computer" -ForegroundColor Red
                    }
                }
                elseif ($5986Table.$Computer) {
                    $TestSession = New-PSSession -ComputerName $Computer -UseSSL -SessionOption @{SkipCACheck=$true;SkipCNCheck=$true;SkipRevocationCheck=$true}
                    if ($TestSession) {
                        $global:Sessions += $TestSession
                        Write-Host "[INFO] Connected via SSL: $Computer" -ForegroundColor Green
                    }
                    else {
                        $global:Denied += $Computer
                        Write-Host "[ERROR] WinRM Port 5986 Failed: $Computer" -ForegroundColor Red
                    }                    
                }
                else {
                    $global:Denied += $Computer
                    Write-Host "[ERROR] WinRM Ports Closed: $Computer" -ForegroundColor Red
                }

            }
        }
    }
}
if ($File -ne '' -and $Path -ne '' -and $global:Sessions.Count -gt 0) {
    if (!(Test-Path $File)) {
        Write-Host "[ERROR] File does not exist" -ForegroundColor Red
        exit
    }
    
    foreach ($Session in $global:Sessions) {
        if ($Exclude -contains $Session.ComputerName) {
            Write-Host "[INFO] Excluded: $($Session.ComputerName)" -ForegroundColor Yellow
            continue
        }
        elseif ($Include.Count -gt 0 -and $Include -notcontains $Session.ComputerName) {
            Write-Host "[INFO] Did not Include: $($Session.ComputerName)" -ForegroundColor Yellow
            continue
        }
        Copy-Item -Path $File -Destination "$Path" -ToSession $Session
        Write-Host "[INFO] Copied: $File to $($Session.ComputerName):$Path" -ForegroundColor Green
    }
}
if (($Script -ne '') -and ($global:Sessions.Count -gt 0) -and ($Out -ne '')) {

    if (!(Test-Path $Out)) {
        mkdir $Out
    }
    $Jobs = @()
    do {
        $Extension = ""
        $Script = $Script.ToLower()
        $ScriptName = $Script.Split(".")[-2]
        $Extension += $ScriptName.Substring(1)
        $Extension += ".$(Get-Random -Maximum 1000)";
    } while (Test-Path "$Out\*.$Extension")

    foreach ($Session in $global:Sessions) {
        if ($Exclude -contains $Session.ComputerName) {
            Write-Host "[INFO] Excluded: $($Session.ComputerName)" -ForegroundColor Yellow
            continue
        }
        elseif ($Include.Count -gt 0 -and $Include -notcontains $Session.ComputerName) {
            Write-Host "[INFO] Did not Include: $($Session.ComputerName)" -ForegroundColor Yellow
            continue
        }
        
        # Execute Script
        $ScriptJob = Invoke-Command -FilePath $Script -Session $Session -AsJob -ArgumentList $ScriptArgs
        
        $Jobs += $ScriptJob
        Write-Host "[INFO: $Script] Script invoked on $($Session.ComputerName)" -ForegroundColor Green
    }
    
    $Complete = @()
    $TotalJobs = $Jobs.count
    $IncompleteJobs = @()
    while ($Complete.Count -lt $TotalJobs) {
        for ($i = 0; $i -lt $Jobs.count; $i++) {
            if ($Jobs[$i].State -eq "Completed" -and $Complete -notcontains $Jobs[$i].Location) {
                if ($global:Computers | Where-Object { $_.IP -eq $Jobs[$i].Location }) {

                    $Comment = $global:Computers | Where-Object { $_.IP -eq $Jobs[$i].Location } | Select-Object -ExpandProperty Comment
                    if ($Comment -ne $null -and $Comment -ne "") {
                        $Jobs[$i] | Receive-Job | Out-File "$Out\$($Jobs[$i].Location).$Comment.$Extension" -Encoding utf8
                    }
                    else {
                        $Jobs[$i] | Receive-Job | Out-File "$Out\$($Jobs[$i].Location).$Extension" -Encoding utf8
                    }
                } else {
                    $Jobs[$i] | Receive-Job | Out-File "$Out\$($Jobs[$i].Location).$Extension" -Encoding utf8
                }
                Write-Host "[INFO: $Script] Script completed on $($Jobs[$i].Location) logged to $Extension" -ForegroundColor Green
                $Complete += $($Jobs[$i].Location)
                # Get-Job
            }
            elseif ($Jobs[$i].State -eq "Running" -and $Complete -notcontains $Jobs[$i].Location){
                $IncompleteJobs += $Jobs[$i]
            }
            elseif ($Jobs[$i].State -eq "Failed" -and $Complete -notcontains $Jobs[$i].Location){
                Write-Host "[ERROR: $Script] Script failed on $($Jobs[$i].Location)" -ForegroundColor Red
                $Complete += $($Jobs[$i].Location)
                $Jobs[$i] | Receive-Job
            }
        }
        if ($IncompleteJobs.Count -ge 1){
            $Jobs = $IncompleteJobs
            $IncompleteJobs = @()
            Start-Sleep -Milliseconds 25
        }
    }
    Get-Job | Remove-Job
}
if ($Sessions.Count -eq 0 -and !$Connect) {
    Write-Host "[ERROR] No sessions" -ForegroundColor Red
}
if ($Script -eq '' -and !$Connect) {
    Write-Host "[ERROR] No script" -ForegroundColor Red
}
if ($File) {
    if ($File -eq '' -and $Path -eq '' -and !$Connect) {
        Write-Host "[ERROR] No file or path" -ForegroundColor Red
    }
}
if ($Out -eq '' -and !$Connect) {
    Write-Host "[ERROR] No output directory" -ForegroundColor Red
}