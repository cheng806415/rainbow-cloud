class FolderModel {
  final int id;
  final String name;
  final int uid;
  final String? pwd;
  final bool hide;
  final String? addtime;
  final int? fileCount;

  FolderModel({
    required this.id,
    required this.name,
    required this.uid,
    this.pwd,
    this.hide = false,
    this.addtime,
    this.fileCount,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '未知文件夹',
      uid: _toInt(json['uid']),
      pwd: json['pwd']?.toString(),
      hide: _toInt(json['hide']) == 1,
      addtime: json['addtime']?.toString(),
      fileCount: json['file_count'] != null ? _toInt(json['file_count']) : null,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
