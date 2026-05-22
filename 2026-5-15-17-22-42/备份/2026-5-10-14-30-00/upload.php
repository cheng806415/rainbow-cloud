<?php
include("./includes/common.php");

$title = '上传文件 - '.$conf['title'];
include SYSTEM_ROOT.'header.php';

if(!$islogin2){
    echo '<script>alert("请先登录后再上传文件");window.location.href="./login.php";</script>';
    exit;
}

$csrf_token = md5(mt_rand(0,999).time());
$_SESSION['csrf_tokens'] = [$csrf_token];
$_SESSION['csrf_token'] = $csrf_token;

$folders = [];
if($islogin2){
    $folders = $DB->getAll("SELECT * FROM pre_folder WHERE uid=:uid ORDER BY id DESC", [':uid'=>$uid]);
}
?>
<div class="container" id="app">
    <div class="row">

      <div class="col-sm-9">
        <div class="well infobox" align="center" id="fileInput" :style="{background: background}">
        <div style="min-height:50px;">
            <div class="alert alert-dismissible" :class="'alert-'+alert.type" v-if="alert.msg">
                <button type="button" class="close" data-dismiss="alert">×</button>
                <strong>{{alert.msg}}</strong>
            </div>
        </div>

         <br><br>
         <h1 style="color:#8d8b8b;" id="uploadTitle">{{uploadTitle}}</h1>

         <input type="hidden" id="csrf_token" name="csrf_token" value="<?php echo $csrf_token?>">
         <input type="file" id="file" name="myfile" @change="selectFile" multiple style="display:none"/>
         <input type="file" id="folder" name="folder" @change="selectFolder" webkitdirectory mozdirectory multiple style="display:none"/>


         <div id="upload_frame">
