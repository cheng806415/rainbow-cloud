<?php
if (version_compare(PHP_VERSION, '7.1.0', '<')) {
    die('require PHP >= 7.1 !');
}
include("./includes/common.php");

$view_mode = isset($_GET['view_mode'])?$_GET['view_mode']:'list';
if(!in_array($view_mode, ['list', 'folder'])){
    $view_mode = 'list';
}

if(isset($_GET['m']) && $_GET['m']=='mine'){
    $title = '我的文件 - ' . $conf['title'];
    $htext = '我上传的文件';
    $ismine = true;
    if($islogin2){
        $sql = " uid='{$uid}'";
    }else{
        if($conf['userlogin']==1){
            $htext .= '<span class="text-muted" style="font-size:16px">（根据浏览器缓存记录，<a href="login.php">登录</a>后可永久保留记录）</span>';
        }else{
            $htext .= '<span class="text-muted" style="font-size:16px">（根据浏览器缓存记录）</span>';
        }
        if(isset($_SESSION['fileids']) && count($_SESSION['fileids'])>0){
            $ids = array_reverse($_SESSION['fileids']);
            if(count($ids) > 60){
                $ids = array_splice($ids, 0, 60);
            }
            $ids = implode(',',$ids);
            $sql = " id IN ($ids)";
        }else{
            $sql = " 1=2";
        }
    }
    $link = '&m=mine';
}else{
    $title = $conf['title'];
    $htext = '文件列表';
    $ismine = false;
    $sql = " hide=0";
    $link = '';
}

$kw = isset($_GET['kw'])?daddslashes(trim(strip_tags($_GET['kw']))):null;
if($conf['filesearch']==1 && $kw){
    $sql.=" AND name LIKE '%{$kw}%'";
    $link .= '&kw='.$kw;
}

$csrf_token = md5(mt_rand(0,999).time());
$_SESSION['csrf_tokens'] = isset($_SESSION['csrf_tokens']) ? $_SESSION['csrf_tokens'] : [];
$_SESSION['csrf_tokens'][] = $csrf_token;

$folder_id = isset($_GET['folder_id'])?intval($_GET['folder_id']):0;
$current_folder = null;
$folder_owner = null;
$folder_pwd_verified = false;

$user_id = isset($_GET['user_id'])?intval($_GET['user_id']):0;

if($view_mode=='folder' && $folder_id > 0){
    $current_folder = $DB->getRow("SELECT * FROM pre_folder WHERE id=:id", [':id'=>$folder_id]);
    if($current_folder){
        $folder_owner = $DB->getRow("SELECT * FROM pre_user WHERE uid=:uid", [':uid'=>$current_folder['uid']]);
        if($current_folder['hide']==1){
            if(!$islogin2 || $current_folder['uid']!=$uid){
                $current_folder = null;
            }
        }
        if($current_folder){
            if($current_folder['pwd']){
                $verify_key = 'folder_pwd_' . $folder_id;
                if(isset($_SESSION[$verify_key]) && $_SESSION[$verify_key] === $current_folder['pwd']){
                    $folder_pwd_verified = true;
                }
                if(!empty($_POST['folder_pwd'])){
                    if($_POST['folder_pwd'] === $current_folder['pwd']){
                        $_SESSION[$verify_key] = $current_folder['pwd'];
                        $folder_pwd_verified = true;
                    }
                }
            }else{
                $folder_pwd_verified = true;
            }
        }
    }
}elseif($view_mode=='folder' && $user_id > 0){
    $folder_owner = $DB->getRow("SELECT * FROM pre_user WHERE uid=:uid AND enable=1 AND allow_view=1", [':uid'=>$user_id]);
}

