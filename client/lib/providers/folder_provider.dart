import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../utils/api_client.dart';
import '../utils/app_logger.dart';
import '../models/folder_model.dart';

class FolderProvider extends ChangeNotifier {
  final _apiClient = ApiClient();
  final _logger = AppLogger();
  List<FolderModel> _folders = [];
  bool _isLoading = false;
  String _error = '';

  List<FolderModel> get folders => _folders;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> loadFolders() async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      final token = await _apiClient.ensureCsrfToken();
      if (token == null) {
        _error = '会话已过期,请重新登录';
        _folders = [];
        return;
      }
      final response = await _apiClient.post('/ajax.php',
        queryParameters: {'act': 'folder_list'},
        data: FormData.fromMap({'csrf_token': token}),
      );
      final data = _apiClient.parseResponse(response);
      if (data['code'] == 0 && data['folders'] is List) {
        _folders = (data['folders'] as List)
            .map((e) => FolderModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        _error = data['msg']?.toString() ?? '加载失败';
        _folders = [];
        if (data['code'] != 0) {
          _logger.w('FolderProvider', 'loadFolders 非 0: ${data['msg']}');
        }
      }
    } catch (e, stack) {
      _logger.e('FolderProvider', 'loadFolders error: $e\n$stack');
      _error = '网络错误: $e';
      _folders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createFolder(String name) async {
    if (name.trim().isEmpty) return false;
    try {
      final token = await _apiClient.ensureCsrfToken();
      if (token == null) return false;
      final response = await _apiClient.post('/ajax.php',
        queryParameters: {'act': 'folder_create'},
        data: FormData.fromMap({'csrf_token': token, 'name': name.trim()}),
      );
      final data = _apiClient.parseResponse(response);
      if (data['code'] == 0) {
        await loadFolders();
        return true;
      }
      _error = data['msg']?.toString() ?? '创建失败';
      notifyListeners();
      return false;
    } catch (e) {
      _logger.e('FolderProvider', 'createFolder error: $e');
      _error = '网络错误: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteFolder(int folderId) async {
    try {
      final token = await _apiClient.ensureCsrfToken();
      if (token == null) return false;
      final response = await _apiClient.post('/ajax.php',
        queryParameters: {'act': 'folder_delete'},
        data: FormData.fromMap({'csrf_token': token, 'folder_id': folderId}),
      );
      final data = _apiClient.parseResponse(response);
      if (data['code'] == 0) {
        _folders.removeWhere((f) => f.id == folderId);
        notifyListeners();
        return true;
      }
      _error = data['msg']?.toString() ?? '删除失败';
      notifyListeners();
      return false;
    } catch (e) {
      _logger.e('FolderProvider', 'deleteFolder error: $e');
      _error = '网络错误: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleHide(int folderId) async {
    try {
      final token = await _apiClient.ensureCsrfToken();
      if (token == null) return false;
      final response = await _apiClient.post('/ajax.php',
        queryParameters: {'act': 'folder_toggle_hide'},
        data: FormData.fromMap({'csrf_token': token, 'folder_id': folderId}),
      );
      final data = _apiClient.parseResponse(response);
      if (data['code'] == 0) {
        await loadFolders();
        return true;
      }
      _error = data['msg']?.toString() ?? '操作失败';
      notifyListeners();
      return false;
    } catch (e) {
      _logger.e('FolderProvider', 'toggleHide error: $e');
      _error = '网络错误: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> setPassword(int folderId, String? pwd) async {
    try {
      final token = await _apiClient.ensureCsrfToken();
      if (token == null) return false;
      final response = await _apiClient.post('/ajax.php',
        queryParameters: {'act': 'folder_setpwd'},
        data: FormData.fromMap({'csrf_token': token, 'folder_id': folderId, 'pwd': pwd ?? ''}),
      );
      final data = _apiClient.parseResponse(response);
      if (data['code'] == 0) {
        await loadFolders();
        return true;
      }
      _error = data['msg']?.toString() ?? '设置失败';
      notifyListeners();
      return false;
    } catch (e) {
      _logger.e('FolderProvider', 'setPassword error: $e');
      _error = '网络错误: $e';
      notifyListeners();
      return false;
    }
  }
}
