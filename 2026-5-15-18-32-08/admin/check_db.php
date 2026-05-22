<?php
define('IN_ADMIN', true);
include("../includes/common.php");

echo "<h2>数据库检查</h2>";

// 检查表是否存在
$tables = $DB->getAll("SHOW TABLES LIKE 'pre_folder'");
if(empty($tables)){
    echo "<p style='color:red;'>错误: pre_folder 表不存在！请先访问 /install/update_folder.php 创建表</p>";
}else{
    echo "<p style='color:green;'>pre_folder 表存在</p>";
    
    // 检查表结构
    $cols = $DB->getAll("DESCRIBE pre_folder");
    echo "<h3>表结构:</h3>";
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>字段</th><th>类型</th><th>空</th><th>键</th><th>默认值</th></tr>";
    foreach($cols as $col){
        echo "<tr>";
        echo "<td>{$col['Field']}</td>";
        echo "<td>{$col['Type']}</td>";
        echo "<td>{$col['Null']}</td>";
        echo "<td>{$col['Key']}</td>";
        echo "<td>{$col['Default']}</td>";
        echo "</tr>";
    }
    echo "</table>";
    
    // 检查数据
    $count = $DB->getColumn("SELECT COUNT(*) FROM pre_folder");
    echo "<p>文件夹总数: {$count}</p>";
    
    if($count > 0){
        $folders = $DB->getAll("SELECT * FROM pre_folder ORDER BY id DESC LIMIT 10");
        echo "<h3>最近10个文件夹:</h3>";
        echo "<table border='1' cellpadding='5'>";
        echo "<tr><th>ID</th><th>名称</th><th>UID</th><th>密码</th><th>隐藏</th><th>时间</th></tr>";
        foreach($folders as $f){
            echo "<tr>";
            echo "<td>{$f['id']}</td>";
            echo "<td>{$f['name']}</td>";
            echo "<td>{$f['uid']}</td>";
            echo "<td>{$f['pwd']}</td>";
            echo "<td>{$f['hide']}</td>";
            echo "<td>{$f['addtime']}</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
}

// 检查用户表
echo "<h3>用户表检查:</h3>";
$user_count = $DB->getColumn("SELECT COUNT(*) FROM pre_user");
echo "<p>用户总数: {$user_count}</p>";

// 检查用户表结构
echo "<h3>用户表结构:</h3>";
$cols = $DB->getAll("DESCRIBE pre_user");
echo "<table border='1' cellpadding='5'>";
echo "<tr><th>字段</th><th>类型</th><th>空</th><th>键</th><th>默认值</th></tr>";
foreach($cols as $col){
    echo "<tr>";
    echo "<td>{$col['Field']}</td>";
    echo "<td>{$col['Type']}</td>";
    echo "<td>{$col['Null']}</td>";
    echo "<td>{$col['Key']}</td>";
    echo "<td>{$col['Default']}</td>";
    echo "</tr>";
}
echo "</table>";

if($user_count > 0){
    $users = $DB->getAll("SELECT uid, username, nickname, avatar, faceimg FROM pre_user LIMIT 10");
    echo "<h3>用户数据示例(最近10个):</h3>";
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>UID</th><th>用户名</th><th>昵称</th><th>自定义头像(avatar)</th><th>第三方头像(faceimg)</th></tr>";
    foreach($users as $u){
        echo "<tr>";
        echo "<td>{$u['uid']}</td>";
        echo "<td>{$u['username']}</td>";
        echo "<td>{$u['nickname']}</td>";
        echo "<td>" . ($u['avatar'] ?: 'NULL') . "</td>";
        echo "<td>" . ($u['faceimg'] ?: 'NULL') . "</td>";
        echo "</tr>";
    }
    echo "</table>";
}

echo "<br><p><a href='./folder.php'>返回文件夹管理</a></p>";
?>