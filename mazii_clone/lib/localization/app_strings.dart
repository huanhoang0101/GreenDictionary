import 'app_language.dart';

class AppStrings {
  final AppLanguage language;

  AppStrings(this.language);

  String get appName => _get(
    'Nihongo',
    '日本語辞典',
    'Nihongo Dictionary',
  );

  String get dictionary => _get('Từ điển', '辞書', 'Dictionary');
  String get kanji => _get('Kanji', '漢字', 'Kanji');
  String get grammar => _get('Ngữ pháp', '文法', 'Grammar');
  String get practice => _get('Luyện tập', '練習', 'Practice');
  String get login => _get('Đăng nhập', 'ログイン', 'Login');
  String get register => _get('Đăng ký', '新規登録', 'Register');

  String get heroTitle => _get(
    'Cùng bạn chinh phục tiếng Nhật',
    '日本語学習を一緒に頑張りましょう',
    'Master Japanese with Us',
  );

  String get heroSubtitle => _get(
    'Tra cứu từ vựng, học Kanji và luyện thi JLPT',
    '単語検索、漢字学習、JLPT対策',
    'Look up words, learn Kanji and prepare for JLPT',
  );

  String get searchHint => _get(
    'Nhập từ tiếng Nhật hoặc tiếng Anh...',
    '日本語または英語を入力してください...',
    'Enter Japanese or English...',
  );

  String get searchButton => _get('Tra cứu', '検索', 'Search');

  String get featuresTitle => _get(
    'Khám phá các tính năng',
    '学習機能',
    'Explore Learning Features',
  );

  String get dailyVocabulary => _get(
    'Từ vựng mỗi ngày',
    '今日の単語',
    'Words of the Day',
  );

  String get footerDescription => _get(
    'Người bạn đồng hành trên hành trình học tiếng Nhật',
    '日本語学習をサポートする辞書アプリ',
    'Your companion for learning Japanese',
  );

  String get footerCopyright => _get(
    '© 2026 Nihongo Dictionary. All rights reserved.',
    '© 2026 Nihongo Dictionary. All rights reserved.',
    '© 2026 Nihongo Dictionary. All rights reserved.',
  );

  String get featureDictionaryTitle =>
      _get('Từ điển', '辞書', 'Dictionary');

  String get featureDictionaryDescription => _get(
    'Tra cứu từ vựng Nhật - Anh',
    '日本語・英語の単語を検索',
    'Search Japanese and English words',
  );

  String get featureKanjiTitle => _get('Kanji', '漢字', 'Kanji');

  String get featureKanjiDescription => _get(
    'Học chữ Hán và cách đọc',
    '漢字と読み方を学ぶ',
    'Learn Kanji and readings',
  );

  String get featureGrammarTitle =>
      _get('Ngữ pháp', '文法', 'Grammar');

  String get featureGrammarDescription => _get(
    'Học cấu trúc ngữ pháp Nhật',
    '日本語の文法を学ぶ',
    'Learn Japanese grammar',
  );

  String get featureJlptTitle => _get('JLPT', 'JLPT', 'JLPT');

  String get featureJlptDescription => _get(
    'Luyện thi từ N5 đến N1',
    'N5からN1までの試験対策',
    'Prepare for JLPT N5 to N1',
  );

  String get featureFlashcardTitle =>
      _get('Flashcard', '単語カード', 'Flashcards');

  String get featureFlashcardDescription => _get(
    'Ghi nhớ từ vựng hiệu quả',
    '単語を効率よく覚える',
    'Memorize vocabulary effectively',
  );

  String get featureVocabularyTitle =>
      _get('Sổ từ vựng', '単語帳', 'My Vocabulary');

  String get featureVocabularyDescription => _get(
    'Lưu từ yêu thích của bạn',
    'お気に入りの単語を保存',
    'Save your favorite words',
  );

  String get vocabularyMeaning1 =>
      _get('Học tập', '勉強すること', 'Study');

  String get vocabularyMeaning2 =>
      _get('Kinh nghiệm', '経験', 'Experience');

  String get vocabularyMeaning3 =>
      _get('Thử thách', '挑戦', 'Challenge');

  String get vocabularyExample1 => _get(
    'Tôi đang học tiếng Nhật.',
    '日本語を勉強しています。',
    'I am studying Japanese.',
  );

  String get vocabularyExample2 => _get(
    'Đó là một kinh nghiệm tốt.',
    'いい経験になりました。',
    'It was a good experience.',
  );

  String get vocabularyExample3 => _get(
    'Tôi sẽ thử thách bản thân với những điều mới.',
    '新しいことに挑戦します。',
    'I will challenge myself with new things.',
  );

  String _get(String vi, String ja, String en) {
    switch (language) {
      case AppLanguage.vi:
        return vi;
      case AppLanguage.ja:
        return ja;
      case AppLanguage.en:
        return en;
    }
  }
}