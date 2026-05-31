<?php
$nosecu = true;
include("./includes/common.php");
$act=isset($_GET['act'])?daddslashes($_GET['act']):null;

if(!checkRefererHost()){
	@header('Content-Type: application/json; charset=UTF-8');
	exit('{"code":403,"msg":"Referer校验失败"}');
}

@header('Content-Type: application/json; charset=UTF-8');

function verifyCsrfToken(&$tokenIndex = null, $reuse = true) {
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
case 'get_user_info':
	if(!$islogin2){
		exit(json_encode(['code'=>-1, 'msg'=>'未登录']));
	}
	$storage_quota = isset($userrow['storage_quota']) ? intval($userrow['storage_quota']) : 1073741824;
	$storage_used = isset($userrow['storage_used']) ? intval($userrow['storage_used']) : 0;
	exit(json_encode([
		'code' => 0,
		'data' => [
			'uid' => $uid,
			'username' => $userrow['username'],
			'nickname' => $userrow['nickname'] ?: '用户',
			'faceimg' => $userrow['faceimg'] ?? '',
			'avatar' => $userrow['avatar'] ?? '',
			'level' => intval($userrow['level']),
			'storage_quota' => $storage_quota,
			'storage_used' => $storage_used,
			'allow_view' => intval($userrow['allow_view'] ?? 1),
			'allow_search' => intval($userrow['allow_search'] ?? 1),
			'addtime' => $userrow['addtime'] ?? '',
			'lasttime' => $userrow['lasttime'] ?? '',
		]
	]));
break;
case 'file_list':
	if(!$islogin2){
		exit(json_encode(['code'=>-1, 'msg'=>'未登录']));
	}
	$folder_id = isset($_GET['folder_id']) ? intval($_GET['folder_id']) : 0;
	$keyword = isset($_GET['keyword']) ? trim($_GET['keyword']) : '';
	$hide = isset($_GET['hide']) ? intval($_GET['hide']) : 0;

	$sql = "SELECT * FROM pre_file WHERE uid=$uid AND is_deleted=0";
	if($folder_id > 0) $sql .= " AND folder_id=$folder_id";
	if($hide == 0) $sql .= " AND hide=0";
	if(!empty($keyword)) $sql .= " AND name LIKE '%$keyword%'";
	$sql .= " ORDER BY id DESC LIMIT 200";

	$rs = $DB->query($sql);
	$files = [];
	while($row = $rs->fetch()){
		$files[] = $row;
	}
	exit(json_encode(['code'=>0, 'files'=>$files]));
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
			$real_sha256 = hash_file('sha256', $savePathTemp);
			$result = $stor->savefile($hash, $savePathTemp, minetype($ext));
			if(!$result)exit('{"code":-1,"msg":"文件上传失败","error":"stor","errmsg":"'.$stor->errmsg().'"}');
		}else{
			$result = ['code'=>0, 'chunk'=>$chunk];
			exit(json_encode($result));
		}
	}else{
		$real_hash = md5_file($_FILES['file']['tmp_name']);
		$real_size = filesize($_FILES['file']['tmp_name']);
		$real_sha256 = hash_file('sha256', $_FILES['file']['tmp_name']);
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

	$sds = $DB->exec("INSERT INTO `pre_file` (`name`,`type`,`size`,`hash`,`sha256`,`addtime`,`ip`,`hide`,`pwd`,`uid`,`folder_id`) values (:name,:type,:size,:hash,:sha256,NOW(),:ip,:hide,:pwd,:uid,:folder_id)", [':name'=>$name, ':type'=>$ext, ':size'=>$size, ':hash'=>$hash, ':sha256'=>$real_sha256, ':ip'=>$clientip, ':hide'=>$hide, ':pwd'=>$pwd, ':uid'=>($uid?$uid:0), ':folder_id'=>$folder_id]);
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

	$sha256 = '';
	$localPath = ROOT . 'file/' . $hash;
	if(file_exists($localPath)){
		$sha256 = hash_file('sha256', $localPath);
	}

	$row = $DB->getRow("SELECT * FROM pre_file WHERE hash=:hash", [':hash'=>$hash]);
	if($row){
		unset($_SESSION['upload']);
		$result = ['code'=>1, 'msg'=>'本站已存在该文件', 'exists'=>1, 'hash'=>$hash, 'name'=>$name, 'size'=>$size, 'type'=>$ext, 'id'=>$row['id']];
		exit(json_encode($result));
	}

	$sds = $DB->exec("INSERT INTO `pre_file` (`name`,`type`,`size`,`hash`,`sha256`,`addtime`,`ip`,`hide`,`pwd`,`uid`,`folder_id`) values (:name,:type,:size,:hash,:sha256,NOW(),:ip,:hide,:pwd,:uid,:folder_id)", [':name'=>$name, ':type'=>$ext, ':size'=>$size, ':hash'=>$hash, ':sha256'=>$sha256, ':ip'=>$clientip, ':hide'=>$hide, ':pwd'=>$pwd, ':uid'=>($uid?$uid:0), ':folder_id'=>$folder_id]);
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
    }elseif($action == 'privacy'){
        $allow_view = isset($_POST['allow_view']) ? intval($_POST['allow_view']) : 1;
        $allow_search = isset($_POST['allow_search']) ? intval($_POST['allow_search']) : 1;
        $DB->exec("UPDATE pre_user SET allow_view=:allow_view, allow_search=:allow_search WHERE uid=:uid", [':allow_view'=>$allow_view, ':allow_search'=>$allow_search, ':uid'=>$uid]);
        exit(json_encode(['code'=>0,'msg'=>'保存成功']));
    }else{
        exit('{"code":-1,"msg":"未知操作"}');
    }
