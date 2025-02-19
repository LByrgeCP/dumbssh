# Author: Dylan Harvey (modified from Joshua Wright's Original, see URL)
# Script for finding hidden services.
# https://www.sans.org/blog/defense-spotlight-finding-hidden-windows-services/

# Locates potentially unwatnted hidden services
$hiddenServices = Compare-Object `
    -ReferenceObject (Get-Service | 
        Select-Object -ExpandProperty Name |
        ForEach-Object { $_ -replace "_[0-9a-f]{2,8}$" } ) `
    -DifferenceObject (Get-ChildItem -path hklm:\system\currentcontrolset\services |
        ForEach-Object { $_.Name -Replace "HKEY_LOCAL_MACHINE\\","HKLM:\" } |
        Where-Object { Get-ItemProperty -Path "$_" -name objectname -erroraction 'ignore' } |
        ForEach-Object { $_.substring(40) }) -PassThru |
    Where-Object { $_.sideIndicator -eq "=>" }

# None found
if ($hiddenServices.Count -eq 0) {
    Write-Host "No hidden services found."
    Pause
    return
}

# Hidden services found
Write-Host "Hiddern services detected:"
$hiddenServices | ForEach-Object { Write-Host $_}

# Removes these services on a case by case basis
foreach ($service in $hiddenServices) {
    $action = Read-Host -Prompt "Action for servuce '$service' (1: Remove, 2: Keep, A: Remove ALL, S: Skip ALL)"

    if ($action -eq "1") {
        Write-Host "Removing service: $service"
        Stop-Service -ServiceName $service
        Remove-Service -ServiceName $service
        sc.exe delete $service | Out-Null
        Write-Host "Service: $service successfully removed."
    } elseif ($action -eq "2") {
        Write-Host "Keeping service: $service"
    } elseif ($action -eq "S") {
        Write-Host "Skipping all hidden services..."
        break
    } elseif ($action -eq "A") {
        Write-Host "Removing all hidden services..."
        foreach ($srv in $hiddenServices) {
            Write-Host "Removing service: $service"
            Stop-Service -ServiceName $service
            Remove-Service -ServiceName $service
            sc.exe delete $service | Out-Null
            Write-Host "Service: $service successfully removed."
        }
        break
    } else {
        Write-Host "Invalid Option. Skipping Service: $service"
    }
}

Pause
