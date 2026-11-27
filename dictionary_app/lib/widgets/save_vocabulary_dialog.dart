
import 'package:flutter/material.dart';

import '../services/vocabulary_group_service.dart';
import '../services/saved_vocabulary_service.dart';

class SaveVocabularyDialog extends StatefulWidget {
  final Map<String, dynamic> word;

  const SaveVocabularyDialog({
    super.key,
    required this.word,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Map<String, dynamic> word,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => SaveVocabularyDialog(word: word),
    );
  }

  @override
  State<SaveVocabularyDialog> createState() =>
      _SaveVocabularyDialogState();
}

class _SaveVocabularyDialogState
    extends State<SaveVocabularyDialog> {
  List<Map<String, dynamic>> groups = [];

  final Set<String> selectedGroupIds = {};
  final Set<String> initialGroupIds = {};

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadGroups();
  }

  Future<void> loadGroups() async {
    try {
      final groupsResult =
          await VocabularyGroupService.getGroups();

      final savedGroupIds =
          await SavedVocabularyService.getSavedGroupIds(
        wordId: widget.word['id'],
      );

      if (!mounted) return;

      setState(() {
        groups = groupsResult;
        selectedGroupIds.addAll(savedGroupIds);
        initialGroupIds.addAll(savedGroupIds);
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> createNewGroup() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tạo nhóm mới'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Tên nhóm',
            hintText: 'Ví dụ: JLPT N2',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (name == null || name.isEmpty) return;

    try {
      final newGroup =
          await VocabularyGroupService.createGroup(name: name);

      if (!mounted) return;

      final newGroupId = newGroup['id'].toString();

      setState(() {
        groups.insert(0, newGroup);
        selectedGroupIds.add(newGroupId);
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  bool get hasAddedGroups =>
      selectedGroupIds.difference(initialGroupIds).isNotEmpty;

  bool get hasRemovedGroups =>
      initialGroupIds.difference(selectedGroupIds).isNotEmpty;

  bool get hasChanges => hasAddedGroups || hasRemovedGroups;

  String get actionLabel {
    if (!hasChanges) return 'Đóng';

    if (hasRemovedGroups && !hasAddedGroups) {
      return 'Gỡ khỏi nhóm';
    }

    if (hasAddedGroups && hasRemovedGroups) {
      return 'Lưu thay đổi';
    }

    return 'Lưu';
  }

  Future<void> saveWord() async {
    if (!hasChanges) {
      Navigator.pop(context, false);
      return;
    }

    setState(() {
      isSaving = true;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      await SavedVocabularyService.updateWordGroups(
        word: widget.word,
        groupIds: selectedGroupIds.toList(),
      );

      if (!mounted) return;

      String message;

      if (hasAddedGroups && hasRemovedGroups) {
        message = 'Đã cập nhật các nhóm thành công!';
      } else if (hasRemovedGroups) {
        message = 'Đã gỡ từ khỏi nhóm thành công!';
      } else {
        message = 'Đã lưu từ vào nhóm thành công!';
      }

      Navigator.pop(context, true);

      messenger.showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      messenger.showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  String get wordTitle {
    final kanji = List<String>.from(widget.word['kanji'] ?? []);
    final kana = List<String>.from(widget.word['kana'] ?? []);

    if (kanji.isNotEmpty) return kanji.first;
    if (kana.isNotEmpty) return kana.first;

    return 'Từ vựng';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quản lý nhóm từ vựng'),
      content: SizedBox(
        width: 360,
        child: isLoading
            ? const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wordTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chọn nhóm muốn lưu từ:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (groups.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Bạn chưa có nhóm nào. Hãy tạo nhóm mới.',
                      ),
                    )
                  else
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: groups.map((group) {
                            final id = group['id'].toString();

                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(group['name'] ?? ''),
                              value: selectedGroupIds.contains(id),
                              activeColor:
                                  const Color(0xFF35A995),
                              controlAffinity:
                                  ListTileControlAffinity.leading,
                              onChanged: isSaving
                                  ? null
                                  : (checked) {
                                      setState(() {
                                        if (checked == true) {
                                          selectedGroupIds.add(id);
                                        } else {
                                          selectedGroupIds.remove(id);
                                        }
                                      });
                                    },
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  TextButton.icon(
                    onPressed: isSaving ? null : createNewGroup,
                    icon: const Icon(
                      Icons.create_new_folder_outlined,
                    ),
                    label: const Text('Tạo nhóm mới'),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving
              ? null
              : () => Navigator.pop(context, false),
          child: const Text('Đóng'),
        ),
        FilledButton(
          onPressed: isLoading || isSaving ? null : saveWord,
          child: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Text(actionLabel),
        ),
      ],
    );
  }
}
