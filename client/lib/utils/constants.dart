class AppConstants {
  static const String defaultServerUrl = 'https://pan.example.com';
  static const String storageKeyServerUrl = 'server_url';
  static const String storageKeyAuthToken = 'auth_token';
  static const String storageKeyUserId = 'user_id';
  static const String storageKeyUserInfo = 'user_info';
  static const int chunkSize = 8 * 1024 * 1024; // 8MB
  static const int maxConcurrentUploads = 3;
  static const int requestTimeout = 30;
}
