$ErrorActionPreference = "SilentlyContinue"
if(-not (Get-Command Get-ScheduledTask)){
    schtasks /Change /TN FWRevert /Disable
}

else{
    Disable-ScheduledTask -TaskName "FWRevert"
    $a = Get-ScheduledTask -TaskName "FWRevert" | Select-Object State
    if($a.state -eq "Disabled"){ Write-Host "Disabled FWRevert" -BackgroundColor Green}
}

