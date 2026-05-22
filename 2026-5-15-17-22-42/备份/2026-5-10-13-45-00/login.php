<?php
include("./includes/common.php");

if(!$conf['userlogin']){
    @header('Content-Type: text/html; charset=UTF-8');
	exit("<script language='javascript'>alert('未开启登录');window.location.href='./';</script>");
}
if(isset($_GET['logout'])){
	if(!checkRefererHost())exit();
	setcookie("user_token", "", time() - 1, '/');
	@header('Content-Type: text/html; charset=UTF-8');
	exit("<script language='javascript'>alert('您已成功注销本次登录！');window.location.href='./login.php';</script>");
}elseif(isset($_GET['act']) && $_GET['act']=='local_login'){
    @header('Content-Type: application/json; charset=UTF-8');
    $username = trim(htmlspecialchars($_POST['username']));
    $password = $_POST['password'];
    if(empty($username))exit(json_encode(['code'=>-1, 'msg'=>'用户名不能为空']));
    if(empty($password))exit(json_encode(['code'=>-1, 'msg'=>'密码不能为空']));
    if(!preg_match('/^[a-zA-Z0-9_\x{4e00}-\x{9fa5}]{2,20}$/u', $username))exit(json_encode(['code'=>-1, 'msg'=>'用户名格式不正确，只能为字母、数字、下划线或中文']));
    $userrow = $DB->getRow("SELECT * FROM pre_user WHERE username=:username", [':username'=>$username]);
    if(!$userrow || empty($userrow['password'])){
        exit(json_encode(['code'=>-1, 'msg'=>'用户不存在']));
    }
    if($userrow['password'] != md5($password)){
        exit(json_encode(['code'=>-1, 'msg'=>'密码错误']));
    }
    if($userrow['enable']==0){
        exit(json_encode(['code'=>-1, 'msg'=>'当前用户已被禁止登录']));
    }
    $uid = $userrow['uid'];
    $DB->exec("UPDATE pre_user SET loginip=:loginip, lasttime=NOW() WHERE uid=:uid", [':loginip'=>$clientip, ':uid'=>$uid]);
    if(isset($_SESSION['fileids']) && count($_SESSION['fileids'])>0){
        $ids = array_reverse($_SESSION['fileids']);
        if(count($ids) > 60){
            $ids = array_splice($ids, 0, 60);
        }
        $ids = implode(',',$ids);
        $DB->exec("UPDATE pre_file SET uid='{$uid}' WHERE id IN ({$ids}) AND uid=0");
    }
    $session=md5($userrow['username'].$userrow['password'].$password_hash);
    $expiretime=time()+2592000;
    $token=authcode("{$uid}\t{$session}\t{$expiretime}", 'ENCODE', SYS_KEY);
    setcookie("user_token", $token, time() + 2592000, '/');
    exit(json_encode(['code'=>0, 'msg'=>'登录成功']));
}elseif(isset($_GET['act']) && $_GET['act']=='local_register'){
    @header('Content-Type: application/json; charset=UTF-8');
    $username = trim(htmlspecialchars($_POST['username']));
    $password = $_POST['password'];
    $repassword = $_POST['repassword'];
    if(empty($username))exit(json_encode(['code'=>-1, 'msg'=>'用户名不能为空']));
    if(empty($password))exit(json_encode(['code'=>-1, 'msg'=>'密码不能为空']));
    if(!preg_match('/^[a-zA-Z0-9_\x{4e00}-\x{9fa5}]{2,20}$/u', $username))exit(json_encode(['code'=>-1, 'msg'=>'用户名格式不正确，只能为字母、数字、下划线或中文']));
    if(strlen($password) < 6 || strlen($password) > 20)exit(json_encode(['code'=>-1, 'msg'=>'密码长度必须在6-20位之间']));
    if(!preg_match('/^[a-zA-Z0-9]+$/', $password))exit(json_encode(['code'=>-1, 'msg'=>'密码只能包含字母和数字']));
    if($password !== $repassword)exit(json_encode(['code'=>-1, 'msg'=>'两次输入的密码不一致']));
    $exist = $DB->getRow("SELECT uid FROM pre_user WHERE username=:username", [':username'=>$username]);
    if($exist)exit(json_encode(['code'=>-1, 'msg'=>'该用户名已被注册']));
    $pwd_md5 = md5($password);
    if(!$DB->exec("INSERT INTO pre_user (username, password, type, openid, nickname, enable, regip, loginip, addtime, lasttime) VALUES (:username, :password, '', '', :nickname, 1, :regip, :loginip, NOW(), NOW())", [':username'=>$username, ':password'=>$pwd_md5, ':nickname'=>$username, ':regip'=>$clientip, ':loginip'=>$clientip])){
        exit(json_encode(['code'=>-1, 'msg'=>'注册失败，请稍后重试']));
    }
    $uid = $DB->lastInsertId();
    if(isset($_SESSION['fileids']) && count($_SESSION['fileids'])>0){
        $ids = array_reverse($_SESSION['fileids']);
        if(count($ids) > 60){
            $ids = array_splice($ids, 0, 60);
        }
        $ids = implode(',',$ids);
        $DB->exec("UPDATE pre_file SET uid='{$uid}' WHERE id IN ({$ids}) AND uid=0");
    }
    $session=md5($username.$pwd_md5.$password_hash);
    $expiretime=time()+2592000;
    $token=authcode("{$uid}\t{$session}\t{$expiretime}", 'ENCODE', SYS_KEY);
    setcookie("user_token", $token, time() + 2592000, '/');
    exit(json_encode(['code'=>0, 'msg'=>'注册成功，已自动登录']));
}elseif(isset($_GET['act']) && $_GET['act']=='connect'){
    @header('Content-Type: application/json; charset=UTF-8');
    $type = isset($_POST['type'])?$_POST['type']:exit('{"code":-1,"msg":"no type"}');
    if(!$conf['login_apiurl'] || !$conf['login_appid'] || !$conf['login_appkey'])exit('{"code":-1,"msg":"未配置好快捷登录接口信息"}');
    $Oauth = new \lib\Oauth($conf['login_apiurl'], $conf['login_appid'], $conf['login_appkey']);
    $res = $Oauth->login($type);
    if(isset($res['code']) && $res['code']==0){
        $result = ['code'=>0, 'url'=>$res['url']];
    }elseif(isset($res['code'])){
        $result = ['code'=>-1, 'msg'=>$res['msg']];
    }else{
        $result = ['code'=>-1, 'msg'=>'快捷登录接口请求失败'];
    }
    exit(json_encode($result));
}elseif($_GET['code'] && $_GET['type'] && $_GET['state']){
	if($_GET['state'] != $_SESSION['Oauth_state']){
		sysmsg("<h2>The state does not match. You may be a victim of CSRF.</h2>");
	}
	$type = $_GET['type'];
    $typename = $type=='wx'?'微信':'QQ';
	$Oauth = new \lib\Oauth($conf['login_apiurl'], $conf['login_appid'], $conf['login_appkey']);
	$arr = $Oauth->callback();
	if(isset($arr['code']) && $arr['code']==0){
		$openid=$arr['social_uid'];
		$access_token=$arr['access_token'];
		$nickname=trim($arr['nickname']);
        if(empty($nickname) || $nickname=='-') $nickname = $typename.'用户';
		$faceimg=$arr['faceimg'];
	}elseif(isset($arr['code'])){
		sysmsg('<h3>error:</h3>'.$arr['errcode'].'<h3>msg  :</h3>'.$arr['msg']);
	}else{
		sysmsg('获取登录数据失败');
	}

    $userrow=$DB->find('user','*',['type'=>$type, 'openid'=>$openid], null, '1');
	if(!$userrow){
        if(!$DB->insert('user', [
            'type' => $type,
            'openid' => $openid,
            'nickname' => $nickname,
            'faceimg' => $faceimg,
            'enable' => 1,
            'regip' => $clientip,
            'loginip' => $clientip,
            'addtime' => 'NOW()',
            'lasttime' => 'NOW()',
        ]))sysmsg('用户注册失败 '.$DB->error());
        $uid = $DB->lastInsertId();
	}else{
        if($userrow['enable']==0){
            $_SESSION['user_block'] = true;
            sysmsg('当前用户已被禁止登录');
        }
        $uid = $userrow['uid'];
        $DB->update('user', ['loginip' => $clientip, 'lasttime'=>'NOW()'], ['uid'=>$uid]);
    }
    if($_SESSION['user_block']){
        $DB->update('user', ['enable' => 0], ['uid'=>$uid]);
        sysmsg('当前用户已被禁止登录');
    }
    if(isset($_SESSION['fileids']) && count($_SESSION['fileids'])>0){
        $ids = array_reverse($_SESSION['fileids']);
        if(count($ids) > 60){
            $ids = array_splice($ids, 0, 60);
        }
        $ids = implode(',',$ids);
        $DB->exec("UPDATE pre_file SET uid='{$uid}' WHERE id IN ({$ids}) AND uid=0");
    }
    $session=md5($type.$openid.$password_hash);
    $expiretime=time()+2592000;
    $token=authcode("{$uid}\t{$session}\t{$expiretime}", 'ENCODE', SYS_KEY);
    ob_clean();
    setcookie("user_token", $token, time() + 2592000, '/');
    exit("<script language='javascript'>window.location.href='./';</script>");
}

