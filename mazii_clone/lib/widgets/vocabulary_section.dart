import 'package:flutter/material.dart';
import '../localization/app_strings.dart';

class VocabularySection extends StatelessWidget {
  final AppStrings strings;

  const VocabularySection({
    super.key,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final words = [
      {
        'word': '勉強',
        'reading': 'べんきょう',
        'meaning': strings.vocabularyMeaning1,
        'example': '日本語を勉強しています。',
        'translation': strings.vocabularyExample1,
      },
      {
        'word': '経験',
        'reading': 'けいけん',
        'meaning': strings.vocabularyMeaning2,
        'example': 'いい経験になりました。',
        'translation': strings.vocabularyExample2,
      },
      {
        'word': '挑戦',
        'reading': 'ちょうせん',
        'meaning': strings.vocabularyMeaning3,
        'example': '新しいことに挑戦します。',
        'translation': strings.vocabularyExample3,
      },
    ];

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
              Text(
                strings.dailyVocabulary,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),

              const SizedBox(height: 24),

              ...words.map((word) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  word['word']!,
                                  style: const TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF263238),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  word['reading']!,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            Text(
                              word['meaning']!,
                              style: const TextStyle(
                                color: Color(0xFF35A995),
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(word['example']!),

                            const SizedBox(height: 4),

                            Text(
                              word['translation']!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.bookmark_border_rounded,
                          color: Color(0xFF35A995),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}