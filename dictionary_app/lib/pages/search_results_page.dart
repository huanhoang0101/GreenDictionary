
import 'package:flutter/material.dart';

import '../services/dictionary_service.dart';
import '../services/grammar_service.dart';
import '../localization/app_language.dart';
import '../localization/app_strings.dart';
import 'word_detail_page.dart';
import 'grammar_detail_page.dart';

enum SearchType {
  vocabulary,
  grammar,
}

class SearchResultsPage extends StatefulWidget {
  final String query;
  final SearchType searchType;
  final String? level;

  const SearchResultsPage({
    super.key,
    required this.query,
    this.searchType = SearchType.vocabulary,
    this.level,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final DictionaryService _dictionaryService = DictionaryService();
  final GrammarService _grammarService = GrammarService();

  List<dynamic> results = [];
  bool isLoading = true;
  String? error;

  int total = 0;
  int offset = 0;
  static const int limit = 20;

  bool get isGrammar => widget.searchType == SearchType.grammar;

  @override
  void initState() {
    super.initState();
    search();
  }

  Future<void> search({bool reset = true}) async {
    if (reset) offset = 0;

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      if (isGrammar) {
        final data = await _grammarService.search(
          query: widget.query,
          level: widget.level,
          limit: limit,
          offset: offset,
        );

        if (!mounted) return;

        setState(() {
          results = List<dynamic>.from(data['results'] ?? []);
          total = data['total'] ?? 0;
          isLoading = false;
        });
      } else {
        final data = await _dictionaryService.search(widget.query);

        if (!mounted) return;

        setState(() {
          results = data;
          total = data.length;
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        results = [];
        total = 0;
        isLoading = false;
      });
    }
  }

  void _openDetail(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isGrammar
            ? GrammarDetailPage(id: item['id'])
            : WordDetailPage(word: item),
      ),
    );
  }

  void _nextPage() {
    if (isLoading || offset + limit >= total) return;

    setState(() {
      offset += limit;
    });

    search(reset: false);
  }

  void _previousPage() {
    if (isLoading || offset == 0) return;

    setState(() {
      offset = (offset - limit).clamp(0, total);
    });

    search(reset: false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, language, child) {
        final strings = AppStrings(language);

        String getLabel(String vi, String ja, String en) {
          switch (language) {
            case AppLanguage.vi:
              return vi;
            case AppLanguage.ja:
              return ja;
            case AppLanguage.en:
              return en;
          }
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FA),
          appBar: AppBar(
            title: Text(
              '${isGrammar ? getLabel('Ngữ pháp', '文法', 'Grammar') : strings.dictionary}: ${widget.query}',
            ),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF263238),
            elevation: 0,
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: _buildBody(getLabel: getLabel),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody({
    required String Function(String, String, String) getLabel,
  }) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF35A995),
            ),
            const SizedBox(height: 16),
            Text(
              getLabel(
                'Đang tìm kiếm...',
                '検索中...',
                'Searching...',
              ),
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                getLabel(
                  'Đã xảy ra lỗi khi tìm kiếm.',
                  '検索中にエラーが発生しました。',
                  'An error occurred while searching.',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: search,
                child: Text(
                  getLabel('Thử lại', '再試行', 'Try again'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              getLabel(
                'Không tìm thấy kết quả.',
                '検索結果が見つかりませんでした。',
                'No results found.',
              ),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: results.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = Map<String, dynamic>.from(results[index]);

              return isGrammar
                  ? _buildGrammarCard(item)
                  : _buildVocabularyCard(item);
            },
          ),
        ),
        if (isGrammar && total > limit) _buildPagination(),
      ],
    );
  }

  Widget _buildVocabularyCard(Map<String, dynamic> word) {
    final kanji = (word['kanji'] as List?) ?? [];
    final kana = (word['kana'] as List?) ?? [];
    final meanings = (word['meanings'] as List?) ?? [];

    final displayWord = kanji.isNotEmpty
        ? kanji.first.toString()
        : kana.isNotEmpty
            ? kana.first.toString()
            : '';

    return _resultCard(
      title: displayWord,
      subtitle: '${kana.join(', ')}\n${meanings.take(3).join(', ')}',
      onTap: () => _openDetail(word),
    );
  }

  Widget _buildGrammarCard(Map<String, dynamic> grammar) {
    final pattern = grammar['pattern']?.toString() ?? '';
    final reading = grammar['reading']?.toString() ?? '';
    final meaning = grammar['meaning']?.toString() ?? '';
    final level = grammar['level']?.toString() ?? '';

    return _resultCard(
      title: pattern,
      subtitle: [
        if (reading.isNotEmpty) reading,
        meaning,
      ].join('\n'),
      level: level,
      onTap: () => _openDetail(grammar),
    );
  }

  Widget _resultCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? level,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
            ),
            if (level != null) _levelBadge(level),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(subtitle),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Color(0xFF35A995),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _levelBadge(String level) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF35A995).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        level,
        style: const TextStyle(
          color: Color(0xFF35A995),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final start = offset + 1;
    final end = (offset + results.length).clamp(0, total);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: offset > 0 && !isLoading ? _previousPage : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            '$start–$end / $total',
            style: const TextStyle(color: Colors.black54),
          ),
          IconButton(
            onPressed: offset + limit < total && !isLoading
                ? _nextPage
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