$islogin2=isset($islogin2)?$islogin2:0;
if($islogin2==1){
    @header('Content-Type: text/html; charset=UTF-8');
    exit("<script language='javascript'>alert('您已登录！');window.location.href='./';</script>");
}

$title = '用户登录 - ' . $conf['title'];
include SYSTEM_ROOT.'header.php';
?>
<div class="container">
<div class="col-xs-10 col-sm-8 col-md-6 col-lg-4 center-block" style="float: none;">
    <div class="well bs-component" style="margin-top:20px;">
        <ul class="nav nav-tabs">
            <li class="active"><a href="#login-tab" data-toggle="tab">账号登录</a></li>
            <li><a href="#register-tab" data-toggle="tab">注册账号</a></li>
            <?php if($conf['login_qq'] || $conf['login_wx']){?><li><a href="#oauth-tab" data-toggle="tab">快捷登录</a></li><?php }?>
        </ul>
        <div class="tab-content" style="padding:20px 0;">
            <div class="tab-pane active" id="login-tab">
                <form id="loginForm" class="form-horizontal">
                    <div class="form-group">
                        <label class="col-sm-3 control-label">用户名</label>
                        <div class="col-sm-9">
                            <input type="text" class="form-control" id="login_username" name="username" placeholder="请输入用户名" required>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-sm-3 control-label">密码</label>
                        <div class="col-sm-9">
                            <input type="password" class="form-control" id="login_password" name="password" placeholder="请输入密码" required>
                        </div>
                    </div>
                    <div class="form-group">
                        <div class="col-sm-offset-3 col-sm-9">
                            <button type="submit" class="btn btn-primary btn-block" id="loginBtn">登 录</button>
                        </div>
                    </div>
                </form>
            </div>
            <div class="tab-pane" id="register-tab">
                <form id="registerForm" class="form-horizontal">
                    <div class="form-group">
                        <label class="col-sm-3 control-label">用户名</label>
                        <div class="col-sm-9">
                            <input type="text" class="form-control" id="reg_username" name="username" placeholder="2-20位字母、数字、下划线或中文" required>
                            <p class="help-block">用户名注册后不可修改</p>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-sm-3 control-label">密码</label>
                        <div class="col-sm-9">
                            <input type="password" class="form-control" id="reg_password" name="password" placeholder="6-20位字母或数字" required>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="col-sm-3 control-label">确认密码</label>
                        <div class="col-sm-9">
                            <input type="password" class="form-control" id="reg_repassword" name="repassword" placeholder="请再次输入密码" required>
                        </div>
                    </div>
                    <div class="form-group">
                        <div class="col-sm-offset-3 col-sm-9">
                            <button type="submit" class="btn btn-success btn-block" id="regBtn">注 册</button>
                        </div>
                    </div>
                </form>
            </div>
            <div class="tab-pane" id="oauth-tab">
                <div class="row text-center" style="padding:30px 0;">
                    <p id="loginform">
                        <?php if($conf['login_qq']){?><a href="javascript:connect('qq')" class="btn btn-info btn-fab loginbtn"><i class="fa fa-qq"></i></a><?php }?>
                        <?php if($conf['login_wx']){?><a href="javascript:connect('wx')" class="btn btn-success btn-fab loginbtn"><i class="fa fa-wechat"></i></a><?php }?>
                    </p>
                    <p class="text-muted">新用户快捷登录后会自动注册账号</p>
                </div>
            </div>
        </div>
    </div>
