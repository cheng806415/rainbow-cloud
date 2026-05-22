<?php
set_time_limit(300);
$timestamp = date('Y-m-d-H-i-s');
$zipName = "update-p1-p2-features-$timestamp.zip";

$files = array(
    "api.php",
    "ajax.php",
    "login.php",
    "user_center.php",
    "index.php",
    "view.php",
    "down.php",
    "file.php",
    "upload.php",
    "includes/functions.php",
    "install/update_all.php",
    "assets/css/style.css",
    "assets/js/custom.js"
);

$zip = new ZipArchive();
if ($zip->open($zipName, ZipArchive::CREATE | ZipArchive::OVERWRITE) !== TRUE) {
    exit("无法创建压缩文件\n");
}

$addedCount = 0;
foreach ($files as $file) {
    if (file_exists($file)) {
        $zip->addFile($file, $file);
        $addedCount++;
        echo "已添加: $file\n";
    } else {
        echo "跳过(不存在): $file\n";
    }
}

$zip->close();

echo "\n=====================================\n";
echo "增量包已生成: $zipName\n";
echo "包含 $addedCount 个文件\n";
echo "文件大小: " . filesize($zipName) . " bytes\n";
echo "=====================================\n";
?>