include SYSTEM_ROOT.'header.php';
?>
<div class="container">
    <div class="well bs-component">
        <h2><?php echo $htext?>
        <?php if($conf['filesearch']==1){?><span class="searchbox">
            <form class="form-inline" action="./" method="GET">
                <?php if(isset($_GET['m'])){?><input name="m" type="hidden" value="<?php echo htmlspecialchars($_GET['m'])?>"><?php }?>
                <?php if($view_mode=='folder'){?><input name="view_mode" type="hidden" value="folder"><?php }?>
                <?php if($folder_id>0){?><input name="folder_id" type="hidden" value="<?php echo $folder_id?>"><?php }?>
                <input name="kw" class="form-control" type="search" placeholder="请输入搜索关键字" value="<?php echo $kw?>" required="">
                <button class="btn btn-default btn-raised btn-sm" type="submit"><i class="fa fa-search" aria-hidden="true"></i> 搜索</button>
            </form>
        </span><?php }?></h2>
        
        <div style="margin-bottom:10px;">
            <div class="btn-group" role="group">
                <a href="?m=<?php echo $ismine?'mine':''?>&view_mode=list<?php echo $folder_id>0?'&folder_id='.$folder_id:''?>" class="btn btn-sm <?php echo $view_mode=='list'?'btn-primary':'btn-default'; ?>"><i class="fa fa-list"></i> 列表模式</a>
                <a href="?m=<?php echo $ismine?'mine':''?>&view_mode=folder" class="btn btn-sm <?php echo $view_mode=='folder'?'btn-primary':'btn-default'; ?>"><i class="fa fa-th"></i> 文件夹模式</a>
            </div>
            
            <?php if($view_mode=='folder'){?>
            <nav aria-label="breadcrumb" style="margin-left:10px;display:inline-block;">
                <ol class="breadcrumb" style="margin-bottom:0;display:inline-block;">
                    <?php if($ismine){?>
                    <li><a href="?m=mine&view_mode=folder">根目录</a></li>
                    <?php }else{?>
                    <li><a href="?view_mode=folder">全部用户</a></li>
                    <?php }?>
                    <?php if($current_folder && $folder_owner){?>
                    <li><a href="?view_mode=folder&folder_id=<?php echo $current_folder['id']?>"><?php echo htmlspecialchars($folder_owner['username']?$folder_owner['username']:'用户'.$current_folder['uid'])?> > <?php echo htmlspecialchars($current_folder['name'])?></a></li>
                    <?php }?>
                </ol>
            </nav>
            <?php }?>
            
            <?php if($ismine && $view_mode=='folder'){?>
            <button class="btn btn-sm btn-success" id="newFolderBtn" style="margin-left:10px;"><i class="fa fa-folder"></i> 新建文件夹</button>
            <?php }?>
            <?php if($current_folder && $folder_owner && $folder_pwd_verified && $islogin2 && $current_folder['uid']==$uid){?>
            <button class="btn btn-sm btn-success" id="newFolderBtn" style="margin-left:10px;"><i class="fa fa-folder"></i> 新建子文件夹</button>
            <?php }?>
        </div>
        
        <?php if($ismine){?>
        <div style="margin-bottom:10px;" id="batchActions">
            <input type="checkbox" id="checkAll"> <label for="checkAll" style="cursor:pointer;">全选</label>
            <button class="btn btn-sm btn-danger" id="batchDeleteBtn" style="margin-left:10px;"><i class="fa fa-trash"></i> 批量删除</button>
            <span id="selectedCount" style="margin-left:10px;color:#999;"></span>
        </div>
        <?php }?>
        
        <?php if($view_mode=='folder' && !$ismine && !$current_folder){?>
        <div class="panel panel-default" id="userFolderList">
            <div class="panel-heading">
                <h3 class="panel-title">用户文件夹</h3>
            </div>
            <div class="table-responsive">
                <table class="table table-striped table-hover">
                    <thead>
                        <tr>
                            <th>用户名</th>
                            <th>文件夹数</th>
                            <th>文件数</th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php
                    $user_folders = $DB->getAll("SELECT u.uid, u.username, u.nickname FROM pre_user u WHERE u.enable=1 AND u.allow_view=1 ORDER BY u.uid");
                    foreach($user_folders as $uf){
                        $folder_count = $DB->getColumn("SELECT count(*) FROM pre_folder WHERE uid=:uid AND hide=0", [':uid'=>$uf['uid']]);
                        if($islogin2) $folder_count += $DB->getColumn("SELECT count(*) FROM pre_folder WHERE uid=:uid AND hide=1", [':uid'=>$uf['uid']]);
                        $file_count = $DB->getColumn("SELECT count(*) FROM pre_file WHERE uid=:uid AND hide=0", [':uid'=>$uf['uid']]);
                    ?>
                        <tr>
                            <td><a href="?view_mode=folder&user_id=<?php echo $uf['uid']?>"><i class="fa fa-user" style="color:#337ab7;"></i> <?php echo htmlspecialchars($uf['username']?$uf['username']:'用户'.$uf['uid'])?></a></td>
                            <td><?php echo $folder_count?></td>
                            <td><?php echo $file_count?></td>
                        </tr>
                    <?php }?>
                    <?php if(empty($user_folders)){?>
                        <tr><td colspan="3" align="center">暂无用户</td></tr>
                    <?php }?>
                    </tbody>
                </table>
            </div>
        </div>
        <?php }?>
        
        <?php if($view_mode=='folder' && $folder_owner && !$current_folder && $user_id > 0){?>
        <div class="panel panel-default" id="userFolderDetail">
            <div class="panel-heading">
                <h3 class="panel-title"><i class="fa fa-folder-open" style="color:#f0ad4e;"></i> <?php echo htmlspecialchars($folder_owner['username']?$folder_owner['username']:'用户'.$folder_owner['uid'])?> 的文件夹</h3>
            </div>
            <div class="table-responsive">
                <table class="table table-striped table-hover">
                    <thead>
                        <tr>
                            <th>名称</th>
                            <th>文件数</th>
                            <th>创建时间</th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php
                    $user_folders_detail = $DB->getAll("SELECT * FROM pre_folder WHERE uid=:uid AND hide=0 ORDER BY id DESC", [':uid'=>$user_id]);
                    if(!empty($user_folders_detail)){
                        foreach($user_folders_detail as $ufd){
                            $fcount = $DB->getColumn("SELECT count(*) FROM pre_file WHERE folder_id=:id AND hide=0", [':id'=>$ufd['id']]);
                    ?>
                        <tr>
                            <td><a href="?view_mode=folder&folder_id=<?php echo $ufd['id']?>"><i class="fa fa-folder<?php echo $ufd['pwd']?' text-warning':''?>" style="color:#f0ad4e;"></i> <?php echo htmlspecialchars($ufd['name'])?><?php echo $ufd['pwd']?' <i class="fa fa-lock text-warning"></i>':''?></a></td>
                            <td><?php echo $fcount?></td>
                            <td><?php echo $ufd['addtime']?></td>
                        </tr>
                    <?php }}else{?>
                        <tr><td colspan="3" align="center">该用户暂无公开文件夹</td></tr>
                    <?php }?>
                    </tbody>
                </table>
            </div>
        </div>
        <?php }?>
        
        <?php if($view_mode=='folder' && $current_folder && $folder_owner){?>
        <?php if(!$folder_pwd_verified){?>
        <div class="panel panel-warning" id="folderPwdPanel">
            <div class="panel-heading">
                <h3 class="panel-title"><i class="fa fa-lock"></i> 此文件夹已加密，请输入密码访问</h3>
            </div>
            <div class="panel-body">
                <form method="POST" action="?view_mode=folder&folder_id=<?php echo $folder_id?>">
                    <div class="form-group">
                        <input type="password" class="form-control" name="folder_pwd" placeholder="请输入文件夹密码" style="max-width:300px;display:inline-block;">
                        <button type="submit" class="btn btn-primary" style="margin-left:5px;">确定</button>
                    </div>
                </form>
            </div>
        </div>
        <?php }else{?>
        
        <?php
        if($ismine || ($islogin2 && $current_folder['uid']==$uid)){
            $sub_folders = $DB->getAll("SELECT * FROM pre_folder WHERE uid=:uid AND hide=0 ORDER BY id DESC", [':uid'=>$current_folder['uid']]);
        }else{
            $sub_folders = $DB->getAll("SELECT * FROM pre_folder WHERE uid=:uid AND hide=0 ORDER BY id DESC", [':uid'=>$current_folder['uid']]);
        }
        if(!empty($sub_folders)){?>
        <div class="panel panel-default" id="folderList">
            <div class="panel-heading">
                <h3 class="panel-title">子文件夹</h3>
            </div>
            <div class="table-responsive">
                <table class="table table-striped table-hover">
                    <thead>
                        <tr>
                            <th>名称</th>
                            <th>文件数</th>
                            <th>创建时间</th>
                            <?php if($islogin2 && $current_folder['uid']==$uid){?><th>操作</th><?php }?>
                        </tr>
                    </thead>
                    <tbody>
                    <?php foreach($sub_folders as $sf){
                        if($sf['id']==$folder_id) continue;
                        $fcount = $DB->getColumn("SELECT count(*) FROM pre_file WHERE folder_id=:id", [':id'=>$sf['id']]);
                    ?>
                        <tr>
                            <td><a href="?view_mode=folder&folder_id=<?php echo $sf['id']?>"><i class="fa fa-folder<?php echo $sf['pwd']?' text-warning':''?>" style="color:#f0ad4e;"></i> <?php echo htmlspecialchars($sf['name'])?><?php echo $sf['pwd']?' <i class="fa fa-lock text-warning"></i>':''?></a></td>
                            <td><?php echo $fcount?></td>
                            <td><?php echo $sf['addtime']?></td>
                            <?php if($islogin2 && $current_folder['uid']==$uid){?><td>
                                <button class="btn btn-xs btn-warning set-folder-pwd" data-id="<?php echo $sf['id']?>" data-name="<?php echo htmlspecialchars($sf['name'])?>">密码</button>
                                <button class="btn btn-xs btn-info toggle-folder-hide" data-id="<?php echo $sf['id']?>" data-hide="<?php echo $sf['hide']?>"><?php echo $sf['hide']?'公开':'隐藏'?></button>
                                <button class="btn btn-xs btn-danger delete-folder" data-id="<?php echo $sf['id']?>" data-name="<?php echo htmlspecialchars($sf['name'])?>">删除</button>
                            </td><?php }?>
                        </tr>
                    <?php }?>
                    </tbody>
                </table>
            </div>
        </div>
        <?php }?>
        
        <?php }?>
        <?php }?>
        
        <?php if($ismine && $view_mode=='folder'){?>
        <div class="panel panel-default" id="folderList">
            <div class="panel-heading">
                <h3 class="panel-title">文件夹</h3>
            </div>
            <div class="table-responsive">
                <table class="table table-striped table-hover">
                    <thead>
                        <tr>
                            <th>名称</th>
                            <th>文件数</th>
                            <th>状态</th>
                            <th>创建时间</th>
                            <th>操作</th>
                        </tr>
                    </thead>
                    <tbody id="folderListBody">
                    </tbody>
                </table>
            </div>
        </div>
        <?php }?>
        
        <?php
        $file_sql = $sql;
        if($view_mode=='folder' && $current_folder && $folder_pwd_verified){
            $file_sql .= " AND folder_id={$folder_id}";
        }elseif($view_mode=='folder' && !$ismine && !$current_folder){
            $file_sql = " hide=0 AND folder_id=0";
        }elseif(!$ismine && $view_mode=='list'){
            $exclude_folders = $DB->getAll("SELECT id FROM pre_folder WHERE pwd IS NOT NULL OR hide=1");
            if(!empty($exclude_folders)){
                $exclude_ids = array_map(function($f){ return $f['id']; }, $exclude_folders);
                $file_sql .= " AND folder_id NOT IN (" . implode(',', $exclude_ids) . ")";
            }
        }
        ?>
        
        <div class="table-responsive">
       <table class="table table-striped table-hover filelist">
            <thead>
                <tr>
                    <?php if($ismine){?><th style="width:30px;"></th><?php }?>
                    <th>#</th>
                    <th>操作</th>
                    <th>文件名</th>
                    <th>文件大小</th>
                    <th>文件格式</th>
                    <th>SHA256</th>
                    <th>上传时间</th>
                    <th>上传者IP</th>
                </tr>
            </thead>
            <tbody>
