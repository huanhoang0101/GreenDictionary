import 'package:flutter/material.dart';

import '../localization/app_language.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, language, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButton<AppLanguage>(
            value: language,
            underline: const SizedBox(),
            borderRadius: BorderRadius.circular(12),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            items: const [
              DropdownMenuItem(
                value: AppLanguage.vi,
                child: Text('🇻🇳 Tiếng Việt'),
              ),
              DropdownMenuItem(
                value: AppLanguage.ja,
                child: Text('🇯🇵 日本語'),
              ),
              DropdownMenuItem(
                value: AppLanguage.en,
                child: Text('🇬🇧 English'),
              ),
            ],
            onChanged: (newLanguage) {
              if (newLanguage != null) {
                changeLanguage(newLanguage);
              }
            },
          ),
        );
      },
    );
  }
}