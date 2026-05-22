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
      id: json['id'] ?? 0,
      name: json['name'] ?? '未知文件夹',
      uid: json['uid'] ?? 0,
      pwd: json['pwd'],
      hide: (json['hide'] ?? 0) == 1,
      addtime: json['addtime'],
      fileCount: json['file_count'],
    );
  }
}
