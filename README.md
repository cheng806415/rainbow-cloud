# 彩虹外链网盘

<p align="center">
  <strong>开源 PHP 网盘系统 | 多端客户端支持</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/PHP-%3E%3D7.1-blue" alt="PHP Version">
  <img src="https://img.shields.io/badge/MySQL-%3E%3D5.5-orange" alt="MySQL Version">
  <img src="https://img.shields.io/badge/Flutter-3.44-blue" alt="Flutter Version">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
</p>

---

## 项目简介

彩虹外链网盘是一款基于 PHP 的开源网盘与外链分享系统，支持所有格式文件的上传、管理与分享。可生成文件外链、图片外链、音乐视频外链，自动生成 UBB 和 HTML 嵌入代码。

同时提供基于 Flutter 开发的跨平台客户端，支持 **Android**、**Windows**、**macOS** 平台。

## 核心功能

### 服务端（PHP）
- 文件上传、下载、管理与分享
- 支持对接 阿里云 OSS、腾讯云 COS、华为云 OBS、又拍云、七牛云
- 在线预览：文本、图片、音乐、视频、PDF、Office 文档、压缩包
- 用户系统：登录注册、文件记录、回收站
- 文件分享：外链生成、提取码、有效期设置
- 图片违规检测、文件完整性校验（SHA256）
- 分块上传、断点续传、极速秒传
- RESTful 上传 API 接口

### 客户端（Flutter）
- 文件列表浏览、分类筛选、搜索
- 文件上传（支持大文件分块上传）
- 在线预览：图片画廊、视频播放、音频播放、PDF、Office、代码高亮
- 文件分享与下载管理
- 用户登录、昵称修改、密码修改
- 深色/浅色主题切换

## 项目架构

```
rainbow-cloud/
├── 📁 服务端（PHP 后端）
│   ├── admin/          # 后台管理
│   ├── includes/       # 核心类库
│   ├── install/        # 安装引导
│   ├── ajax.php        # API 接口
│   ├── upload.php      # 上传处理
│   └── config.php      # 配置文件
│
├── 📁 客户端（Flutter）
│   └── client/
│       ├── lib/        # Dart 源码
│       ├── android/    # Android 原生
│       ├── windows/    # Windows 原生
│       └── macos/      # macOS 原生
│
├── 📁 考试倒计时（独立工具）
│   └── exam/
│       └── index.html
│
└── 📁 CI/CD
    └── .github/workflows/
```

## 快速开始

### 服务端部署

**环境要求：** PHP >= 7.1、MySQL >= 5.5

1. 将项目上传至网站根目录
2. 访问网站，按照安装向导完成数据库配置
3. 默认后台账号：`admin` / `123456`

### 客户端安装

从 [Releases](https://github.com/cheng806415/rainbow-cloud/releases) 页面下载对应平台安装包：

| 平台 | 文件 |
|------|------|
| Android | `rainbow_cloud_v*.apk` |
| Windows | `rainbow_cloud_windows_v*.zip` |
| macOS (Apple Silicon) | `rainbow_cloud_macos_v*.dmg` |

安装后首次启动需配置服务器地址，指向已部署的服务端。

## 在线演示

- 演示站点：https://cccimg.com/
- 官方网站：https://pan.cccyun.cc/

## 技术栈

| 层级 | 技术 |
|------|------|
| 后端 | PHP 7.1+, MySQL 5.5+, PDO |
| 客户端 | Flutter 3.44, Dart, Provider |
| 存储 | 阿里云 OSS / 腾讯云 COS / 华为云 OBS / 又拍云 / 七牛云 |
| 认证 | Cookie Session + CSRF Token |
| CI/CD | GitHub Actions |

## 更新日志

详见 [CHANGELOG.md](./CHANGELOG.md)

## 许可证

本项目基于 MIT 许可证开源，详见 [LICENSE](./LICENSE) 文件。

---

<p align="center">
  <sub>Made with ❤️ by <a href="https://blog.cccyun.cn/">cccyun</a></sub>
</p>