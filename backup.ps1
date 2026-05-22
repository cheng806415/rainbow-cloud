Add-Type -AssemblyName System.IO.Compression.FileSystem
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$timestamp = Get-Date -Format 'yyyy-M-d-H-mm-ss'
$sourceDir = 'd:\Develop\weihu'
$backupDir = Join-Path $sourceDir $timestamp
$zipFile = Join-Path $sourceDir "deploy-$timestamp.zip"
$excludeNames = @('backup', 'tmp')

Write-Output "Creating backup..."
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

# Copy dirs excluding backups
$dirs = Get-ChildItem -Path $sourceDir -Directory
foreach ($dir in $dirs) {
    if ($dir.Name -notmatch '^2026-5' -and $dir.Name -notin $excludeNames) {
        $dest = Join-Path $backupDir $dir.Name
        Copy-Item -Path $dir.FullName -Destination $dest -Recurse -Force
        Write-Output "Copied dir: $($dir.Name)"
    }
}

# Copy files
$files = Get-ChildItem -Path $sourceDir -File
foreach ($file in $files) {
    Copy-Item -Path $file.FullName -Destination $backupDir -Force
    Write-Output "Copied file: $($file.Name)"
}

Write-Output ""
Write-Output "Backup done: $backupDir"
Write-Output ""
Write-Output "Creating deployment package..."

# Create temp dir
$tempDir = Join-Path $env:TEMP "deploy-pkg-$timestamp"
if (Test-Path $tempDir) { Remove-Item -Path $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Copy from backup to temp
Copy-Item -Path "$backupDir\*" -Destination $tempDir -Recurse -Force

# Compress
Write-Output "Compressing..."
[System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir, $zipFile, [System.IO.Compression.CompressionLevel]::Optimal, $false)

# Cleanup
Remove-Item -Path $tempDir -Recurse -Force

$zipSize = (Get-Item $zipFile).Length
Write-Output ""
Write-Output "=========================================="
Write-Output "Deployment package: $zipFile"
Write-Output "Size: $([math]::Round($zipSize/1MB, 2)) MB"
Write-Output "=========================================="
