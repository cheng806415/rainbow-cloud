<?php
define('IN_ADMIN', true);
include("../includes/common.php");
if($islogin==1){}else exit("<script language='javascript'>window.location.href='./login.php';</script>");

header('Content-Type: text/html; charset=UTF-8');
?>
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8"/>
<title>文件夹调试</title>
<style>
body { font-family: Arial; padding: 20px; background: #f5f5f5; }
.panel { background: white; padding: 20px; margin: 10px 0; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
.success { color: green; }
.error { color: red; }
table { border-collapse: collapse; width: 100%; margin: 10px 0; }
th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
th { background: #4CAF50; color: white; }
pre { background: #f4f4f4; padding: 10px; overflow-x: auto; }
</style>
</head>
<body>
<h1>文件夹数据库调试</h1>

<div class="panel">
<h2>1. 检查pre_folder表是否存在</h2>
<?php
$tables = $DB->getAll("SHOW TABLES");
$folder_table_exists = false;
foreach($tables as $table){
    $table_name = array_values($table)[0];
    if($table_name == 'pre_folder'){
        $folder_table_exists = true;
        break;
    }
}

if($folder_table_exists){
    echo '<p class="success">✓ pre_folder表存在</p>';
    
    echo '<h3>表结构:</h3>';
    $cols = $DB->getAll("DESCRIBE pre_folder");
    echo '<table>';
    echo '<tr><th>字段</th><th>类型</th><th>空</th><th>键</th><th>默认值</th></tr>';
    foreach($cols as $col){
        echo "<tr>";
        echo "<td>{$col['Field']}</td>";
        echo "<td>{$col['Type']}</td>";
        echo "<td>{$col['Null']}</td>";
        echo "<td>{$col['Key']}</td>";
        echo "<td>".($col['Default'] ?? 'NULL')."</td>";
        echo "</tr>";
    }
    echo '</table>';
} else {
    echo '<p class="error">✗ pre_folder表不存在！</p>';
    echo '<p>请访问 <a href="../install/update_folder.php">install/update_folder.php</a> 创建表</p>';
}
?>
</div>

<div class="panel">
<h2>2. 文件夹数据统计</h2>
<?php
if($folder_table_exists){
    $total = $DB->getColumn("SELECT COUNT(*) FROM pre_folder");
    echo "<p>文件夹总数: <strong>{$total}</strong></p>";
    
    if($total > 0){
        echo '<h3>所有文件夹:</h3>';
        $folders = $DB->getAll("SELECT f.*, u.username FROM pre_folder f LEFT JOIN pre_user u ON f.uid=u.uid ORDER BY f.id DESC");
        echo '<table>';
        echo '<tr><th>ID</th><th>名称</th><th>UID</th><th>用户名</th><th>密码</th><th>隐藏</th><th>创建时间</th></tr>';
        foreach($folders as $f){
            $hide_text = $f['hide'] ? '<span class="error">隐藏</span>' : '<span class="success">公开</span>';
            echo '<tr>';
            echo "<td>{$f['id']}</td>";
            echo "<td>{$f['name']}</td>";
            echo "<td>{$f['uid']}</td>";
            echo "<td>" . ($f['username'] ?: '-') . "</td>";
            echo "<td>" . ($f['pwd'] ? '已设置' : '无') . "</td>";
            echo "<td>{$hide_text}</td>";
            echo "<td>{$f['addtime']}</td>";
            echo '</tr>';
        }
        echo '</table>';
    } else {
        echo '<p class="error">数据库中没有文件夹数据</p>';
        echo '<p><a href="../index.php" target="_blank">前往首页创建文件夹</a></p>';
    }
}
?>
</div>

<div class="panel">
<h2>3. 模拟API查询测试</h2>
<?php
if($folder_table_exists){
    echo '<h3>测试1: 查询所有文件夹(无过滤)</h3>';
    $sql1 = "SELECT count(*) from pre_folder WHERE 1=1";
    $count1 = $DB->getColumn($sql1);
    echo "<p>SQL: <code>{$sql1}</code></p>";
    echo "<p>结果: <strong>{$count1}</strong> 条记录</p>";
    
    echo '<h3>测试2: 查询公开文件夹</h3>';
    $sql2 = "SELECT count(*) from pre_folder WHERE 1=1 AND hide=0";
    $count2 = $DB->getColumn($sql2);
    echo "<p>SQL: <code>{$sql2}</code></p>";
    echo "<p>结果: <strong>{$count2}</strong> 条记录</p>";
    
    echo '<h3>测试3: 带用户名查询(测试用户名查找)</h3>';
    $first_user = $DB->getRow("SELECT uid, username FROM pre_user LIMIT 1");
    if($first_user){
        $test_username = $first_user['username'];
        $test_uid = $DB->getColumn("SELECT uid FROM pre_user WHERE username=:username", [':username'=>$test_username]);
        echo "<p>测试用户名: <strong>{$test_username}</strong> (UID: {$test_uid})</p>";
        
        $sql3 = "SELECT count(*) from pre_folder WHERE 1=1 AND uid='{$test_uid}'";
        $count3 = $DB->getColumn($sql3);
        echo "<p>SQL: <code>{$sql3}</code></p>";
        echo "<p>结果: <strong>{$count3}</strong> 条记录</p>";
    } else {
        echo '<p class="error">没有用户数据</p>';
    }
    
    echo '<h3>测试4: 查询隐藏文件夹</h3>';
    $sql4 = "SELECT count(*) from pre_folder WHERE 1=1 AND hide=1";
    $count4 = $DB->getColumn($sql4);
    echo "<p>SQL: <code>{$sql4}</code></p>";
    echo "<p>结果: <strong>{$count4}</strong> 条记录</p>";
}
?>
</div>

<div class="panel">
<h2>4. 用户数据检查</h2>
<?php
$user_count = $DB->getColumn("SELECT COUNT(*) FROM pre_user");
echo "<p>用户总数: <strong>{$user_count}</strong></p>";

if($user_count > 0){
    $users = $DB->getAll("SELECT uid, username, nickname, enable FROM pre_user LIMIT 10");
    echo '<table>';
    echo '<tr><th>UID</th><th>用户名</th><th>昵称</th><th>状态</th></tr>';
    foreach($users as $u){
        $enable_text = $u['enable'] ? '<span class="success">正常</span>' : '<span class="error">禁用</span>';
        echo '<tr>';
        echo "<td>{$u['uid']}</td>";
        echo "<td>{$u['username']}</td>";
        echo "<td>{$u['nickname']}</td>";
        echo "<td>{$enable_text}</td>";
        echo '</tr>';
    }
    echo '</table>';
}
?>
</div>

<div class="panel">
<h2>5. 建议操作</h2>
<?php
if(!$folder_table_exists){
    echo '<p class="error">1. 首先访问 <a href="../install/update_folder.php">install/update_folder.php</a> 创建pre_folder表</p>';
} elseif($total == 0){
    echo '<p>1. 数据库中没有文件夹，请先在首页创建文件夹</p>';
    echo '<p>2. <a href="../index.php" target="_blank">前往首页</a></p>';
} else {
    echo '<p>数据库状态正常，文件夹数据存在</p>';
    echo '<p>如果后台文件夹管理仍然显示"没有找到匹配的记录"，请检查:</p>';
    echo '<ul>';
    echo '<li>浏览器控制台是否有JavaScript错误</li>';
    echo '<li>网络请求是否成功(查看Network标签)</li>';
    echo '<li>ajax.php的folderList接口返回的数据</li>';
    echo '</ul>';
}
?>
<p><a href="./folder.php">返回文件夹管理</a></p>
</div>

</body>
</html>