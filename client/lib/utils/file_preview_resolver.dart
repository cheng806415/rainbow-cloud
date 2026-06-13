import '../../models/file_model.dart';

/// 预览类型枚举
enum PreviewType {
  image,
  video,
  audio,
  pdf,
  office,
  code,
  text,
  archive,
  unknown,
}

/// 文件预览类型识别器
class FilePreviewResolver {
  /// Office 文档类型
  static const Set<String> _officeTypes = {
    'doc', 'docx', 'xps', 'rtf', 'wps',
    'xls', 'xlsx', 'ppt', 'pptx', 'odt', 'ods', 'odp',
  };

  /// 压缩包类型
  static const Set<String> _archiveTypes = {
    'zip', '7z', 'rar', 'tgz', 'gz', 'xz', 'tar', 'jar',
  };

  /// 代码文件
  static const Set<String> _codeTypes = {
    'js', 'mjs', 'cjs', 'ts', 'jsx', 'tsx',
    'py', 'rb', 'php', 'go', 'java', 'kt', 'swift', 'm',
    'c', 'h', 'cpp', 'cc', 'cxx', 'hpp', 'cs', 'rs', 'lua',
    'sh', 'bash', 'zsh', 'ps1',
    'sql', 'xml', 'html', 'htm', 'css', 'scss', 'less', 'sass',
    'json', 'yaml', 'yml', 'toml', 'ini', 'cfg', 'conf',
    'dart', 'r', 'matlab', 'pl',
  };

  /// 纯文本
  static const Set<String> _textTypes = {
    'txt', 'log', 'csv', 'tsv',
  };

  static PreviewType resolve(FileModel file) {
    final type = (file.type ?? '').toLowerCase();
    if (type.isEmpty) return PreviewType.unknown;

    if (file.isImage) return PreviewType.image;
    if (file.isVideo) return PreviewType.video;
    if (file.isAudio) return PreviewType.audio;
    if (file.isPdf) return PreviewType.pdf;
    if (_archiveTypes.contains(type)) return PreviewType.archive;
    if (_officeTypes.contains(type)) return PreviewType.office;
    if (_codeTypes.contains(type)) return PreviewType.code;
    if (_textTypes.contains(type)) return PreviewType.text;
    return PreviewType.unknown;
  }

  /// 兼容网页版的 get_view_type
  static String webViewType(FileModel file) {
    final type = (file.type ?? '').toLowerCase();
    if (file.isImage) return 'image';
    if (file.isAudio) return 'audio';
    if (file.isVideo) return 'video';
    if (file.isPdf) return 'pdf';
    if (_archiveTypes.contains(type)) return 'archive';
    if (_officeTypes.contains(type)) return 'office';
    if (_codeTypes.contains(type)) return 'code';
    if (_textTypes.contains(type)) return 'text';
    return 'file';
  }
}
