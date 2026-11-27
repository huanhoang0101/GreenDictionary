
import 'package:flutter/material.dart';

import '../localization/app_language.dart';
import '../services/dictionary_service.dart';
import '../widgets/save_vocabulary_dialog.dart';
import 'login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WordDetailPage extends StatefulWidget {
  final Map<String, dynamic> word;

  const WordDetailPage({
    super.key,
    required this.word,
  });

  @override
  State<WordDetailPage> createState() => _WordDetailPageState();
}

class _WordDetailPageState extends State<WordDetailPage> {
  final DictionaryService _dictionaryService = DictionaryService();

  late Future<Map<String, dynamic>> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadWordDetail();
  }

  Future<Map<String, dynamic>> _loadWordDetail() async {
    final id = widget.word['id'];

    if (id == null) {
      return widget.word;
    }

    try {
      return await _dictionaryService.getWordDetail(id.toString());
    } catch (_) {
      // Nếu không lấy được dữ liệu đầy đủ,
      // vẫn hiển thị dữ liệu tóm tắt đang có.
      return widget.word;
    }
  }

  List<Map<String, dynamic>> _asMaps(dynamic value) {
    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<String> _extractTexts(dynamic value) {
    if (value is! List) return [];

    return value.map((item) {
      if (item is String) return item;
      if (item is Map) return item['text']?.toString() ?? '';
      return '';
    }).where((text) => text.isNotEmpty).toList();
  }

  List<Map<String, dynamic>> _getSenses(Map<String, dynamic> word) {
    final value = word['sense'] ?? word['senses'];
    return _asMaps(value);
  }

  List<String> _getMeanings(Map<String, dynamic> word) {
    final existing = word['meanings'];

    if (existing is List && existing.isNotEmpty) {
      return existing.map((e) {
        if (e is Map) return e['text']?.toString() ?? '';
        return e.toString();
      }).where((e) => e.isNotEmpty).toList();
    }

    final results = <String>[];

    for (final sense in _getSenses(word)) {
      final glosses = sense['gloss'];

      if (glosses is! List) continue;

      for (final gloss in glosses) {
        if (gloss is String) {
          results.add(gloss);
        } else if (gloss is Map) {
          final language = gloss['lang']?.toString() ?? 'eng';
          final text = gloss['text']?.toString() ?? '';

          if (language == 'eng' && text.isNotEmpty) {
            results.add(text);
          }
        }
      }
    }

    return results.toSet().toList();
  }

  String _label(
    AppLanguage language,
    String vi,
    String ja,
    String en,
  ) {
    switch (language) {
      case AppLanguage.vi:
        return vi;
      case AppLanguage.ja:
        return ja;
      case AppLanguage.en:
        return en;
    }
  }

  String _translateMetadataTag(
  String tag,
  String category,
  AppLanguage language,
) {
  const miscTranslations = {
    'arch': ['Cổ / cổ ngữ', '古語', 'Archaic'],
    'obs': ['Lỗi thời', '廃語', 'Obsolete'],
    'sl': ['Tiếng lóng', '俗語', 'Slang'],
    'vulg': ['Thô tục', '卑語', 'Vulgar'],
    'col': ['Khẩu ngữ', '口語', 'Colloquial'],
    'hon': ['Kính ngữ', '敬語', 'Honorific'],
    'hum': ['Khiêm nhường ngữ', '謙譲語', 'Humble language'],
    'pol': ['Lịch sự', '丁寧語', 'Polite'],
    'derog': ['Mang nghĩa xúc phạm', '軽蔑的', 'Derogatory'],
    'fam': ['Thân mật', 'くだけた表現', 'Familiar'],
    'joc': ['Nói đùa', '冗談めいた表現', 'Jocular'],
    'poet': ['Văn phong thơ ca', '詩語', 'Poetic'],
    'rare': ['Hiếm gặp', 'まれ', 'Rare'],
    'dated': ['Cách dùng cũ', '古風な表現', 'Dated'],
    'abbr': ['Viết tắt', '略語', 'Abbreviation'],
    'male': ['Cách nói của nam giới', '男性語', 'Male speech'],
    'fem': ['Cách nói của nữ giới', '女性語', 'Female speech'],
    'on-mim': ['Từ tượng thanh / tượng hình', '擬音語・擬態語', 'Onomatopoeic'],
  };

  const fieldTranslations = {
    'comp': ['Máy tính', 'コンピューター', 'Computing'],
    'math': ['Toán học', '数学', 'Mathematics'],
    'med': ['Y học', '医学', 'Medicine'],
    'ling': ['Ngôn ngữ học', '言語学', 'Linguistics'],
    'econ': ['Kinh tế học', '経済学', 'Economics'],
    'law': ['Luật pháp', '法律', 'Law'],
    'chem': ['Hóa học', '化学', 'Chemistry'],
    'physics': ['Vật lý', '物理学', 'Physics'],
    'biol': ['Sinh học', '生物学', 'Biology'],
    'sports': ['Thể thao', 'スポーツ', 'Sports'],
    'music': ['Âm nhạc', '音楽', 'Music'],
    'geogr': ['Địa lý', '地理', 'Geography'],
    'food': ['Ẩm thực', '食品・料理', 'Food'],
    'bus': ['Kinh doanh', 'ビジネス', 'Business'],
    'mil': ['Quân sự', '軍事', 'Military'],
  };

  final translations = category == 'misc'
      ? miscTranslations
      : fieldTranslations;

  final values = translations[tag];

  if (values == null) return tag;

  switch (language) {
    case AppLanguage.vi:
      return values[0];
    case AppLanguage.ja:
      return values[1];
    case AppLanguage.en:
      return values[2];
  }
}

String _translateTag(String tag, AppLanguage language) {
  const translations = {
    'n': ['Danh từ', '名詞', 'Noun'],
    'n-adv': ['Danh từ dùng như trạng từ', '副詞的名詞', 'Adverbial noun'],
    'n-suf': ['Danh từ hậu tố', '接尾辞としての名詞', 'Noun suffix'],
    'n-pref': ['Danh từ tiền tố', '接頭辞としての名詞', 'Noun prefix'],
    'v1': ['Động từ nhóm 2', '一段動詞', 'Ichidan verb'],
    'v5': ['Động từ nhóm 1', '五段動詞', 'Godan verb'],
    'v5u': ['Động từ nhóm 1 kết thúc bằng う', '五段動詞・う', 'Godan verb ending in u'],
    'vs': ['Động từ する', 'サ変動詞', 'Suru verb'],
    'vk': ['Động từ 来る', 'カ変動詞', 'Kuru verb'],
    'adj-i': ['Tính từ đuôi い', 'い形容詞', 'い-adjective'],
    'adj-na': ['Tính từ đuôi な', 'な形容詞', 'な-adjective'],
    'adv': ['Trạng từ', '副詞', 'Adverb'],
    'prt': ['Trợ từ', '助詞', 'Particle'],
    'exp': ['Cụm từ / Thành ngữ', '表現・慣用句', 'Expression / Idiom'],
    'int': ['Thán từ', '感動詞', 'Interjection'],
    'pn': ['Đại từ', '代名詞', 'Pronoun'],
    'pref': ['Tiền tố', '接頭辞', 'Prefix'],
    'suf': ['Hậu tố', '接尾辞', 'Suffix'],
    'conj': ['Liên từ', '接続詞', 'Conjunction'],
    'cop': ['Động từ liên kết', 'コピュラ', 'Copula'],
  };

  final values = translations[tag];

  if (values == null) return tag;

  switch (language) {
    case AppLanguage.vi:
      return values[0];
    case AppLanguage.ja:
      return values[1];
    case AppLanguage.en:
      return values[2];
  }
}


  Future<void> _saveWord(
    BuildContext context,
    Map<String, dynamic> word,
  ) async {
    var user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      final loginResult = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
      );

      if (!context.mounted || loginResult != true) return;

      user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
    }

    if (word['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Từ vựng không có ID hợp lệ.'),
        ),
      );
      return;
    }

    // Chuẩn hóa dữ liệu để tương thích với SaveVocabularyDialog.
    final saveWord = <String, dynamic>{
      ...word,
      'kanji': _extractTexts(word['kanji']),
      'kana': _extractTexts(word['kana']),
      'meanings': _getMeanings(word),
    };

    final result = await SaveVocabularyDialog.show(
      context,
      word: saveWord,
    );

    if (!context.mounted) return;

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật nhóm từ vựng!'),
        ),
      );
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF263238),
        ),
      ),
    );
  }

  Widget _infoCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  

