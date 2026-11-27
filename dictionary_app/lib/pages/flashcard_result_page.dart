import 'dart:math' as math;

import 'package:flutter/material.dart';

class FlashcardResultPage extends StatelessWidget {
  final int total;
  final int notKnown;
  final int vague;
  final int known;

  const FlashcardResultPage({
    super.key,
    required this.total,
    required this.notKnown,
    required this.vague,
    required this.known,
  });

  static const Color _primary = Color(0xFF35A995);
  static const Color _dark = Color(0xFF263238);
  static const Color _background = Color(0xFFF7F9FA);
  static const Color _red = Color(0xFFE57373);
  static const Color _orange = Color(0xFFFFB74D);
  static const Color _green = Color(0xFF66BB6A);

  @override
  Widget build(BuildContext context) {
    final results = [
      _ResultItem(
        label: 'Chưa thuộc',
        count: notKnown,
        color: _red,
        icon: Icons.close_rounded,
      ),
      _ResultItem(
        label: 'Thuộc lơ mơ',
        count: vague,
        color: _orange,
        icon: Icons.question_mark_rounded,
      ),
      _ResultItem(
        label: 'Đã thuộc',
        count: known,
        color: _green,
        icon: Icons.check_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Kết quả ôn tập',
          style: TextStyle(
            color: Color(0xFF263238),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF263238),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 58,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE8EEEE)),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 600;
            final horizontalPadding = constraints.maxWidth < 500 ? 18.0 : 28.0;
            final chartSize = compact ? 112.0 : 148.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: compact ? 10 : 20,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: compact ? 38 : 44,
                            height: compact ? 38 : 44,
                            decoration: BoxDecoration(
                              color: _primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.celebration_rounded,
                              color: _primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hoàn thành ôn tập!',
                                  style: TextStyle(
                                    color: _dark,
                                    fontSize: compact ? 18 : 21,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Bạn đã ôn tập $total thẻ',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: compact ? 12 : 18),

                      // Bảng kết quả là nội dung chính của trang.
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(compact ? 16 : 22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE8EEEE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Kết quả của bạn',
                                    style: TextStyle(
                                      color: _dark,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$total thẻ',
                                  style: const TextStyle(
                                    color: Colors.black45,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: compact ? 10 : 14),
                            ...List.generate(results.length, (index) {
                              final item = results[index];
                              final percent = total <= 0
                                  ? 0
                                  : (item.count / total * 100).round();

                              return Padding(
                                padding: EdgeInsets.only(
                                  top: index == 0 ? 0 : (compact ? 9 : 12),
                                ),
                                child: _ResultRow(
                                  item: item,
                                  percent: percent,
                                  compact: compact,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      SizedBox(height: compact ? 8 : 12),

                      // Dùng phần không gian còn lại cho biểu đồ,
                      // tránh để một khoảng trống lớn trước hai nút.
                      Expanded(
                        child: Center(
                          child: SizedBox(
                            width: chartSize,
                            height: chartSize,
                            child: CustomPaint(
                              painter: _PieChartPainter(
                                values: [notKnown, vague, known],
                                colors: const [_red, _orange, _green],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Hai nút đặt cạnh nhau, cùng chiều cao và không kéo dài quá rộng.
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context, false),
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: const Text('Hoàn thành'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _dark,
                                side: const BorderSide(
                                  color: Color(0xFFD7E1E0),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: compact ? 11 : 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => Navigator.pop(context, true),
                              icon: const Icon(Icons.replay_rounded, size: 18),
                              label: const Text('Ôn tập lại'),
                              style: FilledButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: compact ? 11 : 14,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ResultItem {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _ResultItem({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });
}

class _ResultRow extends StatelessWidget {
  final _ResultItem item;
  final int percent;
  final bool compact;

  const _ResultRow({
    required this.item,
    required this.percent,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 13,
        vertical: compact ? 9 : 12,
      ),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 28 : 32,
            height: compact ? 28 : 32,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(item.icon, color: item.color, size: compact ? 17 : 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(
                color: Color(0xFF263238),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${item.count}',
            style: const TextStyle(
              color: Color(0xFF263238),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: 43,
            child: Text(
              '$percent%',
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<int> values;
  final List<Color> colors;

  const _PieChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<int>(0, (sum, value) => sum + value);
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;

    if (total <= 0) {
      final paint = Paint()..color = const Color(0xFFE1E7E6);
      canvas.drawCircle(center, radius, paint);
      return;
    }

    var startAngle = -math.pi / 2;

    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;

      final sweepAngle = values[i] / total * math.pi * 2;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    if (oldDelegate.values.length != values.length ||
        oldDelegate.colors.length != colors.length) {
      return true;
    }

    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i] ||
          oldDelegate.colors[i] != colors[i]) {
        return true;
      }
    }
    return false;
  }
}
