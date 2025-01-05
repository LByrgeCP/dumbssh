param(
    [String]$ScriptArgs = ""
)

$ArgumentsArray = $ScriptArgs -split ";"
if ($ArgumentsArray.Length -lt 1) {
    Write-Host "Not enough arguments provided." -ForegroundColor Red
    break
}
$Manager = $ArgumentsArray[0]
if ($ArgumentsArray[1]) {
    $RegistrationPassword = $ArgumentsArray[1]
} else {
    $RegistrationPassword = ""
}

$ErrorActionPreference = "Continue"

$DownloadPath = "C:\Windows\System32\wazuh-agent-4.9.2-1.msi"

if (Test-Path $DownloadPath) {
    $InstallCommand = "msiexec /i $DownloadPath /qn WAZUH_MANAGER=$Manager"
    if ($RegistrationPassword -ne "") {
        $InstallCommand += " WAZUH_REGISTRATION_PASSWORD=$RegistrationPassword"
    }
	
    cmd.exe /c "$InstallCommand"
    sc.exe config WazuhSvc start= auto
    sc.exe start WazuhSvc
}

if (sc.exe query WazuhSvc | Select-String "RUNNING") {
    Write-Host "Wazuh agent is running." -ForegroundColor Green
    Write-Output "Wazuh agent is running."
} else {
    Write-Host "Wazuh agent is NOT running." -ForegroundColor RED
    Write-Output "Wazuh agent is NOT running."
}
