$ErrorActionPreference = "SilentlyContinue"
if(-not (Get-Command Get-NetTCPConnection)){
    netstat -n | Select-String -Pattern ":(5985|5986)" | Write-Host
}
else{
    (Get-NetTCPConnection -LocalPort 5985 -State Established).RemoteAddress | Write-Host
}

