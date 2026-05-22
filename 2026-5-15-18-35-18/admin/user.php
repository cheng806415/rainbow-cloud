<?php

include("../includes/common.php");

$title='用户管理';

include './head.php';

if($islogin==1){}else exit("<script language='javascript'>window.location.href='./login.php';</script>");

?>

<style>
.table>tbody>tr>td {
	vertical-align: middle;
    max-width: 360px;
	word-break: break-all;
}
.img-circle{margin-right: 7px;}
</style>
<div class="modal" id="modal-store" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
	<div class="modal-dialog">
		<div class="modal-content animated flipInX">
			<div class="modal-header">
				<button type="button" class="close" data-dismiss="modal"><span
							aria-hidden="true">&times;</span><span
							class="sr-only">Close</span></button>
				<h4 class="modal-title" id="modal-title">用户信息修改</h4>
			</div>
			<div class="modal-body">
			<div class="alert alert-info">高级权限的用户无每日上传数量、文件类型、关键词屏蔽等限制，且视频文件无需审核。</div>
				<form class="form-horizontal" id="form-store">
					<input type="hidden" name="action" id="action"/>
					<input type="hidden" name="uid" id="uid"/>
					<div class="form-group">
						<label class="col-sm-2 control-label no-padding-right">用户权限</label>
						<div class="col-sm-10">
							<select id="level" name="level" class="form-control"><option value="0">0_普通</option><option value="1">1_高级</option></select>
						</div>
					</div>
					<div class="form-group">
						<label class="col-sm-2 control-label no-padding-right">用户昵称</label>
						<div class="col-sm-10">
							<input type="text" id="nickname" name="nickname" class="form-control" placeholder="输入用户昵称"/>
						</div>
					</div>
					<div class="form-group">
						<label class="col-sm-2 control-label no-padding-right">重置密码</label>
						<div class="col-sm-10">
							<input type="text" id="resetpwd" name="resetpwd" class="form-control" placeholder="留空则不修改"/>
						</div>
					</div>
				</form>
			</div>
			<div class="modal-footer">
				<button type="button" class="btn btn-white" data-dismiss="modal">关闭</button>
				<button type="button" class="btn btn-primary" id="store" onclick="save()">保存</button>
			</div>
		</div>
	</div>
</div>

  <div class="container" style="padding-top:70px;">

    <div class="col-xs-12 center-block" style="float: none;">

	    <form onsubmit="return searchSubmit()" method="GET" class="form-inline" id="searchToolbar">

	        <div class="form-group">

          <label>搜索</label>

		  <select name="type" class="form-control"><option value="1">UID</option><option value="2">第三方账号UID</option><option value="3">昵称</option><option value="4">登录IP</option></select>

		    </div>

			<div class="form-group" id="searchword">

			<input type="text" class="form-control" name="kw" placeholder="搜索内容">

			</div>

			<div class="form-group">

			<select id="dstatus" name="dstatus" class="form-control"><option value="-1">全部状态</option><option value="0">正常状态</option><option value="1">封禁状态</option></select>

		    </div>

			<div class="form-group">

				<button class="btn btn-primary" type="submit"><i class="fa fa-search"></i> 搜索</button>

				<a href="javascript:searchClear()" class="btn btn-default"><i class="fa fa-repeat"></i> 重置</a>

			</div>

		</form>

		<table id="listTable">

	  	</table>

    </div>

  </div>

<script src="https://s4.zstatic.net/ajax/libs/layer/3.1.1/layer.min.js"></script>

<script src="https://s4.zstatic.net/ajax/libs/bootstrap-table/1.21.4/bootstrap-table.min.js"></script>

<script src="https://s4.zstatic.net/ajax/libs/bootstrap-table/1.21.4/extensions/page-jump-to/bootstrap-table-page-jump-to.min.js"></script>

<script src="../assets/js/custom.js"></script>

<script>

