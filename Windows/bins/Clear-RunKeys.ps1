# Author: Dylan Harvey
# Script for removing common runkeys.

#Requires -RunAsAdministrator

# May want to add a more extensive list of common runkeys/hidden paths etc
$RunKeys = @(
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
)

# Clear all values in the keys
foreach ($Key in $RunKeys) {
    Remove-Item -Path $Key -Recurse -Force # -ErrorAction SilentlyContinue
}

Write-Host "Review extra_runkeys.txt for further registry paths that should be examined."