
import 'dart:math';

import 'package:flutter/material.dart';

import 'flashcard_result_page.dart';

class FlashcardPage extends StatefulWidget {
  final List<Map<String, dynamic>> savedItems;
  final String title;

  const FlashcardPage({
    super.key,
    required this.savedItems,
    required this.title,
  });

  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {
  static const primaryColor = Color(0xFF35A995);

  late List<Map<String, dynamic>> cards;
  final Map<int, String> ratings = {};

  int currentIndex = 0;
  bool isFlipped = false;

  @override
  void initState() {
    super.initState();
    _shuffleCards();
  }

  void _shuffleCards() {
    cards = List<Map<String, dynamic>>.from(widget.savedItems);
    cards.shuffle(Random());
  }

  bool _isGrammar(Map<String, dynamic> item) {
    final data = Map<String, dynamic>.from(item['word_data'] ?? {});
    final key = item['word_key']?.toString() ?? '';

    return data['type'] == 'grammar' || key.startsWith('openjlpt:');
  }

  String _getFront(Map<String, dynamic> item) {
    final data = Map<String, dynamic>.from(item['word_data'] ?? {});

    if (_isGrammar(item)) {
      return data['pattern']?.toString() ?? 'Không có mẫu ngữ pháp';
    }

    final kanji = List<String>.from(data['kanji'] ?? []);
    final kana = List<String>.from(data['kana'] ?? []);

    if (kanji.isNotEmpty) return kanji.join('、');
    if (kana.isNotEmpty) return kana.join('、');

    return 'Không có từ';
  }

  String _getReading(Map<String, dynamic> item) {
    final data = Map<String, dynamic>.from(item['word_data'] ?? {});

    if (_isGrammar(item)) {
      return data['reading']?.toString() ?? '';
    }

    final kana = List<String>.from(data['kana'] ?? []);
    return kana.join('、');
  }

  String _getBack(Map<String, dynamic> item) {
    final data = Map<String, dynamic>.from(item['word_data'] ?? {});

    if (_isGrammar(item)) {
      final meaning = data['meaning']?.toString() ?? '';
      final formation = data['formation']?.toString() ?? '';

      if (formation.isEmpty) return meaning;
      if (meaning.isEmpty) return formation;

      return '$meaning\n\nCấu trúc:\n$formation';
    }

    final meanings = List<String>.from(data['meanings'] ?? []);
    return meanings.isEmpty ? 'Chưa có nghĩa' : meanings.join('\n');
  }

  void _goToPreviousCard() {
    if (currentIndex == 0) return;

    setState(() {
      currentIndex--;
      isFlipped = false;
    });
  }

  Future<void> _rateCard(String rating) async {
    final updatedRatings = Map<int, String>.from(ratings);
    updatedRatings[currentIndex] = rating;

    if (currentIndex == cards.length - 1) {
      final notKnown =
          updatedRatings.values.where((value) => value == 'again').length;
      final vague =
          updatedRatings.values.where((value) => value == 'hard').length;
      final known =
          updatedRatings.values.where((value) => value == 'good').length;

      final shouldRestart = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => FlashcardResultPage(
            total: cards.length,
            notKnown: notKnown,
            vague: vague,
            known: known,
          ),
        ),
      );

      if (!mounted) return;

      if (shouldRestart == true) {
        setState(() {
          _shuffleCards();
          ratings.clear();
          currentIndex = 0;
          isFlipped = false;
        });
      } else {
        Navigator.pop(context);
      }

      return;
    }

