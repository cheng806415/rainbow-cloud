<?php
define('IN_ADMIN', true);
include("../includes/common.php");
if($islogin==1){}else exit("<script language='javascript'>window.location.href='./login.php';</script>");
$title='文件夹管理';
include './head.php';
?>
<div class="container" style="padding-top:70px;">
  <div class="panel panel-primary">
    <div class="panel-heading">
      <h3 class="panel-title">文件夹管理</h3>
    </div>
    <div class="panel-body">
      <form class="form-inline" id="searchToolbar">
        <div class="form-group">
          <label>用户名：</label>
          <input type="text" class="form-control" name="username" placeholder="请输入用户名">
        </div>
        <div class="form-group">
          <label>隐藏状态：</label>
          <select class="form-control" name="dstatus">
            <option value="-1">全部</option>
            <option value="0">公开</option>
            <option value="1">隐藏</option>
          </select>
        </div>
        <button type="button" class="btn btn-primary" onclick="searchSubmit()"><i class="fa fa-search"></i>搜索</button>
        <a href="javascript:searchClear()" class="btn btn-default"><i class="fa fa-repeat"></i> 重置</a>
      </form>
    </div>
  </div>

  <div class="panel panel-default">
    <div class="panel-body">
      <table id="listTable"></table>
    </div>
  </div>

  <div class="modal fade" id="editModal">
    <div class="modal-dialog">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal"><span>&times;</span></button>
          <h4 class="modal-title">编辑文件夹</h4>
        </div>
        <div class="modal-body">
          <form class="form-horizontal" id="editForm">
            <input type="hidden" id="edit_id" name="id">
            <div class="form-group">
              <label class="col-sm-3 control-label">文件夹名称</label>
              <div class="col-sm-9">
                <input type="text" class="form-control" id="edit_name" name="name">
              </div>
            </div>
            <div class="form-group">
              <label class="col-sm-3 control-label">所属用户</label>
              <div class="col-sm-9">
                <input type="text" class="form-control" id="edit_username" disabled>
              </div>
            </div>
            <div class="form-group">
              <label class="col-sm-3 control-label">隐藏状态</label>
              <div class="col-sm-9">
                <select id="edit_hide" name="hide" class="form-control"><option value="0">公开</option><option value="1">隐藏</option></select>
              </div>
            </div>
            <div class="form-group">
              <label class="col-sm-3 control-label">访问密码</label>
              <div class="col-sm-9">
                <input type="text" class="form-control" id="edit_pwd" name="pwd" placeholder="留空表示不设置密码">
              </div>
            </div>
          </form>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-white" data-dismiss="modal">关闭</button>
          <button type="button" class="btn btn-primary" onclick="saveFolder()">保存</button>
        </div>
      </div>
    </div>
  </div>
</div>
<script src="https://s4.zstatic.net/ajax/libs/bootstrap-table/1.21.4/bootstrap-table.min.js"></script>
<script src="https://s4.zstatic.net/ajax/libs/bootstrap-table/1.21.4/extensions/page-jump-to/bootstrap-table-page-jump-to.min.js"></script>
<script src="https://s4.zstatic.net/ajax/libs/layer/3.1.1/layer.min.js"></script>
<script src="../assets/js/custom.js"></script>
<script>
$(document).ready(function(){
  updateToolbar();
  const defaultPageSize = 20;
  const pageNumber = typeof window.$_GET['pageNumber'] != 'undefined' ? parseInt(window.$_GET['pageNumber']) : 1;
  const pageSize = typeof window.$_GET['pageSize'] != 'undefined' ? parseInt(window.$_GET['pageSize']) : defaultPageSize;

  $('#listTable').bootstrapTable({
    url: './ajax.php?act=folderList',
    pageNumber: pageNumber,
    pageSize: pageSize,
    classes: 'table table-striped table-hover table-bordered',
    columns: [
      {
        field: 'id',
        title: 'ID',
        formatter: function(value, row, index) {
          return '<b>'+value+'</b>';
        }
      },
      {
        field: 'name',
        title: '文件夹名称',
        formatter: function(value, row, index) {
          return '<i class="fa fa-folder" style="color:#f0ad4e;"></i> ' + value;
        }
      },
      {
        field: 'username',
        title: '所属用户',
        formatter: function(value, row, index) {
          return value || '-';
        }
      },
      {
        field: 'file_count',
        title: '文件数'
      },
      {
        field: 'pwd',
        title: '密码状态',
        formatter: function(value, row, index) {
          return value ? '<span class="label label-warning"><i class="fa fa-lock"></i> 已加密</span>' : '<span class="label label-success">无密码</span>';
        }
      },
      {
        field: 'hide',
        title: '状态',
        formatter: function(value, row, index) {
          return value==1 ? '<span class="label label-warning">隐藏</span>' : '<span class="label label-success">公开</span>';
        }
      },
      {
        field: 'addtime',
        title: '创建时间'
      },
      {
        field: '',
        title: '操作',
        formatter: function(value, row, index) {
          var html = '<a href="javascript:editFolder('+row.id+')">编辑</a> | ';
          html += '<a href="javascript:delFolder('+row.id+')">删除</a>';
          return html;
        }
      }
    ],
  });
});

function editFolder(id){
  var ii = layer.load(2, {shade:[0.1,'#fff']});
  $.ajax({
    type: 'GET',
    url: './ajax.php?act=getFolder',
    data: {id: id},
    dataType: 'json',
    success: function(data){
      layer.close(ii);
      if(data.code == 0){
        $('#edit_id').val(data.id);
        $('#edit_name').val(data.name);
        $('#edit_username').val(data.username);
        $('#edit_hide').val(data.hide);
        $('#edit_pwd').val(data.pwd || '');
        $('#editModal').modal('show');
      }else{
        layer.alert(data.msg, {icon: 2});
      }
    },
    error: function(){
      layer.close(ii);
      layer.msg('服务器错误');
    }
  });
}

function saveFolder(){
  if($('#edit_name').val()==''){
    layer.alert('文件夹名称不能为空');return false;
  }
  var ii = layer.load(2, {shade:[0.1,'#fff']});
  $.ajax({
    type: 'POST',
    url: './ajax.php?act=saveFolder',
    data: {
      id: $('#edit_id').val(),
      name: $('#edit_name').val(),
      hide: $('#edit_hide').val(),
      pwd: $('#edit_pwd').val()
    },
    dataType: 'json',
    success: function(data){
      layer.close(ii);
      if(data.code == 0){
        layer.alert(data.msg,{
          icon: 1,
          closeBtn: false
        }, function(){
          $('#editModal').modal('hide');
          searchSubmit();
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
}

function delFolder(id){
  layer.confirm('确定要删除这个文件夹吗？文件夹内的文件不会被删除。', {
    btn: ['确定','取消'], icon: 3
  }, function(){
    var ii = layer.load(2, {shade:[0.1,'#fff']});
    $.ajax({
      type: 'POST',
      url: './ajax.php?act=delFolder',
      data: {id: id},
      dataType: 'json',
      success: function(data){
        layer.close(ii);
        if(data.code == 0){
          layer.msg('删除成功', {icon: 1});
          searchSubmit();
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
}
</script>
</body>
</html>
