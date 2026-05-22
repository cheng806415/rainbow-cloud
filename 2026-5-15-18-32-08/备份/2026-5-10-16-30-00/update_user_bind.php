<?php
include("../includes/common.php");

$DB->exec("ALTER TABLE `pre_user` ADD COLUMN `wx_openid` varchar(150) DEFAULT NULL AFTER `openid`");
$DB->exec("ALTER TABLE `pre_user` ADD COLUMN `wx_nickname` varchar(255) DEFAULT NULL AFTER `wx_openid`");
$DB->exec("ALTER TABLE `pre_user` ADD COLUMN `wx_faceimg` varchar(255) DEFAULT NULL AFTER `wx_nickname`");
$DB->exec("ALTER TABLE `pre_user` ADD COLUMN `qq_openid` varchar(150) DEFAULT NULL AFTER `wx_faceimg`");
$DB->exec("ALTER TABLE `pre_user` ADD COLUMN `qq_nickname` varchar(255) DEFAULT NULL AFTER `qq_openid`");
$DB->exec("ALTER TABLE `pre_user` ADD COLUMN `qq_faceimg` varchar(255) DEFAULT NULL AFTER `qq_nickname`");

echo "数据库更新完成 - 已添加微信和QQ绑定账号字段";
