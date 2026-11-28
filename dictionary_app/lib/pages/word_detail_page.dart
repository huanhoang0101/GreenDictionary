import 'package:flutter/material.dart';

import '../localization/app_language.dart';
import '../services/dictionary_service.dart';
import '../services/example_sentence_service.dart';
import '../widgets/save_vocabulary_dialog.dart';
import 'login_page.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class WordDetailPage extends StatefulWidget {
  final Map<String, dynamic> word;

  const WordDetailPage({super.key, required this.word});

  @override
  State<WordDetailPage> createState() => _WordDetailPageState();
}

class _WordDetailPageState extends State<WordDetailPage> {
  final DictionaryService _dictionaryService = DictionaryService();
  final ExampleSentenceService _exampleSentenceService =
      ExampleSentenceService();

  final Map<String, Future<List<Map<String, dynamic>>>> _exampleFutures = {};
  late Future<Map<String, dynamic>> _detailFuture;
  final Map<String, Future<Map<String, dynamic>>> _inferredMeaningFutures = {};

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadWordDetail();
  }

  Future<Map<String, dynamic>> _loadWordDetail() async {
    final id = widget.word['id'];

    if (id == null) return widget.word;

    try {
      final response = await _dictionaryService.getWordDetail(id.toString());

      final rawWord = response['word'];

      if (rawWord is Map) {
        final detailWord = Map<String, dynamic>.from(rawWord);

        detailWord['_partsOfSpeech'] = response['partsOfSpeech'] ?? [];
        detailWord['_conjugation'] = response['conjugation'];

        return detailWord;
      }

      // Tương thích với API cũ chỉ trả về word.
      return response;
    } catch (error) {
      debugPrint('Load word detail error: $error');
      return widget.word;
    }
  }

  Future<Map<String, dynamic>> _loadInferredMeanings(String query) {
    return _inferredMeaningFutures.putIfAbsent(
      query,
      () => _dictionaryService.getInferredMeanings(query),
    );
  }

  Widget _buildInferredMeanings(
    Map<String, dynamic> word,
    AppLanguage language,
  ) {
    // Chỉ hiển thị nghĩa suy luận khi giao diện dùng tiếng Việt.
    if (language != AppLanguage.vi) {
      return const SizedBox.shrink();
    }

    final kanji = _extractTexts(word['kanji']);
    final kana = _extractTexts(word['kana']);

    final query = kanji.isNotEmpty
        ? kanji.first
        : kana.isNotEmpty
        ? kana.first
        : '';

    if (query.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>>(
      future: _loadInferredMeanings(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _infoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Nghĩa tiếng Việt'),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(color: Color(0xFF35A995)),
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final rawMeanings = data['meanings'];

        if (rawMeanings is! List || rawMeanings.isEmpty) {
          return const SizedBox.shrink();
        }

        String getMeaningText(dynamic item) {
          if (item is String) return item;

          if (item is Map) {
            return item['meaning']?.toString() ??
                item['text']?.toString() ??
                item['word']?.toString() ??
                item['value']?.toString() ??
                '';
          }

          return '';
        }

        final meanings = rawMeanings
            .map(getMeaningText)
            .where((text) => text.trim().isNotEmpty)
            .toSet()
            .toList();

        if (meanings.isEmpty) return const SizedBox.shrink();

        final totalSentences = data['totalSentences']?.toString() ?? '';

        return _infoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Nghĩa tiếng Việt'),
              const Text(
                'Nghĩa suy luận từ câu ví dụ Tatoeba',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              ...meanings.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${entry.key + 1}. ${entry.value}',
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }),
              if (totalSentences.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Dựa trên $totalSentences câu ví dụ',
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ],
          ),
        );
      },
    );
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

    return value
        .map((item) {
          if (item is String) return item;
          if (item is Map) return item['text']?.toString() ?? '';
          return '';
        })
        .where((text) => text.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _getSenses(Map<String, dynamic> word) {
    final value = word['sense'] ?? word['senses'];
    return _asMaps(value);
  }

  List<String> _getMeanings(Map<String, dynamic> word) {
    final existing = word['meanings'];

    if (existing is List && existing.isNotEmpty) {
      return existing
          .map((e) {
            if (e is Map) return e['text']?.toString() ?? '';
            return e.toString();
          })
          .where((e) => e.isNotEmpty)
          .toList();
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

  String _label(AppLanguage language, String vi, String ja, String en) {
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
      'v5u': [
        'Động từ nhóm 1 kết thúc bằng う',
        '五段動詞・う',
        'Godan verb ending in u',
      ],
      'vs': ['Động từ する', 'サ変動詞', 'Suru verb'],
      'vk': ['Động từ 来る', 'カ変動詞', 'Kuru verb'],
      'adj-i': ['Tính từ đuôi い', 'い形容詞', 'い-adjective'],
      'adj-na': ['Tính từ đuôi な', 'な形容詞', 'な-adjective'],
      'adv': ['Trạng từ', '副詞', 'Adverb'],
      'prt': ['Trợ từ', '助詞', 'Particle'],
      'exp': ['Cụm từ / Thành ngữ', '表現・慣用句', 'Expression / Idiom'],
      'int': ['Thán từ', '感動詞', 'Interjection'],
      'pref': ['Tiền tố', '接頭辞', 'Prefix'],
      'suf': ['Hậu tố', '接尾辞', 'Suffix'],
      'conj': ['Liên từ', '接続詞', 'Conjunction'],
      'cop': ['Động từ liên kết', 'コピュラ', 'Copula'],
      'n-pr': ['Danh từ riêng', '固有名詞', 'Proper noun'],
      'n-t': ['Danh từ chỉ thời gian', '時を表す名詞', 'Temporal noun'],
      'n-unc': ['Danh từ không đếm được', '不可算名詞', 'Uncountable noun'],
      'adj-f': ['Tính từ không biến đổi', '変化しない形容詞', 'Uninflected adjective'],
      'adj-pn': ['Tính từ tiền danh từ', '連体詞', 'Pre-noun adjectival'],
      'adj-t': ['Tính từ chỉ thời gian', '時を表す形容詞', 'Temporal adjective'],
      'adv-to': ['Trạng từ kết thúc bằng と', 'と副詞', 'Adverb taking と'],
      'aux': ['Trợ động từ', '助動詞', 'Auxiliary'],
      'aux-v': ['Trợ động từ', '助動詞', 'Auxiliary verb'],
      'aux-adj': ['Trợ tính từ', '補助形容詞', 'Auxiliary adjective'],
      'ctr': ['Từ đếm', '助数詞', 'Counter'],
      'num': ['Số từ', '数詞', 'Numeric'],
      'vi': ['Tự động từ', '自動詞', 'Intransitive verb'],
      'vt': ['Tha động từ', '他動詞', 'Transitive verb'],
      'v2a-s': ['Động từ nhóm 2', '下二段動詞', 'Nidan verb'],
      'v4': ['Động từ nhóm 4', '四段動詞', 'Yodan verb'],
      'vz': ['Động từ ず', 'ず動詞', 'Zuru verb'],
      'vs-i': ['Động từ する bất quy tắc', '不規則サ変動詞', 'Irregular suru verb'],
      'v5aru': [
        'Động từ nhóm 1 kết thúc bằng ある',
        '五段動詞・ある',
        'Godan verb ending in aru',
      ],
      'v5b': [
        'Động từ nhóm 1 kết thúc bằng ぶ',
        '五段動詞・ぶ',
        'Godan verb ending in bu',
      ],
      'v5g': [
        'Động từ nhóm 1 kết thúc bằng ぐ',
        '五段動詞・ぐ',
        'Godan verb ending in gu',
      ],
      'v5k': [
        'Động từ nhóm 1 kết thúc bằng く',
        '五段動詞・く',
        'Godan verb ending in ku',
      ],
      'v5m': [
        'Động từ nhóm 1 kết thúc bằng む',
        '五段動詞・む',
        'Godan verb ending in mu',
      ],
      'v5n': [
        'Động từ nhóm 1 kết thúc bằng ぬ',
        '五段動詞・ぬ',
        'Godan verb ending in nu',
      ],
      'v5r': [
        'Động từ nhóm 1 kết thúc bằng る',
        '五段動詞・る',
        'Godan verb ending in ru',
      ],
      'v5s': [
        'Động từ nhóm 1 kết thúc bằng す',
        '五段動詞・す',
        'Godan verb ending in su',
      ],
      'v5t': [
        'Động từ nhóm 1 kết thúc bằng つ',
        '五段動詞・つ',
        'Godan verb ending in tsu',
      ],
      'v5u-s': ['Động từ nhóm 1 đặc biệt', '特殊な五段動詞', 'Special godan verb'],
      'v5uru': [
        'Động từ nhóm 1 kết thúc bằng うる',
        '五段動詞・うる',
        'Godan verb ending in uru',
      ],
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
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );

      if (!context.mounted || loginResult != true) return;

      user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
    }

    if (word['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Từ vựng không có ID hợp lệ.')),
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

    final result = await SaveVocabularyDialog.show(context, word: saveWord);

    if (!context.mounted) return;

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật nhóm từ vựng!')),
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

  Widget _infoCard({required Widget child}) {
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(display, style: const TextStyle(fontSize: 12)),
        );
      }).toList(),
    );
  }

  Widget _buildSpellings(Map<String, dynamic> word, AppLanguage language) {
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
          _sectionTitle(_label(language, 'Cách viết', '表記', 'Writing')),

          if (kanjiTexts.isNotEmpty) ...[
            const Text('Kanji', style: TextStyle(fontWeight: FontWeight.w600)),
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
                      child: Text(text, style: const TextStyle(fontSize: 20)),
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
            const Text('Kana', style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _buildSenses(Map<String, dynamic> word, AppLanguage language) {
    final senses = _getSenses(word);

    if (senses.isEmpty) {
      final meanings = _getMeanings(word);

      if (meanings.isEmpty) return const SizedBox.shrink();

      return _infoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(_label(language, 'Ý nghĩa', '意味', 'Meanings')),
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
        _sectionTitle(_label(language, 'Ý nghĩa', '意味', 'Meanings')),
        ...senses.asMap().entries.map((entry) {
          final index = entry.key;
          final sense = entry.value;

          final glosses = sense['gloss'] is List
              ? (sense['gloss'] as List)
              : [];

          final meanings = glosses
              .map((gloss) {
                if (gloss is String) return gloss;

                if (gloss is Map) {
                  final lang = gloss['lang']?.toString() ?? 'eng';

                  // Chỉ hiển thị nghĩa tiếng Anh từ JMdict.
                  if (lang != 'eng') return '';

                  return gloss['text']?.toString() ?? '';
                }

                return '';
              })
              .where((text) => text.isNotEmpty)
              .toList();

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
                  Text(
                    _label(language, 'Loại từ', '品詞', 'Part of speech'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
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

  Future<List<Map<String, dynamic>>> _loadExamples(
    String query,
    String language,
  ) {
    final key = '$query|$language';
    return _exampleFutures.putIfAbsent(
      key,
      () => _exampleSentenceService.searchExamples(
        query: query,
        language: language,
        limit: 8,
      ),
    );
  }

  Widget _buildExamples(Map<String, dynamic> word, AppLanguage language) {
    final kanjiTexts = _extractTexts(word['kanji']);
    final kanaTexts = _extractTexts(word['kana']);
    final query = kanjiTexts.isNotEmpty
        ? kanjiTexts.first
        : kanaTexts.isNotEmpty
        ? kanaTexts.first
        : '';

    if (query.isEmpty) return const SizedBox.shrink();

    // Tatoeba hiện có dữ liệu Nhật–Việt và Nhật–Anh.
    // Khi giao diện là tiếng Nhật, dùng bản dịch tiếng Anh.
    final translationLanguage = language == AppLanguage.vi ? 'vi' : 'en';

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadExamples(query, translationLanguage),
      builder: (context, snapshot) {
        final title = _label(language, 'Câu ví dụ', '例文', 'Example sentences');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _infoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(title),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(color: Color(0xFF35A995)),
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError || (snapshot.data ?? []).isEmpty) {
          return const SizedBox.shrink();
        }

        final examples = snapshot.data!;
        return _infoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(title),
              ...examples.asMap().entries.map((entry) {
                final example = entry.value;
                final japanese = example['japanese']?.toString() ?? '';
                final translation = example['translation']?.toString() ?? '';

                if (japanese.isEmpty || translation.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.key == examples.length - 1 ? 0 : 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        japanese,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF263238),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        translation,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF35A995),
                        ),
                      ),
                      if (entry.key != examples.length - 1)
                        const Divider(height: 20),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPartsOfSpeech(Map<String, dynamic> word, AppLanguage language) {
    final parts = _asMaps(word['_partsOfSpeech']);

    if (parts.isEmpty) return const SizedBox.shrink();

    String labelFor(Map<String, dynamic> item) {
      switch (language) {
        case AppLanguage.vi:
          return item['vietnamese']?.toString() ??
              item['code']?.toString() ??
              '';
        case AppLanguage.ja:
          return item['japanese']?.toString() ?? item['code']?.toString() ?? '';
        case AppLanguage.en:
          return item['english']?.toString() ?? item['code']?.toString() ?? '';
      }
    }

    final labels = parts
        .map(labelFor)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();

    if (labels.isEmpty) return const SizedBox.shrink();

    return _infoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(_label(language, 'Từ loại', '品詞', 'Part of speech')),
          _tagList(labels),
        ],
      ),
    );
  }

  Widget _buildConjugation(Map<String, dynamic> word, AppLanguage language) {
    final raw = word['_conjugation'];
    if (raw is! Map) return const SizedBox.shrink();

    final conjugation = Map<String, dynamic>.from(raw);
    final rawForms = conjugation['forms'];
    if (rawForms is! List || rawForms.isEmpty) {
      return const SizedBox.shrink();
    }

    final forms = rawForms
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => (item['value']?.toString() ?? '').isNotEmpty)
        .toList();

    if (forms.isEmpty) return const SizedBox.shrink();

    String getFormLabel(Map<String, dynamic> form) {
      switch (language) {
        case AppLanguage.vi:
          return form['vietnamese']?.toString() ??
              form['japanese']?.toString() ??
              '';
        case AppLanguage.ja:
          return form['japanese']?.toString() ??
              form['vietnamese']?.toString() ??
              '';
        case AppLanguage.en:
          return form['english']?.toString() ??
              form['japanese']?.toString() ??
              '';
      }
    }

    return _infoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(_label(language, 'Chia từ', '活用', 'Conjugation')),
          ...forms.map((form) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 112,
                    child: Text(
                      getFormLabel(form),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64747A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      form['value']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF263238),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          Text(
            _label(
              language,
              'Các dạng chia được tạo tự động từ quy tắc cơ bản.',
              '基本的な活用規則から自動生成しています。',
              'Forms are generated automatically using standard rules.',
            ),
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(Map<String, dynamic> word, AppLanguage language) {
    final kanjiTexts = _extractTexts(word['kanji']);
    final kanaTexts = _extractTexts(word['kana']);

    final displayWord = kanjiTexts.isNotEmpty
        ? kanjiTexts.first
        : kanaTexts.isNotEmpty
        ? kanaTexts.first
        : '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth < 900
            ? constraints.maxWidth
            : 900.0;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            Center(
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        ],
                      ),
                    ),
                    _buildPartsOfSpeech(word, language),
                    _buildConjugation(word, language),
                    _buildSenses(word, language),
                    _buildInferredMeanings(word, language),
                    _buildExamples(word, language),
                  ],
                ),
              ),
            ),
          ],
        );
      },
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
              _label(language, 'Chi tiết từ vựng', '単語の詳細', 'Word Detail'),
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
                  child: CircularProgressIndicator(color: Color(0xFF35A995)),
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
