import 'package:flutter/material.dart';

import '../services/dictionary_service.dart';
import '../localization/app_language.dart';
import '../localization/app_strings.dart';
import 'word_detail_page.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;

  const SearchResultsPage({
    super.key,
    required this.query,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final DictionaryService _service = DictionaryService();

  List<dynamic> results = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    search();
  }

  Future<void> search() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await _service.search(widget.query);

      if (!mounted) return;

      setState(() {
        results = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(appLanguage.value);

    return Scaffold(
      appBar: AppBar(
        title: Text('${strings.dictionary}: ${widget.query}'),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF35A995),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Text('Error: $error'),
      );
    }

    if (results.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy kết quả.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final word = Map<String, dynamic>.from(results[index]);

        final kanji = (word['kanji'] as List?) ?? [];
        final kana = (word['kana'] as List?) ?? [];
        final meanings = (word['meanings'] as List?) ?? [];

        final displayWord = kanji.isNotEmpty
            ? kanji.first.toString()
            : kana.isNotEmpty
                ? kana.first.toString()
                : '';

        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              displayWord,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${kana.join(', ')}\n${meanings.take(3).join(', ')}',
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: Color(0xFF35A995),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WordDetailPage(word: word),
                ),
              );
            },
          ),
        );
      },
    );
  }
}