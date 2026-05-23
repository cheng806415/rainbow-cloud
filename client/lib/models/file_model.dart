class FileModel {
  final int id;
  final String name;
  final String? type;
  final int size;
  final String hash;
  final String? sha256;
  final String? addtime;
  final String? lasttime;
  final String? ip;
  final bool hide;
  final String? pwd;
  final int block;
  final int count;
  final int uid;
  final int folderId;
  final String? folderName;
  final bool isDeleted;
  final String? deletedTime;
  final int? deletedBy;
  final int? savedFrom;

  FileModel({
    required this.id,
    required this.name,
    this.type,
    required this.size,
    required this.hash,
    this.sha256,
    this.addtime,
    this.lasttime,
    this.ip,
    this.hide = false,
    this.pwd,
    this.block = 0,
    this.count = 0,
    this.uid = 0,
    this.folderId = 0,
    this.folderName,
    this.isDeleted = false,
    this.deletedTime,
    this.deletedBy,
    this.savedFrom,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '未知文件',
      type: json['type']?.toString(),
      size: _toInt(json['size']),
      hash: json['hash']?.toString() ?? '',
      sha256: json['sha256']?.toString(),
      addtime: json['addtime']?.toString(),
      lasttime: json['lasttime']?.toString(),
      ip: json['ip']?.toString(),
      hide: _toInt(json['hide']) == 1,
      pwd: json['pwd']?.toString(),
      block: _toInt(json['block']),
      count: _toInt(json['count']),
      uid: _toInt(json['uid']),
      folderId: _toInt(json['folder_id']),
      folderName: json['folder_name']?.toString(),
      isDeleted: _toInt(json['is_deleted']) == 1,
      deletedTime: json['deleted_time']?.toString(),
      deletedBy: json['deleted_by'] != null ? _toInt(json['deleted_by']) : null,
      savedFrom: json['saved_from'] != null ? _toInt(json['saved_from']) : null,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String get formattedSize => _formatBytes(size);

  String get formattedAddtime => addtime ?? '';

  String get icon => _getIconFromType(type);

  bool get isImage => _isTypeIn(['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp', 'ico', 'svg']);
  bool get isAudio => _isTypeIn(['mp3', 'wav', 'ogg', 'm4a', 'flac', 'aac']);
  bool get isVideo => _isTypeIn(['mp4', 'webm', 'flv', 'f4v', 'mov', '3gp', 'avi', 'mkv', 'ts']);
  bool get isPdf => type?.toLowerCase() == 'pdf';

  String _getIconFromType(String? ext) {
    if (ext == null) return 'insert_drive_file';
    switch (ext.toLowerCase()) {
      case 'png': case 'jpg': case 'jpeg': case 'gif': case 'bmp': case 'webp': case 'svg':
        return 'image';
      case 'mp3': case 'wav': case 'ogg': case 'm4a': case 'flac':
        return 'audiotrack';
      case 'mp4': case 'webm': case 'flv': case 'mov': case 'avi': case 'mkv':
        return 'videocam';
      case 'pdf':
        return 'picture_as_pdf';
      case 'doc': case 'docx':
        return 'description';
      case 'xls': case 'xlsx':
        return 'table_chart';
      case 'zip': case 'rar': case '7z': case 'tar': case 'gz':
        return 'folder_zip';
      default:
        return 'insert_drive_file';
    }
  }

  bool _isTypeIn(List<String> types) => types.contains(type?.toLowerCase());

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
