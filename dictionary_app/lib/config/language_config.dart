
class LanguageOption {
  final String code;
  final String name;

  const LanguageOption({
    required this.code,
    required this.name,
  });
}

class LanguageConfig {
  static const List<LanguageOption> languages = [
    LanguageOption(code: 'vi', name: 'Tiếng Việt'),
    LanguageOption(code: 'ja', name: '日本語'),
    LanguageOption(code: 'en', name: 'English'),
  ];
}
