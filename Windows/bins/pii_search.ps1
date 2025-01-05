param(
    [Parameter(Mandatory=$false)]
    [String[]]$Path = "C:\"
)

$ErrorActionPreference = "SilentlyContinue"

$Directory = "C:\Windows\System32\PII"

if (-not (Test-Path $Directory)) {
    New-Item -ItemType Directory -Path $Directory
}

$patterns = 
    '\b\d{3}[)]?[-| |.]\d{3}[-| |.]\d{4}\b', 
    '\b\d{3}[-| |.]\d{2}[-| |.]\d{4}\b',
    '\b\d+\s+[\w\s]+\s+(?:road|street|avenue|boulevard|court|ave|st|blvd|cir|circle)\b',
    '\b(?:\d{4}[-| ]?){3}\d{4}\b'
$fileExtensions = "\.docx|\.doc|\.odt|\.xlsx|\.xls|\.ods|\.pptx|\.ppt|\.odp|\.pdf|\.mdb|\.accdb|\.sqlite3?|\.eml|\.msg|\.txt|\.csv|\.html?|\.xml|\.json"

Get-ChildItem -Recurse -Force -Path $Path | Where-Object { $_.Extension -match $fileExtensions } | ForEach-Object {
    $piiMatches = Select-String -Path $_.FullName -Pattern $patterns -AllMatches | Select-Object -ExpandProperty Matches

    if ($piiMatches.Count -ge 20) {
        "PII found in $($_.FullName)" | Out-File -FilePath "$Directory\pii.txt" -Append

        $piiMatches |
            Sort-Object Value -Unique |
            ForEach-Object { $_.Value } |
            Out-File -FilePath "$Directory\pii.txt" -Append

    }
}
