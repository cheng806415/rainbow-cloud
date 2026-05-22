<?php
$nosecu = true;
include("./includes/common.php");
$act=isset($_GET['act'])?daddslashes($_GET['act']):null;

if(!checkRefererHost())exit('{"code":403}');

@header('Content-Type: application/json; charset=UTF-8');

function verifyCsrfToken(&$tokenIndex = null, $reuse = false) {
    $token = isset($_POST['csrf_token']) ? $_POST['csrf_token'] : (isset($_GET['csrf_token']) ? $_GET['csrf_token'] : null);
    if (!$token) return false;
    $tokens = isset($_SESSION['csrf_tokens']) ? $_SESSION['csrf_tokens'] : [];
    $reuseTokens = isset($_SESSION['csrf_tokens_reuse']) ? $_SESSION['csrf_tokens_reuse'] : [];
    $idx = array_search($token, $tokens);
    if ($idx !== false) {
        $tokenIndex = $idx;
        if ($reuse) {
            unset($tokens[$idx]);
            $_SESSION['csrf_tokens'] = array_values($tokens);
            $reuseTokens[] = $token;
            $_SESSION['csrf_tokens_reuse'] = $reuseTokens;
        } else {
            unset($tokens[$idx]);
            $_SESSION['csrf_tokens'] = array_values($tokens);
        }
        return true;
    }
    if (in_array($token, $reuseTokens)) return true;
    if (isset($_SESSION['csrf_token']) && $_SESSION['csrf_token'] === $token) {
        unset($_SESSION['csrf_token']);
        return true;
    }
    return false;
}

if($islogin2 && $userrow['level']>0){
	$conf['upload_limit']=0;
	$conf['videoreview']=0;
	$conf['type_block']=null;
	$conf['name_block']=null;
}

