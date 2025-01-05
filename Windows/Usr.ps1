param(
[String]$ScriptArgs = @("")
)

$ErrorActionPreference = "SilentlyContinue"
$DomainController = $False

$ArgumentsArray = $ScriptArgs -split ";"
$UserPassword = $ArgumentsArray[0]
$AdminPassword = $ArgumentsArray[1]
$Exclude = $ArgumentsArray[2]
$Exclude = $Exclude -split ","

$CSVArray = @("")

Add-Type -AssemblyName System.Web
function Get-Password {
    do {
        $p = [System.Web.Security.Membership]::GeneratePassword(14,4)
    } while ($p -match '[,;:|iIlLoO0]')
    return $p + "1!"
}

if ($UserPassword -eq 'YOLO') {
	$UserPassword = Get-Password
}

if (Get-WmiObject -Query "select * from Win32_OperatingSystem where ProductType='2'") {
    $DomainController = $True
    Write-Host "`n$env:ComputerName - Domain Controller" -ForegroundColor Yellow

    if ((Get-WmiObject Win32_ComputerSystem).DomainRole -eq 4) {
        Write-Host "[INFO] Secondary Domain Controller Detected." -ForegroundColor Yellow 
        break
    }
}
else {
    Write-Host "`n$env:ComputerName" -ForegroundColor Yellow
}

if ($DomainController) {
    Import-Module ActiveDirectory
    $Users = Get-ADUser -Filter * | Select-Object -ExpandProperty sAMAccountName
    foreach ($User in $Users) {
        if ($Exclude -contains $user) {
            Write-Host "[SKIPPED] Skipped changing $User's password." -ForegroundColor Gray
            continue
        }
        try {
            Set-AdAccountPassword -Identity "$User" -NewPassword (ConvertTo-SecureString -AsPlainText $UserPassword -Force) -Reset -ErrorAction Stop
            Write-Host "[SUCCESS] Successfully changed "$User"'s password." -ForegroundColor Green
            $CSVArray += "$User,$UserPassword"
        }
        catch {
            Write-Output "[ERROR] Failed to change $User's password." -ForegroundColor Red
        }
    }

    try {
        $UserExists = Get-ADUser -Filter {SAMAccountName -eq "ttuccdc"}
        
        if ($UserExists) {
            Set-ADAccountPassword -Identity "ttuccdc" -NewPassword (ConvertTo-SecureString -AsPlainText $AdminPassword -Force) -Reset -ErrorAction Stop
        }

        if (!$UserExists) {
            New-ADUser -Name "ttuccdc" -AccountPassword (ConvertTo-SecureString -AsPlainText $AdminPassword -Force) -Enabled $True -ErrorAction Stop
            Write-Host "[SUCCESS] Successfully created ttuccdc user on $env:ComputerName" -ForegroundColor Green
        }

        try {
            Add-ADGroupMember -Identity "Administrators" -Members "ttuccdc"
        }
        catch {
            Write-Host "[INFO] ttuccdc is already in Administrators group." -ForegroundColor Yellow
        }
        try {
            Add-ADGroupMember -Identity "Remote Desktop Users" -Members "ttuccdc"
        }
        catch {
            Write-Host "[INFO] ttuccdc is already in Remote Desktop Users Group." -ForegroundColor Yellow
        }
        try {
            Add-ADGroupMember -Identity "Domain Admins" -Members "ttuccdc"
        }
        catch {
            Write-Host "[INFO] ttuccdc is already in Domain Admins Group." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "[ERROR] Failed to create user ttuccdc." -ForegroundColor Red
        Set-ADAccountPassword -Identity "Administrator" -NewPassword (ConvertTo-SecureString -AsPlainText $AdminPassword -Force) -Reset
        Enable-ADAccount -Identity "Administrator"
    }
}
else {
    try {
        $Users = Get-LocalUser | Select-Object -ExpandProperty Name
        foreach ($User in $Users) {
            if ($Exclude -contains $user) {
                Write-Host "[SKIPPED] Skipped changing $User's password." -ForegroundColor Gray
                continue
            }
            try {
                Set-LocalUser -Name "$User" -Password (ConvertTo-SecureString -AsPlainText "$UserPassword" -Force) -AccountNeverExpires -ErrorAction Stop
                Write-Host "[SUCCESS] Successfully changed $User's password." -ForegroundColor Green
                $CSVArray += "$User,$UserPassword"
            } 
            catch {
                Write-Host "[ERROR] Failed to change $User's password." -ForegroundColor Red
            }
        }
    }
    catch {
        $Users = Get-WmiObject -Class Win32_UserAccount | Select-Object -ExpandProperty Name
        foreach ($User in $Users) {
            if ($Exclude -contains $user) {
                Write-Host "[SKIPPED] Skipped changing $User's password." -ForegroundColor Gray
                continue
            }
            try {
                net user $User $UserPassword -ErrorAction Stop
                Write-Host "[SUCCESS] Successfully changed $User's password." -ForegroundColor Green
                $CSVArray += "$User,$UserPassword"
            }
            catch {
                Write-Host "[ERROR] Failed to change $User's password." -ForegroundColor Red
            }
        }
    }
    
    try {

        try {
            $UserExists = [bool](Get-LocalUser -Name "ttuccdc")
        }
        catch {
            $UserExists = [bool](Get-WmiObject -Class Win32_UserAccount -Filter "Name='ttuccdc'")
        }

        if ($UserExists) {
            try {
            Set-LocalUser -Name "ttuccdc" -Password (ConvertTo-SecureString -AsPlainText $AdminPassword -Force) -AccountNeverExpires
            }
            catch {
            net user ttuccdc $AdminPassword
            }
        }

        if (!$UserExists) {
            try {
            New-LocalUser -Name "ttuccdc" -Password (ConvertTo-SecureString -AsPlainText $AdminPassword -Force) -AccountNeverExpires
            }
            catch {
            net user ttuccdc $AdminPassword /add
            }
            Write-Host "[SUCCESS] Successfully created ttuccdc user on $env:ComputerName" -ForegroundColor Green
        }

        try {
            Add-LocalGroupMember -Group "Administrators" -Member "ttuccdc" -ErrorAction Stop
        } 
        catch {
            try {
            net localgroup Administrators ttuccdc /add
            }
            catch {
            Write-Host "[INFO] ttuccdc is already in Administrators." -ForegroundColor Yellow
            }
        }
        try {
            Add-LocalGroupMember -Group "Remote Desktop Users" -Member "ttuccdc" -ErrorAction Stop
        }
        catch {
            try {
            net localgroup "Remote Desktop Users" ttuccdc /add
            }
            catch {
            Write-Host "[INFO] ttuccdc is already in Remote Desktop Users." -ForegroundColor Yellow
            }
        }
        }
        catch {
        Write-Host "[ERROR] Failed to create user ttuccdc." -ForegroundColor Red
        try {
            Set-LocalUser -Name "Administrator" -Password (ConvertTo-SecureString -AsPlainText $AdminPassword -Force) -AccountNeverExpires
        }
        catch {
            net user Administrator $AdminPassword
        }
        Set-LocalUser -Name "Administrator" -AccountNeverExpires
        }
}

foreach ($User in $CSVArray) {
    Write-Output "$User"
}


