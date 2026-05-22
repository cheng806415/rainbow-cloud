<?php
include("./includes/common.php");

if($islogin==1){}else exit("<script language='javascript'>window.location.href='./login.php';</script>");

$DB->exec("
CREATE TABLE IF NOT EXISTS `pre_folder` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `parent_id` int(11) unsigned NOT NULL DEFAULT '0',
  `uid` int(11) unsigned NOT NULL DEFAULT '0',
  `addtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `parent_id` (`parent_id`),
  KEY `uid` (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
");

$DB->exec("
ALTER TABLE `pre_file` ADD COLUMN `folder_id` int(11) unsigned NOT NULL DEFAULT '0' AFTER `uid`;
");

$DB->exec("
ALTER TABLE `pre_file` ADD KEY `folder_id` (`folder_id`);
");

echo "数据库更新完成";
