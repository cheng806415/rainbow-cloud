import 'file_model.dart';

class ShareModel {
  final int id;
  final String surl;
  final int fileId;
  final int uid;
  final String? pwd;
  final String? expireTime;
  final int expireType;
  final int downloadLimit;
  final int downloadCount;
  final int viewCount;
  final int status;
  final String? addtime;
  final FileModel? file;

  ShareModel({
    required this.id,
    required this.surl,
    required this.fileId,
    required this.uid,
    this.pwd,
    this.expireTime,
    required this.expireType,
    this.downloadLimit = 0,
    this.downloadCount = 0,
    this.viewCount = 0,
    this.status = 1,
    this.addtime,
    this.file,
  });

  factory ShareModel.fromJson(Map<String, dynamic> json) {
    return ShareModel(
      id: _toInt(json['id']),
      surl: json['surl']?.toString() ?? '',
      fileId: _toInt(json['file_id']),
      uid: _toInt(json['uid']),
      pwd: json['pwd']?.toString(),
      expireTime: json['expire_time']?.toString(),
      expireType: _toInt(json['expire_type']),
      downloadLimit: _toInt(json['download_limit']),
      downloadCount: _toInt(json['download_count']),
      viewCount: _toInt(json['view_count']),
      status: _toInt(json['status'], defaultValue: 1),
      addtime: json['addtime']?.toString(),
      file: json['file'] != null ? FileModel.fromJson(json['file']) : null,
    );
  }

  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  String get shareUrl => '/s/$surl';

  bool get hasPassword => pwd != null && pwd!.isNotEmpty;

  bool get isExpired => status == 0 || (expireTime != null && DateTime.tryParse(expireTime!)?.isBefore(DateTime.now()) == true);

  String get expireLabel {
    switch (expireType) {
      case 0: return '永久有效';
      case 1: return '7天有效';
      case 2: return '30天有效';
      case 3: return expireTime ?? '自定义';
      default: return '永久有效';
    }
  }
}
