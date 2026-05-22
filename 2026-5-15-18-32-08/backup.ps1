$timestamp = Get-Date -Format 'yyyy-M-d-H-mm-ss'
$sourceDir = $PSScriptRoot
$backupDir = Join-Path $sourceDir $timestamp

Write-Output "Creating backup..."
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

Get-ChildItem -Path $sourceDir -Directory | Where-Object {
    $_.Name -notmatch '^2026-5' -and $_.Name -notin @('backup', 'tmp')
} | Copy-Item -Destination $backupDir -Recurse -Force

Get-ChildItem -Path $sourceDir -File | Copy-Item -Destination $backupDir -Force

Write-Output "Backup completed: $backupDir"

Write-Output "Creating deployment package..."
$tempDir = Join-Path $env:TEMP "deploy-temp-$timestamp"
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

Get-ChildItem -Path $sourceDir -Directory | Where-Object {
    $_.Name -notmatch '^2026-5' -and $_.Name -notin @('backup', 'tmp')
} | Copy-Item -Destination $tempDir -Recurse -Force

Get-ChildItem -Path $sourceDir -File | Where-Object {
    $_.Name -ne 'backup.ps1' -and $_.Name -notmatch '^deploy-.*\.zip$'
} | Copy-Item -Destination $tempDir -Force

$zipFile = Join-Path $sourceDir "deploy-$timestamp.zip"
Compress-Archive -Path "$tempDir\*" -DestinationPath $zipFile -Force

Remove-Item -Path $tempDir -Recurse -Force

Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment package created: $zipFile"
Write-Output "=========================================="
Write-Output ""
Write-Output "Files included in package:"
$files = Get-ChildItem -Path $zipFile
Write-Output "Package size: $([math]::Round($files.Length / 1MB, 2)) MB"
Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment Guide:"
Write-Output "=========================================="
Write-Output "1. Server requirements: PHP >= 7.1, MySQL >= 5.5"
Write-Output "2. Upload deploy-$timestamp.zip to server web root"
Write-Output "3. Extract to web root directory"
Write-Output "4. Set write permission for 'file' directory (chmod 755 or 777)"
Write-Output "5. Visit http://your-domain/ and follow installation wizard"
Write-Output "6. Enter database credentials during installation"
Write-Output "7. Default admin account: admin / 123456"
Write-Output "8. Delete 'install' directory after installation"
Write-Output "=========================================="
