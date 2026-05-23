import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'api_client.dart';
import '../models/file_model.dart';

enum DownloadStatus { waiting, downloading, success, failed, paused }

class DownloadTask {
  final String name;
  final int size;
  final String url;
  final FileModel? file;
  double progress;
  DownloadStatus status;
  String? localPath;
  String? error;

  DownloadTask({
    required this.name,
    required this.size,
    required this.url,
    this.file,
    this.progress = 0,
    this.status = DownloadStatus.waiting,
    this.localPath,
    this.error,
  });
}

class DownloadManager extends ChangeNotifier {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final List<DownloadTask> _tasks = [];
  final List<void Function()> _listeners = [];

  List<DownloadTask> get tasks => _tasks;

  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  Future<void> startDownload(FileModel file) async {
    final task = DownloadTask(
      name: file.name,
      size: file.size,
      url: ApiClient().getDownloadUrl(file),
      file: file,
    );
    _tasks.insert(0, task);
    _notifyListeners();
    _downloadFile(task);
  }

  Future<void> _downloadFile(DownloadTask task) async {
    task.status = DownloadStatus.downloading;
    _notifyListeners();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/${task.name}';

      await ApiClient().download(
        task.url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            task.progress = received / total;
            _notifyListeners();
          }
        },
      );

      task.status = DownloadStatus.success;
      task.progress = 1.0;
      task.localPath = savePath;
      _notifyListeners();
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.error = e.toString();
      _notifyListeners();
    }
  }

  Future<void> openFile(DownloadTask task) async {
    if (task.localPath != null) {
      final result = await OpenFile.open(task.localPath);
      if (result.type != ResultType.done) {
        // Handle error
      }
    }
  }

  void clearCompleted() {
    _tasks.removeWhere((t) => t.status == DownloadStatus.success);
    _notifyListeners();
  }

  void clearAll() {
    _tasks.clear();
    _notifyListeners();
  }
}
