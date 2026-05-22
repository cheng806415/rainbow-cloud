new Vue({
    el: '#app',
    data: {
        uploadTitle: '选择文件/Ctrl+V粘贴/拖拽到此上传',
        background: '#fff',
        isBlock: false,
        alert: {
            type: 'success',
            msg: ''
        },
        beginTime: 0,
        input: {
            csrf_token: '',
            show: true,
            ispwd: false,
            pwd: '',
            folder_id: 0
        },
        fileList: [],
        currentIndex: -1,
        csrf_token: '',
        isLogin: false
    },
    mounted() {
        $(".colorful_loading_frame").hide();
        this.csrf_token = $("#csrf_token").val();
        this.input.csrf_token = this.csrf_token;
        this.isLogin = (typeof is_login !== 'undefined' && is_login == 1);

        var that = this;
        var fileInput = $("#fileInput");
        var elemetnNode = "";

        fileInput.on("dragenter", function(e) {
            elemetnNode = e.originalEvent.target;
            that.uploadTitle = '释放鼠标立即上传';
            that.background = '#ccc';
        });
        fileInput.on("dragleave", function(e) {
            if (elemetnNode === e.originalEvent.target) {
                that.uploadTitle = '选择文件/Ctrl+V粘贴/拖拽到此上传';
                that.background = '#fff';
            }
        });
        fileInput.on('dragover', false).on("drop", function(e) {
            that.uploadTitle = '选择文件/Ctrl+V粘贴/拖拽到此上传';
            that.background = '#fff';
            var fs = e.originalEvent.dataTransfer.files;
            if (fs.length > 0) {
                that.addFilesToQueue(Array.prototype.slice.call(fs));
            }
            return false;
        });

        document.addEventListener('paste', function(e) {
            var items = ((e.clipboardData || window.clipboardData).items) || [];
            var files = [];
            if (items && items.length) {
                for (var i = 0; i < items.length; i++) {
                    if (items[i].type.indexOf('text/') === -1) {
                        var file = items[i].getAsFile();
                        if (file) files.push(file);
                    }
                }
            }
            if (files.length > 0) {
                that.addFilesToQueue(files);
            }
        });
    },
    methods: {
        show_msg(msg, type) {
            type = type || 'success';
            this.alert.type = type;
            this.alert.msg = msg;
            this.isBlock = false;
        },
        clickUpload() {
            if (this.isBlock) return;
            $("#file").trigger("click");
        },
        clickFolderUpload() {
            if (this.isBlock) return;
            if (!this.isLogin) {
                layer.msg('请先登录后再上传文件夹', { icon: 0 });
                return;
            }
            $("#folder").trigger("click");
        },
        addFilesToQueue(fileArray) {
            if (typeof forbid !== 'undefined' && forbid) {
                layer.alert('登录后才能上传文件！', { icon: 0 }, function() { window.location.href = './login.php' });
                return;
            }
            for (var i = 0; i < fileArray.length; i++) {
                var file = fileArray[i];
                if (upload_max_filesize != '' && parseInt(upload_max_filesize) > 0) {
                    if (file.size > parseInt(upload_max_filesize) * 1024 * 1024) {
                        layer.msg('文件 ' + file.name + ' 大小超过限制(' + upload_max_filesize + 'MB)，已跳过', { icon: 0, shade: 0.3, time: 2000 });
                        continue;
                    }
                }
                var idx = this.fileList.length;
                this.fileList.push({
                    id: Date.now() + '_' + i,
                    name: file.name,
                    size: file.size,
                    file: file,
                    status: 'hashing',
                    progress: 0,
                    progress_tip: '正在计算哈希...',
                    speed: '',
                    hash: '',
                    downurl: '',
                    viewurl: '',
                    msg: '',
                    pwd: this.input.ispwd ? this.input.pwd : '',
                    folder_id: this.input.folder_id
                });
                var that = this;
                this.getFileHash(file, this.fileList[idx]).then(function(hash){
                    that.fileList[idx].hash = hash;
                    that.fileList[idx].progress_tip = '';
                    that.fileList[idx].status = 'pending';
                    that.fileList[idx].progress_tip = '等待中';
                }).catch(function(){
                    that.fileList[idx].status = 'pending';
                    that.fileList[idx].progress_tip = '等待中';
                });
            }
            if (this.fileList.length > 0 && this.currentIndex === -1) {
                this.uploadNext();
            }
        },
        async selectFile(e) {
            var total = e.target.files.length;
            if (total == 0) return;
            var files = Array.prototype.slice.call(e.target.files);
            this.addFilesToQueue(files);
            $("#file").val('');
        },
        async selectFolder(e) {
            var total = e.target.files.length;
            if (total == 0) return;
            var files = Array.prototype.slice.call(e.target.files);
            this.addFilesToQueue(files);
            $("#folder").val('');
        },
        async uploadNext() {
            if (this.currentIndex >= 0) {
                var current = this.fileList[this.currentIndex];
                if (current.status === 'uploading' || current.status === 'hashing') return;
            }
            for (var i = 0; i < this.fileList.length; i++) {
                if (this.fileList[i].status === 'pending') {
                    this.currentIndex = i;
                    await this.uploadFile(this.fileList[i]);
                    await this.uploadNext();
                    return;
                }
            }
            var allDone = true;
            for (var j = 0; j < this.fileList.length; j++) {
                if (this.fileList[j].status === 'hashing' || this.fileList[j].status === 'uploading') {
                    allDone = false;
                    break;
                }
            }
            if (allDone) {
                this.currentIndex = -1;
                var successCount = this.fileList.filter(function(f) { return f.status === 'success'; }).length;
                var failCount = this.fileList.filter(function(f) { return f.status === 'error'; }).length;
                if (successCount > 0 || failCount > 0) {
                    this.show_msg('上传完成！成功 ' + successCount + ' 个，失败 ' + failCount + ' 个。', failCount > 0 ? 'warning' : 'success');
                }
            } else {
                var that = this;
                setTimeout(function() { that.uploadNext(); }, 100);
            }
        },
        async getNewToken() {
            var that = this;
            return new Promise(function(resolve, reject) {
                $.ajax({
                    type: 'GET',
                    url: 'ajax.php?act=get_token',
                    dataType: 'json',
                    success: function(data) {
                        if (data.code == 0 && data.csrf_token) {
                            resolve(data.csrf_token);
                        } else {
                            reject('获取token失败');
                        }
                    },
                    error: function() {
                        reject('获取token失败');
                    }
                });
            });
        },
        async uploadFile(fileItem) {
            var that = this;
            fileItem.status = 'uploading';
            fileItem.progress = 0;
            fileItem.speed = '';

            var loading = layer.msg('正在准备上传: ' + fileItem.name, { icon: 16, shade: 0.1, time: 0 });

            var maxWait = 30000;
            var waitStart = Date.now();
            while (!fileItem.hash && Date.now() - waitStart < maxWait) {
                await new Promise(function(r) { setTimeout(r, 50); });
            }

            if (!fileItem.hash) {
                layer.close(loading);
                fileItem.status = 'error';
                fileItem.msg = '计算文件哈希超时';
                throw Error();
            }

            var newToken;
            try {
                newToken = await that.getNewToken();
            } catch (e) {
                layer.close(loading);
                fileItem.status = 'error';
                fileItem.msg = '获取上传令牌失败';
                throw Error();
            }
            fileItem.csrf_token = newToken;
            fileItem.progress_tip = '正在上传...';

            var result = {};
            var preResult = await that.preUpload(fileItem).catch(function(res) {
                layer.close(loading);
                fileItem.status = 'error';
                fileItem.msg = res;
                throw Error();
            });
            layer.close(loading);

            if (preResult.code == 1) {
                fileItem.progress = 100;
                fileItem.status = 'success';
                fileItem.downurl = preResult.downurl || (that.getDownUrl(fileItem));
                fileItem.viewurl = preResult.viewurl || '';
                fileItem.msg = preResult.msg || '秒传成功';
                return;
            }

            if (preResult.third) {
                await that.uploadThird(preResult.url, preResult.post, fileItem.file, fileItem).catch(function(res) {
                    fileItem.status = 'error';
                    fileItem.msg = res;
                    throw Error();
                });
                var completeResult = await that.completeUpload(fileItem).catch(function(res) {
                    fileItem.status = 'error';
                    fileItem.msg = res;
                    throw Error();
                });
                fileItem.status = 'success';
                fileItem.downurl = that.getDownUrl(fileItem);
                if (completeResult.viewurl) fileItem.viewurl = completeResult.viewurl;
                fileItem.msg = '上传成功';
            } else {
                var chunkSize = preResult.chunksize;
                var chunks = preResult.chunks;
                if (chunks == 1) {
                    await that.uploadPart(fileItem.file, 1, fileItem).catch(function(res) {
                        fileItem.status = 'error';
                        fileItem.msg = res;
                        throw Error();
                    });
                } else {
                    var blobSlice = File.prototype.mozSlice || File.prototype.webkitSlice || File.prototype.slice;
                    for (var chunk = 1; chunk <= chunks; chunk++) {
                        var start = (chunk - 1) * chunkSize;
                        var end = start + chunkSize > fileItem.file.size ? fileItem.file.size : start + chunkSize;
                        var blob = blobSlice.call(fileItem.file, start, end);
                        await that.uploadPart(blob, chunk, fileItem).catch(function(res) {
                            fileItem.status = 'error';
                            fileItem.msg = res;
                            throw Error();
                        });
                    }
                }
                fileItem.status = 'success';
                fileItem.downurl = that.getDownUrl(fileItem);
                fileItem.msg = '上传成功';
            }
        },
        getDownUrl(fileItem) {
            var url = './down.php/' + fileItem.hash + '.' + this.getFileExt(fileItem.name);
            if (fileItem.pwd) url += '&' + fileItem.pwd;
            return url;
        },
        getFileExt(name) {
            var lastDot = name.lastIndexOf('.');
            return lastDot > 0 ? name.substring(lastDot + 1) : '';
        },
        async preUpload(fileItem) {
            var postData = {
                csrf_token: fileItem.csrf_token,
                name: fileItem.name,
                hash: fileItem.hash,
                size: fileItem.size,
                show: this.input.show ? '1' : '0',
                ispwd: this.input.ispwd ? '1' : '0',
                pwd: fileItem.pwd,
                folder_id: fileItem.folder_id || 0
            };
            var that = this;
            return new Promise(function(resolve, reject) {
                $.ajax({
                    type: 'POST',
                    url: 'ajax.php?act=pre_upload',
                    data: postData,
                    dataType: 'json',
                    success: function(data) {
                        if (data.code == 0 || data.code == 1) {
                            resolve(data);
                        } else {
                            reject(data.msg);
                        }
                    },
                    error: function() {
                        reject('服务器错误');
                    }
                });
            });
        },
        async completeUpload(fileItem) {
            var that = this;
            return new Promise(function(resolve, reject) {
                $.ajax({
                    type: 'POST',
                    url: 'ajax.php?act=complete_upload',
                    data: { hash: fileItem.hash, csrf_token: fileItem.csrf_token },
                    dataType: 'json',
                    success: function(data) {
                        if (data.code == 0 || data.code == 1) {
                            resolve(data);
                        } else {
                            reject(data.msg);
                        }
                    },
                    error: function() {
                        reject('服务器错误');
                    }
                });
            });
        },
        async uploadPart(file, chunk, fileItem) {
            var that = this;
            var tempTime = new Date().getTime();
            var oloaded = 0;
            var baseLoaded = (chunk - 1) * fileItem.size;
            return new Promise(function(resolve, reject) {
                var data = new FormData();
                data.append('file', file);
                data.append('hash', fileItem.hash);
                data.append('chunk', chunk);
                data.append('csrf_token', fileItem.csrf_token);
                $.ajax({
                    type: "POST",
                    url: "ajax.php?act=upload_part",
                    data: data,
                    processData: false,
                    contentType: false,
                    dataType: 'json',
                    success: function(data) {
                        if (data.code == 0 || data.code == 1) {
                            resolve(data);
                        } else {
                            reject(data.msg);
                        }
                    },
                    error: function() {
                        reject('上传失败，请稍后再试或联系站长');
                    },
                    xhr: function() {
                        var xhr = new XMLHttpRequest();
                        xhr.upload.addEventListener('progress', function(e) {
                            var loaded = baseLoaded + e.loaded;
                            var progressRate = Math.round(loaded / fileItem.size * 100);
                            if (progressRate > 100) progressRate = 100;
                            fileItem.progress = progressRate;
                            if (progressRate == 100) fileItem.progress_tip = '正在保存中，请稍候';
                            else fileItem.progress_tip = '上传中 ' + progressRate + '%';

                            var nowTime = new Date().getTime();
                            var pertime = (nowTime - tempTime) / 1000;
                            tempTime = nowTime;
                            var perload = e.loaded - oloaded;
                            oloaded = e.loaded;
                            var speed = that.size_format(perload / pertime) + '/s';
                            fileItem.speed = speed;
                        });
                        return xhr;
                    }
                });
            });
        },
        async uploadThird(url, postdata, file, fileItem) {
            var that = this;
            var tempTime = new Date().getTime();
            var oloaded = 0;
            return new Promise(function(resolve, reject) {
                var data = new FormData();
                for (var key in postdata) {
                    data.append(key, postdata[key]);
                }
                data.append('file', file);
                $.ajax({
                    type: "POST",
                    url: url,
                    data: data,
                    processData: false,
                    contentType: false,
                    dataType: 'html',
                    success: function(data) {
                        resolve();
                    },
                    error: function() {
                        reject('上传失败，请稍后再试或联系站长');
                    },
                    xhr: function() {
                        var xhr = new XMLHttpRequest();
                        xhr.upload.addEventListener('progress', function(e) {
                            var progressRate = Math.round(e.loaded / e.total * 100);
                            if (progressRate > 100) progressRate = 100;
                            fileItem.progress = progressRate;
                            if (progressRate == 100) fileItem.progress_tip = '正在保存中，请稍候';
                            else fileItem.progress_tip = '上传中 ' + progressRate + '%';

                            var nowTime = new Date().getTime();
                            var pertime = (nowTime - tempTime) / 1000;
                            tempTime = nowTime;
                            var perload = e.loaded - oloaded;
                            oloaded = e.loaded;
                            var speed = that.size_format(perload / pertime) + '/s';
                            fileItem.speed = speed;
                        });
                        return xhr;
                    }
                });
            });
        },
        async getFileHash(file, fileItem) {
            var that = this;
            return new Promise(function(resolve) {
                var fileReader = new FileReader(),
                    blobSlice = File.prototype.mozSlice || File.prototype.webkitSlice || File.prototype.slice,
                    chunkSize = 2097152,
                    chunks = Math.ceil(file.size / chunkSize),
                    currentChunk = 0,
                    spark = new SparkMD5();

                loadNext();

                fileReader.onload = function(e) {
                    spark.appendBinary(e.target.result);
                    currentChunk++;
                    var progressRate = Math.round(currentChunk / chunks * 100);
                    if (fileItem) fileItem.progress_tip = '正在读取文件(' + progressRate + '%)';
                    if (currentChunk < chunks) {
                        loadNext();
                    } else {
                        resolve(spark.end());
                    }
                };

                function loadNext() {
                    var start = currentChunk * chunkSize,
                        end = start + chunkSize >= file.size ? file.size : start + chunkSize;
                    fileReader.readAsBinaryString(blobSlice.call(file, start, end));
                }
            });
        },
        size_format(size) {
            var units = 'B';
            if (size / 1024 > 1) {
                size = size / 1024;
                units = 'KB';
            }
            if (size / 1024 > 1) {
                size = size / 1024;
                units = 'MB';
            }
            if (size / 1024 > 1) {
                size = size / 1024;
                units = 'GB';
            }
            return size.toFixed(2) + units;
        },
        getStatusIcon(status) {
            if (status === 'success') return 'fa-check-circle text-success';
            if (status === 'error') return 'fa-times-circle text-danger';
            if (status === 'uploading') return 'fa-spinner fa-spin text-info';
            if (status === 'hashing') return 'fa-cog fa-spin text-info';
            return 'fa-clock-o text-muted';
        },
        getStatusText(status) {
            if (status === 'success') return '上传成功';
            if (status === 'error') return '上传失败';
            if (status === 'uploading') return '上传中';
            if (status === 'hashing') return '计算哈希';
            return '等待中';
        },
        copyUrl(url) {
            var input = document.createElement('input');
            input.value = url;
            document.body.appendChild(input);
            input.select();
            document.execCommand('copy');
            document.body.removeChild(input);
            layer.msg('链接已复制', { icon: 1, shade: 0.3, time: 1500 });
        },
        removeFile(index) {
            var s = this.fileList[index].status;
            if (s === 'uploading' || s === 'hashing') return;
            this.fileList.splice(index, 1);
        },
        clearAll() {
            for (var i = 0; i < this.fileList.length; i++) {
                if (this.fileList[i].status === 'uploading' || this.fileList[i].status === 'hashing') {
                    layer.msg('有文件正在处理，请等待完成', { icon: 0, shade: 0.3, shadeClose: true });
                    return;
                }
            }
            this.fileList = [];
            this.currentIndex = -1;
        },
        createNewFolder() {
            if (!this.isLogin) {
                layer.msg('请先登录', { icon: 2 });
                return;
            }
            var that = this;
            layer.prompt({title: '输入文件夹名称', formType: 0}, function(name, index){
                layer.close(index);
                var ii = layer.load(2);
                $.ajax({
                    type: 'POST',
                    url: 'ajax.php?act=folder_create',
                    data: {name: name, parent_id: 0, csrf_token: that.csrf_token},
                    dataType: 'json',
                    success: function(data){
                        layer.close(ii);
                        if(data.code == 0){
                            layer.msg('创建成功', {icon:1});
                            location.reload();
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
        }
    }
})
