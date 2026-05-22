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

$DB->exec("
ALTER TABLE `pre_file` ADD COLUMN `folder_id` int(11) unsigned NOT NULL DEFAULT '0' AFTER `uid`;
");

$DB->exec("
ALTER TABLE `pre_file` ADD KEY `folder_id` (`folder_id`);
");

echo "数据库更新完成";
