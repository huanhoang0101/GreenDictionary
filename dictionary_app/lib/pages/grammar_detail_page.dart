
import 'package:flutter/material.dart';

import '../services/grammar_service.dart';
import '../widgets/save_grammar_dialog.dart';

const Color _primaryColor = Color(0xFF35A995);
const Color _backgroundColor = Color(0xFFF7F9FA);
const Color _darkColor = Color(0xFF263238);

class GrammarDetailPage extends StatefulWidget {
  final dynamic id;

  const GrammarDetailPage({
    super.key,
    required this.id,
  });

  @override
  State<GrammarDetailPage> createState() => _GrammarDetailPageState();
}

class _GrammarDetailPageState extends State<GrammarDetailPage> {
  final GrammarService _service = GrammarService();

  late Future<Map<String, dynamic>> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _service.getDetail(widget.id);
  }

  Future<void> _saveGrammar(Map<String, dynamic> grammar) async {
    await SaveGrammarDialog.show(
      context,
      grammar: grammar,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Chi tiết ngữ pháp'),
        backgroundColor: Colors.white,
        foregroundColor: _darkColor,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: _primaryColor,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Không thể tải dữ liệu: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('Không tìm thấy dữ liệu ngữ pháp.'),
            );
          }

          final grammar = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () => _saveGrammar(grammar),
                        icon: const Icon(Icons.bookmark_add_outlined),
                        label: const Text('Lưu vào nhóm'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailContent(grammar),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailContent(Map<String, dynamic> grammar) {
    final pattern = grammar['pattern']?.toString() ?? '';
    final reading = grammar['reading']?.toString() ?? '';
    final romaji = grammar['romaji']?.toString() ?? '';
    final level = grammar['level']?.toString() ?? '';
    final meaning = grammar['meaning']?.toString() ?? '';
    final formation = grammar['formation']?.toString() ?? '';
    final notes = grammar['notes']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                pattern,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: _darkColor,
                ),
              ),
            ),
            _levelBadge(level),
          ],
        ),
        if (reading.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            reading,
            style: const TextStyle(fontSize: 17),
          ),
        ],
        if (romaji.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            romaji,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
        const SizedBox(height: 24),
        _section('Ý nghĩa', meaning),
        _section('Cấu trúc', formation),
        _section('Ví dụ', _formatValue(grammar['examples'])),
        _section('Ghi chú', notes),
        _section('Tags', _formatValue(grammar['tags'])),
      ],
    );
  }

  Widget _section(String title, String content) {
    if (content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.7,
              color: _darkColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return '';

    if (value is String) return value;

    if (value is List) {
      return value
          .map(_formatValue)
          .where((item) => item.isNotEmpty)
          .join('\n\n');
    }

    if (value is Map) {
      return value.entries
          .map((entry) => '${entry.key}: ${_formatValue(entry.value)}')
          .join('\n');
    }

    return value.toString();
  }

  Widget _levelBadge(String level) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        level,
        style: const TextStyle(
          color: _primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
