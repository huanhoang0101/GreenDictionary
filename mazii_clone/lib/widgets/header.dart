import 'package:flutter/material.dart';

import '../localization/app_language.dart';
import '../localization/app_strings.dart';
import 'language_selector.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, language, child) {
        final strings = AppStrings(language);

        return Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 750;

                  return Row(
                    children: [
                      // Logo
                      Row(
                        children: [
                          const Icon(
                            Icons.menu_book_rounded,
                            color: Color(0xFF35A995),
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            strings.appName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF263238),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      if (!isMobile) ...[
                        _menuButton(strings.dictionary),
                        _menuButton(strings.kanji),
                        _menuButton(strings.grammar),
                        _menuButton(strings.practice),

                        const SizedBox(width: 12),

                        TextButton(
                          onPressed: () {},
                          child: Text(strings.login),
                        ),

                        const SizedBox(width: 4),

                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF35A995),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(strings.register),
                        ),

                        const SizedBox(width: 12),
                      ],

                      const LanguageSelector(),

                      if (isMobile) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () {
                            _showMobileMenu(context, strings);
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _menuButton(String title) {
    return TextButton(
      onPressed: () {},
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF455A64),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showMobileMenu(BuildContext context, AppStrings strings) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(strings.dictionary),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                title: Text(strings.kanji),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                title: Text(strings.grammar),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                title: Text(strings.practice),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                title: Text(strings.login),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                title: Text(strings.register),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
