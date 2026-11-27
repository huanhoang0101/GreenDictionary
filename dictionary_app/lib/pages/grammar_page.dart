
import 'dart:async';

import 'package:flutter/material.dart';

import '../services/grammar_service.dart';
import 'grammar_detail_page.dart';
import 'search_results_page.dart';

const Color primaryColor = Color(0xFF35A995);
const Color backgroundColor = Color(0xFFF7F9FA);
const Color darkColor = Color(0xFF263238);

class GrammarPage extends StatefulWidget {
  const GrammarPage({super.key});

  @override
  State<GrammarPage> createState() => _GrammarPageState();
}

class _GrammarPageState extends State<GrammarPage> {
  final GrammarService _service = GrammarService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounce;

  String? _selectedLevel;

  List<dynamic> _suggestions = [];

  bool _isLoadingSuggestions = false;
  bool _showSuggestions = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();

    final keyword = query.trim();

    if (keyword.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _isLoadingSuggestions = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _showSuggestions = true;
      _isLoadingSuggestions = true;
      _error = null;
    });

    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _loadSuggestions(keyword),
    );
  }

  Future<void> _loadSuggestions(String query) async {
    try {
      final data = await _service.search(
        query: query,
        level: _selectedLevel,
        limit: 5,
        offset: 0,
      );

      if (!mounted || _searchController.text.trim() != query) return;

      setState(() {
        _suggestions = List<dynamic>.from(data['results'] ?? []);
        _isLoadingSuggestions = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || _searchController.text.trim() != query) return;

      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
        _error = e.toString();
      });
    }
  }

  void _search() {
    final query = _searchController.text.trim();

    _debounce?.cancel();
    _searchFocusNode.unfocus();

    setState(() {
      _showSuggestions = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsPage(
          query: query,
          searchType: SearchType.grammar,
          level: _selectedLevel,
        ),
      ),
    );
  }

  void _changeLevel(String? level) {
    setState(() {
      _selectedLevel = level;
    });

    final query = _searchController.text.trim();

    if (query.isNotEmpty) {
      _onQueryChanged(query);
    }
  }

  void _openDetail(Map<String, dynamic> grammar) {
    _debounce?.cancel();
    _searchFocusNode.unfocus();

    setState(() {
      _showSuggestions = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GrammarDetailPage(id: grammar['id']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        _searchFocusNode.unfocus();
        setState(() {
          _showSuggestions = false;
        });
      },
      child: Container(
        color: backgroundColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tra cứu ngữ pháp tiếng Nhật',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: darkColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tìm kiếm và học các mẫu ngữ pháp theo cấp độ JLPT N5–N1.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildSearchBox(),
                  if (_showSuggestions) ...[
                    const SizedBox(height: 8),
                    _buildSuggestions(),
                  ],
                  const SizedBox(height: 24),
                  _buildLevelSelector(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const Icon(Icons.search, color: primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              onSubmitted: (_) => _search(),
              decoration: const InputDecoration(
                hintText: 'Nhập mẫu ngữ pháp, ý nghĩa hoặc cách đọc...',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              tooltip: 'Xóa',
              onPressed: () {
                _searchController.clear();
                _onQueryChanged('');
              },
              icon: const Icon(Icons.close, color: Colors.grey),
            ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: _search,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Tìm kiếm'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    if (_isLoadingSuggestions) {
      return const Card(
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: CircularProgressIndicator(
              color: primaryColor,
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Không thể tải gợi ý: $_error',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return const Card(
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Không tìm thấy gợi ý phù hợp.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: _suggestions.map((item) {
          final grammar = Map<String, dynamic>.from(item);

          final pattern = grammar['pattern']?.toString() ?? '';
          final reading = grammar['reading']?.toString() ?? '';
          final meaning = grammar['meaning']?.toString() ?? '';
          final level = grammar['level']?.toString() ?? '';

          return ListTile(
            onTap: () => _openDetail(grammar),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    pattern,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkColor,
                    ),
                  ),
                ),
                _levelBadge(level),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                [
                  if (reading.isNotEmpty) reading,
                  meaning,
                ].join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: primaryColor,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLevelSelector() {
    const levels = ['Tất cả', 'N5', 'N4', 'N3', 'N2', 'N1'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lọc theo cấp độ JLPT',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: darkColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: levels.map((level) {
            final value = level == 'Tất cả' ? null : level;
            final selected = _selectedLevel == value;

            return ChoiceChip(
              label: Text(level),
              selected: selected,
              onSelected: (_) => _changeLevel(value),
              selectedColor: primaryColor,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? Colors.white : darkColor,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: selected ? primaryColor : Colors.grey.shade300,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _levelBadge(String level) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        level,
        style: const TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