<?php
$numrows=$DB->getColumn("SELECT count(*) from pre_file WHERE{$file_sql}");
$pagesize=15;
$pages=ceil($numrows/$pagesize);
$page=isset($_GET['page'])?intval($_GET['page']):1;
$offset=$pagesize*($page - 1);

$rs=$DB->query("SELECT * FROM pre_file WHERE{$file_sql} ORDER BY id DESC LIMIT $offset,$pagesize");
$i=1;
while($res = $rs->fetch())
{
    $fileurl = './down.php/'.$res['hash'].'.'.($res['type']?$res['type']:'file');
    $viewurl = './file.php?hash='.$res['hash'];
    if($ismine){
        echo '<tr><td><input type="checkbox" class="file-check" value="'.$res['hash'].'" data-id="'.$res['id'].'"></td><td><b>'.$i++.'</b></td><td><a href="'.$fileurl.'">下载</a>|<a href="'.$viewurl.'">查看</a></td><td><i class="fa '.type_to_icon($res['type']).' fa-fw"></i>'.$res['name'].'</td><td>'.size_format($res['size']).'</td><td><font color="blue">'.($res['type']?$res['type']:'未知').'</font></td><td style="font-family:monospace;font-size:11px;max-width:180px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;" title="'.($res['sha256']?$res['sha256']:'').'">'.($res['sha256']?$res['sha256']:'-').'</td><td>'.$res['addtime'].'</td><td>'.preg_replace('/\d+$/','*',$res['ip']).'</td></tr>';
    }else{
    echo '<tr><td><b>'.$i++.'</b></td><td><a href="'.$fileurl.'">下载</a>|<a href="'.$viewurl.'">查看</a></td><td><i class="fa '.type_to_icon($res['type']).' fa-fw"></i>'.$res['name'].'</td><td>'.size_format($res['size']).'</td><td><font color="blue">'.($res['type']?$res['type']:'未知').'</font></td><td style="font-family:monospace;font-size:11px;max-width:180px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;" title="'.($res['sha256']?$res['sha256']:'').'">'.($res['sha256']?$res['sha256']:'-').'</td><td>'.$res['addtime'].'</td><td>'.preg_replace('/\d+$/','*',$res['ip']).'</td></tr>';
    }
}
if($numrows == 0) echo '<tr><td colspan="'.($ismine?'9':'8').'" align="center">暂无文件</td></tr>';
?>
            </tbody>
        </table>
        </div>
        <div class="row">
        <div class="col-md-6"><br>共有 <?php echo $numrows?> 个文件&nbsp;&nbsp;当前第 <?php echo $page?> 页，共 <?php echo $pages?> 页</div>
        <div class="col-md-6"><nav>
  <ul class="pagination pagination-sm" style="float:right;">
