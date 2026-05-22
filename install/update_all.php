<?php
error_reporting(E_ERROR | E_WARNING | E_PARSE);
require '../config.php';

@header('Content-Type: text/html; charset=UTF-8');
@header('Cache-Control: no-cache, no-store, must-revalidate');

if(!defined('IN_ADMIN') && !defined('IN_CRON')){
    define('IN_ADMIN', true);
}

try{
    $DB = new PDO("mysql:host=".$dbconfig['host'].";dbname=".$dbconfig['dbname'].";port=".$dbconfig['port'], $dbconfig['user'], $dbconfig['pwd']);
}catch(Exception $e){
    exit('链接数据库失败:'.$e->getMessage());
}

date_default_timezone_set("PRC");
$DB->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_SILENT);
$DB->exec("set sql_mode = ''");
$DB->exec("set names utf8");

$success = 0;
$error = 0;
$errorMsg = '';
$update_log = [];

function execute_sql($sql, $desc = ''){
    global $DB, $success, $error, $errorMsg, $update_log;
    $sql = trim($sql);
    if(empty($sql)) return;
    $result = $DB->exec($sql);
    if($result === false){
        $error++;
        $dberror = $DB->errorInfo();
        $errorMsg .= "执行失败 [{$desc}]: ".$dberror[2]."<br>";
    }else{
        $success++;
        if($desc) $update_log[] = $desc;
    }
}

function column_exists($table, $column){
    global $DB;
    $count = $DB->query("SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='{$table}' AND COLUMN_NAME='{$column}'")->fetchColumn();
    return $count > 0;
}

function index_exists($table, $index_name){
    global $DB;
    $count = $DB->query("SELECT COUNT(*) FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='{$table}' AND INDEX_NAME='{$index_name}'")->fetchColumn();
    return $count > 0;
}

function table_exists($table){
    global $DB;
    $count = $DB->query("SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='{$table}'")->fetchColumn();
    return $count > 0;
}

$version = 0;
if($rs = $DB->query("SELECT v FROM pre_config WHERE k='version'")){
    $version = $rs->fetchColumn();
}

$need_upgrade = false;
if($version >= 2000){
    if(!column_exists('pre_user', 'storage_quota') || !column_exists('pre_user', 'storage_used')){
        $need_upgrade = true;
        $version = 1999;
    }
}else{
    $need_upgrade = true;
}

if(!$need_upgrade){
    exit('你的网站已经是最新版本了');
}

echo '<h3>彩虹外链网盘 - 数据库升级脚本</h3>';
echo '<p>当前数据库版本: '.$version.' -> 目标版本: 2000</p>';
echo '<hr>';

execute_sql("ALTER TABLE `pre_user` MODIFY COLUMN `password` varchar(255) DEFAULT NULL", "升级密码字段长度以支持password_hash");

if(!column_exists('pre_file', 'is_deleted')){
    execute_sql("ALTER TABLE `pre_file` ADD COLUMN `is_deleted` tinyint(1) NOT NULL DEFAULT '0' AFTER `hide`", "添加回收站is_deleted字段");
}
if(!column_exists('pre_file', 'deleted_time')){
    execute_sql("ALTER TABLE `pre_file` ADD COLUMN `deleted_time` datetime DEFAULT NULL AFTER `is_deleted`", "添加回收站deleted_time字段");
}
if(!column_exists('pre_file', 'deleted_by')){
    execute_sql("ALTER TABLE `pre_file` ADD COLUMN `deleted_by` int(11) unsigned DEFAULT NULL AFTER `deleted_time`", "添加回收站deleted_by字段");
}
if(!index_exists('pre_file', 'is_deleted')){
    execute_sql("ALTER TABLE `pre_file` ADD INDEX `is_deleted` (`is_deleted`)", "添加is_deleted索引");
}