$(document).ready(function(){

	updateToolbar();

	const defaultPageSize = 15;

	const pageNumber = typeof window.$_GET['pageNumber'] != 'undefined' ? parseInt(window.$_GET['pageNumber']) : 1;

	const pageSize = typeof window.$_GET['pageSize'] != 'undefined' ? parseInt(window.$_GET['pageSize']) : defaultPageSize;



	$("#listTable").bootstrapTable({

		url: 'ajax.php?act=userList',

		pageNumber: pageNumber,

		pageSize: pageSize,

		classes: 'table table-striped table-hover table-bordered',

		columns: [
			{
				field: 'uid',
				title: 'UID',
				width: 60
			},
			{
				field: 'username',
				title: '登录账号',
				width: 120,
				formatter: function(value, row, index) {
					return value ? '<b>'+value+'</b>' : '<span class="label label-default">第三方登录</span>';
				}
			},
			{
				field: 'faceimg',
				title: '头像&昵称',
				width: 180,
				formatter: function(value, row, index) {
					return '<img src="'+(row.faceimg||'../assets/images/default.png')+'" alt="Avatar" width="30" class="img-circle">'+row.nickname;
				}
			},
			{
				field: 'type',
				title: '登录方式',
				width: 90,
				formatter: function(value, row, index) {
					return '<b>'+value+'</b>';
				}
			},
			{
				field: 'file_count',
				title: '文件数/文件夹数',
				width: 120,
				formatter: function(value, row, index) {
					return (row.file_count||0)+'/'+(row.folder_count||0);
				}
			},
			{
				field: 'bind_status',
				title: '绑定账号',
				width: 100,
				formatter: function(value, row, index) {
					var html = '';
					if(row.wx_openid) html += '<span class="label label-success" title="已绑定微信">微</span> ';
					if(row.qq_openid) html += '<span class="label label-info" title="已绑定QQ">Q</span> ';
					return html || '-';
				}
			},
			{
				field: 'level',
				title: '权限',
				width: 70,
				formatter: function(value, row, index) {
					if(value == '1'){
						return '<span class="label label-warning">高级</span>';
					}else{
						return '<span class="label label-primary">普通</span>';
					}
				}
			},
			{
				field: 'allow_view',
				title: '隐私设置',
				width: 100,
				formatter: function(value, row, index) {
					var html = '';
					if(row.allow_view == 1) html += '<span class="label label-success">可看</span> ';
					else html += '<span class="label label-default">隐藏</span> ';
					if(row.allow_search == 1) html += '<span class="label label-success">可搜</span>';
					else html += '<span class="label label-default">不可搜</span>';
					return html;
				}
			},
			{
				field: 'addtime',
				title: '注册时间',
				width: 100
			},
			{
				field: 'enable',
				title: '状态',
				width: 70,
				formatter: function(value, row, index) {
					if(value == '1'){
						return '<a href="javascript:setEnable('+row.uid+',0)" class="btn btn-xs btn-success">正常</a>';
					}else{
						return '<a href="javascript:setEnable('+row.uid+',1)" class="btn btn-xs btn-danger">封禁</a>';
					}
				}
			},
			{
				field: 'status',
				title: '操作',
				width: 180,
				formatter: function(value, row, index) {
					return '<a href="javascript:setLevel('+row.uid+',\''+row.nickname+'\')" class="btn btn-xs btn-primary" title="编辑用户">编辑</a> '+
						   '<a href="./file.php?uid='+row.uid+'" class="btn btn-xs btn-info" target="_blank">文件</a> '+
						   '<a href="javascript:delUser('+row.uid+')" class="btn btn-xs btn-danger">删除</a>';
				}
			},
		],

	})

})



function setEnable(uid,enable) {

	$.ajax({

		type : 'POST',

		url : 'ajax.php?act=setUserEnable',

		data: {uid:uid, enable:enable},

		dataType : 'json',

		success : function(data) {

			searchSubmit();

		},

		error:function(data){

			layer.msg('服务器错误');

		}

	});

}



function setLevel(uid, nickname){
	$("#modal-store").modal('show');
	$("#action").val("edit");
	$("#form-store #uid").val(uid);
	$("#form-store #nickname").val(nickname);
	$("#form-store #resetpwd").val('');
}



function save(){

	var ii = layer.load(2, {shade:[0.1,'#fff']});

	$.ajax({

		type : 'POST',

		url : 'ajax.php?act=saveUserInfo',

		data : $("#form-store").serialize(),

		dataType : 'json',

		success : function(data) {

			layer.close(ii);

			if(data.code == 0){

				layer.alert(data.msg,{

					icon: 1,

					closeBtn: false

				}, function(){

					$("#modal-store").modal('hide');

					searchSubmit();

					layer.closeAll();

				});

			}else{

				layer.alert(data.msg, {icon: 2})

			}

		},

		error:function(data){

			layer.msg('服务器错误');

		}

	});

}



function delUser(uid) {

	var confirmobj = layer.confirm('你确定要删除此用户吗？', {

	  btn: ['确定','取消'], icon: 0

	}, function(){

	  $.ajax({

		type : 'POST',

		url : 'ajax.php?act=delUser',

		data : {uid: uid},

		dataType : 'json',

		success : function(data) {

			if(data.code == 0){

				searchSubmit();

				layer.alert('删除成功', {icon:1});

			}else{

				layer.alert(data.msg, {icon:2});

			}

		},

		error:function(data){

			layer.msg('服务器错误');

		}

	  });

	}, function(){

	  layer.close(confirmobj);

	});

}



</script>