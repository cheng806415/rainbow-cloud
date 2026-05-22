<?php
include("../includes/common.php");

$DB->exec("
ALTER TABLE `pre_user` ADD COLUMN `username` varchar(50) DEFAULT NULL AFTER `uid`;
");

$DB->exec("
ALTER TABLE `pre_user` ADD COLUMN `password` varchar(100) DEFAULT NULL AFTER `username`;
");

$DB->exec("
ALTER TABLE `pre_user` ADD UNIQUE KEY `username` (`username`);
");

echo "数据库更新完成 - 已添加本地账号登录支持";
