<?php
define('IN_ADMIN', true);
include("../includes/common.php");

$DB->exec("
CREATE TABLE IF NOT EXISTS `pre_folder` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `uid` int(11) unsigned NOT NULL DEFAULT '0',
  `pwd` varchar(100) DEFAULT NULL,
  `hide` tinyint(1) NOT NULL DEFAULT '0',
  `addtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`),
  KEY `hide` (`hide`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
");

$has_hide = $DB->getColumn("SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='pre_folder' AND COLUMN_NAME='hide'");
if($has_hide == 0){
	$DB->exec("ALTER TABLE `pre_folder` ADD COLUMN `hide` tinyint(1) NOT NULL DEFAULT '0' AFTER `pwd`");
	$DB->exec("ALTER TABLE `pre_folder` ADD KEY `hide` (`hide`)");
}

$has_pwd = $DB->getColumn("SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='pre_folder' AND COLUMN_NAME='pwd'");
if($has_pwd == 0){
	$DB->exec("ALTER TABLE `pre_folder` ADD COLUMN `pwd` varchar(100) DEFAULT NULL AFTER `uid`");
}

$DB->exec("
ALTER TABLE `pre_file` ADD COLUMN IF NOT EXISTS `folder_id` int(11) unsigned NOT NULL DEFAULT '0' AFTER `uid`;
");

$has_folder_key = $DB->getColumn("SELECT COUNT(*) FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='pre_file' AND INDEX_NAME='folder_id'");
if($has_folder_key == 0){
	$DB->exec("ALTER TABLE `pre_file` ADD KEY `folder_id` (`folder_id`)");
}

echo "数据库更新完成";