    setState(() {
      ratings
        ..clear()
        ..addAll(updatedRatings);

      currentIndex++;
      isFlipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: Text('Không có thẻ nào để ôn tập.')),
        ),
      );
    }

    final item = cards[currentIndex];
    final front = _getFront(item);
    final reading = _getReading(item);
    final back = _getBack(item);
    final isGrammar = _isGrammar(item);

    return Scaffold(
      // Không dùng AppBar để dành toàn bộ chiều cao cho flashcard.
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final compact = screenHeight < 560;
            final horizontalPadding = compact ? 12.0 : 20.0;
            final verticalPadding = compact ? 8.0 : 14.0;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${currentIndex + 1} / ${cards.length}',
                        style: TextStyle(
                          fontSize: compact ? 13 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isGrammar ? 'Ngữ pháp' : 'Từ vựng',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: compact ? 13 : 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 6 : 10),
                  LinearProgressIndicator(
                    value: (currentIndex + 1) / cards.length,
                    minHeight: compact ? 5 : 7,
                    borderRadius: BorderRadius.circular(10),
                    backgroundColor: Colors.grey.shade200,
                    color: primaryColor,
                  ),
                  SizedBox(height: compact ? 8 : 14),

                  // Expanded giúp thẻ tự lấy phần chiều cao còn lại.
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        // Giới hạn chiều rộng để thẻ có cảm giác như một tấm flashcard.
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: SizedBox(
                          width: double.infinity,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isFlipped = !isFlipped;
                              });
                            },
                            child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Container(
                          key: ValueKey(isFlipped),
                          width: double.infinity,
                          constraints: const BoxConstraints.expand(),
                          padding: EdgeInsets.all(compact ? 12 : 24),
                          decoration: BoxDecoration(
                            color: isFlipped
                                ? const Color(0xFFEAF6F2)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.35),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: LayoutBuilder(
                            builder: (context, cardConstraints) {
                              // Scale nội dung xuống nếu nghĩa dài hoặc màn hình thấp.
                              // Nhờ vậy không còn Column overflow khi lật thẻ.
                              return Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: SizedBox(
                                    width: cardConstraints.maxWidth,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isFlipped
                                              ? Icons.lightbulb_outline
                                              : Icons.touch_app_outlined,
                                          size: compact ? 25 : 34,
                                          color: primaryColor,
                                        ),
                                        SizedBox(height: compact ? 8 : 16),
                                        Text(
                                          isFlipped
                                              ? 'Ý nghĩa'
                                              : 'Hãy nhớ từ này',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: compact ? 13 : 16,
                                          ),
                                        ),
                                        SizedBox(height: compact ? 8 : 16),
                                        Text(
                                          isFlipped ? back : front,
                                          textAlign: TextAlign.center,
                                          softWrap: true,
                                          style: TextStyle(
                                            fontSize: isFlipped
                                                ? (compact ? 18 : 22)
                                                : (compact ? 28 : 34),
                                            fontWeight: FontWeight.bold,
                                            height: 1.35,
                                            color: const Color(0xFF263238),
                                          ),
                                        ),
                                        if (!isFlipped && reading.isNotEmpty) ...[
                                          SizedBox(height: compact ? 6 : 12),
                                          Text(
                                            reading,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: compact ? 14 : 18,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                        SizedBox(height: compact ? 8 : 16),
                                        Text(
                                          isFlipped
                                              ? 'Chạm để xem mặt trước'
                                              : 'Chạm vào thẻ để xem nghĩa',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: compact ? 11 : 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                  SizedBox(height: compact ? 8 : 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed:
                          currentIndex == 0 ? null : _goToPreviousCard,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Quay lại'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: compact ? 7 : 10,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 6 : 10),
                  Text(
                    'Bạn nhớ được thẻ này đến mức nào?',
                    style: TextStyle(
                      fontSize: compact ? 12 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: compact ? 6 : 10),
                  Row(
                    children: [
                      Expanded(
                        child: _RatingButton(
                          label: 'Chưa thuộc',
                          icon: Icons.close,
                          color: const Color(0xFFE57373),
                          compact: compact,
                          onPressed: () => _rateCard('again'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _RatingButton(
                          label: 'Lơ mơ',
                          icon: Icons.help_outline,
                          color: const Color(0xFFFFB74D),
                          compact: compact,
                          onPressed: () => _rateCard('hard'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _RatingButton(
                          label: 'Đã thuộc',
                          icon: Icons.check,
                          color: const Color(0xFF66BB6A),
                          compact: compact,
                          onPressed: () => _rateCard('good'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool compact;

  const _RatingButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: compact ? 7 : 12, horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 18 : 24),
          SizedBox(height: compact ? 2 : 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: compact ? 10 : 11),
          ),
        ],
      ),
    );
  }
}
