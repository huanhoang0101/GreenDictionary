
import 'package:flutter/material.dart';

import '../services/saved_vocabulary_service.dart';
import '../widgets/save_vocabulary_dialog.dart';
import '../widgets/save_grammar_dialog.dart';
import 'word_detail_page.dart';
import 'grammar_detail_page.dart';
import 'flashcard_page.dart';

class VocabularyWordsPage extends StatefulWidget {
  final String? groupId;
  final String title;

  const VocabularyWordsPage({
    super.key,
    this.groupId,
    required this.title,
  });

  @override
  State<VocabularyWordsPage> createState() => _VocabularyWordsPageState();
}

class _VocabularyWordsPageState extends State<VocabularyWordsPage> {
  List<Map<String, dynamic>> words = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadWords();
  }

  Future<void> loadWords() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = widget.groupId == null
          ? await SavedVocabularyService.getAllSavedItems()
          : await SavedVocabularyService.getItemsInGroup(
              widget.groupId!,
            );

      if (!mounted) return;

      setState(() {
        words = result;
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

  bool isGrammar(
    Map<String, dynamic> savedItem,
    Map<String, dynamic> itemData,
  ) {
    final wordKey = savedItem['word_key']?.toString() ?? '';

    return itemData['type'] == 'grammar' ||
        wordKey.startsWith('openjlpt:');
  }

  String getJapaneseWord(Map<String, dynamic> word) {
    final kanji = List<String>.from(word['kanji'] ?? []);
    final kana = List<String>.from(word['kana'] ?? []);

    if (kanji.isNotEmpty) return kanji.join('、');
    if (kana.isNotEmpty) return kana.join('、');

    return 'Không có dữ liệu';
  }

  String getReading(Map<String, dynamic> word) {
    final kana = List<String>.from(word['kana'] ?? []);
    return kana.join('、');
  }

  String getMeanings(Map<String, dynamic> word) {
    final meanings = List<String>.from(word['meanings'] ?? []);

    if (meanings.isEmpty) return 'Chưa có nghĩa';

    return meanings.join(', ');
  }

  String getGrammarMeaning(Map<String, dynamic> grammar) {
    final meaning = grammar['meaning'];

    if (meaning == null || meaning.toString().isEmpty) {
      return 'Chưa có nghĩa';
    }

    return meaning.toString();
  }

  String getGrammarTitle(Map<String, dynamic> grammar) {
    return grammar['pattern']?.toString() ?? 'Ngữ pháp';
  }

  Future<void> removeWord(String savedWordId) async {
    if (widget.groupId == null) return;

    try {
      await SavedVocabularyService.removeItemFromGroup(
        groupId: widget.groupId!,
        savedItemId: savedWordId,
      );

      if (!mounted) return;

      setState(() {
        words.removeWhere(
          (word) => word['id'].toString() == savedWordId,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa mục khỏi nhóm.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> manageItemGroups({
    required Map<String, dynamic> itemData,
    required bool grammar,
  }) async {
    final result = grammar
        ? await SaveGrammarDialog.show(
            context,
            grammar: itemData,
          )
        : await SaveVocabularyDialog.show(
            context,
            word: itemData,
          );

    if (!mounted) return;

    if (result == true) {
      await loadWords();
    }
  }

  void openDetail({
  required Map<String, dynamic> itemData,
  required bool grammar,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => grammar
          ? GrammarDetailPage(id: itemData['id'])
          : WordDetailPage(word: itemData),
    ),
  );
}

void startReview() {
  if (words.isEmpty) return;

  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      builder: (context) => FlashcardPage(
        savedItems: words,
        title: 'Ôn tập - ${widget.title}',
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF35A995);

    return Scaffold(
      appBar: AppBar(
  title: Text(widget.title),
  actions: [
    IconButton(
      tooltip: 'Ôn tập',
      onPressed: words.isEmpty ? null : startReview,
      icon: const Icon(Icons.style),
    ),
    IconButton(
      tooltip: 'Làm mới',
      onPressed: loadWords,
      icon: const Icon(Icons.refresh),
    ),
  ],
),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : words.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 56,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text('Chưa có mục nào được lưu.'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadWords,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: words.length,
                    itemBuilder: (context, index) {
                      final savedItem = words[index];

                      final itemData = Map<String, dynamic>.from(
                        savedItem['word_data'] ?? {},
                      );

                      //final savedItemId = savedItem['id'].toString();

                      final grammar = isGrammar(
                        savedItem,
                        itemData,
                      );

                      final title = grammar
                          ? getGrammarTitle(itemData)
                          : getJapaneseWord(itemData);

                      final subtitle = grammar
                          ? getGrammarMeaning(itemData)
                          : getMeanings(itemData);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          onTap: () {
                            openDetail(
                              itemData: itemData,
                              grammar: grammar,
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: grammar
                                ? const Color(0xFFE8EAF6)
                                : const Color(0xFFE0F2EE),
                            child: Icon(
                              grammar
                                  ? Icons.translate
                                  : Icons.menu_book,
                              color: grammar
                                  ? const Color(0xFF5965A8)
                                  : primaryColor,
                            ),
                          ),
                          title: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (grammar) ...[
                                  Text(
                                    'JLPT ${itemData['level'] ?? ''}',
                                    style: const TextStyle(
                                      color: Color(0xFF5965A8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ] else if (getReading(itemData).isNotEmpty) ...[
                                  Text(getReading(itemData)),
                                  const SizedBox(height: 4),
                                ],
                                Text(
                                  subtitle,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: grammar
                                        ? const Color(0xFFE8EAF6)
                                        : const Color(0xFFE0F2EE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    grammar ? 'Ngữ pháp' : 'Từ vựng',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: grammar
                                          ? const Color(0xFF5965A8)
                                          : primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: IconButton(
                            tooltip: 'Quản lý nhóm',
                            icon: const Icon(
                              Icons.bookmark,
                              color: primaryColor,
                            ),
                            onPressed: () {
                              manageItemGroups(
                                itemData: itemData,
                                grammar: grammar,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

