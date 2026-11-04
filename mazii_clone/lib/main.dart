import 'package:flutter/material.dart';

import 'localization/app_language.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const JapaneseDictionaryApp());
}

class JapaneseDictionaryApp extends StatelessWidget {
  const JapaneseDictionaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appLanguage,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Nihongo Dictionary',

          theme: ThemeData(
            primaryColor: const Color(0xFF35A995),
            scaffoldBackgroundColor: const Color(0xFFF7F9FA),
            fontFamily: 'Arial',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF35A995),
            ),
          ),

          home: const HomePage(),
        );
      },
    );
  }
}