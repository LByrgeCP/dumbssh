# Samuel Brucker 2024 - 2025
# Thanks SEMO

$ErrorActionPreference = "Continue"
$INDEXER_IP = "10.250.103.224"
$RECEIVER_PORT = "9997"

$SPLUNK_VERSION = "9.4.0"
$SPLUNK_BUILD = "6b4ebe426ca6"
$SPLUNK_MSI = "splunkforwarder-${SPLUNK_VERSION}-${SPLUNK_BUILD}-windows-x64.msi"
$SPLUNK_DOWNLOAD_URL = "https://download.splunk.com/products/universalforwarder/releases/${SPLUNK_VERSION}/windows/${SPLUNK_MSI}"
$INSTALL_DIR = "C:\Program Files\SplunkUniversalForwarder"

Write-Host "Downloading Splunk Universal Forwarder MSI..."

curl.exe -k $SPLUNK_DOWNLOAD_URL -o $SPLUNK_MSI
Write-Host "curl.exe -k $SPLUNK_DOWNLOAD_URL -o $SPLUNK_MSI"

Write-Host "Installing Splunk Universal Forwarder..."
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $SPLUNK_MSI AGREETOLICENSE=Yes RECEIVING_INDEXER=${INDEXER_IP}:${RECEIVER_PORT} /quiet" -Wait

$inputsConfPath = "$INSTALL_DIR\etc\system\local\inputs.conf"
Write-Host "Configuring inputs.conf for monitoring..."
@"
[default]
host = ActiveDirectory

[WinEventLog://Security]
disabled = 0
index = main

[WinEventLog://Application]
dsiabled = 0
index = main

[WinEventLog://System]
disabled = 0
index = main

[WinEventLog://DNS Server]
disabled = 0
index = main

[WinEventLog://Directory Service]
disabled = 0
index = main

[WinEventLog://Windows Powershell]
disabled = 0
index = main
"@ | Out-File -FilePath $inputsConfPath -Encoding ASCII

Write-Host "Starting Splunk Universal Forwarder service..."
Start-Process -FilePath "$INSTALL_DIR\bin\splunk.exe" -ArgumentList "start" -Wait

Write-Host "Setting Splunk Universal Forwarder to start on boot..."
Start-Process -FilePath "$INSTALL_DIR\bin\splunk.exe" -ArgumentList "enable boot-start" -Wait

Write-Host "Splunk Universal Forwarder installation and configuration complete!"
sc.exe query SplunkForwarder