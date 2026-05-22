<?php
define('IN_ADMIN', true);
include("../includes/common.php");
if($islogin==1){}else exit("<script language='javascript'>window.location.href='./login.php';</script>");
$act=isset($_GET['act'])?daddslashes($_GET['act']):null;

if(!checkRefererHost())exit('{"code":403}');

@header('Content-Type: application/json; charset=UTF-8');

switch($act){
case 'getcount':
	$thtime=date("Y-m-d").' 00:00:00';
	$lastday=date("Y-m-d",strtotime("-1 day")).' 00:00:00';
	$count1=$DB->getColumn("SELECT count(*) from pre_file");
	$count2=$DB->getColumn("SELECT count(*) from pre_file WHERE addtime>='$thtime'");
	$count3=$DB->getColumn("SELECT count(*) from pre_file WHERE addtime>='$lastday' AND addtime<'$thtime'");
	$count4=$DB->getColumn("SELECT count(*) from pre_user");
	$count5=$DB->getColumn("SELECT count(*) from pre_folder");

	$result=["code"=>0,"count1"=>$count1,"count2"=>$count2,"count3"=>$count3,"count4"=>$count4,"count5"=>$count5];
	exit(json_encode($result));
break;
case 'set':
	if(isset($_POST['green_label_porn'])){
		$_POST['green_label_porn'] = implode(',',$_POST['green_label_porn']);
	}
	if(isset($_POST['green_label_terrorism'])){
		$_POST['green_label_terrorism'] = implode(',',$_POST['green_label_terrorism']);
	}
	foreach($_POST as $k=>$v){
		saveSetting($k, $v);
	}
	exit('{"code":0,"msg":"succ"}');
break;
case 'iptype':
	$result = [
	['name'=>'0_X_FORWARDED_FOR', 'ip'=>real_ip(0), 'city'=>get_ip_city(real_ip(0))],
	['name'=>'1_X_REAL_IP', 'ip'=>real_ip(1), 'city'=>get_ip_city(real_ip(1))],
	['name'=>'2_REMOTE_ADDR', 'ip'=>real_ip(2), 'city'=>get_ip_city(real_ip(2))]
	];
	exit(json_encode($result));
break;
case 'userList':
	$sql=" 1=1";
	$type_arr = ['qq'=>'QQ','wx'=>'微信'];
	if(isset($_POST['dstatus']) && $_POST['dstatus']>-1) {
		$dstatus = intval($_POST['dstatus']);
		$sql.=" AND `enable`={$dstatus}";
	}
	if(isset($_POST['kw']) && !empty($_POST['kw'])) {
		$type = intval($_POST['type']);
		$kw = trim(daddslashes($_POST['kw']));
		if($type == 1){
			$sql.=" AND `uid`='{$kw}'";
		}elseif($type == 2){
			$sql.=" AND `openid`='{$kw}'";
		}elseif($type == 3){
			$sql.=" AND `nickname` LIKE '%{$kw}%'";
		}elseif($type == 4){
			$sql.=" AND `loginip`='{$kw}'";
		}
	}
	$offset = intval($_POST['offset']);
	$limit = intval($_POST['limit']);
	$total = $DB->getColumn("SELECT count(*) from pre_user WHERE{$sql}");
	$list = $DB->getAll("SELECT * FROM pre_user WHERE{$sql} order by uid desc limit $offset,$limit");
	$list2 = [];
	foreach($list as $row){
		$row['type'] = $type_arr[$row['type']];
		$row['faceimg'] = $row['faceimg'] ?: ($row['avatar'] ?: '');
		$list2[] = $row;
	}

	exit(json_encode(['total'=>$total, 'rows'=>$list2]));
break;
case 'setUserEnable':
	$uid=intval($_POST['uid']);
	$enable=intval($_POST['enable']);
	$sql = "UPDATE pre_user SET enable='$enable' WHERE uid='$uid'";
	if($DB->exec($sql)!==false)exit('{"code":0,"msg":"修改用户成功！"}');
	else exit('{"code":-1,"msg":"修改用户失败['.$DB->error().']"}');
break;
case 'saveUserInfo':
	$uid=intval($_POST['uid']);
	$level=intval($_POST['level']);
	$sql = "UPDATE pre_user SET level='$level' WHERE uid='$uid'";
	if($DB->exec($sql)!==false)exit('{"code":0,"msg":"修改用户成功！"}');
	else exit('{"code":-1,"msg":"修改用户失败['.$DB->error().']"}');
break;
case 'delUser':
	$uid=intval($_POST['uid']);
	$row=$DB->getRow("select * from pre_user where uid='$uid' limit 1");
	if(!$row)
		exit('{"code":-1,"msg":"当前用户不存在！"}');
	$sql = "DELETE FROM pre_user WHERE uid='$uid'";
	if($DB->exec($sql))exit('{"code":0,"msg":"删除文件成功！"}');
	else exit('{"code":-1,"msg":"删除文件失败['.$DB->error().']"}');
break;
case 'folderList':
	$sql=" 1=1";
	if(isset($_POST['username']) && !empty($_POST['username'])) {
		$username = trim(daddslashes($_POST['username']));
		$uid = $DB->getColumn("SELECT uid FROM pre_user WHERE username=:username", [':username'=>$username]);
		if($uid){
			$sql.=" AND `uid`='$uid'";
		}else{
			$sql.=" AND 1=2";
		}
	}
	if(isset($_POST['dstatus']) && $_POST['dstatus']>-1) {
		$dstatus = intval($_POST['dstatus']);
		$sql.=" AND `hide`={$dstatus}";
	}
	$offset = intval($_POST['offset']);
	$limit = intval($_POST['limit']);
	
	$total = $DB->getColumn("SELECT count(*) from pre_folder WHERE{$sql}");
	$list = $DB->getAll("SELECT * FROM pre_folder WHERE{$sql} order by id desc limit $offset,$limit");
	
	if($list === false){
		exit(json_encode(['total'=>0, 'rows'=>[], 'debug'=>'查询失败: '.$DB->error()]));
	}
	
	$list2 = [];
	foreach($list as $row){
		$row['username'] = $DB->getColumn("SELECT username FROM pre_user WHERE uid=:uid", [':uid'=>$row['uid']]);
		$row['file_count'] = $DB->getColumn("SELECT count(*) FROM pre_file WHERE folder_id=:id", [':id'=>$row['id']]);
		$list2[] = $row;
	}
	
	exit(json_encode(['total'=>$total, 'rows'=>$list2]));
break;
case 'getFolder':
	$id=intval($_GET['id']);
	$row=$DB->getRow("select * from pre_folder where id='$id' limit 1");
	if(!$row)exit('{"code":-1,"msg":"文件夹不存在！"}');
	$row['username'] = $DB->getColumn("SELECT username FROM pre_user WHERE uid=:uid", [':uid'=>$row['uid']]);
	exit(json_encode(['code'=>0,'id'=>$row['id'],'name'=>$row['name'],'username'=>$row['username'],'hide'=>$row['hide'],'pwd'=>$row['pwd']]));
break;
case 'saveFolder':
	$id=intval($_POST['id']);
	$name=trim(daddslashes($_POST['name']));
	$hide=intval($_POST['hide']);
	$pwd=trim($_POST['pwd']);
	if(empty($name))exit('{"code":-1,"msg":"文件夹名称不能为空"}');
	$sql = "UPDATE pre_folder SET `name`='$name',`hide`='$hide',`pwd`='$pwd' WHERE id='$id'";
	if($DB->exec($sql)!==false)exit('{"code":0,"msg":"修改成功！"}');
	else exit('{"code":-1,"msg":"修改失败['.$DB->error().']"}');
break;
case 'delFolder':
	$id=intval($_POST['id']);
	$row=$DB->getRow("select * from pre_folder where id='$id' limit 1");
	if(!$row)exit('{"code":-1,"msg":"文件夹不存在！"}');
	$sql = "DELETE FROM pre_folder WHERE id='$id'";
	if($DB->exec($sql))exit('{"code":0,"msg":"删除文件夹成功！"}');
	else exit('{"code":-1,"msg":"删除文件夹失败['.$DB->error().']"}');
break;
default:
	exit('{"code":-4,"msg":"No Act"}');
break;
}