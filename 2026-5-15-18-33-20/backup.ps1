$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$timestamp = Get-Date -Format 'yyyy-M-d-H-mm-ss'
$sourceDir = 'd:\Develop\weihu'
$backupDir = "d:\Develop\weihu\$timestamp"

Write-Output "Creating backup..."
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

Get-ChildItem -Path $sourceDir -Directory | Where-Object {
    $_.Name -notmatch '^2026-5' -and $_.Name -notin @('backup', 'tmp')
} | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $backupDir -Recurse -Force
    Write-Output "Copied: $($_.Name)"
}

Get-ChildItem -Path $sourceDir -File | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $backupDir -Force
    Write-Output "Copied: $($_.Name)"
}

Write-Output "Backup completed: $backupDir"

Write-Output ""
Write-Output "Creating deployment package..."
$tempDir = "$env:TEMP\deploy-temp-$timestamp"
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

Get-ChildItem -Path $sourceDir -Directory | Where-Object {
    $_.Name -notmatch '^2026-5' -and $_.Name -notin @('backup', 'tmp')
} | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $tempDir -Recurse -Force
}

Get-ChildItem -Path $sourceDir -File | Where-Object {
    $_.Name -ne 'backup.ps1' -and $_.Name -notmatch '^deploy-.*\.zip$'
} | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $tempDir -Force
}

$zipFile = "d:\Develop\weihu\deploy-$timestamp.zip"
if (Test-Path $zipFile) {
    Remove-Item -Path $zipFile -Force
}
[system.io.compression.zipfile]::CreateFromDirectory($tempDir, $zipFile)

Remove-Item -Path $tempDir -Recurse -Force

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment package created: $zipFile"
$zipSize = (Get-Item $zipFile).Length / 1MB
Write-Output "Package size: $([math]::Round($zipSize, 2)) MB"
Write-Output "=========================================="
Write-Output ""
Write-Output "Package contents:"
Get-ChildItem -Path $tempDir -Recurse | Select-Object -First 50 | ForEach-Object {
    $relative = $_.FullName.Replace($sourceDir, '').TrimStart('\')
    Write-Output "  $relative"
}
