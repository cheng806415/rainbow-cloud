Add-Type -AssemblyName System.IO.Compression.FileSystem

$timestamp = Get-Date -Format 'yyyy-M-d-H-mm-ss'
$sourceDir = 'd:\Develop\weihu'

$updateFiles = @(
    'ajax.php',
    'index.php',
    'file.php',
    'install\install.sql',
    'install\update_sha256.php'
)

$tempDir = Join-Path $env:TEMP "update-incremental-$timestamp"
if (Test-Path $tempDir) { Remove-Item -Path $tempDir -Recurse -Force }

foreach ($file in $updateFiles) {
    $srcPath = Join-Path $sourceDir $file
    $destPath = Join-Path $tempDir $file
    $destFolder = Split-Path $destPath -Parent
    if (-not (Test-Path $destFolder)) {
        New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
    }
    Copy-Item -Path $srcPath -Destination $destPath -Force
    Write-Output "Added: $file"
}

$zipFile = Join-Path $sourceDir "update-incremental-$timestamp.zip"
if (Test-Path $zipFile) { Remove-Item -Path $zipFile -Force }

[System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir, $zipFile, [System.IO.Compression.CompressionLevel]::Optimal, $false)

Remove-Item -Path $tempDir -Recurse -Force

$zipSize = (Get-Item $zipFile).Length
Write-Output ""
Write-Output "=========================================="
Write-Output "Incremental update package: update-incremental-$timestamp.zip"
Write-Output "Size: $([math]::Round($zipSize/1KB, 2)) KB"
Write-Output "=========================================="
Write-Output ""
Write-Output "Files included:"
Write-Output "  - ajax.php (add SHA256 calculation on upload)"
Write-Output "  - index.php (show SHA256 column in file list)"
Write-Output "  - file.php (show SHA256 in file details)"
Write-Output "  - install/install.sql (add sha256 field)"
Write-Output "  - install/update_sha256.php (database update script)"
Write-Output ""
Write-Output "Deploy steps:"
Write-Output "1. Upload and extract to server web root"
Write-Output "2. Visit http://your-domain/install/update_sha256.php to update database"
Write-Output "3. Delete install directory after update"
Write-Output "=========================================="
