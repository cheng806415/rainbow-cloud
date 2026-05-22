# 彩虹外链网盘 - P1/P2功能更新增量包生成脚本
# 使用方法：在 d:\Develop\weihu 目录下右键，选择"使用PowerShell运行"

$timestamp = Get-Date -Format "yyyy-M-d-HH-mm-ss"
$zipName = "update-p1-p2-features-$timestamp.zip"

$files = @(
    "api.php",
    "ajax.php",
    "login.php",
    "user_center.php",
    "index.php",
    "view.php",
    "down.php",
    "file.php",
    "upload.php",
    "includes\functions.php",
    "install\update_all.php",
    "assets\css\style.css",
    "assets\js\custom.js"
)

$validFiles = @()
foreach ($file in $files) {
    $fullPath = Join-Path $PSScriptRoot $file
    if (Test-Path $fullPath) {
        $validFiles += $fullPath
    } else {
        Write-Warning "跳过不存在的文件: $file"
    }
}

if ($validFiles.Count -eq 0) {
    Write-Error "没有找到需要打包的文件！"
    exit 1
}

$zipPath = Join-Path $PSScriptRoot $zipName
Compress-Archive -Path $validFiles -DestinationPath $zipPath -Force

Write-Host "=====================================" -ForegroundColor Green
Write-Host "增量包已生成: $zipName" -ForegroundColor Green
Write-Host "包含 $($validFiles.Count) 个文件" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
