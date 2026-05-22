import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import '../providers/folder_provider.dart';
import '../providers/auth_provider.dart';
import '../models/file_model.dart';
import '../models/folder_model.dart';
import 'preview_page.dart';

class FileListPage extends StatefulWidget {
  const FileListPage({super.key});

  @override
  State<FileListPage> createState() => _FileListPageState();
}

class _FileListPageState extends State<FileListPage> {
  final _searchController = TextEditingController();
  int _currentFolderId = 0;
  String _searchKeyword = '';
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFiles();
    });
  }

  void _loadFiles() {
    context.read<FileProvider>().loadFiles(
      folderId: _currentFolderId,
      keyword: _searchKeyword,
    );
  }

  Future<void> _refreshFiles() async {
    await context.read<FileProvider>().loadFiles(
      folderId: _currentFolderId,
      keyword: _searchKeyword,
    );
  }

  void _enterFolder(FolderModel folder) {
    setState(() => _currentFolderId = folder.id);
    _loadFiles();
  }

  void _goBack() {
    setState(() => _currentFolderId = 0);
    _loadFiles();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        context.read<FileProvider>().clearSelection();
      }
    });
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建文件夹'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '文件夹名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await context.read<FolderProvider>().createFolder(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showFileActions(FileModel file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (file.isImage || file.isVideo || file.isAudio || file.isPdf)
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('预览'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PreviewPage(file: file),
                  ));
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('删除'),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('确认删除'),
                    content: Text('确定要删除 "${file.name}" 吗？'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
                    ],
                  ),
                );
                if (confirmed == true) {
                  final success = await context.read<FileProvider>().deleteFile(file);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? '删除成功' : '删除失败'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _batchDelete() async {
    final selected = context.read<FileProvider>().selectedFiles;
    if (selected.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定要删除选中的 ${selected.length} 个文件吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await context.read<FileProvider>().batchDelete(selected);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['success'] == true
                ? '删除完成，成功 ${result['deleted']} 个，失败 ${result['failed']} 个'
                : '批量删除失败: ${result['msg']}'),
            backgroundColor: result['success'] == true ? Colors.green : Colors.red,
          ),
        );
        setState(() => _isSelectionMode = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _currentFolderId > 0
            ? Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _goBack,
                    tooltip: '返回根目录',
                  ),
                  const Text('文件夹'),
                ],
              )
            : const Text('我的文件'),
        actions: [
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.close : Icons.select_all),
            onPressed: _toggleSelectionMode,
            tooltip: _isSelectionMode ? '退出选择' : '批量选择',
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            onPressed: _showCreateFolderDialog,
            tooltip: '新建文件夹',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshFiles,
            tooltip: '刷新',
          ),
        ],
        bottom: _isSelectionMode ? null : PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索文件...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                        _searchController.clear();
                        setState(() => _searchKeyword = '');
                        _loadFiles();
                      })
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                isDense: true,
              ),
              onSubmitted: (value) {
                setState(() => _searchKeyword = value);
                _loadFiles();
              },
            ),
          ),
        ),
      ),
      floatingActionButton: _isSelectionMode && context.watch<FileProvider>().hasSelection
          ? FloatingActionButton.extended(
              onPressed: _batchDelete,
              icon: const Icon(Icons.delete),
              label: Text('删除选中 (${context.watch<FileProvider>().selectedFiles.length})'),
            )
          : null,
      body: Column(
        children: [
          Consumer<FolderProvider>(
            builder: (context, folderProvider, _) {
              if (folderProvider.folders.isEmpty || _currentFolderId > 0) return const SizedBox.shrink();
              return SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8),
                  itemCount: folderProvider.folders.length,
                  itemBuilder: (context, index) {
                    final folder = folderProvider.folders[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: Icon(Icons.folder,
                          color: folder.hide ? Colors.grey : Theme.of(context).colorScheme.primary),
                        label: Text(folder.name),
                        onPressed: () => _enterFolder(folder),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          Expanded(
            child: Consumer<FileProvider>(
              builder: (context, fileProvider, _) {
                if (fileProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (fileProvider.error.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(fileProvider.error),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _refreshFiles, child: const Text('重试')),
                      ],
                    ),
                  );
                }
                if (fileProvider.files.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('暂无文件', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('点击底部上传按钮上传文件', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshFiles,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: fileProvider.files.length,
                    itemBuilder: (context, index) {
                      final file = fileProvider.files[index];
                      final isSelected = fileProvider.selectedFiles.contains(file);

                      return ListTile(
                        leading: Icon(
                          Icons.folder,
                          color: _getFolderColor(file),
                          size: 40,
                        ),
                        title: Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${file.formattedSize}${file.addtime != null ? ' · ${file.addtime}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: _isSelectionMode
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (_) => context.read<FileProvider>().toggleSelection(file),
                              )
                            : PopupMenuButton(
                                itemBuilder: (context) => [
                                  if (file.isImage || file.isVideo || file.isAudio || file.isPdf)
                                    const PopupMenuItem(value: 'preview', child: ListTile(
                                      leading: Icon(Icons.visibility, size: 20), title: Text('预览'), contentPadding: EdgeInsets.zero,
                                    )),
                                  const PopupMenuItem(value: 'delete', child: ListTile(
                                    leading: Icon(Icons.delete, size: 20, color: Colors.red), title: Text('删除'), contentPadding: EdgeInsets.zero,
                                  )),
                                ],
                                onSelected: (value) {
                                  if (value == 'preview') {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => PreviewPage(file: file),
                                    ));
                                  } else if (value == 'delete') {
                                    _showFileActions(file);
                                  }
                                },
                              ),
                        onTap: _isSelectionMode
                            ? () => context.read<FileProvider>().toggleSelection(file)
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getFolderColor(FileModel file) {
    if (file.isImage) return Colors.pink;
    if (file.isVideo) return Colors.purple;
    if (file.isAudio) return Colors.orange;
    if (file.isPdf) return Colors.red;
    return Colors.blue;
  }
}
