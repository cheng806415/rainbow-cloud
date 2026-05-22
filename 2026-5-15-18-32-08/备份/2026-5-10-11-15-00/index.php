<?php
if (version_compare(PHP_VERSION, '7.1.0', '<')) {
    die('require PHP >= 7.1 !');
}
include("./includes/common.php");

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

$folder_id = isset($_GET['folder_id'])?intval($_GET['folder_id']):0;
$view_mode = isset($_GET['view_mode'])?$_GET['view_mode']:'list';
if(!in_array($view_mode, ['list', 'folder'])){
    $view_mode = 'list';
}

$csrf_token = md5(mt_rand(0,999).time());
$_SESSION['csrf_token'] = $csrf_token;

$breadcrumbs = [];
if($folder_id > 0 && $ismine){
    $fid = $folder_id;
    while($fid > 0){
        $folder = $DB->getRow("SELECT * FROM pre_folder WHERE id=:id AND uid=:uid", [':id'=>$fid, ':uid'=>$uid]);
        if($folder){
            array_unshift($breadcrumbs, $folder);
            $fid = $folder['parent_id'];
        }else{
            break;
        }
    }
}

include SYSTEM_ROOT.'header.php';
?>
<div class="container">
    <div class="well bs-component">
        <h2><?php echo $htext?>
        <?php if($conf['filesearch']==1){?><span class="searchbox">
            <form class="form-inline" action="./" method="GET">
                <?php if(isset($_GET['m'])){?><input name="m" type="hidden" value="<?php echo htmlspecialchars($_GET['m'])?>"><?php }?>
                <input name="kw" class="form-control" type="search" placeholder="请输入搜索关键字" value="<?php echo $kw?>" required="">
                <button class="btn btn-default btn-raised btn-sm" type="submit"><i class="fa fa-search" aria-hidden="true"></i> 搜索</button>
            </form>
        </span><?php }?></h2>
        
        <?php if($ismine){?>
        <div style="margin-bottom:10px;">
            <div class="btn-group" role="group">
                <a href="?m=mine&view_mode=list&folder_id=<?php echo $folder_id?>" class="btn btn-sm <?php echo $view_mode=='list'?'btn-primary':'btn-default'; ?>"><i class="fa fa-list"></i> 列表模式</a>
                <a href="?m=mine&view_mode=folder&folder_id=<?php echo $folder_id?>" class="btn btn-sm <?php echo $view_mode=='folder'?'btn-primary':'btn-default'; ?>"><i class="fa fa-th"></i> 文件夹模式</a>
            </div>
            
            <?php if($view_mode=='folder'){?>
            <nav aria-label="breadcrumb" style="margin-left:10px;display:inline-block;">
                <ol class="breadcrumb" style="margin-bottom:0;display:inline-block;">
                    <li><a href="?m=mine&view_mode=folder">根目录</a></li>
                    <?php foreach($breadcrumbs as $bc){?>
                    <li><a href="?m=mine&view_mode=folder&folder_id=<?php echo $bc['id']?>"><?php echo htmlspecialchars($bc['name'])?></a></li>
                    <?php }?>
                </ol>
            </nav>
            <button class="btn btn-sm btn-success" id="newFolderBtn" style="margin-left:10px;"><i class="fa fa-folder"></i> 新建文件夹</button>
            <?php }?>
        </div>
        
        <div style="margin-bottom:10px;" id="batchActions">
            <input type="checkbox" id="checkAll"> <label for="checkAll" style="cursor:pointer;">全选</label>
            <button class="btn btn-sm btn-danger" id="batchDeleteBtn" style="margin-left:10px;"><i class="fa fa-trash"></i> 批量删除</button>
            <span id="selectedCount" style="margin-left:10px;color:#999;"></span>
        </div>
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
                    <th>上传时间</th>
                    <th>上传者IP</th>
                </tr>
            </thead>
            <tbody>
<?php
if($ismine && $view_mode=='folder'){
    $sql .= " AND folder_id={$folder_id}";
}
$numrows=$DB->getColumn("SELECT count(*) from pre_file WHERE{$sql}");
$pagesize=15;
$pages=ceil($numrows/$pagesize);
$page=isset($_GET['page'])?intval($_GET['page']):1;
$offset=$pagesize*($page - 1);

$rs=$DB->query("SELECT * FROM pre_file WHERE{$sql} ORDER BY id DESC LIMIT $offset,$pagesize");
$i=1;
while($res = $rs->fetch())
{
    $fileurl = './down.php/'.$res['hash'].'.'.($res['type']?$res['type']:'file');
    $viewurl = './file.php?hash='.$res['hash'];
    if($ismine){
        echo '<tr><td><input type="checkbox" class="file-check" value="'.$res['hash'].'" data-id="'.$res['id'].'"></td><td><b>'.$i++.'</b></td><td><a href="'.$fileurl.'">下载</a>｜<a href="'.$viewurl.'">查看</a></td><td><i class="fa '.type_to_icon($res['type']).' fa-fw"></i>'.$res['name'].'</td><td>'.size_format($res['size']).'</td><td><font color="blue">'.($res['type']?$res['type']:'未知').'</font></td><td>'.$res['addtime'].'</td><td>'.preg_replace('/\d+$/','*',$res['ip']).'</td></tr>';
    }else{
        echo '<tr><td><b>'.$i++.'</b></td><td><a href="'.$fileurl.'">下载</a>｜<a href="'.$viewurl.'">查看</a></td><td><i class="fa '.type_to_icon($res['type']).' fa-fw"></i>'.$res['name'].'</td><td>'.size_format($res['size']).'</td><td><font color="blue">'.($res['type']?$res['type']:'未知').'</font></td><td>'.$res['addtime'].'</td><td>'.preg_replace('/\d+$/','*',$res['ip']).'</td></tr>';
    }
}
if($numrows == 0) echo '<tr><td colspan="'.($ismine?'8':'7').'" align="center">还没上传过任何文件</td></tr>';
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
    loadFolders();
    
    $('#newFolderBtn').click(function(){
        layer.prompt({title: '输入文件夹名称', formType: 0}, function(name, index){
            layer.close(index);
            var ii = layer.load(2);
            $.ajax({
                type: 'POST',
                url: 'ajax.php?act=folder_create',
                data: {name: name, parent_id: <?php echo $folder_id;?>, csrf_token: '<?php echo $csrf_token;?>'},
                dataType: 'json',
                success: function(data){
                    layer.close(ii);
                    if(data.code == 0){
                        layer.msg('创建成功', {icon:1});
                        loadFolders();
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
    
    function loadFolders(){
        $.ajax({
            type: 'GET',
            url: 'ajax.php?act=folder_list&parent_id=<?php echo $folder_id;?>&csrf_token=<?php echo $csrf_token;?>',
            dataType: 'json',
            success: function(data){
                if(data.code == 0){
                    var html = '';
                    if(data.folders.length == 0){
                        html = '<tr><td colspan="3" align="center">暂无文件夹</td></tr>';
                    }else{
                        $.each(data.folders, function(i, folder){
                            html += '<tr>';
                            html += '<td><a href="?m=mine&view_mode=folder&folder_id=' + folder.id + '"><i class="fa fa-folder" style="color:#f0ad4e;"></i> ' + folder.name + '</a></td>';
                            html += '<td>' + folder.addtime + '</td>';
                            html += '<td><button class="btn btn-xs btn-danger delete-folder" data-id="' + folder.id + '" data-name="' + folder.name + '">删除</button></td>';
                            html += '</tr>';
                        });
                    }
                    $('#folderListBody').html(html);
                    
                    $('.delete-folder').click(function(){
                        var folder_id = $(this).data('id');
                        var folder_name = $(this).data('name');
                        layer.confirm('确定要删除文件夹 "' + folder_name + '" 吗？文件夹内的文件将移到根目录。', {
                            btn: ['确定','取消'], icon: 3
                        }, function(){
                            layer.closeAll();
                            var ii = layer.load(2);
                            $.ajax({
                                type: 'POST',
                                url: 'ajax.php?act=folder_delete',
                                data: {folder_id: folder_id, csrf_token: '<?php echo $csrf_token;?>'},
                                dataType: 'json',
                                success: function(data){
                                    layer.close(ii);
                                    if(data.code == 0){
                                        layer.msg('删除成功', {icon:1});
                                        loadFolders();
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
                }
            }
        });
    }
    <?php }?>
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
