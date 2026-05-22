<?php
define('IN_ADMIN', true);
include("../includes/common.php");

$DB->exec("
CREATE TABLE IF NOT EXISTS `pre_folder` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `parent_id` int(11) unsigned NOT NULL DEFAULT '0',
  `uid` int(11) unsigned NOT NULL DEFAULT '0',
  `pwd` varchar(100) DEFAULT NULL,
  `is_public` tinyint(1) NOT NULL DEFAULT '1',
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

if (!$DB->getColumn("SHOW COLUMNS FROM pre_folder LIKE 'pwd'")) {
	$DB->exec("ALTER TABLE `pre_folder` ADD COLUMN `pwd` varchar(100) DEFAULT NULL");
}

if (!$DB->getColumn("SHOW COLUMNS FROM pre_folder LIKE 'is_public'")) {
	$DB->exec("ALTER TABLE `pre_folder` ADD COLUMN `is_public` tinyint(1) NOT NULL DEFAULT '1'");
}

echo "数据库更新完成";
