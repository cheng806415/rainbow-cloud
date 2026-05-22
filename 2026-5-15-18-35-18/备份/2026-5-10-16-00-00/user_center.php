<?php
include("./includes/common.php");

if(!$conf['userlogin']){
    @header('Content-Type: text/html; charset=UTF-8');
    exit("<script language='javascript'>alert('未开启登录');window.location.href='./';</script>");
}
if(!$islogin2){
    @header('Content-Type: text/html; charset=UTF-8');
    exit("<script language='javascript'>alert('请先登录');window.location.href='./login.php';</script>");
}

$avatar = $userrow['avatar'] ? $userrow['avatar'] : ($userrow['faceimg'] ?: '');
$allow_view = isset($userrow['allow_view']) ? intval($userrow['allow_view']) : 1;
$allow_search = isset($userrow['allow_search']) ? intval($userrow['allow_search']) : 1;

$title = '用户中心 - ' . $conf['title'];
include SYSTEM_ROOT.'header.php';
?>
<style>
.user-center-container {
    padding: 30px 0;
}
.profile-card {
    background: #fff;
    border-radius: 8px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    padding: 30px;
    margin-bottom: 20px;
}
.profile-header {
    text-align: center;
    border-bottom: 1px solid #eee;
    padding-bottom: 20px;
    margin-bottom: 20px;
}
.avatar-wrapper {
    position: relative;
    width: 100px;
    height: 100px;
    margin: 0 auto 15px;
    cursor: pointer;
}
.avatar-wrapper .avatar-img {
    width: 100px;
    height: 100px;
    border-radius: 50%;
    object-fit: cover;
    border: 3px solid #fff;
    box-shadow: 0 2px 8px rgba(0,0,0,0.15);
}
.avatar-wrapper .avatar-placeholder {
    width: 100px;
    height: 100px;
    border-radius: 50%;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: #fff;
    font-size: 40px;
    line-height: 100px;
    border: 3px solid #fff;
    box-shadow: 0 2px 8px rgba(0,0,0,0.15);
}
.avatar-wrapper .avatar-overlay {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    border-radius: 50%;
    background: rgba(0,0,0,0.5);
    color: #fff;
    font-size: 14px;
    display: none;
    text-align: center;
    line-height: 100px;
}
.avatar-wrapper:hover .avatar-overlay {
    display: block;
}
.avatar-input {
    display: none;
}
.profile-username {
    font-size: 20px;
    font-weight: bold;
    margin-bottom: 5px;
}
.profile-type {
    color: #999;
    font-size: 14px;
}
.settings-section {
    margin-bottom: 20px;
}
.settings-section h4 {
    border-bottom: 1px solid #eee;
    padding-bottom: 10px;
    margin-bottom: 15px;
    color: #333;
}
.form-row {
    display: flex;
    align-items: center;
    margin-bottom: 15px;
}
.form-row label {
    width: 100px;
    text-align: right;
    margin-right: 15px;
    color: #666;
    font-weight: normal;
}
.form-row input[type="text"],
.form-row input[type="url"] {
    flex: 1;
    max-width: 300px;
}
.btn-save {
    margin-left: 115px;
}
.stat-card {
    background: #f8f9fa;
    border-radius: 6px;
    padding: 15px;
    text-align: center;
    margin-bottom: 10px;
}
.stat-card .stat-num {
    font-size: 24px;
    font-weight: bold;
    color: #667eea;
}
.stat-card .stat-label {
    color: #999;
    font-size: 14px;
}
.switch-group {
    display: flex;
    align-items: center;
    margin-bottom: 15px;
}
.switch-group label {
    width: 100px;
    text-align: right;
    margin-right: 15px;
    color: #666;
    font-weight: normal;
    margin-bottom: 0;
}
.switch-control {
    position: relative;
    display: inline-block;
    width: 50px;
    height: 26px;
}
.switch-control input {
    opacity: 0;
    width: 0;
    height: 0;
}
.switch-slider {
    position: absolute;
    cursor: pointer;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: #ccc;
    transition: .3s;
    border-radius: 26px;
}
.switch-slider:before {
    position: absolute;
    content: "";
    height: 20px;
    width: 20px;
    left: 3px;
    bottom: 3px;
    background-color: white;
    transition: .3s;
    border-radius: 50%;
}
.switch-control input:checked + .switch-slider {
    background-color: #667eea;
}
.switch-control input:checked + .switch-slider:before {
    transform: translateX(24px);
}
.switch-desc {
    margin-left: 10px;
    color: #999;
    font-size: 14px;
}
</style>
<div class="container user-center-container">
    <div class="col-xs-10 center-block" style="float: none;">
        <div class="row">
            <div class="col-md-5">
                <div class="profile-card">
                    <div class="profile-header">
                        <div class="avatar-wrapper" id="avatarWrapper" title="点击更换头像">
                            <?php if($avatar){?>
                            <img src="<?php echo htmlspecialchars($avatar)?>" class="avatar-img" id="avatarImg">
                            <?php }else{?>
                            <div class="avatar-placeholder">
                                <i class="fa fa-<?php echo $userrow['type']=='qq'?'qq':'user';?>"></i>
                            </div>
                            <?php }?>
                            <div class="avatar-overlay"><i class="fa fa-camera"></i> 更换头像</div>
                        </div>
                        <input type="file" class="avatar-input" id="avatarInput" accept="image/*">
                        <div class="profile-username"><?php echo htmlspecialchars($userrow['nickname'])?></div>
                        <div class="profile-type">
                            <?php
                            if($userrow['type'] && $userrow['type']=='qq'){
                                echo 'QQ登录';
                            }elseif($userrow['type'] && $userrow['type']=='wx'){
                                echo '微信登录';
                            }elseif($userrow['username']){
                                echo '账号登录';
                            }else{
                                echo '快捷登录';
                            }
                            ?>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-xs-4">
                            <div class="stat-card">
                                <div class="stat-num"><?php echo $DB->getColumn("SELECT count(*) FROM pre_file WHERE uid=:uid", [':uid'=>$uid])?></div>
                                <div class="stat-label">文件数</div>
                            </div>
                        </div>
                        <div class="col-xs-4">
                            <div class="stat-card">
                                <div class="stat-num"><?php echo $DB->getColumn("SELECT count(*) FROM pre_folder WHERE uid=:uid", [':uid'=>$uid])?></div>
                                <div class="stat-label">文件夹</div>
                            </div>
                        </div>
                        <div class="col-xs-4">
                            <div class="stat-card">
                                <div class="stat-num"><?php echo $userrow['level']==1?'高级':'普通'?></div>
                                <div class="stat-label">权限</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="col-md-7">
                <div class="profile-card">
                    <div class="settings-section">
                        <h4><i class="fa fa-user-circle"></i> 账号设置</h4>
                        <?php if($userrow['username']){?>
                        <div class="form-row">
                            <label>登录账号</label>
                            <input type="text" class="form-control" value="<?php echo htmlspecialchars($userrow['username'])?>" disabled>
                        </div>
                        <p class="text-muted" style="margin-left:115px;margin-top:-10px;margin-bottom:15px;">登录账号不可修改</p>
                        <?php }else{?>
                        <div class="form-row">
                            <label>登录方式</label>
                            <span>第三方账号登录</span>
                        </div>
                        <?php }?>
                        <div class="form-row">
                            <label>显示昵称</label>
                            <input type="text" class="form-control" id="nickname" value="<?php echo htmlspecialchars($userrow['nickname'])?>" placeholder="请输入显示昵称" maxlength="20">
                        </div>
                        <div class="form-group">
                            <button class="btn btn-primary btn-save" id="saveNickname">保存昵称</button>
                        </div>
                    </div>

                    <?php if($userrow['username']){?>
                    <div class="settings-section" style="border-top:1px solid #eee;padding-top:20px;">
                        <h4><i class="fa fa-lock"></i> 修改密码</h4>
                        <div class="form-row">
                            <label>当前密码</label>
                            <input type="password" class="form-control" id="old_password" placeholder="请输入当前密码">
                        </div>
                        <div class="form-row">
                            <label>新密码</label>
                            <input type="password" class="form-control" id="new_password" placeholder="6-20位字母或数字">
                        </div>
                        <div class="form-row">
                            <label>确认密码</label>
                            <input type="password" class="form-control" id="confirm_password" placeholder="请再次输入新密码">
                        </div>
                        <div class="form-group">
                            <button class="btn btn-warning btn-save" id="changePassword">修改密码</button>
                        </div>
                    </div>
                    <?php }?>

                    <div class="settings-section" style="border-top:1px solid #eee;padding-top:20px;">
                        <h4><i class="fa fa-shield"></i> 隐私设置</h4>
                        <div class="switch-group">
                            <label>允许被查看</label>
                            <label class="switch-control">
                                <input type="checkbox" id="allow_view" <?php echo $allow_view?'checked':'';?>>
                                <span class="switch-slider"></span>
                            </label>
                            <span class="switch-desc">开启后其他人可以查看你的文件夹</span>
                        </div>
                        <div class="switch-group">
                            <label>允许被搜索</label>
                            <label class="switch-control">
                                <input type="checkbox" id="allow_search" <?php echo $allow_search?'checked':'';?>>
                                <span class="switch-slider"></span>
                            </label>
                            <span class="switch-desc">开启后其他人可以搜索到你的用户名</span>
                        </div>
                        <div class="form-group">
                            <button class="btn btn-success btn-save" id="savePrivacy">保存隐私设置</button>
                        </div>
                    </div>

                    <div class="settings-section" style="border-top:1px solid #eee;padding-top:20px;">
                        <h4><i class="fa fa-info-circle"></i> 账号信息</h4>
                        <div class="form-row">
                            <label>注册时间</label>
                            <span><?php echo $userrow['addtime']?></span>
                        </div>
                        <div class="form-row">
                            <label>最后登录</label>
                            <span><?php echo $userrow['lasttime']?></span>
                        </div>
                        <div class="form-row">
                            <label>登录IP</label>
                            <span><?php echo $userrow['loginip']?></span>
                        </div>
                    </div>

                    <div style="border-top:1px solid #eee;padding-top:20px;text-align:center;">
                        <a href="./login.php?logout=1" class="btn btn-danger" onclick="return confirm('是否确定退出登录？')">
                            <i class="fa fa-sign-out"></i> 退出登录
                        </a>
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
    $('#avatarWrapper').click(function(){
        $('#avatarInput').click();
    });

    $('#avatarInput').change(function(){
        var file = this.files[0];
        if(!file) return;
        if(!/^image\/(jpeg|png|gif|webp|bmp)/i.test(file.type)){
            layer.msg('只支持上传图片格式文件');
            this.value = '';
            return;
        }
        if(file.size > 2 * 1024 * 1024){
            layer.msg('图片大小不能超过2MB');
            this.value = '';
            return;
        }
        var formData = new FormData();
        formData.append('avatar', file);
        var ii = layer.load(2, {shade:[0.1,'#fff']});
        $.ajax({
            type: 'POST',
            url: 'ajax.php?act=uploadAvatar',
            data: formData,
            processData: false,
            contentType: false,
            dataType: 'json',
            success: function(data){
                layer.close(ii);
                if(data.code == 0){
                    layer.msg('头像上传成功', {icon:1, time:1000}, function(){
                        window.location.reload();
                    });
                }else{
                    layer.alert(data.msg, {icon: 2});
                }
            },
            error: function(){
                layer.close(ii);
                layer.msg('服务器错误');
            }
        });
    });

    $('#saveNickname').click(function(){
        var nickname = $.trim($('#nickname').val());
        if(!nickname){ layer.msg('昵称不能为空'); return; }
        if(nickname.length > 20){ layer.msg('昵称不能超过20个字符'); return; }
        var ii = layer.load(2, {shade:[0.1,'#fff']});
        $.ajax({
            type: 'POST',
            url: 'ajax.php?act=saveUserSettings',
            data: {action:'nickname', nickname: nickname},
            dataType: 'json',
            success: function(data){
                layer.close(ii);
                if(data.code == 0){
                    layer.msg('保存成功', {icon:1, time:1000}, function(){
                        window.location.reload();
                    });
                }else{
                    layer.alert(data.msg, {icon: 2});
                }
            },
            error: function(){
                layer.close(ii);
                layer.msg('服务器错误');
            }
        });
    });

    $('#savePrivacy').click(function(){
        var allow_view = $('#allow_view').is(':checked') ? 1 : 0;
        var allow_search = $('#allow_search').is(':checked') ? 1 : 0;
        var ii = layer.load(2, {shade:[0.1,'#fff']});
        $.ajax({
            type: 'POST',
            url: 'ajax.php?act=saveUserSettings',
            data: {action:'privacy', allow_view: allow_view, allow_search: allow_search},
            dataType: 'json',
            success: function(data){
                layer.close(ii);
                if(data.code == 0){
                    layer.msg('保存成功', {icon:1});
                }else{
                    layer.alert(data.msg, {icon: 2});
                }
            },
            error: function(){
                layer.close(ii);
                layer.msg('服务器错误');
            }
        });
    });

    $('#changePassword').click(function(){
        var oldPassword = $('#old_password').val();
        var newPassword = $('#new_password').val();
        var confirmPassword = $('#confirm_password').val();
        if(!oldPassword){ layer.msg('请输入当前密码'); return; }
        if(!newPassword){ layer.msg('请输入新密码'); return; }
        if(newPassword.length < 6 || newPassword.length > 20){ layer.msg('密码长度必须在6-20位之间'); return; }
        if(!/^[a-zA-Z0-9]+$/.test(newPassword)){ layer.msg('密码只能包含字母和数字'); return; }
        if(newPassword !== confirmPassword){ layer.msg('两次输入的密码不一致'); return; }
        var ii = layer.load(2, {shade:[0.1,'#fff']});
        $.ajax({
            type: 'POST',
            url: 'ajax.php?act=saveUserSettings',
            data: {action:'password', old_password: oldPassword, new_password: newPassword},
            dataType: 'json',
            success: function(data){
                layer.close(ii);
                if(data.code == 0){
                    layer.msg('密码修改成功', {icon:1, time:1500}, function(){
                        $('#old_password').val('');
                        $('#new_password').val('');
                        $('#confirm_password').val('');
                    });
                }else{
                    layer.alert(data.msg, {icon: 2});
                }
            },
            error: function(){
                layer.close(ii);
                layer.msg('服务器错误');
            }
        });
    });
});
</script>
</body>
</html>
