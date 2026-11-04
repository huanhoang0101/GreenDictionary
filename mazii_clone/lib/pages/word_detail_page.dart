import 'package:flutter/material.dart';

class WordDetailPage extends StatelessWidget {
  final Map<String, dynamic> word;

  const WordDetailPage({
    super.key,
    required this.word,
  });

  @override
  Widget build(BuildContext context) {
    final kanji = (word['kanji'] as List?) ?? [];
    final kana = (word['kana'] as List?) ?? [];
    final meanings = (word['meanings'] as List?) ?? [];

    final displayWord = kanji.isNotEmpty
        ? kanji.first.toString()
        : kana.isNotEmpty
            ? kana.first.toString()
            : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Detail'),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                displayWord,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                kana.join(', '),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFF35A995),
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Meanings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              ...meanings.asMap().entries.map((entry) {
                return Card(
                  elevation: 0,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          const Color(0xFF35A995).withValues(alpha: 0.1),
                      child: Text('${entry.key + 1}'),
                    ),
                    title: Text(entry.value.toString()),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}