if(!table_exists('pre_share')){
    execute_sql("
CREATE TABLE `pre_share` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `surl` varchar(32) NOT NULL,
  `file_id` int(11) unsigned NOT NULL,
  `uid` int(11) unsigned NOT NULL DEFAULT '0',
  `pwd` varchar(10) DEFAULT NULL,
  `expire_time` datetime DEFAULT NULL,
  `expire_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0:永久 1:7天 2:30天 3:自定义',
  `download_limit` int(11) NOT NULL DEFAULT '0' COMMENT '0:无限制',
  `download_count` int(11) NOT NULL DEFAULT '0',
  `view_count` int(11) NOT NULL DEFAULT '0',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '0:失效 1:正常',
  `addtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `surl` (`surl`),
  KEY `file_id` (`file_id`),
  KEY `uid` (`uid`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", "创建分享链接表pre_share");
}

if(!column_exists('pre_user', 'storage_quota')){
    execute_sql("ALTER TABLE `pre_user` ADD COLUMN `storage_quota` bigint(20) NOT NULL DEFAULT '1073741824' AFTER `avatar`", "添加用户存储配额字段");
}
if(!column_exists('pre_user', 'storage_used')){
    execute_sql("ALTER TABLE `pre_user` ADD COLUMN `storage_used` bigint(20) NOT NULL DEFAULT '0' AFTER `storage_quota`", "添加用户已使用空间字段");
}

if(!column_exists('pre_file', 'saved_from')){
    execute_sql("ALTER TABLE `pre_file` ADD COLUMN `saved_from` int(11) unsigned DEFAULT NULL COMMENT '转存来源文件ID' AFTER `folder_id`", "添加转存来源字段");
}
if(!index_exists('pre_file', 'saved_from')){
    execute_sql("ALTER TABLE `pre_file` ADD INDEX `saved_from` (`saved_from`)", "添加saved_from索引");
}

if(!table_exists('pre_log')){
    execute_sql("
CREATE TABLE `pre_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `uid` int(11) unsigned NOT NULL DEFAULT '0',
  `action` varchar(50) NOT NULL COMMENT '操作类型',
  `target_type` varchar(50) NOT NULL DEFAULT '' COMMENT '目标类型',
  `target_id` int(11) NOT NULL DEFAULT '0' COMMENT '目标ID',
  `detail` text COMMENT '操作详情',
  `ip` varchar(50) NOT NULL DEFAULT '',
  `addtime` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `uid` (`uid`),
  KEY `action` (`action`),
  KEY `addtime` (`addtime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", "创建操作日志表pre_log");
}

$config_items = [
    ['search_mode', '1', '搜索模式 0:精确 1:模糊'],
    ['share_enable', '1', '是否开启分享功能'],
    ['recycle_enable', '1', '是否开启回收站功能'],
    ['recycle_days', '30', '回收站文件保留天数'],
    ['default_storage_quota', '1073741824', '默认用户存储配额(字节)'],
    ['allow_transfer', '1', '是否允许文件转存'],
    ['share_pwd_length', '4', '分享码长度'],
];

foreach($config_items as $item){
    $exists = $DB->query("SELECT v FROM pre_config WHERE k='{$item[0]}'")->fetchColumn();
    if($exists === false){
        execute_sql("INSERT INTO `pre_config` VALUES ('{$item[0]}', '{$item[1]}')", "添加配置项: {$item[0]}");
    }
}

execute_sql("REPLACE INTO `pre_config` VALUES ('version', '2000')", "更新版本号到2000");

echo '<hr>';
echo '<h4>升级结果</h4>';
echo '<p>成功执行SQL语句: <b style="color:green">'.$success.'</b> 条</p>';
if($error > 0){
    echo '<p>失败: <b style="color:red">'.$error.'</b> 条</p>';
}
if(!empty($update_log)){
    echo '<h5>执行详情:</h5><ul>';
    foreach($update_log as $log){
        echo '<li>'.$log.'</li>';
    }
    echo '</ul>';
}
if($errorMsg){
    echo '<h5>错误信息:</h5><div style="color:red">'.$errorMsg.'</div>';
}

if($error == 0){
    echo '<hr><p style="color:green;font-size:16px;font-weight:bold">数据库升级完成！</p>';
    echo '<p><a href="../">返回首页</a> | <a href="../admin/">进入后台</a></p>';
}else{
    echo '<hr><p style="color:red;font-weight:bold">数据库升级完成，但存在错误，请检查上述错误信息。</p>';
}
?>
