<?php
define('IN_ADMIN', true);
include("../includes/common.php");
if($islogin==1){}else exit("<script language='javascript'>window.location.href='./login.php';</script>");
?>
<!DOCTYPE html>
<html lang="zh-cn">
<head>
  <meta charset="utf-8"/>
  <title>API测试</title>
  <style>
    body { font-family: Arial; padding: 20px; background: #f5f5f5; }
    .panel { background: white; padding: 20px; margin: 10px 0; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    pre { background: #f4f4f4; padding: 15px; overflow-x: auto; border: 1px solid #ddd; }
    button { padding: 10px 20px; margin: 5px; cursor: pointer; }
    .result { margin-top: 10px; }
  </style>
</head>
<body>
<h1>文件夹API测试</h1>

<div class="panel">
  <h2>测试1: 直接调用folderList API</h2>
  <button onclick="testApi1()">测试: 无过滤条件</button>
  <button onclick="testApi2()">测试: 过滤公开文件夹</button>
  <button onclick="testApi3()">测试: 过滤隐藏文件夹</button>
  <button onclick="testApi4()">测试: 按用户名过滤</button>
  
  <div class="result">
    <h3>请求参数:</h3>
    <pre id="requestInfo">点击按钮开始测试</pre>
    
    <h3>响应结果:</h3>
    <pre id="responseInfo">等待响应...</pre>
  </div>
</div>

<div class="panel">
  <h2>测试2: 检查JavaScript环境</h2>
  <button onclick="checkEnv()">检查环境</button>
  <div id="envResult" class="result"></div>
</div>

<script>
function testApi1(){
  var data = {
    offset: 0,
    limit: 20,
    username: '',
    dstatus: -1
  };
  
  document.getElementById('requestInfo').textContent = 'POST ./ajax.php?act=folderList\n' + JSON.stringify(data, null, 2);
  
  fetch('./ajax.php?act=folderList', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams(data)
  })
  .then(response => response.json())
  .then(result => {
    document.getElementById('responseInfo').textContent = JSON.stringify(result, null, 2);
  })
  .catch(error => {
    document.getElementById('responseInfo').textContent = '错误: ' + error;
  });
}

function testApi2(){
  var data = {
    offset: 0,
    limit: 20,
    username: '',
    dstatus: 0
  };
  
  document.getElementById('requestInfo').textContent = 'POST ./ajax.php?act=folderList\n' + JSON.stringify(data, null, 2);
  
  fetch('./ajax.php?act=folderList', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams(data)
  })
  .then(response => response.json())
  .then(result => {
    document.getElementById('responseInfo').textContent = JSON.stringify(result, null, 2);
  })
  .catch(error => {
    document.getElementById('responseInfo').textContent = '错误: ' + error;
  });
}

function testApi3(){
  var data = {
    offset: 0,
    limit: 20,
    username: '',
    dstatus: 1
  };
  
  document.getElementById('requestInfo').textContent = 'POST ./ajax.php?act=folderList\n' + JSON.stringify(data, null, 2);
  
  fetch('./ajax.php?act=folderList', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams(data)
  })
  .then(response => response.json())
  .then(result => {
    document.getElementById('responseInfo').textContent = JSON.stringify(result, null, 2);
  })
  .catch(error => {
    document.getElementById('responseInfo').textContent = '错误: ' + error;
  });
}

function testApi4(){
  var data = {
    offset: 0,
    limit: 20,
    username: 'cheng806415',
    dstatus: -1
  };
  
  document.getElementById('requestInfo').textContent = 'POST ./ajax.php?act=folderList\n' + JSON.stringify(data, null, 2);
  
  fetch('./ajax.php?act=folderList', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams(data)
  })
  .then(response => response.json())
  .then(result => {
    document.getElementById('responseInfo').textContent = JSON.stringify(result, null, 2);
  })
  .catch(error => {
    document.getElementById('responseInfo').textContent = '错误: ' + error;
  });
}

function checkEnv(){
  var html = '<h3>JavaScript环境检查:</h3><ul>';
  html += '<li>jQuery版本: ' + (typeof jQuery !== 'undefined' ? jQuery.fn.jquery : '<span style="color:red;">未加载</span>') + '</li>';
  html += '<li>bootstrapTable: ' + (typeof $.fn.bootstrapTable !== 'undefined' ? '已加载' : '<span style="color:red;">未加载</span>') + '</li>';
  html += '<li>Fetch API: ' + (typeof fetch !== 'undefined' ? '支持' : '<span style="color:red;">不支持</span>') + '</li>';
  html += '<li>当前URL: ' + window.location.href + '</li>';
  html += '</ul>';
  document.getElementById('envResult').innerHTML = html;
}
</script>

</body>
</html>