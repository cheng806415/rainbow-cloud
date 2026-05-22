# 彩虹网盘 Flutter 客户端

基于 Flutter 框架开发的跨平台客户端，同时支持 Android 和 Windows。

## 功能特性

- 用户登录/注册
- 文件浏览和搜索
- 文件上传（支持分片上传）
- 文件下载和管理
- 文件预览（图片、视频、音频、PDF）
- 文件分享
- 回收站管理
- 文件夹管理
- 深色/浅色主题切换
- 自适应布局（移动端/桌面端）

## 项目结构

```
client/
├── pubspec.yaml                  # 项目依赖配置
├── analysis_options.yaml         # 代码规范配置
├── lib/
│   ├── main.dart                 # 应用入口
│   ├── models/                   # 数据模型
│   │   ├── file_model.dart       # 文件模型
│   │   ├── folder_model.dart     # 文件夹模型
│   │   ├── share_model.dart      # 分享模型
│   │   └── user_model.dart       # 用户模型
│   ├── pages/                    # 页面
│   │   ├── about_page.dart       # 关于页面
│   │   ├── download_page.dart    # 下载管理页面
│   │   ├── file_list_page.dart   # 文件列表页面
│   │   ├── home_page.dart        # 主页（导航容器）
│   │   ├── login_page.dart       # 登录/注册页面
│   │   ├── preview_page.dart     # 文件预览页面
│   │   ├── profile_page.dart     # 用户中心页面
│   │   ├── recycle_page.dart     # 回收站页面
│   │   ├── settings_page.dart    # 设置页面
│   │   ├── share_page.dart       # 分享页面
│   │   └── upload_page.dart      # 上传页面
│   ├── providers/                # 状态管理（Provider）
│   │   ├── auth_provider.dart    # 认证状态
│   │   ├── file_provider.dart    # 文件状态
│   │   ├── folder_provider.dart  # 文件夹状态
│   │   └── theme_provider.dart   # 主题状态
│   ├── utils/                    # 工具类
│   │   ├── api_client.dart       # HTTP 客户端
│   │   ├── app_utils.dart        # 应用工具
│   │   └── constants.dart        # 常量定义
│   └── widgets/                  # 公共组件
│       └── common_widgets.dart   # 通用组件
├── android/                      # Android 平台配置
└── windows/                      # Windows 平台配置
```

## 环境要求

- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / VS Code
- Windows 10+ (可选，用于 Windows 桌面端开发)

## 快速开始

### 1. 安装 Flutter SDK

从 https://flutter.dev 下载并安装 Flutter SDK。

### 2. 获取依赖

```bash
cd client
flutter pub get
```

### 3. 配置服务器地址

修改 `lib/utils/constants.dart` 中的 `defaultServerUrl`：

```dart
static const String defaultServerUrl = 'https://your-pan-domain.com';
```

### 4. 运行应用

#### Android
```bash
flutter run
```

#### Windows
```bash
flutter run -d windows
```

### 5. 构建发布版本

#### Android APK
```bash
flutter build apk --release
```

#### Android App Bundle
```bash
flutter build appbundle --release
```

#### Windows
```bash
flutter build windows --release
```

## 后端 API 说明

客户端通过以下 API 与后端通信：

| 接口 | 方法 | 说明 |
|------|------|------|
| `/login.php?act=local_login` | POST | 用户登录 |
| `/login.php?act=local_register` | POST | 用户注册 |
| `/ajax.php?act=get_token` | GET | 获取 CSRF Token |
| `/ajax.php?act=get_user_info` | GET | 获取用户信息 |
| `/ajax.php?act=file_list` | GET | 获取文件列表 |
| `/ajax.php?act=pre_upload` | POST | 预上传检查 |
| `/ajax.php?act=upload_part` | POST | 上传分片 |
| `/ajax.php?act=deleteFile` | POST | 删除文件 |
| `/ajax.php?act=batch_delete` | POST | 批量删除 |
| `/ajax.php?act=folder_list` | POST | 获取文件夹列表 |
| `/ajax.php?act=folder_create` | POST | 创建文件夹 |

## 认证方式

使用 PHP Session Cookie (`user_token`) 进行认证，客户端通过 `dio_cookie_manager` 自动管理 Cookie。

## 技术栈

- Flutter - 跨平台 UI 框架
- Provider - 状态管理
- Dio - HTTP 请求
- Cookie Jar - Cookie 管理
- File Picker - 文件选择
- Photo View - 图片预览
- Chewie - 视频播放器
- Flutter Secure Storage - 安全存储

## License

MIT