Widget _tagList(
  List<dynamic> values, {
  AppLanguage? language,
  String? category,
  Color color = const Color(0xFFE5F4F1),
}) {
  if (values.isEmpty) return const SizedBox.shrink();

  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: values.map((value) {
      final original = value.toString();

      final display = language != null && category != null
          ? _translateMetadataTag(original, category, language)
          : language != null
              ? _translateTag(original, language)
              : original;

      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          display,
          style: const TextStyle(fontSize: 12),
        ),
      );
    }).toList(),
  );
}



  Widget _buildSpellings(
    Map<String, dynamic> word,
    AppLanguage language,
  ) {
    final kanji = _asMaps(word['kanji']);
    final kana = _asMaps(word['kana']);

    final kanjiTexts = _extractTexts(word['kanji']);
    final kanaTexts = _extractTexts(word['kana']);

    if (kanjiTexts.isEmpty && kanaTexts.isEmpty) {
      return const SizedBox.shrink();
    }

    return _infoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            _label(language, 'Cách viết', '表記', 'Writing'),
          ),

          if (kanjiTexts.isNotEmpty) ...[
            const Text(
              'Kanji',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...kanjiTexts.map((text) {
              final item = kanji.firstWhere(
                (e) => e['text'] == text,
                orElse: () => {},
              );

              final common = item['common'] == true;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    if (common)
                      const Chip(
                        label: Text('Common'),
                        backgroundColor: Color(0xFFE5F4F1),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              );
            }),
          ],

          if (kanaTexts.isNotEmpty) ...[
            const Divider(height: 24),
            const Text(
              'Kana',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...kanaTexts.map((text) {
              final item = kana.firstWhere(
                (e) => e['text'] == text,
                orElse: () => {},
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            text,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        if (item['common'] == true)
                          const Chip(
                            label: Text('Common'),
                            backgroundColor: Color(0xFFE5F4F1),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    if (item['appliesToKanji'] is List &&
                        (item['appliesToKanji'] as List).isNotEmpty)
                      Text(
                        'Áp dụng cho: '
                        '${(item['appliesToKanji'] as List).join(', ')}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSenses(
    Map<String, dynamic> word,
    AppLanguage language,
  ) {
    final senses = _getSenses(word);

    if (senses.isEmpty) {
      final meanings = _getMeanings(word);

      if (meanings.isEmpty) return const SizedBox.shrink();

      return _infoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(
              _label(language, 'Ý nghĩa', '意味', 'Meanings'),
            ),
            ...meanings.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${entry.key + 1}. ${entry.value}',
                  style: const TextStyle(fontSize: 16),
                ),
              );
            }),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          _label(language, 'Ý nghĩa', '意味', 'Meanings'),
        ),
        ...senses.asMap().entries.map((entry) {
          final index = entry.key;
          final sense = entry.value;

          final glosses = sense['gloss'] is List
              ? (sense['gloss'] as List)
              : [];

          final meanings = glosses.map((gloss) {
            if (gloss is String) return gloss;

            if (gloss is Map) {
              return gloss['text']?.toString() ?? '';
            }

            return '';
          }).where((text) => text.isNotEmpty).toList();

          final pos = sense['pos'] is List
              ? List<dynamic>.from(sense['pos'])
              : <dynamic>[];

          final misc = sense['misc'] is List
              ? List<dynamic>.from(sense['misc'])
              : <dynamic>[];

          final fields = sense['field'] is List
              ? List<dynamic>.from(sense['field'])
              : <dynamic>[];

          final info = sense['s_inf'] is List
              ? List<dynamic>.from(sense['s_inf'])
              : <dynamic>[];

          final related = sense['xref'] is List
              ? List<dynamic>.from(sense['xref'])
              : <dynamic>[];

          final antonyms = sense['ant'] is List
              ? List<dynamic>.from(sense['ant'])
              : <dynamic>[];

          return _infoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_label(language, 'Nghĩa', '意味', 'Sense')} ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF35A995),
                  ),
                ),
                const SizedBox(height: 10),

                ...meanings.asMap().entries.map((meaning) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '• ${meaning.value}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }),

                if (pos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Part of speech',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  _tagList(pos, language: language),
                ],

                if (misc.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Miscellaneous',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  _tagList(misc, language: language, category: 'misc'),
                ],

                if (fields.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Field',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  _tagList(fields, language: language, category: 'field'),
                ],

                if (info.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Additional information',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  ...info.map((item) => Text('• $item')),
                ],

                if (related.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Related words',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  _tagList(related),
                ],

                if (antonyms.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Antonyms',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  _tagList(antonyms),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDetail(
    Map<String, dynamic> word,
    AppLanguage language,
  ) {
    final kanjiTexts = _extractTexts(word['kanji']);
    final kanaTexts = _extractTexts(word['kana']);

    final displayWord = kanjiTexts.isNotEmpty
        ? kanjiTexts.first
        : kanaTexts.isNotEmpty
            ? kanaTexts.first
            : '';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _infoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayWord,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
              if (kanaTexts.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  kanaTexts.join('、'),
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF35A995),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'ID: ${word['id'] ?? '-'}',
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        _buildSpellings(word, language),
        _buildSenses(word, language),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, language, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FA),
          appBar: AppBar(
            title: Text(
              _label(
                language,
                'Chi tiết từ vựng',
                '単語の詳細',
                'Word Detail',
              ),
            ),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF263238),
            actions: [
              IconButton(
                tooltip: _label(
                  language,
                  'Lưu từ vựng',
                  '単語を保存',
                  'Save vocabulary',
                ),
                onPressed: () async {
                  final word = await _detailFuture;

                  if (!context.mounted) return;

                  await _saveWord(context, word);
                },
                icon: const Icon(Icons.bookmark_add_outlined),
              ),
            ],
          ),
          body: FutureBuilder<Map<String, dynamic>>(
            future: _detailFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF35A995),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    _label(
                      language,
                      'Không thể tải dữ liệu từ vựng.',
                      '単語データを読み込めません。',
                      'Could not load vocabulary data.',
                    ),
                  ),
                );
              }

              final word = snapshot.data ?? widget.word;

              return _buildDetail(word, language);
            },
          ),
        );
      },
    );
  }
}
