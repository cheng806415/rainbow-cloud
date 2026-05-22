<?php
include("../includes/common.php");

$DB->exec("ALTER TABLE `pre_file` ADD COLUMN `sha256` varchar(64) DEFAULT NULL AFTER `hash`");

echo "数据库更新完成 - 已添加SHA256字段";