break;

case 'uploadAvatar':
     if(!$islogin2)exit('{"code":-1,"msg":"请先登录"}');
     if(!isset($_FILES['avatar']))exit('{"code":-1,"msg":"请选择图片文件"}');
     $file = $_FILES['avatar'];
     if($file['error'] != 0)exit('{"code":-1,"msg":"上传失败，错误代码:'.$file['error'].'"}');
     $allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/bmp'];
     if(!in_array($file['type'], $allowed_types))exit('{"code":-1,"msg":"只支持上传图片格式文件"}');
     if($file['size'] > 2 * 1024 * 1024)exit('{"code":-1,"msg":"图片大小不能超过2MB"}');
     $ext = pathinfo($file['name'], PATHINFO_EXTENSION);
     if(!$ext) $ext = 'jpg';
     $avatar_name = 'avatar_' . $uid . '_' . time() . '.' . $ext;
     $avatar_path = ROOT . 'assets/img/avatars/' . $avatar_name;
     $avatar_dir = dirname($avatar_path);
     if(!is_dir($avatar_dir)){
         mkdir($avatar_dir, 0755, true);
     }
     if(!move_uploaded_file($file['tmp_name'], $avatar_path))exit('{"code":-1,"msg":"头像保存失败"}');
     $avatar_url = './assets/img/avatars/' . $avatar_name;
     $DB->exec("UPDATE pre_user SET avatar=:avatar WHERE uid=:uid", [':avatar'=>$avatar_url, ':uid'=>$uid]);
     exit(json_encode(['code'=>0,'msg'=>'头像上传成功','avatar'=>$avatar_url]));
 break;

