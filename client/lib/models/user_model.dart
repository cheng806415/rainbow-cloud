class UserModel {
  final int uid;
  final String? username;
  final String nickname;
  final String? faceimg;
  final String? avatar;
  final String? type;
  final String? openid;
  final int level;
  final bool enable;
  final String? regip;
  final String? loginip;
  final String? addtime;
  final String? lasttime;
  final bool allowView;
  final bool allowSearch;
  final int storageQuota;
  final int storageUsed;
  final String? wxOpenid;
  final String? qqOpenid;

  UserModel({
    required this.uid,
    this.username,
    required this.nickname,
    this.faceimg,
    this.avatar,
    this.type,
    this.openid,
    this.level = 0,
    this.enable = true,
    this.regip,
    this.loginip,
    this.addtime,
    this.lasttime,
    this.allowView = true,
    this.allowSearch = true,
    this.storageQuota = 1073741824,
    this.storageUsed = 0,
    this.wxOpenid,
    this.qqOpenid,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? 0,
      username: json['username'],
      nickname: json['nickname'] ?? '用户',
      faceimg: json['faceimg'],
      avatar: json['avatar'],
      type: json['type'],
      openid: json['openid'],
      level: json['level'] ?? 0,
      enable: (json['enable'] ?? 1) == 1,
      regip: json['regip'],
      loginip: json['loginip'],
      addtime: json['addtime'],
      lasttime: json['lasttime'],
      allowView: (json['allow_view'] ?? 1) == 1,
      allowSearch: (json['allow_search'] ?? 1) == 1,
      storageQuota: json['storage_quota'] ?? 1073741824,
      storageUsed: json['storage_used'] ?? 0,
      wxOpenid: json['wx_openid'],
      qqOpenid: json['qq_openid'],
    );
  }

  String get displayAvatar => avatar ?? faceimg ?? '';

  double get storageUsagePercent => storageQuota > 0 ? (storageUsed / storageQuota) * 100 : 0;

  String get formattedStorageUsed => _formatBytes(storageUsed);

  String get formattedStorageQuota => _formatBytes(storageQuota);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'nickname': nickname,
      'faceimg': faceimg,
      'avatar': avatar,
      'type': type,
      'openid': openid,
      'level': level,
      'enable': enable ? 1 : 0,
      'regip': regip,
      'loginip': loginip,
      'addtime': addtime,
      'lasttime': lasttime,
      'allow_view': allowView ? 1 : 0,
      'allow_search': allowSearch ? 1 : 0,
      'storage_quota': storageQuota,
      'storage_used': storageUsed,
      'wx_openid': wxOpenid,
      'qq_openid': qqOpenid,
    };
  }
}
