import 'package:flutter/material.dart';

enum AppLanguage {
  vi,
  ja,
  en,
}

final ValueNotifier<AppLanguage> appLanguage =
    ValueNotifier<AppLanguage>(AppLanguage.vi);

void changeLanguage(AppLanguage language) {
  appLanguage.value = language;
}