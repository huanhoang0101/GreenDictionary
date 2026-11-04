import 'package:flutter/material.dart';

import '../localization/app_language.dart';
import '../localization/app_strings.dart';

import '../widgets/header.dart';
import '../widgets/search_section.dart';
import '../widgets/feature_section.dart';
import '../widgets/vocabulary_section.dart';
import '../widgets/footer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, language, child) {
        final strings = AppStrings(language);

        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const Header(),

                const SizedBox(height: 32),
                SearchSection(key: ValueKey(language)),

                const SizedBox(height: 40),
                const FeatureSection(),

                const SizedBox(height: 40),
                VocabularySection(strings: strings),

                const SizedBox(height: 48),
                Footer(strings: strings),
              ],
            ),
          ),
        );
      },
    );
  }
}