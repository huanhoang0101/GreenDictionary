
import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../services/dictionary_service.dart';
import '../pages/word_detail_page.dart';

class VocabularySection extends StatefulWidget {
  final AppStrings strings;

  const VocabularySection({
    super.key,
    required this.strings,
  });

  @override
  State<VocabularySection> createState() => _VocabularySectionState();
}

class _VocabularySectionState extends State<VocabularySection> {
  static const Color primaryColor = Color(0xFF35A995);
  static const Color darkColor = Color(0xFF263238);

  final DictionaryService _dictionaryService = DictionaryService();

  List<dynamic> words = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadRandomWords();
  }

  // Tải từ ngẫu nhiên từ backend.
  Future<void> loadRandomWords() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _dictionaryService.getRandomWords();

      if (!mounted) return;

      setState(() {
        words = result;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  // Mở trang chi tiết từ vựng.
  void openWordDetail(Map<String, dynamic> word) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WordDetailPage(word: word),
      ),
    );
  }

  // Lấy cách viết tiếng Nhật để hiển thị.
  String getWordText(Map<String, dynamic> word) {
    final kanji = word['kanji'] as List<dynamic>? ?? [];
    final kana = word['kana'] as List<dynamic>? ?? [];

    if (kanji.isNotEmpty) {
      return kanji.first.toString();
    }

    if (kana.isNotEmpty) {
      return kana.first.toString();
    }

    return '';
  }

  // Lấy cách đọc.
  String getReading(Map<String, dynamic> word) {
    final kana = word['kana'] as List<dynamic>? ?? [];

    if (kana.isNotEmpty) {
      return kana.first.toString();
    }

    return '';
  }

  // Lấy nghĩa tiếng Anh.
  String getMeaning(Map<String, dynamic> word) {
    final meanings = word['meanings'] as List<dynamic>? ?? [];

    if (meanings.isEmpty) {
      return 'No meaning available';
    }

    return meanings.take(2).join(', ');
  }

  // Tạo thẻ từ vựng có thể nhấn.
  Widget buildWordCard(Map<String, dynamic> word) {
    final wordText = getWordText(word);
    final reading = getReading(word);
    final meaning = getMeaning(word);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openWordDetail(word),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE8EEEE),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                wordText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: darkColor,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                reading,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                meaning,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.strings.dailyVocabulary,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: darkColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: isLoading ? null : loadRandomWords,
                    tooltip: 'Đổi từ vựng',
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  ),
                )
              else if (errorMessage != null)
                Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 36,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      const Text('Không thể tải từ vựng.'),
                      TextButton(
                        onPressed: loadRandomWords,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              else if (words.isEmpty)
                const Center(
                  child: Text('Chưa có từ vựng để hiển thị.'),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: words.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 150,
                  ),
                  itemBuilder: (context, index) {
                    final word = Map<String, dynamic>.from(
                      words[index] as Map,
                    );

                    return buildWordCard(word);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
