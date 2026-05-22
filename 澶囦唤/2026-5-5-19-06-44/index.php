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

$csrf_token = md5(mt_rand(0,999).time());
$_SESSION['csrf_token'] = $csrf_token;

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
        <div style="margin-bottom:10px;" id="batchActions">
            <input type="checkbox" id="checkAll"> <label for="checkAll" style="cursor:pointer;">全选</label>
            <button class="btn btn-sm btn-danger" id="batchDeleteBtn" style="margin-left:10px;"><i class="fa fa-trash"></i> 批量删除</button>
            <span id="selectedCount" style="margin-left:10px;color:#999;"></span>
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
echo '<li><a href="index.php?page='.$first.$link.'">首页</a></li>';
echo '<li><a href="index.php?page='.$prev.$link.'">&laquo;</a></li>';
} else {
echo '<li class="disabled"><a>首页</a></li>';
echo '<li class="disabled"><a>&laquo;</a></li>';
}
$start=$page-10>1?$page-10:1;
$end=$page+10<$pages?$page+10:$pages;
for ($i=$start;$i<$page;$i++)
echo '<li><a href="index.php?page='.$i.$link.'">'.$i .'</a></li>';
echo '<li class="disabled"><a>'.$page.'</a></li>';
for ($i=$page+1;$i<=$end;$i++)
echo '<li><a href="index.php?page='.$i.$link.'">'.$i .'</a></li>';
echo '';
if ($page<$pages)
{
echo '<li><a href="index.php?page='.$next.$link.'">&raquo;</a></li>';
echo '<li><a href="index.php?page='.$last.$link.'">尾页</a></li>';
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