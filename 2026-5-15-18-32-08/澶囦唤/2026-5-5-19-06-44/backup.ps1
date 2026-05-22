$now = Get-Date -Format 'yyyy-M-d-H-mm-ss'
$backupDir = "d:\Develop\weihu\备份\$now"
New-Item -ItemType Directory -Path $backupDir -Force

$excludeDirs = @('备份')
$files = Get-ChildItem -Path 'd:\Develop\weihu' -Recurse | Where-Object {
    $exclude = $false
    foreach ($d in $excludeDirs) {
        if ($_.FullName -like "*\backup\$d*" -or $_.FullName -like "*\$d\*") {
            $exclude = $true
            break
        }
    }
    -not $exclude
}

foreach ($f in $files) {
    $dest = $backupDir + $f.FullName.Substring('d:\Develop\weihu'.Length)
    if (-not (Test-Path (Split-Path $dest -Parent))) {
        New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null
    }
    if (-not $f.PSIsContainer) {
        Copy-Item -Path $f.FullName -Destination $dest -Force
    }
}

Write-Host "Backup created: $backupDir"