case 'unbindAccount':
    if(!verifyCsrfToken())exit('{"code":-1,"msg":"CSRF TOKEN ERROR"}');
    if(!$islogin2)exit('{"code":-1,"msg":"请先登录"}');
    $type = trim($_POST['type']);
    if(!in_array($type, ['wx', 'qq']))exit('{"code":-1,"msg":"不支持的类型"}');
    if($type == 'wx'){
        if(!$userrow['wx_openid'])exit('{"code":-1,"msg":"未绑定微信账号"}');
        $DB->exec("UPDATE pre_user SET wx_openid=NULL, wx_nickname=NULL, wx_faceimg=NULL WHERE uid=:uid", [':uid'=>$uid]);
    }elseif($type == 'qq'){
        if(!$userrow['qq_openid'])exit('{"code":-1,"msg":"未绑定QQ账号"}');
        $DB->exec("UPDATE pre_user SET qq_openid=NULL, qq_nickname=NULL, qq_faceimg=NULL WHERE uid=:uid", [':uid'=>$uid]);
    }
    exit(json_encode(['code'=>0,'msg'=>'解绑成功']));
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
	$result = $DB->exec("UPDATE pre_file SET is_deleted=1, deleted_time=NOW() WHERE id=:id", [':id'=>$row['id']]);
	if(!$result)exit('{"code":-1,"msg":"删除失败'.$DB->error().'"}');
	exit('{"code":0,"msg":"删除文件成功！文件已移至回收站"}');
break;

case 'recycle_list':
	if(!$islogin2)exit(json_encode(['code'=>-1,'msg'=>'未登录']));
	$rs = $DB->query("SELECT * FROM pre_file WHERE uid=$uid AND is_deleted=1 ORDER BY deleted_time DESC LIMIT 200");
	$files = [];
	while($row = $rs->fetch()){
		$files[] = $row;
	}
	exit(json_encode(['code'=>0,'files'=>$files]));
break;

case 'restoreFile':
	$hash = isset($_POST['hash'])?trim($_POST['hash']):exit('{"code":-1,"msg":"no hash"}');
	if(!verifyCsrfToken())exit('{"code":-1,"msg":"CSRF TOKEN ERROR"}');
	if(!preg_match('/^[0-9a-z]{32}$/i', $hash))exit('{"code":-1,"msg":"hash error"}');
	$row = $DB->getRow("SELECT * FROM pre_file WHERE hash=:hash AND uid=:uid AND is_deleted=1", [':hash'=>$hash, ':uid'=>$uid]);
	if(!$row)exit('{"code":-1,"msg":"文件不存在或不在回收站中"}');
	$DB->exec("UPDATE pre_file SET is_deleted=0, deleted_time=NULL WHERE id=:id", [':id'=>$row['id']]);
	exit('{"code":0,"msg":"恢复成功"}');
break;

case 'share_list':
	if(!$islogin2)exit(json_encode(['code'=>-1,'msg'=>'未登录']));
	$rs = $DB->query("SELECT s.*, f.name as file_name, f.size as file_size, f.type as file_type, f.hash as file_hash FROM pre_share s LEFT JOIN pre_file f ON s.file_id=f.id WHERE s.uid=$uid ORDER BY s.id DESC LIMIT 100");
	$shares = [];
	while($row = $rs->fetch()){
		$shares[] = $row;
	}
	exit(json_encode(['code'=>0,'shares'=>$shares]));
break;

case 'create_share':
	if(!verifyCsrfToken())exit('{"code":-1,"msg":"CSRF TOKEN ERROR"}');
	if(!$islogin2)exit('{"code":-1,"msg":"请先登录"}');
	$file_id = isset($_POST['file_id'])?intval($_POST['file_id']):exit('{"code":-1,"msg":"参数错误"}');
	$pwd = isset($_POST['pwd'])?trim($_POST['pwd']):'';
	$expire_type = isset($_POST['expire_type'])?intval($_POST['expire_type']):0;
	$file = $DB->getRow("SELECT * FROM pre_file WHERE id=:id AND uid=:uid AND is_deleted=0", [':id'=>$file_id, ':uid'=>$uid]);
	if(!$file)exit('{"code":-1,"msg":"文件不存在"}');
	if($file['block']==1)exit('{"code":-1,"msg":"文件已被冻结"}');
	$surl = md5($uid.$file_id.time().mt_rand(0,999));
	$expire_time = null;
	if($expire_type==1) $expire_time = date('Y-m-d H:i:s', strtotime('+7 days'));
	elseif($expire_type==2) $expire_time = date('Y-m-d H:i:s', strtotime('+30 days'));
	$DB->exec("INSERT INTO pre_share (surl,file_id,uid,pwd,expire_time,expire_type,addtime) VALUES (:surl,:file_id,:uid,:pwd,:expire_time,:expire_type,NOW())", [
		':surl'=>$surl, ':file_id'=>$file_id, ':uid'=>$uid, ':pwd'=>$pwd ?: null,
		':expire_time'=>$expire_time, ':expire_type'=>$expire_type
	]);
	exit(json_encode(['code'=>0,'msg'=>'分享创建成功','surl'=>$surl]));
