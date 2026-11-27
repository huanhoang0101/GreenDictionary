import 'package:flutter/material.dart';

import '../services/vocabulary_group_service.dart';
import '../services/saved_vocabulary_service.dart';
import 'vocabulary_words_page.dart';

class VocabularyGroupsPage extends StatefulWidget {
  const VocabularyGroupsPage({super.key});

  @override
  State<VocabularyGroupsPage> createState() => _VocabularyGroupsPageState();
}

class _VocabularyGroupsPageState extends State<VocabularyGroupsPage> {
  static const Color primaryColor = Color(0xFF35A995);
  static const Color backgroundColor = Color(0xFFF7F9FA);

  List<Map<String, dynamic>> groups = [];
  int savedWordCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // Tải danh sách nhóm và tổng số mục đã lưu.
  Future<void> loadData() async {
    try {
      final results = await Future.wait([
        VocabularyGroupService.getGroups(),
        SavedVocabularyService.getAllSavedItems(),
      ]);

      if (!mounted) return;

      setState(() {
        groups = results[0];
        savedWordCount = results[1].length;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  // Lấy số mục trong một nhóm từ kết quả Supabase.
  int getGroupItemCount(Map<String, dynamic> group) {
    final relations = group['vocabulary_group_words'] as List<dynamic>? ?? [];

    if (relations.isEmpty) return 0;

    final count = relations.first['count'];

    return count is int ? count : int.tryParse('$count') ?? 0;
  }

  // Định dạng ngày dd/MM/yyyy.
  String formatDate(dynamic value) {
    if (value == null) return '--/--/----';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return '--/--/----';

    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();

    return '$day/$month/$year';
  }

  // Tạo nhóm mới.
  Future<void> showCreateGroupDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tạo nhóm từ vựng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Tên nhóm',
                  hintText: 'Ví dụ: JLPT N2',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả (không bắt buộc)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên nhóm.')),
                  );
                  return;
                }

                try {
                  await VocabularyGroupService.createGroup(
                    name: name,
                    description: descriptionController.text,
                  );

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, true);
                  }
                } catch (error) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(
                      dialogContext,
                    ).showSnackBar(SnackBar(content: Text(error.toString())));
                  }
                }
              },
              child: const Text('Tạo'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();

    if (result == true) {
      await loadData();
    }
  }

  // Đổi tên nhóm.
  Future<void> showRenameGroupDialog(String groupId, String currentName) async {
    final nameController = TextEditingController(text: currentName);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Đổi tên nhóm'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Tên nhóm mới'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                final newName = nameController.text.trim();

                if (newName.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Tên nhóm không được để trống.'),
                    ),
                  );
                  return;
                }

                try {
                  await VocabularyGroupService.renameGroup(
                    groupId: groupId,
                    newName: newName,
                  );

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, true);
                  }
                } catch (error) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(
                      dialogContext,
                    ).showSnackBar(SnackBar(content: Text(error.toString())));
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );

    nameController.dispose();

    if (result == true) {
      await loadData();
    }
  }

  // Xóa nhóm.
  Future<void> deleteGroup(String groupId, String groupName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa nhóm?'),
        content: Text('Bạn có chắc muốn xóa nhóm "$groupName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await VocabularyGroupService.deleteGroup(groupId);
      await loadData();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  // Thẻ nhóm.
  Widget buildGroupCard(Map<String, dynamic> group) {
    final groupId = group['id'].toString();
    final groupName = group['name']?.toString() ?? 'Nhóm chưa đặt tên';
    final itemCount = getGroupItemCount(group);

    final updatedAt = group['updated_at'] ?? group['created_at'];
    final dateText = formatDate(updatedAt);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE8EEEE)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  VocabularyWordsPage(groupId: groupId, title: groupName),
            ),
          ).then((_) => loadData());
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2EE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.folder_rounded,
                      color: primaryColor,
                      size: 21,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 21,
                    tooltip: 'Tùy chọn',
                    onSelected: (value) {
                      if (value == 'rename') {
                        showRenameGroupDialog(groupId, groupName);
                      } else if (value == 'delete') {
                        deleteGroup(groupId, groupName);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Đổi tên'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Xóa nhóm',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                groupName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF263238),
                ),
              ),

              const Spacer(),

              const Divider(height: 14, thickness: 1, color: Color(0xFFEEF1F1)),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$itemCount mục',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF526565),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      dateText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF899696),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Dữ liệu đã lưu'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Tất cả mục đã lưu.
                  Card(
                    color: Colors.white,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE0F2EE),
                        child: Icon(Icons.bookmark, color: primaryColor),
                      ),
                      title: const Text(
                        'Tất cả mục đã lưu',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('$savedWordCount mục đã lưu'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VocabularyWordsPage(
                              title: 'Tất cả mục đã lưu',
                            ),
                          ),
                        ).then((_) => loadData());
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tiêu đề nhóm.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nhóm của tôi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: showCreateGroupDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Tạo nhóm'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (groups.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(Icons.folder_open, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Bạn chưa có nhóm từ vựng nào.'),
                          Text(
                            'Hãy tạo nhóm đầu tiên!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: groups.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 150,
                          ),
                      itemBuilder: (context, index) {
                        return buildGroupCard(groups[index]);
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
