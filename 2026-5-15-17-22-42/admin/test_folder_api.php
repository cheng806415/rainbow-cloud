<?php
define('IN_ADMIN', true);
include("../includes/common.php");
if($islogin==1){}else exit("<script language='javascript'>window.location.href='./login.php';</script>");

@header('Content-Type: application/json; charset=UTF-8');

echo "=== 测试folderList API ===\n\n";

echo "--- 测试1: 无过滤条件 ---\n";
$_POST = [
    'offset' => 0,
    'limit' => 20,
    'username' => '',
    'dstatus' => -1
];

$sql=" 1=1";
echo "初始SQL: {$sql}\n";

if(isset($_POST['username']) && !empty($_POST['username'])) {
    echo "用户名过滤: {$_POST['username']}\n";
    $username = trim(daddslashes($_POST['username']));
    $uid = $DB->getColumn("SELECT uid FROM pre_user WHERE username=:username", [':username'=>$username]);
    echo "查询到的UID: {$uid}\n";
    if($uid){
        $sql.=" AND `uid`='$uid'";
    }else{
        $sql.=" AND 1=2";
    }
}

if(isset($_POST['dstatus']) && $_POST['dstatus']>-1) {
    $dstatus = intval($_POST['dstatus']);
    $sql.=" AND `hide`={$dstatus}";
    echo "隐藏状态过滤: {$dstatus}\n";
}

$offset = intval($_POST['offset']);
$limit = intval($_POST['limit']);
echo "最终SQL条件: {$sql}\n";

$total_sql = "SELECT count(*) from pre_folder WHERE{$sql}";
echo "Count SQL: {$total_sql}\n";
$total = $DB->getColumn($total_sql);
echo "总数: {$total}\n";

$list_sql = "SELECT * FROM pre_folder WHERE{$sql} order by id desc limit $offset,$limit";
echo "List SQL: {$list_sql}\n";
$list = $DB->getAll($list_sql);
echo "查询结果: ";
print_r($list);
?>