</div>
</div>
<?php include SYSTEM_ROOT.'footer.php';?>
<script src="https://s4.zstatic.net/ajax/libs/layer/2.3/layer.js"></script>
<script>
$(function(){
    $('#loginForm').submit(function(e){
        e.preventDefault();
        var username = $.trim($('#login_username').val());
        var password = $('#login_password').val();
        if(!username){ layer.msg('请输入用户名'); return; }
        if(!password){ layer.msg('请输入密码'); return; }
        var ii = layer.load(2, {shade:[0.1,'#fff']});
        $('#loginBtn').prop('disabled', true).text('登录中...');
        $.ajax({
            type: 'POST',
            url: 'login.php?act=local_login',
            data: {username: username, password: password},
            dataType: 'json',
            success: function(data){
                layer.close(ii);
                $('#loginBtn').prop('disabled', false).text('登 录');
                if(data.code == 0){
                    layer.msg(data.msg, {icon:1, time:1000}, function(){
                        window.location.href = './';
                    });
                }else{
                    layer.alert(data.msg, {icon: 2});
                }
            },
            error: function(){
                layer.close(ii);
                $('#loginBtn').prop('disabled', false).text('登 录');
                layer.msg('服务器错误');
            }
        });
    });

    $('#registerForm').submit(function(e){
        e.preventDefault();
        var username = $.trim($('#reg_username').val());
        var password = $('#reg_password').val();
        var repassword = $('#reg_repassword').val();
        if(!username){ layer.msg('请输入用户名'); return; }
        if(!password){ layer.msg('请输入密码'); return; }
        if(password !== repassword){ layer.msg('两次输入的密码不一致'); return; }
        var ii = layer.load(2, {shade:[0.1,'#fff']});
        $('#regBtn').prop('disabled', true).text('注册中...');
        $.ajax({
            type: 'POST',
            url: 'login.php?act=local_register',
            data: {username: username, password: password, repassword: repassword},
            dataType: 'json',
            success: function(data){
                layer.close(ii);
                $('#regBtn').prop('disabled', false).text('注 册');
                if(data.code == 0){
                    layer.msg(data.msg, {icon:1, time:1500}, function(){
                        window.location.href = './';
                    });
                }else{
                    layer.alert(data.msg, {icon: 2});
                }
            },
            error: function(){
                layer.close(ii);
                $('#regBtn').prop('disabled', false).text('注 册');
                layer.msg('服务器错误');
            }
        });
    });
});

function connect(type){
    var ii = layer.load(2, {shade:[0.1,'#fff']});
	$.ajax({
		type : "POST",
		url : "login.php?act=connect",
		data : {type:type},
		dataType : 'json',
		success : function(data) {
			layer.close(ii);
			if(data.code == 0){
				window.location.href = data.url;
			}else{
				layer.alert(data.msg, {icon: 7});
			}
		}
	});
}
</script>
</body>
</html>
