<?php
include("../includes/common.php");

$DB->exec("ALTER TABLE `pre_user` ADD COLUMN `avatar` varchar(255) DEFAULT NULL AFTER `faceimg`");

$DB->exec("ALTER TABLE `pre_user` ADD COLUMN `allow_view` tinyint(1) NOT NULL DEFAULT '1' AFTER `level`");

$DB->exec("ALTER TABLE `pre_user` ADD COLUMN `allow_search` tinyint(1) NOT NULL DEFAULT '1' AFTER `allow_view`");

echo "数据库更新完成 - 已添加头像和隐私设置字段";
