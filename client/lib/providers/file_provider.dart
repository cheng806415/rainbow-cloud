import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../models/file_model.dart';

class FileProvider extends ChangeNotifier {
  final _apiClient = ApiClient();
  List<FileModel> _files = [];
  List<FileModel> _selectedFiles = [];
  bool _isLoading = false;
  String _error = '';
  int _currentFolderId = 0;
  bool _showHidden = false;

  List<FileModel> get files => _files;
  List<FileModel> get selectedFiles => _selectedFiles;
  bool get isLoading => _isLoading;
  String get error => _error;
  int get currentFolderId => _currentFolderId;
  bool get hasSelection => _selectedFiles.isNotEmpty;

  Future<void> loadFiles({int folderId = 0, String keyword = ''}) async {
    _isLoading = true;
    _currentFolderId = folderId;
    notifyListeners();
    try {
      _files = await _apiClient.loadFileList(
        folderId: folderId,
        keyword: keyword,
        showHidden: _showHidden,
      );
      _error = '';
    } catch (e) {
      _error = '网络错误: $e';
      _files = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> deleteFile(FileModel file) async {
    try {
      final token = await _apiClient.getCsrfToken();
      final response = await _apiClient.post('/ajax.php',
        queryParameters: {'act': 'deleteFile'},
        data: {'csrf_token': token, 'hash': file.hash},
      );
      if (response.data['code'] == 0) {
        _files.removeWhere((f) => f.id == file.id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> batchDelete(List<FileModel> files) async {
    try {
      final token = await _apiClient.getCsrfToken();
      final hashes = files.map((f) => f.hash).join(',');
      final ids = files.map((f) => f.id.toString()).join(',');
      final response = await _apiClient.post('/ajax.php',
        queryParameters: {'act': 'batch_delete'},
        data: {'csrf_token': token, 'hashes': hashes, 'ids': ids},
      );
      if (response.data['code'] == 0) {
        final deletedHashes = files.map((f) => f.hash).toSet();
        _files.removeWhere((f) => deletedHashes.contains(f.hash));
        _selectedFiles.clear();
        notifyListeners();
        return {'success': true, 'deleted': response.data['deleted'], 'failed': response.data['failed']};
      }
      return {'success': false, 'msg': response.data['msg']};
    } catch (e) {
      return {'success': false, 'msg': '网络错误'};
    }
  }

  void toggleSelection(FileModel file) {
    if (_selectedFiles.contains(file)) {
      _selectedFiles.remove(file);
    } else {
      _selectedFiles.add(file);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedFiles.clear();
    notifyListeners();
  }

  void selectAll() {
    _selectedFiles = List.from(_files);
    notifyListeners();
  }

  void toggleShowHidden() {
    _showHidden = !_showHidden;
    loadFiles(folderId: _currentFolderId);
  }
}
