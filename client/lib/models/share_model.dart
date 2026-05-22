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
      id: json['id'] ?? 0,
      surl: json['surl'] ?? '',
      fileId: json['file_id'] ?? 0,
      uid: json['uid'] ?? 0,
      pwd: json['pwd'],
      expireTime: json['expire_time'],
      expireType: json['expire_type'] ?? 0,
      downloadLimit: json['download_limit'] ?? 0,
      downloadCount: json['download_count'] ?? 0,
      viewCount: json['view_count'] ?? 0,
      status: json['status'] ?? 1,
      addtime: json['addtime'],
      file: json['file'] != null ? FileModel.fromJson(json['file']) : null,
    );
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
