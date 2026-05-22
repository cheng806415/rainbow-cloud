<?php
include("./includes/common.php");

$hash = isset($_GET['hash'])?trim($_GET['hash']):exit("<script language='javascript'>alert('参数错误');window.location.href='./';</script>");

if(!preg_match('/^[0-9a-z]{32}$/i', $hash))exit("<script language='javascript'>alert('参数错误');window.location.href='./';</script>");

$row = $DB->getRow("SELECT * FROM pre_file WHERE hash=:hash", [':hash'=>$hash]);
if(!$row)exit("<script language='javascript'>alert('文件不存在');window.location.href='./';</script>");

$DB->exec("UPDATE pre_file SET count=count+1 WHERE hash=:hash", [':hash'=>$hash]);

$type = $row['type']?$row['type']:'file';
$name = $row['name'];
$viewurl = 'view.php/'.$hash.'.'.$type;

$title = 'PDF在线预览 - ' . $conf['title'];
include SYSTEM_ROOT.'header.php';
?>
<style>
.fullscreen-btn{cursor:pointer;float:right;margin-top:-28px;margin-right:10px;padding:4px 8px;background:#fff;color:#337ab7;border:1px solid #337ab7;border-radius:3px;}
.fullscreen-btn:hover{background:#337ab7;color:#fff;}
.pdf-container{position:relative;}
</style>
<div class="container">
    <div class="row">
      <div class="col-sm-12">
<div class="panel panel-primary">
<div class="panel-heading">
<h3 class="panel-title"><i class="fa fa-file-pdf-o"></i> <?php echo htmlspecialchars($name)?></h3>
<span class="fullscreen-btn" onclick="toggleFullscreen()"><i class="fa fa-arrows-alt"></i> 全屏</span>
</div>
<div class="panel-body" style="padding:0;" id="pdfContainer">
<iframe src="<?php echo $viewurl?>" width="100%" height="800px" frameborder="0" id="pdfIframe"></iframe>
</div>
</div>
      </div>
    </div>
</div>
<?php include SYSTEM_ROOT.'footer.php';?>
<script>
function toggleFullscreen(){
    var elem=document.getElementById('pdfContainer');
    if(!document.fullscreenElement){
        if(elem.requestFullscreen){elem.requestFullscreen();}
        else if(elem.mozRequestFullScreen){elem.mozRequestFullScreen();}
        else if(elem.webkitRequestFullscreen){elem.webkitRequestFullscreen();}
        else if(elem.msRequestFullscreen){elem.msRequestFullscreen();}
    }else{
        if(document.exitFullscreen){document.exitFullscreen();}
        else if(document.mozCancelFullScreen){document.mozCancelFullScreen();}
        else if(document.webkitExitFullscreen){document.webkitExitFullscreen();}
        else if(document.msExitFullscreen){document.msExitFullscreen();}
    }
}
document.addEventListener('fullscreenchange',function(){
    var iframe=document.getElementById('pdfIframe');
    if(document.fullscreenElement){
        iframe.style.height='100vh';
    }else{
        iframe.style.height='800px';
    }
});
</script>
</body>
</html>