<?php
$first=1;
$prev=$page-1;
$next=$page+1;
$last=$pages;
if ($page>1)
{
echo '<li><a href="index.php?page='.$first.$link.'&view_mode='.$view_mode.'&folder_id='.$folder_id.'">首页</a></li>';
echo '<li><a href="index.php?page='.$prev.$link.'&view_mode='.$view_mode.'&folder_id='.$folder_id.'">&laquo;</a></li>';
} else {
echo '<li class="disabled"><a>首页</a></li>';
echo '<li class="disabled"><a>&laquo;</a></li>';
}
$start=$page-10>1?$page-10:1;
$end=$page+10<$pages?$page+10:$pages;
for ($i=$start;$i<$page;$i++)
echo '<li><a href="index.php?page='.$i.$link.'&view_mode='.$view_mode.'&folder_id='.$folder_id.'">'.$i .'</a></li>';
echo '<li class="disabled"><a>'.$page.'</a></li>';
for ($i=$page+1;$i<=$end;$i++)
echo '<li><a href="index.php?page='.$i.$link.'&view_mode='.$view_mode.'&folder_id='.$folder_id.'">'.$i .'</a></li>';
echo '';
if ($page<$pages)
{
echo '<li><a href="index.php?page='.$next.$link.'&view_mode='.$view_mode.'&folder_id='.$folder_id.'">&raquo;</a></li>';
echo '<li><a href="index.php?page='.$last.$link.'&view_mode='.$view_mode.'&folder_id='.$folder_id.'">尾页</a></li>';
} else {
echo '<li class="disabled"><a>&raquo;</a></li>';
echo '<li class="disabled"><a>尾页</a></li>';
}
?>
  </ul>