<?php if($conf['forcelogin']==1 && !$islogin2){?>
         <button id="uploadFile" class="btn btn-raised btn-primary" style="height:50px;font-size:20px;" onclick="window.location.href='./login.php'"><i class="fa fa-sign-in"></i> 请先登录<div class="ripple-container"></div></button>
         <script>var forbid = true;</script>
<?php }else{?>
         <button id="uploadFile" class="btn btn-raised btn-primary" style="height:50px;font-size:20px;" @click="clickUpload"><i class="fa fa-upload"></i> 选择文件<div class="ripple-container"></div></button>
         <button id="uploadFolder" class="btn btn-raised btn-primary" style="height:50px;font-size:20px;margin-left:10px;" @click="clickFolderUpload" v-if="isLogin"><i class="fa fa-folder-open"></i> 选择文件夹<div class="ripple-container"></div></button>
<?php }?>
<?php if($islogin2){?>
<div class="form-group" style="margin-top:15px;">
    <label>上传到文件夹：</label>
    <select class="form-control" id="targetFolder" v-model="input.folder_id">
        <option value="0">根目录</option>
        <?php foreach($folders as $f){?>
        <option value="<?php echo $f['id']?>"><?php echo htmlspecialchars($f['name'])?></option>
        <?php }?>
    </select>
    <button class="btn btn-sm btn-success" style="margin-top:5px;" @click="createNewFolder"><i class="fa fa-plus"></i> 新建文件夹</button>
</div>
<?php }?>
<div class="form-group">
<div class="checkbox">
<label>
<input type="checkbox" id="show" v-model="input.show"> 在首页文件列表显示
</label>
</div>
</div>
<div class="form-group">
<div class="checkbox">
<label>
<input type="checkbox" id="ispwd" v-model="input.ispwd"> 设定密码
</label>
</div>
</div>
<div class="form-group" style="max-width:220px;" id="pwd_frame" v-if="input.ispwd">
<input type="text" class="form-control" id="pwd" placeholder="请输入密码" autocomplete="off" v-model="input.pwd">
<p class="help-block">密码只能为字母或数字</p>
</div>
         </div>

        <br><br><br><br>
        </div>

        <div v-if="fileList.length > 0" class="panel panel-default">
            <div class="panel-heading">
                <span>上传队列 ({{fileList.length}} 个文件)</span>
                <button class="btn btn-xs btn-danger pull-right" @click="clearAll">清空</button>
            </div>
            <div class="table-responsive">
                <table class="table table-striped table-hover" style="margin-bottom:0;">
                    <thead>
                        <tr>
                            <th style="width:40%">文件名</th>
                            <th style="width:15%">大小</th>
                            <th style="width:30%">进度</th>
                            <th style="width:15%">操作</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="(item, index) in fileList" :key="item.id">
                            <td>
                                <i class="fa" :class="getStatusIcon(item.status)"></i>
                                {{ item.name }}
                                <span v-if="item.status==='hashing'" class="text-info"> (正在计算哈希)</span>
                                <span v-if="item.status==='uploading'" class="text-info"> ({{getStatusText(item.status)}})</span>
                                <span v-if="item.status==='success'" class="text-success"> ({{getStatusText(item.status)}})</span>
                                <span v-if="item.status==='error'" class="text-danger"> ({{item.msg}})</span>
                                <span v-if="item.status==='pending'" class="text-muted"> ({{getStatusText(item.status)}})</span>
                            </td>
                            <td>{{size_format(item.size)}}</td>
                            <td>
                                <div v-if="item.status==='uploading'">
                                    <div class="progress" style="margin-bottom:2px;height:8px;">
                                        <div class="progress-bar" :style="{width: item.progress + '%'}" style="transition: width 0.3s;"></div>
                                    </div>
                                    <small class="text-muted">{{item.progress_tip}} <span v-if="item.speed">{{item.speed}}</span></small>
                                </div>
                                <div v-else-if="item.status==='hashing'">
                                    <small class="text-info">{{item.progress_tip}}</small>
                                </div>
                                <small v-else-if="item.status==='success'" class="text-success">{{item.msg}}</small>
                                <small v-else-if="item.status==='error'" class="text-danger">{{item.msg}}</small>
                                <small v-else class="text-muted">等待中</small>
                            </td>
                            <td>
                                <button v-if="item.status==='success' && item.downurl" class="btn btn-xs btn-default" @click="copyUrl(item.downurl)" title="复制链接">
                                    <i class="fa fa-copy"></i> 复制
                                </button>
                                <button v-if="item.status==='pending'||item.status==='error'||item.status==='hashing'" class="btn btn-xs btn-default" @click="removeFile(index)" title="移除">
                                    <i class="fa fa-times"></i>
                                </button>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
      </div>
      <div class="col-sm-3">
      <div class="panel panel-primary">
<div class="panel-heading">
<h3 class="panel-title"><i class="fa fa-exclamation-circle"></i> 上传提示</h3>
</div>
<div class="list-group-item">
**您的IP是<?php echo $clientip?>，请不要上传违规文件！
</div>
<?php if($conf['upload_size']>0){?>
<div class="list-group-item">**上传无格式限制，当前服务器单个文件上传最大支持<b><?php echo $conf['upload_size']?>MB</b>！
</div>
<?php }else{?>
<div class="list-group-item">**上传无格式限制，无大小限制</b>！
</div>
<?php }?>
<?php if($conf['videoreview']==1){?>
<div class="list-group-item">**当前网站已开启视频文件审核，如果上传的是视频文件，需要等待审核通过后才能下载和播放。
</div>
<?php }?>
</div>
      </div>
    </div>
  </div>
<div class="colorful_loading_frame">
  <div class="colorful_loading"><i class="rect1"></i><i class="rect2"></i><i class="rect3"></i><i class="rect4"></i><i class="rect5"></i></div>
</div>
<?php include SYSTEM_ROOT.'footer.php';?>
<script src="https://s4.zstatic.net/ajax/libs/vue/2.6.14/vue.min.js"></script>
<script src="https://s4.zstatic.net/ajax/libs/layer/3.1.1/layer.js"></script>
<script src="https://s4.zstatic.net/ajax/libs/spark-md5/3.0.2/spark-md5.min.js"></script>
<script>var upload_max_filesize = '<?php echo $conf['upload_size']?>';</script>
<script>var is_login = <?php echo $islogin2?1:0;?>;</script>
<script src="./assets/js/uploadnew.js?v=<?php echo VERSION?>"></script>
</body>
</html>