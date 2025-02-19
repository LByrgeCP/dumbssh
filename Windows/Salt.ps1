sc.exe query salt-minion

$conf = Get-ChildItem -Path "C:\ProgramData\Salt Project\Salt\conf\minion" -ErrorAction SilentlyContinue
if ($conf -eq $null) {
    $conf = Get-ChildItem -Path "C:\salt\conf\minion" -ErrorAction SilentlyContinue
}

if ($conf -ne $null) {
    $master = Get-Content -Path $conf.FullName | Select-String -Pattern "(?<=^\s*master:\s*)[^\s-#][^\n]*|(?<=^\s*-\s*)[^\n#]+" | ForEach-Object { $_.Matches.Value }
    if ($master -ne $null) {
        Write-Host "Master: $master"
    } else {
        Write-Host "Master not found"
    }
    $id = Get-Content -Path $conf.FullName.Replace("minion", "minion_id") -ErrorAction SilentlyContinue
    if ($id -ne $null) {
        Write-Host "ID: $id"
    } else {
        Write-Host "ID not found"
    }
} else {
    Write-Host "Conf file not found"
}

nslookup.exe salt
nslookup.exe salt.salt