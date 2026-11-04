import 'dart:async';

import 'package:flutter/material.dart';

import '../localization/app_language.dart';
import '../localization/app_strings.dart';
import '../services/dictionary_service.dart';
import '../pages/search_results_page.dart';
import '../pages/word_detail_page.dart';

class SearchSection extends StatefulWidget {
  const SearchSection({super.key});

  @override
  State<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<SearchSection> {
  final TextEditingController _controller = TextEditingController();
  final DictionaryService _service = DictionaryService();

  Timer? _debounce;

  List<dynamic> suggestions = [];

  bool isLoading = false;
  bool showSuggestions = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();

    final query = value.trim();

    if (query.isEmpty) {
      setState(() {
        suggestions = [];
        showSuggestions = false;
        isLoading = false;
      });
      return;
    }

    setState(() {
      showSuggestions = true;
      isLoading = true;
    });

    _debounce = Timer(
      const Duration(milliseconds: 350),
      () async {
        try {
          final data = await _service.search(query);

          if (!mounted || query != _controller.text.trim()) return;

          setState(() {
            suggestions = data.take(5).toList();
            isLoading = false;
          });
        } catch (_) {
          if (!mounted || query != _controller.text.trim()) return;

          setState(() {
            suggestions = [];
            isLoading = false;
          });
        }
      },
    );
  }

  void _openSearchResults() {
    final query = _controller.text.trim();

    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      showSuggestions = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsPage(query: query),
      ),
    );
  }

  void _openWordDetail(dynamic item) {
    FocusScope.of(context).unfocus();

    setState(() {
      showSuggestions = false;
    });

    final word = Map<String, dynamic>.from(item);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WordDetailPage(word: word),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(appLanguage.value);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            children: [
              Text(
                strings.heroTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                strings.heroSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 28),

              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF35A995),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: TextField(
                            controller: _controller,
                            onChanged: _onQueryChanged,
                            onSubmitted: (_) => _openSearchResults(),
                            decoration: InputDecoration(
                              hintText: strings.searchHint,
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        ElevatedButton(
                          onPressed: _openSearchResults,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF35A995),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(strings.searchButton),
                        ),
                      ],
                    ),
                  ),

                  if (showSuggestions)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: _buildSuggestions(),
                    ),
                ],
              ),

              const SizedBox(height: 18),

              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  'ありがとう',
                  '勉強',
                  '日本語',
                  'こんにちは',
                ].map((word) {
                  return ActionChip(
                    label: Text(word),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300),
                    onPressed: () {
                      _controller.text = word;
                      _onQueryChanged(word);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF35A995),
          ),
        ),
      );
    }

    if (suggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Không tìm thấy gợi ý.'),
      );
    }

    return Column(
      children: suggestions.map((item) {
        final word = Map<String, dynamic>.from(item);

        final kanji = (word['kanji'] as List?) ?? [];
        final kana = (word['kana'] as List?) ?? [];
        final meanings = (word['meanings'] as List?) ?? [];

        final displayWord = kanji.isNotEmpty
            ? kanji.first.toString()
            : kana.isNotEmpty
                ? kana.first.toString()
                : '';

        return ListTile(
          title: Text(
            displayWord,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          subtitle: Text(
            '${kana.join(', ')}  •  ${meanings.take(2).join(', ')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 15,
            color: Color(0xFF35A995),
          ),
          onTap: () => _openWordDetail(item),
        );
      }).toList(),
    );
  }
}