break;

case 'delete_share':
	$surl = isset($_POST['surl'])?trim($_POST['surl']):exit('{"code":-1,"msg":"参数错误"}');
	if(!verifyCsrfToken())exit('{"code":-1,"msg":"CSRF TOKEN ERROR"}');
	if(!$islogin2)exit('{"code":-1,"msg":"请先登录"}');
	$DB->exec("DELETE FROM pre_share WHERE surl=:surl AND uid=:uid", [':surl'=>$surl, ':uid'=>$uid]);
	exit(json_encode(['code'=>0,'msg'=>'分享已删除']));
break;

case 'permanentDelete':
	$hash = isset($_POST['hash'])?trim($_POST['hash']):exit('{"code":-1,"msg":"no hash"}');
	if(!verifyCsrfToken())exit('{"code":-1,"msg":"CSRF TOKEN ERROR"}');
	if(!preg_match('/^[0-9a-z]{32}$/i', $hash))exit('{"code":-1,"msg":"hash error"}');
	$row = $DB->getRow("SELECT * FROM pre_file WHERE hash=:hash AND uid=:uid AND is_deleted=1", [':hash'=>$hash, ':uid'=>$uid]);
	if(!$row)exit('{"code":-1,"msg":"文件不存在"}');
	$stor->delete($row['hash']);
	$DB->exec("DELETE FROM pre_file WHERE id=:id", [':id'=>$row['id']]);
	exit('{"code":0,"msg":"彻底删除成功"}');
break;
case 'archive_list':
	$hash = trim(daddslashes($_GET['hash']));
	$row = $DB->getRow("SELECT * FROM pre_file WHERE hash=:hash", [':hash'=>$hash]);
	if(!$row) exit(json_encode(['code'=>-1,'msg'=>'文件不存在']));
	$type = $row['type'];
	$type_archive = ['zip','tar','tgz','gz'];
	if(!in_array($type, $type_archive)) exit(json_encode(['code'=>-1,'msg'=>'不支持的压缩包格式，仅支持ZIP和TAR格式']));
	if($conf['storage'] != 'local') exit(json_encode(['code'=>-1,'msg'=>'仅支持本地存储的压缩包查看']));
	$filepath = !empty($conf['filepath']) ? rtrim($conf['filepath'], '/') . '/' . $row['hash'] : ROOT . 'file/' . $row['hash'];
	if(!file_exists($filepath)) exit(json_encode(['code'=>-1,'msg'=>'文件不存在于本地存储']));
	$list = get_archive_list($filepath, $type);
	$total_size = 0;
	$file_count = 0;
	$dir_count = 0;
	foreach($list as $item){
		if(!$item['is_dir']){
			$total_size += $item['size'];
			$file_count++;
		}else{
			$dir_count++;
		}
	}
	exit(json_encode(['code'=>0,'name'=>$row['name'],'archive_type'=>$type,'total_size'=>$total_size,'file_count'=>$file_count,'dir_count'=>$dir_count,'list'=>$list]));
break;

default:

	exit('{"code":-4,"msg":"No Act"}');

break;

}