switch($act){
case 'get_token':
	$newToken = md5(mt_rand(0,999).time().mt_rand(0,999));
	if (!isset($_SESSION['csrf_tokens']) || !is_array($_SESSION['csrf_tokens'])) {
		$_SESSION['csrf_tokens'] = [];
	}
	$_SESSION['csrf_tokens'][] = $newToken;
	exit(json_encode(['code'=>0, 'csrf_token'=>$newToken]));
break;
case 'pre_upload':
	if(!verifyCsrfToken())exit('{"code":-1,"msg":"CSRF TOKEN ERROR"}');
	if($conf['forcelogin']==1 && !$islogin2)exit('{"code":-1,"msg":"请先登录"}');
	$name = trim(htmlspecialchars($_POST['name']));
	$hash = trim($_POST['hash']);
	$size = intval($_POST['size']);
	$hide = $_POST['show']==1?0:1;
	$ispwd = intval($_POST['ispwd']);
	$pwd = $ispwd==1?trim(htmlspecialchars($_POST['pwd'])):null;
	$folder_id = isset($_POST['folder_id'])?intval($_POST['folder_id']):0;
	$name = str_replace(['/','\\',':','*','"','<','>','|','?'],'',$name);
	if(empty($name))exit('{"code":-1,"msg":"文件名不能为空"}');
	if(!preg_match('/^[0-9a-z]{32}$/i', $hash))exit('{"code":-1,"msg":"hash error"}');
	if($ispwd==1 && !empty($pwd)){
		if (!preg_match('/^[a-zA-Z0-9]+$/', $pwd)) {
			exit('{"code":-1,"msg":"文件密码只能为字母和数字"}');
		}
	}
	$ext=get_file_ext($name);
	if($conf['type_block']){
		$type_block = explode('|',$conf['type_block']);
		if(in_array($ext,$type_block)){
			exit('{"code":-1,"msg":"文件上传失败，不支持上传该格式文件","error":"block"}');
		}
	}
	if($conf['name_block']){
		$name_block = explode('|',$conf['name_block']);
		foreach($name_block as $row){
			if(strpos($name,$row)!==false){
				exit('{"code":-1,"msg":"文件上传失败","error":"block"}');
			}
		}
	}
	$limit_size = intval($conf['upload_size']);
	if($limit_size > 0 && $size > $limit_size * 1024 * 1024){
		exit('{"code":-1,"msg":"上传文件大小限制'.$limit_size.'MB"}');
	}
	if($conf['upload_limit']>0){
		$thisday = date("Y-m-d 00:00:00");
		if($islogin2){
			$ipcount=$DB->getColumn("SELECT count(*) from pre_file WHERE uid='$uid' AND addtime>='".$thisday."'");
		}else{
			$ipcount=$DB->getColumn("SELECT count(*) from pre_file WHERE ip='$clientip' AND addtime>='".$thisday."'");
		}
		if($ipcount>$conf['upload_limit']){
			exit('{"code":-1,"msg":"你今天上传文件的数量已超过限制"}');
		}
	}
	$row = $DB->getRow("SELECT * FROM pre_file WHERE hash=:hash", [':hash'=>$hash]);
	if($row){
		$result = ['code'=>1, 'msg'=>'本站已存在该文件', 'exists'=>1, 'hash'=>$hash, 'name'=>$name, 'size'=>$size, 'type'=>$ext, 'id'=>$row['id']];
		exit(json_encode($result));
	}

	if(\lib\StorHelper::is_cloud() && $conf['uploadfile_type'] == 1){
		$param = $stor->getUploadParam($hash, $name, $limit_size * 1024 * 1024);
		if(!$param)exit('{"code":-1,"msg":"获取上传参数失败","errmsg":"'.$stor->errmsg().'"}');
		$_SESSION['upload'] = [
			'chunks' => 1,
			'name' => $name,
			'hash' => $hash,
			'size' => $size,
			'ext' => $ext,
			'hide' => $hide,
			'pwd' => $pwd,
			'folder_id' => $folder_id
		];
		$result = ['code'=>0, 'third'=>true, 'hash'=>$hash, 'url'=>$param['url'], 'post'=>$param['post']];
		exit(json_encode($result));
	}else{
		$chunksize = 8 * 1024 * 1024;
		$chunks = ceil($size / $chunksize);
		$_SESSION['upload'] = [
			'chunks' => $chunks,
			'name' => $name,
			'hash' => $hash,
			'size' => $size,
			'ext' => $ext,
			'hide' => $hide,
			'pwd' => $pwd,
			'folder_id' => $folder_id
		];
		$result = ['code'=>0, 'third'=>false, 'hash'=>$hash, 'chunksize'=>$chunksize, 'chunks'=>$chunks];
		exit(json_encode($result));
	}
break;

case 'upload_part':
	if(!isset($_FILES['file']))exit('{"code":-1,"msg":"请选择文件"}');
	if($conf['forcelogin']==1 && !$islogin2)exit('{"code":-1,"msg":"请先登录"}');
	$chunk = intval($_POST['chunk']);
	$hash = trim($_POST['hash']);
	if(!$_SESSION['upload'] || !$_SESSION['upload']['hash'] || $_SESSION['upload']['hash']!=$hash){
		exit('{"code":-1,"msg":"参数校验失败，请刷新页面重试"}');
	}
	if(!preg_match('/^[0-9a-z]{32}$/i', $hash))exit('{"code":-1,"msg":"hash error"}');
	$chunks = intval($_SESSION['upload']['chunks']);
	$ext = $_SESSION['upload']['ext'];
	if($chunks > 1){
		$tempFile = sys_get_temp_dir() . '/' . $hash. '.part'.$chunk;
		if(!move_uploaded_file($_FILES['file']['tmp_name'], $tempFile)){
			exit('{"code":-1,"msg":"文件第'.$chunk.'分块上传失败"}');
		}
		if($chunks == $chunk){
			$savePathTemp = file_part_merge($hash, $chunks);
			$real_hash = md5_file($savePathTemp);
			$real_size = filesize($savePathTemp);
			$result = $stor->savefile($hash, $savePathTemp, minetype($ext));
			if(!$result)exit('{"code":-1,"msg":"文件上传失败","error":"stor","errmsg":"'.$stor->errmsg().'"}');
		}else{
			$result = ['code'=>0, 'chunk'=>$chunk];
			exit(json_encode($result));
		}
	}else{
		$real_hash = md5_file($_FILES['file']['tmp_name']);
		$real_size = filesize($_FILES['file']['tmp_name']);
		$result = $stor->upload($hash, $_FILES['file']['tmp_name'], minetype($ext));
		if(!$result)exit('{"code":-1,"msg":"文件上传失败","error":"stor","errmsg":"'.$stor->errmsg().'"}');
	}

	$size = $_SESSION['upload']['size'];
	if($real_size != $size){
		exit('{"code":-1,"msg":"文件大小校验失败"}');
	}
	if($real_hash != $hash){
		exit('{"code":-1,"msg":"文件MD5校验失败"}');
	}

	$name = $_SESSION['upload']['name'];
	$hide = $_SESSION['upload']['hide'];
	$pwd = $_SESSION['upload']['pwd'];
	$folder_id = isset($_SESSION['upload']['folder_id'])?intval($_SESSION['upload']['folder_id']):0;

	$row = $DB->getRow("SELECT * FROM pre_file WHERE hash=:hash", [':hash'=>$hash]);
	if($row){
		unset($_SESSION['upload']);
		$result = ['code'=>1, 'msg'=>'本站已存在该文件', 'exists'=>1, 'hash'=>$hash, 'name'=>$name, 'size'=>$size, 'type'=>$ext, 'id'=>$row['id']];
		exit(json_encode($result));
	}

	$sds = $DB->exec("INSERT INTO `pre_file` (`name`,`type`,`size`,`hash`,`addtime`,`ip`,`hide`,`pwd`,`uid`,`folder_id`) values (:name,:type,:size,:hash,NOW(),:ip,:hide,:pwd,:uid,:folder_id)", [':name'=>$name, ':type'=>$ext, ':size'=>$size, ':hash'=>$hash, ':ip'=>$clientip, ':hide'=>$hide, ':pwd'=>$pwd, ':uid'=>($uid?$uid:0), ':folder_id'=>$folder_id]);
	if(!$sds)exit('{"code":-1,"msg":"上传失败'.$DB->error().'","error":"database"}');
	$id = $DB->lastInsertId();

	$type_image = explode('|',$conf['type_image']);
	$type_video = explode('|',$conf['type_video']);
	if($conf['green_check']>0 && in_array($ext,$type_image)){
		if(checkImage($hash, $ext)){
			$DB->exec("UPDATE `pre_file` SET `block`=1 WHERE `id`='{$id}' LIMIT 1");
		}
	}
	if($conf['videoreview']==1 && in_array($ext,$type_video)){
		$DB->exec("UPDATE `pre_file` SET `block`=2 WHERE `id`='{$id}' LIMIT 1");
	}
	
	$_SESSION['fileids'][] = $id;
	unset($_SESSION['upload']);
	$result = ['code'=>1, 'msg'=>'文件上传成功！', 'exists'=>0, 'hash'=>$hash, 'name'=>$name, 'size'=>$size, 'type'=>$ext, 'id'=>$id];
	exit(json_encode($result));
break;

case 'complete_upload':
	if($conf['forcelogin']==1 && !$islogin2)exit('{"code":-1,"msg":"请先登录"}');
	$hash = trim($_POST['hash']);
	if(!$_SESSION['upload'] || !$_SESSION['upload']['hash'] || $_SESSION['upload']['hash']!=$hash){
		exit('{"code":-1,"msg":"参数校验失败，请刷新页面重试"}');
	}
	if(!preg_match('/^[0-9a-z]{32}$/i', $hash))exit('{"code":-1,"msg":"hash error"}');
	
	if(!$stor->exists($hash)){
		exit('{"code":-1,"msg":"文件上传失败","error":"stor","errmsg":"'.$stor->errmsg().'"}');
	}

	$name = $_SESSION['upload']['name'];
	$size = $_SESSION['upload']['size'];
	$ext = $_SESSION['upload']['ext'];
	$hide = $_SESSION['upload']['hide'];
	$pwd = $_SESSION['upload']['pwd'];
	$folder_id = isset($_SESSION['upload']['folder_id'])?intval($_SESSION['upload']['folder_id']):0;

	$row = $DB->getRow("SELECT * FROM pre_file WHERE hash=:hash", [':hash'=>$hash]);
	if($row){
		unset($_SESSION['upload']);
		$result = ['code'=>1, 'msg'=>'本站已存在该文件', 'exists'=>1, 'hash'=>$hash, 'name'=>$name, 'size'=>$size, 'type'=>$ext, 'id'=>$row['id']];
		exit(json_encode($result));
	}

	$sds = $DB->exec("INSERT INTO `pre_file` (`name`,`type`,`size`,`hash`,`addtime`,`ip`,`hide`,`pwd`,`uid`,`folder_id`) values (:name,:type,:size,:hash,NOW(),:ip,:hide,:pwd,:uid,:folder_id)", [':name'=>$name, ':type'=>$ext, ':size'=>$size, ':hash'=>$hash, ':ip'=>$clientip, ':hide'=>$hide, ':pwd'=>$pwd, ':uid'=>($uid?$uid:0), ':folder_id'=>$folder_id]);
	if(!$sds)exit('{"code":-1,"msg":"上传失败'.$DB->error().'","error":"database"}');
	$id = $DB->lastInsertId();

	$type_image = explode('|',$conf['type_image']);
	$type_video = explode('|',$conf['type_video']);
	if($conf['green_check']>0 && in_array($ext,$type_image)){
		if(checkImage($hash, $ext)){
			$DB->exec("UPDATE `pre_file` SET `block`=1 WHERE `id`='{$id}' LIMIT 1");
		}
	}
	if($conf['videoreview']==1 && in_array($ext,$type_video)){
		$DB->exec("UPDATE `pre_file` SET `block`=2 WHERE `id`='{$id}' LIMIT 1");
	}
	
	$_SESSION['fileids'][] = $id;
	unset($_SESSION['upload']);
	$result = ['code'=>1, 'msg'=>'文件上传成功！', 'exists'=>0, 'hash'=>$hash, 'name'=>$name, 'size'=>$size, 'type'=>$ext, 'id'=>$id];
	exit(json_encode($result));
break;

case 'batch_delete':
	$hashes = isset($_POST['hashes'])?trim($_POST['hashes']):exit('{"code":-1,"msg":"no hashes"}');
	$ids = isset($_POST['ids'])?trim($_POST['ids']):exit('{"code":-1,"msg":"no ids"}');
	if(!verifyCsrfToken())exit('{"code":-1,"msg":"CSRF TOKEN ERROR"}');
	$hash_arr = array_filter(array_map('trim', explode(',', $hashes)));
	$id_arr = array_filter(array_map('intval', explode(',', $ids)));
	if(empty($hash_arr) || empty($id_arr))exit('{"code":-1,"msg":"参数错误"}');
	$deleted = 0;
	$failed = 0;
	$now = date("Y-m-d H:i:s");
	foreach($hash_arr as $i => $hash){
		if(!preg_match('/^[0-9a-z]{32}$/i', $hash)){ $failed++; continue; }
		$id = isset($id_arr[$i]) ? $id_arr[$i] : 0;
		$row = $DB->getRow("SELECT * FROM `pre_file` WHERE `hash`=:hash AND `id`=:id", [':hash'=>$hash, ':id'=>$id]);
		if(!$row){ $failed++; continue; }
		if($islogin2 && $row['uid']!=$uid || !$islogin2 && (!isset($_SESSION['fileids']) || !in_array($row['id'], $_SESSION['fileids']))){ $failed++; continue; }
		if($row['block']==1){ $failed++; continue; }
		if(!$islogin2 && strtotime($row['addtime'])<strtotime("-7 days")){ $failed++; continue; }
		$stor->delete($row['hash']);
		$DB->exec("DELETE FROM pre_file WHERE id=:id", [':id'=>$row['id']]);
		$deleted++;
	}
	exit(json_encode(['code'=>0,'msg'=>'删除完成','deleted'=>$deleted,'failed'=>$failed]));
break;

case 'folder_list':
	if(!verifyCsrfToken())exit('{"code":-1,"msg":"CSRF TOKEN ERROR"}');
	if(!$islogin2)exit('{"code":-1,"msg":"请先登录"}');
	$folders = $DB->getAll("SELECT * FROM pre_folder WHERE uid=:uid ORDER BY id DESC", [':uid'=>$uid]);
	foreach($folders as $k => $f){
		$folders[$k]['file_count'] = $DB->getColumn("SELECT count(*) FROM pre_file WHERE folder_id=:id AND uid=:uid", [':id'=>$f['id'], ':uid'=>$uid]);
	}
	exit(json_encode(['code'=>0,'folders'=>$folders]));
break;

case 'folder_create':
	if(!verifyCsrfToken())exit('{"code":-1,"msg":"CSRF TOKEN ERROR"}');
	if(!$islogin2)exit('{"code":-1,"msg":"请先登录"}');
	$name = trim(htmlspecialchars($_POST['name']));
	if(empty($name))exit('{"code":-1,"msg":"文件夹名称不能为空"}');
	$name = str_replace(['/','\\',':','*','"','<','>','|','?'],'',$name);
	if(empty($name))exit('{"code":-1,"msg":"文件夹名称不合法"}');
	$exist = $DB->getRow("SELECT * FROM pre_folder WHERE name=:name AND uid=:uid", [':name'=>$name, ':uid'=>$uid]);
	if($exist)exit('{"code":-1,"msg":"该文件夹已存在"}');
	$sds = $DB->exec("INSERT INTO `pre_folder` (`name`,`uid`,`addtime`) values (:name,:uid,NOW())", [':name'=>$name, ':uid'=>$uid]);
	if(!$sds)exit('{"code":-1,"msg":"创建失败'.$DB->error().'"}');
	$id = $DB->lastInsertId();
	exit(json_encode(['code'=>0,'msg'=>'创建成功','id'=>$id]));
break;

case 'folder_setpwd':
	if(!verifyCsrfToken())exit('{"code":-1,"msg":"CSRF TOKEN ERROR"}');
	if(!$islogin2)exit('{"code":-1,"msg":"请先登录"}');
	$folder_id = isset($_POST['folder_id'])?intval($_POST['folder_id']):exit('{"code":-1,"msg":"参数错误"}');
	$pwd = trim($_POST['pwd']);
	$folder = $DB->getRow("SELECT * FROM pre_folder WHERE id=:id AND uid=:uid", [':id'=>$folder_id, ':uid'=>$uid]);
	if(!$folder)exit('{"code":-1,"msg":"文件夹不存在"}');
	$DB->exec("UPDATE pre_folder SET pwd=:pwd WHERE id=:id", [':pwd'=>empty($pwd)?null:$pwd, ':id'=>$folder_id]);
	exit(json_encode(['code'=>0,'msg'=>'设置成功']));
break;

case 'folder_toggle_hide':
	if(!verifyCsrfToken())exit('{"code":-1,"msg":"CSRF TOKEN ERROR"}');
	if(!$islogin2)exit('{"code":-1,"msg":"请先登录"}');
	$folder_id = isset($_POST['folder_id'])?intval($_POST['folder_id']):exit('{"code":-1,"msg":"参数错误"}');
	$folder = $DB->getRow("SELECT * FROM pre_folder WHERE id=:id AND uid=:uid", [':id'=>$folder_id, ':uid'=>$uid]);
	if(!$folder)exit('{"code":-1,"msg":"文件夹不存在"}');
	$new_hide = $folder['hide']==1?0:1;
	$DB->exec("UPDATE pre_folder SET hide=:hide WHERE id=:id", [':hide'=>$new_hide, ':id'=>$folder_id]);
	exit(json_encode(['code'=>0,'msg'=>'操作成功']));
break;

case 'folder_delete':
	if(!verifyCsrfToken())exit('{"code":-1,"msg":"CSRF TOKEN ERROR"}');
	if(!$islogin2)exit('{"code":-1,"msg":"请先登录"}');
	$folder_id = isset($_POST['folder_id'])?intval($_POST['folder_id']):exit('{"code":-1,"msg":"参数错误"}');
	$folder = $DB->getRow("SELECT * FROM pre_folder WHERE id=:id AND uid=:uid", [':id'=>$folder_id, ':uid'=>$uid]);
	if(!$folder)exit('{"code":-1,"msg":"文件夹不存在"}');
	$DB->exec("DELETE FROM pre_folder WHERE id=:id", [':id'=>$folder_id]);
	exit(json_encode(['code'=>0,'msg'=>'删除成功']));
break;

case 'saveUserSettings':
    if(!verifyCsrfToken())exit('{"code":-1,"msg":"CSRF TOKEN ERROR"}');
    if(!$islogin2)exit('{"code":-1,"msg":"请先登录"}');
    $action = isset($_POST['action'])?trim($_POST['action']):exit('{"code":-1,"msg":"参数错误"}');
    
    if($action == 'nickname'){
        $nickname = trim(htmlspecialchars($_POST['nickname']));
        if(empty($nickname))exit('{"code":-1,"msg":"昵称不能为空"}');
        if(strlen($nickname) > 20)exit('{"code":-1,"msg":"昵称不能超过20个字符"}');
        $DB->exec("UPDATE pre_user SET nickname=:nickname WHERE uid=:uid", [':nickname'=>$nickname, ':uid'=>$uid]);
        exit(json_encode(['code'=>0,'msg'=>'保存成功']));
    }elseif($action == 'password'){
        if(!$userrow['username'] || !$userrow['password'])exit('{"code":-1,"msg":"当前账号不支持修改密码"}');
        $old_password = trim($_POST['old_password']);
        $new_password = trim($_POST['new_password']);
        if(empty($old_password))exit('{"code":-1,"msg":"请输入当前密码"}');
        if(empty($new_password))exit('{"code":-1,"msg":"请输入新密码"}');
        if(strlen($new_password) < 6 || strlen($new_password) > 20)exit('{"code":-1,"msg":"密码长度必须在6-20位之间"}');
        if(!preg_match('/^[a-zA-Z0-9]+$/', $new_password))exit('{"code":-1,"msg":"密码只能包含字母和数字"}');
        if($userrow['password'] != md5($old_password))exit('{"code":-1,"msg":"当前密码错误"}');
        $new_pwd_md5 = md5($new_password);
        $DB->exec("UPDATE pre_user SET password=:password WHERE uid=:uid", [':password'=>$new_pwd_md5, ':uid'=>$uid]);
        exit(json_encode(['code'=>0,'msg'=>'密码修改成功']));
    }else{
        exit('{"code":-1,"msg":"未知操作"}');
    }
break;

case 'deleteFile':
	$hash = isset($_POST['hash'])?trim($_POST['hash']):exit('{"code":-1,"msg":"no hash"}');
	if(!verifyCsrfToken())exit('{"code":-1,"msg":"CSRF TOKEN ERROR"}');
	if(!preg_match('/^[0-9a-z]{32}$/i', $hash))exit('{"code":-1,"msg":"hash error"}');
	$row = $DB->getRow("SELECT * FROM `pre_file` WHERE `hash`=:hash", [':hash'=>$hash]);
	if(!$row)exit('{"code":-1,"msg":"文件不存在"}');
	if($islogin2 && $row['uid']!=$uid || !$islogin2 && (!isset($_SESSION['fileids']) || !in_array($row['id'], $_SESSION['fileids'])))exit('{"code":-1,"msg":"无权限"}');
	if($row['block']==1)exit('{"code":-1,"msg":"文件已被冻结，无法删除"}');
	if(!$islogin2 && strtotime($row['addtime'])<strtotime("-7 days"))exit('{"code":-1,"msg":"无法删除7天前的文件"}');
	$result = $stor->delete($row['hash']);
	$sql = "DELETE FROM pre_file WHERE id=:id";
	if($DB->exec($sql, [':id'=>$row['id']]))exit('{"code":0,"msg":"删除文件成功！"}');
	else exit('{"code":-1,"msg":"删除文件失败['.$DB->error().']"}');
break;

default:
	exit('{"code":-4,"msg":"No Act"}');
break;
}