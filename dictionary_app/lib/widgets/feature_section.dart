
import 'package:flutter/material.dart';
import '../localization/app_language.dart';
import '../localization/app_strings.dart';

class FeatureSection extends StatelessWidget {
  const FeatureSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, language, child) {
        final strings = AppStrings(language);

        final features = [
          {
            'icon': Icons.menu_book_rounded,
            'title': strings.featureDictionaryTitle,
            'description': strings.featureDictionaryDescription,
          },
          {
            'icon': Icons.translate_rounded,
            'title': strings.featureKanjiTitle,
            'description': strings.featureKanjiDescription,
          },
          {
            'icon': Icons.edit_note_rounded,
            'title': strings.featureGrammarTitle,
            'description': strings.featureGrammarDescription,
          },
          {
            'icon': Icons.school_rounded,
            'title': strings.featureJlptTitle,
            'description': strings.featureJlptDescription,
          },
          {
            'icon': Icons.style_rounded,
            'title': strings.featureFlashcardTitle,
            'description': strings.featureFlashcardDescription,
          },
          {
            'icon': Icons.bookmark_rounded,
            'title': strings.featureVocabularyTitle,
            'description': strings.featureVocabularyDescription,
          },
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                children: [
                  Text(
                    strings.featuresTitle,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int columns = 3;

                      if (constraints.maxWidth < 600) {
                        columns = 1;
                      } else if (constraints.maxWidth < 900) {
                        columns = 2;
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: features.length,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: columns == 1 ? 3.2 : 2.0,
                        ),
                        itemBuilder: (context, index) {
                          final feature = features[index];

                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.shade200,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF35A995)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    feature['icon'] as IconData,
                                    color: const Color(0xFF35A995),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        feature['title'] as String,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        feature['description'] as String,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
