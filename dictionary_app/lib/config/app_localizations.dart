
class AppLocalizations {
  final String languageCode;

  const AppLocalizations(this.languageCode);

  static const Map<String, Map<String, String>> _texts = {
    'vi': {
      // Header
      'dictionary': 'Từ điển',
      'grammar': 'Ngữ pháp',
      'kanji': 'Kanji',
      'jlpt': 'JLPT',
      'login': 'Đăng nhập',
      'register': 'Đăng ký',
      'choose_language': 'Chọn ngôn ngữ giao diện',

      // Search
      'hero_title': '日本語をもっと楽しく。',
      'hero_subtitle': 'Tra cứu từ vựng tiếng Nhật dễ dàng',
      'search_hint': 'Nhập từ tiếng Nhật hoặc tiếng Anh...',
      'search_button': 'Tra cứu',

      // Categories
      'japanese_english': 'Nhật - Anh',
      'kanji_category': 'Kanji',
      'grammar_category': 'Ngữ pháp',
      'jlpt_category': 'JLPT',

      // Welcome
      'welcome': 'Chào mừng bạn đến với Nihongo!',
      'welcome_desc': 'Bắt đầu bằng cách tìm kiếm một từ.',

      // Results
      'search_results': 'Kết quả tìm kiếm',
      'no_results': 'Không tìm thấy từ vựng.',
      'try_another': 'Hãy thử tìm kiếm bằng từ khóa khác.',
      'favorite': 'Yêu thích',
      'unfavorite': 'Bỏ yêu thích',
      'english_meanings': 'Nghĩa tiếng Anh',
      'no_english_meaning': 'Chưa có nghĩa tiếng Anh.',
      'search_error': 'Không thể tải dữ liệu. Hãy kiểm tra kết nối API.',

      // Detail
      'word_detail': 'Chi tiết từ vựng',
      'dictionary_id': 'Mã từ điển',
    },

    'ja': {
      // Header
      'dictionary': '辞書',
      'grammar': '文法',
      'kanji': '漢字',
      'jlpt': 'JLPT',
      'login': 'ログイン',
      'register': '新規登録',
      'choose_language': '表示言語を選択',

      // Search
      'hero_title': '日本語をもっと楽しく。',
      'hero_subtitle': '日本語の単語を簡単に検索できます',
      'search_hint': '日本語または英語を入力してください...',
      'search_button': '検索',

      // Categories
      'japanese_english': '日英辞書',
      'kanji_category': '漢字',
      'grammar_category': '文法',
      'jlpt_category': 'JLPT',

      // Welcome
      'welcome': 'Nihongoへようこそ！',
      'welcome_desc': '調べたい単語を入力してください。',

      // Results
      'search_results': '検索結果',
      'no_results': '単語が見つかりません。',
      'try_another': '別のキーワードで検索してください。',
      'favorite': 'お気に入り',
      'unfavorite': 'お気に入り解除',
      'english_meanings': '英語の意味',
      'no_english_meaning': '英語の意味がありません。',
      'search_error': 'データを取得できません。APIの接続を確認してください。',

      // Detail
      'word_detail': '単語の詳細',
      'dictionary_id': '辞書ID',
    },

    'en': {
      // Header
      'dictionary': 'Dictionary',
      'grammar': 'Grammar',
      'kanji': 'Kanji',
      'jlpt': 'JLPT',
      'login': 'Login',
      'register': 'Register',
      'choose_language': 'Choose interface language',

      // Search
      'hero_title': 'Make learning Japanese fun.',
      'hero_subtitle': 'Search Japanese vocabulary easily',
      'search_hint': 'Enter Japanese or English...',
      'search_button': 'Search',

      // Categories
      'japanese_english': 'Japanese - English',
      'kanji_category': 'Kanji',
      'grammar_category': 'Grammar',
      'jlpt_category': 'JLPT',

      // Welcome
      'welcome': 'Welcome to Nihongo!',
      'welcome_desc': 'Start by searching for a word.',

      // Results
      'search_results': 'Search results',
      'no_results': 'No vocabulary found.',
      'try_another': 'Try searching with another keyword.',
      'favorite': 'Favorite',
      'unfavorite': 'Remove favorite',
      'english_meanings': 'English meanings',
      'no_english_meaning': 'No English meaning available.',
      'search_error': 'Unable to load data. Please check the API connection.',

      // Detail
      'word_detail': 'Word details',
      'dictionary_id': 'Dictionary ID',
    },
  };

  String text(String key) {
    return _texts[languageCode]?[key] ??
        _texts['vi']?[key] ??
        key;
  }
}
