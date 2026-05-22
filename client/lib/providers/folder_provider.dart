import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import '../models/folder_model.dart';

class FolderProvider extends ChangeNotifier {
  final _apiClient = ApiClient();
  List<FolderModel> _folders = [];
  bool _isLoading = false;
  String _error = '';

  List<FolderModel> get folders => _folders;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> loadFolders() async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await _apiClient.getCsrfToken();
      final response = await _apiClient.post('/ajax.php',
        queryParameters: {'act': 'folder_list'},
        data: {'csrf_token': token},
      );
      if (response.data['code'] == 0) {
        _folders = (response.data['folders'] as List).map((e) => FolderModel.fromJson(e)).toList();
        _error = '';
      } else {
        _error = response.data['msg'] ?? '加载失败';
        _folders = [];
      }
    } catch (e) {
      _error = '网络错误: $e';
      _folders = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createFolder(String name) async {
    try {
      final token = await _apiClient.getCsrfToken();
      final response = await _apiClient.post('/ajax.php',
        queryParameters: {'act': 'folder_create'},
        data: {'csrf_token': token, 'name': name},
      );
      if (response.data['code'] == 0) {
        await loadFolders();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteFolder(int folderId) async {
    try {
      final token = await _apiClient.getCsrfToken();
      final response = await _apiClient.post('/ajax.php',
        queryParameters: {'act': 'folder_delete'},
        data: {'csrf_token': token, 'folder_id': folderId},
      );
      if (response.data['code'] == 0) {
        _folders.removeWhere((f) => f.id == folderId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleHide(int folderId) async {
    try {
      final token = await _apiClient.getCsrfToken();
      final response = await _apiClient.post('/ajax.php',
        queryParameters: {'act': 'folder_toggle_hide'},
        data: {'csrf_token': token, 'folder_id': folderId},
      );
      if (response.data['code'] == 0) {
        await loadFolders();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
