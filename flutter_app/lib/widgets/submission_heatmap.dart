import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// One data point for the heatmap.
class HeatmapDay {
  final DateTime date;
  final int count;

  const HeatmapDay({required this.date, required this.count});

  factory HeatmapDay.fromJson(Map<String, dynamic> json) {
    return HeatmapDay(
      date: DateTime.parse(json['date'] as String),
      count: json['count'] as int? ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LeetCode-style submission heatmap
// 53 columns × 7 rows, light-theme green scale, month labels, day labels
// Works identically on Flutter Web and Android — no external packages
// ─────────────────────────────────────────────────────────────────────────────

class SubmissionHeatmap extends StatefulWidget {
  const SubmissionHeatmap({
    super.key,
    required this.days,
    this.cellSize = 11.0,
    this.cellGap = 2.0,
  });

  /// Sparse input — only dates with count > 0 are required.
  final List<HeatmapDay> days;
  final double cellSize;
  final double cellGap;

  @override
  State<SubmissionHeatmap> createState() => _SubmissionHeatmapState();
}

class _SubmissionHeatmapState extends State<SubmissionHeatmap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  HeatmapDay? _hovered;
  Offset _tooltipPos = Offset.zero;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Build complete 53×7 grid anchored to today ──────────────────────────
  List<HeatmapDay> _buildGrid() {
    final today = DateTime.now();
    final rawStart = today.subtract(const Duration(days: 364));
    // Walk back to the previous Sunday (weekday % 7 → Sun=0)
    final startWeekday = rawStart.weekday % 7;
    final start = rawStart.subtract(Duration(days: startWeekday));

    final lookup = <String, int>{};
    for (final d in widget.days) {
      final key = _dateKey(d.date);
      lookup[key] = d.count;
    }

    return List.generate(53 * 7, (i) {
      final date = start.add(Duration(days: i));
      return HeatmapDay(date: date, count: lookup[_dateKey(date)] ?? 0);
    });
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── LeetCode light-theme colour scale ────────────────────────────────────
  Color _colorFor(int count) {
    if (count == 0) return const Color(0xFFEBEDF0);
    if (count <= 2) return const Color(0xFF9BE9A8);
    if (count <= 5) return const Color(0xFF40C463);
    if (count <= 9) return const Color(0xFF30A14E);
    return const Color(0xFF216E39);
  }

  static const _monthNames = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final grid = _buildGrid();
    final stride = widget.cellSize + widget.cellGap;
    final totalYear = widget.days.fold(0, (s, d) => s + d.count);

    return FadeTransition(
      opacity: _fade,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary line ────────────────────────────────────────────────
          Text(
            '$totalYear submissions in the last year',
            style: const TextStyle(
              color: Color(0xFF1A1A2E),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          // ── Grid row (day labels + grid) ────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day-of-week column (Mon / Wed / Fri only, matching LeetCode)
              Padding(
                padding: const EdgeInsets.only(top: 18, right: 6),
                child: SizedBox(
                  width: 26,
                  child: Column(
                    children: List.generate(7, (row) {
                      const labels = ['', 'Mon', '', 'Wed', '', 'Fri', ''];
                      return SizedBox(
                        height: stride,
                        child: labels[row].isEmpty
                            ? const SizedBox()
                            : Text(
                                labels[row],
                                style: const TextStyle(
                                  color: Color(0xFF666680),
                                  fontSize: 9,
                                ),
                              ),
                      );
                    }),
                  ),
                ),
              ),

              // Month labels + grid — constrained width to prevent overflow
              Expanded(
                child: LayoutBuilder(builder: (ctx, bc) {
                  final maxW = bc.maxWidth;
                  final cols = math.min(53, (maxW / stride).floor());

                  return ClipRect(
                    child: MouseRegion(
                      onExit: (_) => setState(() => _hovered = null),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Month labels
                          SizedBox(
                            height: 16,
                            width: cols * stride,
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              children: _buildMonthLabels(grid, stride, cols, maxW),
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Grid
                          SizedBox(
                            width: cols * stride,
                            height: 7 * stride,
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              children: [
                                // Cells
                                ...List.generate(cols * 7, (i) {
                                  final col = i ~/ 7;
                                  final row = i % 7;
                                  final day = grid[i];
                                  final isToday = _isSameDay(day.date, DateTime.now());
                                  final dx = col * stride;
                                  final dy = row * stride;

                                  return Positioned(
                                    left: dx,
                                    top: dy,
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      onEnter: (_) => setState(() {
                                        _hovered = day;
                                        // Position tooltip above the cell
                                        // but clamp so it doesn't go off left edge
                                        _tooltipPos = Offset(
                                          math.max(0, dx - 40),
                                          math.max(0, dy - 38),
                                        );
                                      }),
                                      child: GestureDetector(
                                        onLongPress: () =>
                                            setState(() => _hovered = day),
                                        child: Container(
                                          width: widget.cellSize,
                                          height: widget.cellSize,
                                          decoration: BoxDecoration(
                                            color: _colorFor(day.count),
                                            borderRadius: BorderRadius.circular(2),
                                            border: isToday
                                                ? Border.all(
                                                    color: const Color(0xFF216E39),
                                                    width: 1.5,
                                                  )
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),

                                // Tooltip overlay
                                if (_hovered != null)
                                  Positioned(
                                    left: _tooltipPos.dx,
                                    top: _tooltipPos.dy,
                                    child: IgnorePointer(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1A1A2E),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _formatTooltip(_hovered!),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Legend ──────────────────────────────────────────────────────
          Row(
            children: [
              const Text('Less',
                  style: TextStyle(color: Color(0xFF666680), fontSize: 10)),
              const SizedBox(width: 4),
              for (final color in const [
                Color(0xFFEBEDF0),
                Color(0xFF9BE9A8),
                Color(0xFF40C463),
                Color(0xFF30A14E),
                Color(0xFF216E39),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              const Text('More',
                  style: TextStyle(color: Color(0xFF666680), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  List<Positioned> _buildMonthLabels(
      List<HeatmapDay> grid, double stride, int cols, double maxW) {
    final result = <Positioned>[];
    int prevMonth = -1;

    for (var col = 0; col < cols; col++) {
      final cell = grid[col * 7];
      final month = cell.date.month;
      // Only label the first column of each month, and when day is near start
      if (month != prevMonth && cell.date.day <= 7) {
        prevMonth = month;
        final x = col * stride;
        // Skip label if it would overflow the right edge
        if (x > maxW - 20) continue;
        result.add(Positioned(
          left: x,
          top: 0,
          child: Text(
            _monthNames[month],
            style: const TextStyle(
              color: Color(0xFF666680),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ));
      }
    }
    return result;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatTooltip(HeatmapDay day) {
    final m = _monthNames[day.date.month];
    final countStr = day.count == 0
        ? 'No submissions'
        : '${day.count} submission${day.count == 1 ? '' : 's'}';
    return '$m ${day.date.day}, ${day.date.year}\n$countStr';
  }
}