</nav></div>
</div>
    </div>
<?php include SYSTEM_ROOT.'footer.php';?>
<script src="https://s4.zstatic.net/ajax/libs/layer/3.1.1/layer.js"></script>
<script>
var currentCsrfToken = '<?php echo $csrf_token;?>';
function getNewCsrfToken(callback){
    $.ajax({
        type: 'GET',
        url: 'ajax.php?act=get_token',
        dataType: 'json',
        success: function(data){
            if(data.code == 0 && data.csrf_token){
                currentCsrfToken = data.csrf_token;
            }
            if(callback) callback();
        },
        error: function(){
            if(callback) callback();
        }
    });
}
$(function(){
    $('#checkAll').change(function(){
        $('.file-check').prop('checked', this.checked);
        updateSelectedCount();
    });
    $('.file-check').change(function(){
        updateSelectedCount();
    });
    function updateSelectedCount(){
        var n = $('.file-check:checked').length;
        $('#selectedCount').text(n > 0 ? '已选 ' + n + ' 个' : '');
        $('#batchDeleteBtn').prop('disabled', n === 0);
    }
    $('#batchDeleteBtn').click(function(){
        var hashes = [];
        var ids = [];
        $('.file-check:checked').each(function(){
            hashes.push($(this).val());
            ids.push($(this).data('id'));
        });
        if(hashes.length === 0) return;
        layer.confirm('确定要删除选中的 ' + hashes.length + ' 个文件吗？删除后不可恢复！', {
            btn: ['确定删除','取消'], icon: 0
        }, function(){
            var ii = layer.load(2);
            $.ajax({
                type: 'POST',
                url: 'ajax.php?act=batch_delete',
                data: {hashes: hashes.join(','), ids: ids.join(','), csrf_token: '<?php echo $csrf_token;?>'},
                dataType: 'json',
                success: function(data){
                    layer.close(ii);
                    if(data.code == 0){
                        layer.msg('成功删除 ' + data.deleted + ' 个文件', {icon:1}, function(){
                            $('.file-check:checked').closest('tr').remove();
                            updateSelectedCount();
                        });
                    } else {
                        layer.alert(data.msg, {icon:2});
                    }
                },
                error: function(){
                    layer.close(ii);
                    layer.msg('服务器错误', {icon:2});
                }
            });
        });
    });
    
    <?php if($ismine && $view_mode=='folder'){?>
    loadMyFolders();
    
    function loadMyFolders(){
        getNewCsrfToken(function(){
            $.ajax({
                type: 'GET',
                url: 'ajax.php?act=folder_list&csrf_token=' + currentCsrfToken,
                dataType: 'json',
                success: function(data){
                    if(data.code == 0){
                        var html = '';
                        if(data.folders.length == 0){
                            html = '<tr><td colspan="5" align="center">暂无文件夹，点击上方按钮创建</td></tr>';
                        }else{
                            $.each(data.folders, function(i, folder){
                                html += '<tr>';
                                html += '<td><a href="?m=mine&view_mode=folder&folder_id=' + folder.id + '"><i class="fa fa-folder"' + (folder.pwd?' style="color:#f0ad4e"':'') + '></i> ' + folder.name + (folder.pwd?' <i class="fa fa-lock text-warning"></i>':'') + '</a></td>';
                                html += '<td>' + folder.file_count + '</td>';
                                html += '<td>' + (folder.hide==1?'<span class="label label-warning">隐藏</span>':'<span class="label label-success">公开</span>') + '</td>';
                                html += '<td>' + folder.addtime + '</td>';
                                html += '<td>';
                                html += '<button class="btn btn-xs btn-warning set-folder-pwd" data-id="' + folder.id + '" data-name="' + folder.name + '">密码</button> ';
                                html += '<button class="btn btn-xs btn-info toggle-folder-hide" data-id="' + folder.id + '" data-hide="' + folder.hide + '">' + (folder.hide==1?'公开':'隐藏') + '</button> ';
                                html += '<button class="btn btn-xs btn-danger delete-folder" data-id="' + folder.id + '" data-name="' + folder.name + '">删除</button>';
                                html += '</td>';
                                html += '</tr>';
                            });
                        }
                        $('#folderListBody').html(html);
                    }
                },
                error: function(){
                    $('#folderListBody').html('<tr><td colspan="5" align="center">加载失败</td></tr>');
                }
            });
        });
    }
    <?php }?>
    
    $('#newFolderBtn').click(function(){
        layer.prompt({title: '输入文件夹名称', formType: 0}, function(name, index){
            layer.close(index);
            getNewCsrfToken(function(){
                var ii = layer.load(2);
                $.ajax({
                    type: 'POST',
                    url: 'ajax.php?act=folder_create',
                    data: {name: name, parent_id: 0, csrf_token: currentCsrfToken},
                    dataType: 'json',
                    success: function(data){
                        layer.close(ii);
                        if(data.code == 0){
                            layer.msg('创建成功', {icon:1}, function(){ location.reload(); });
                        } else {
                            layer.alert(data.msg, {icon:2});
                        }
                    },
                    error: function(){
                        layer.close(ii);
                        layer.msg('服务器错误', {icon:2});
                    }
                });
            });
        });
    });
    
    $(document).on('click', '.set-folder-pwd', function(){
        var folder_id = $(this).data('id');
        var folder_name = $(this).data('name');
        layer.prompt({title: '为文件夹 "' + folder_name + '" 设置密码（留空取消密码）', formType: 1}, function(pwd, index){
            layer.close(index);
            getNewCsrfToken(function(){
                var ii = layer.load(2);
                $.ajax({
                    type: 'POST',
                    url: 'ajax.php?act=folder_setpwd',
                    data: {folder_id: folder_id, pwd: pwd, csrf_token: currentCsrfToken},
                    dataType: 'json',
                    success: function(data){
                        layer.close(ii);
                        if(data.code == 0){
                            layer.msg('设置成功', {icon:1}, function(){ location.reload(); });
                        } else {
                            layer.alert(data.msg, {icon:2});
                        }
                    },
                    error: function(){
                        layer.close(ii);
                        layer.msg('服务器错误', {icon:2});
                    }
                });
            });
        });
    });
    
    $(document).on('click', '.toggle-folder-hide', function(){
        var folder_id = $(this).data('id');
        var hide = $(this).data('hide');
        getNewCsrfToken(function(){
            var ii = layer.load(2);
            $.ajax({
                type: 'POST',
                url: 'ajax.php?act=folder_toggle_hide',
                data: {folder_id: folder_id, csrf_token: currentCsrfToken},
                dataType: 'json',
                success: function(data){
                    layer.close(ii);
                    if(data.code == 0){
                        layer.msg('操作成功', {icon:1}, function(){ location.reload(); });
                    } else {
                        layer.alert(data.msg, {icon:2});
                    }
                },
                error: function(){
                    layer.close(ii);
                    layer.msg('服务器错误', {icon:2});
                }
            });
        });
    });
    
    $(document).on('click', '.delete-folder', function(){
        var folder_id = $(this).data('id');
        var folder_name = $(this).data('name');
        layer.confirm('确定要删除文件夹 "' + folder_name + '" 吗？文件夹内的文件不会被删除。', {
            btn: ['确定','取消'], icon: 3
        }, function(){
            layer.closeAll();
            getNewCsrfToken(function(){
                var ii = layer.load(2);
                $.ajax({
                    type: 'POST',
                    url: 'ajax.php?act=folder_delete',
                    data: {folder_id: folder_id, csrf_token: currentCsrfToken},
                    dataType: 'json',
                    success: function(data){
                        layer.close(ii);
                        if(data.code == 0){
                            layer.msg('删除成功', {icon:1}, function(){ location.reload(); });
                        } else {
                            layer.alert(data.msg, {icon:2});
                        }
                    },
                    error: function(){
                        layer.close(ii);
                        layer.msg('服务器错误', {icon:2});
                    }
                });
            });
        });
    });
});
</script>
<?php if(!empty($conf['gonggao'])){?>
<link href="https://s4.zstatic.net/ajax/libs/snackbarjs/1.1.0/snackbar.min.css" rel="stylesheet">
<script src="https://s4.zstatic.net/ajax/libs/snackbarjs/1.1.0/snackbar.min.js"></script>
<script src="https://s4.zstatic.net/ajax/libs/jquery-cookie/1.4.1/jquery.cookie.min.js"></script>
<script>
$(function() {
    if(!$.cookie('gonggao')){
        $.snackbar({content: "<?php echo $conf['gonggao']?>", timeout: 10000});
        var cookietime = new Date();
        cookietime.setTime(cookietime.getTime() + (60*60*1000));
        $.cookie('gonggao', false, { expires: cookietime });
    }
});
</script>
<?php }?>
</body>
</html>
