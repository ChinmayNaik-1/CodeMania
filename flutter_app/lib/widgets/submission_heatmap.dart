import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codemania/providers/heatmap_provider.dart';
import 'package:codemania/models/heatmap_data.dart';

class HeatmapEntry {
  final DateTime date;
  final int count;
  const HeatmapEntry({required this.date, required this.count});
}

class SubmissionHeatmap extends ConsumerWidget {
  final String userId;

  const SubmissionHeatmap({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmapAsync = ref.watch(heatmapProvider(userId));

    return heatmapAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: Color(0xFF6C3CE1)),
        ),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text('Error loading heatmap: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
      data: (data) => _SubmissionHeatmapView(data: data),
    );
  }
}

class _SubmissionHeatmapView extends StatefulWidget {
  final HeatmapData data;
  const _SubmissionHeatmapView({required this.data});

  @override
  State<_SubmissionHeatmapView> createState() => _SubmissionHeatmapViewState();
}

class _SubmissionHeatmapViewState extends State<_SubmissionHeatmapView> {
  final double cellSize = 10.0;
  final double cellGap = 2.0;

  HeatmapEntry? _hovered;
  Offset _tooltipPos = Offset.zero;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color _getPaletteColor(int index, bool isDark) {
    if (isDark) {
      const colors = [
        Color(0xFF2D333B),
        Color(0xFF0E4429),
        Color(0xFF006D32),
        Color(0xFF26A641),
        Color(0xFF39D353),
      ];
      return colors[index];
    } else {
      const colors = [
        Color(0xFFEBEDF0),
        Color(0xFFC6E48B),
        Color(0xFF7BC96F),
        Color(0xFF239A3B),
        Color(0xFF196127),
      ];
      return colors[index];
    }
  }

  Color _cellColor(int count, int maxCount, bool isDark) {
    if (count == 0) return _getPaletteColor(0, isDark);
    final ratio = count / maxCount;
    if (ratio <= 0.25) return _getPaletteColor(1, isDark);
    if (ratio <= 0.50) return _getPaletteColor(2, isDark);
    if (ratio <= 0.75) return _getPaletteColor(3, isDark);
    return _getPaletteColor(4, isDark);
  }

  static const _monthNames = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  List<Positioned> _buildMonthLabels(DateTime start, int cols, double stride) {
    final result = <Positioned>[];
    int prevMonth = -1;

    for (var col = 0; col < cols; col++) {
      final cellDate = start.add(Duration(days: col * 7));
      final month = cellDate.month;
      if (month != prevMonth && cellDate.day <= 14) {
        prevMonth = month;
        final x = col * stride;
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

  String _formatTooltip(HeatmapEntry day) {
    final m = _monthNames[day.date.month];
    final countStr = day.count == 0
        ? 'No submissions'
        : '${day.count} submission${day.count == 1 ? '' : 's'}';
    return '$m ${day.date.day}, ${day.date.year}\n$countStr';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxCount = widget.data.heatmap.values.isEmpty
        ? 0
        : widget.data.heatmap.values.reduce(math.max);

    final today = DateTime.now();
    final todayStripped = DateTime(today.year, today.month, today.day);
    final rawStart = todayStripped.subtract(const Duration(days: 364));
    final startOffset = rawStart.weekday % 7;
    final startDate = rawStart.subtract(Duration(days: startOffset));

    final int totalDays = todayStripped.difference(startDate).inDays + 1;
    final int cols = (totalDays / 7).ceil();

    final stride = cellSize + cellGap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats row
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            Text(
              '${widget.data.totalSubmissions} submissions in the past year',
              style: const TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Active days: ${widget.data.totalActiveDays}',
              style: const TextStyle(color: Color(0xFF666680), fontSize: 12),
            ),
            Text(
              'Max streak: ${widget.data.maxStreak}',
              style: const TextStyle(color: Color(0xFF666680), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Scrollable horizontal heatmap
        SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day labels
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
                                    color: Color(0xFF666680), fontSize: 9),
                              ),
                      );
                    }),
                  ),
                ),
              ),

              // Heatmap grid with month labels
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: SizedBox(
                  width: cols * stride,
                  height: 7 * stride + 16,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Month labels
                      ..._buildMonthLabels(startDate, cols, stride),

                      // Grid cells
                      ...List.generate(totalDays, (i) {
                        final date = startDate.add(Duration(days: i));
                        final col = i ~/ 7;
                        final row = i % 7;
                        final count = widget.data.heatmap[date] ?? 0;
                        final dx = col * stride;
                        final dy = row * stride + 16;
                        final isToday = date.isAtSameMomentAs(todayStripped);

                        return Positioned(
                          left: dx,
                          top: dy,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            onEnter: (_) => setState(() {
                              _hovered = HeatmapEntry(date: date, count: count);
                              _tooltipPos = Offset(math.max(0, dx - 40), math.max(0, dy - 42));
                            }),
                            onExit: (_) => setState(() => _hovered = null),
                            child: GestureDetector(
                              onTapDown: (_) => setState(() {
                                _hovered = HeatmapEntry(date: date, count: count);
                                _tooltipPos = Offset(math.max(0, dx - 40), math.max(0, dy - 42));
                              }),
                              onTapUp: (_) => setState(() => _hovered = null),
                              onTapCancel: () => setState(() => _hovered = null),
                              child: Container(
                                width: cellSize,
                                height: cellSize,
                                decoration: BoxDecoration(
                                  color: _cellColor(count, maxCount, isDark),
                                  borderRadius: BorderRadius.circular(2),
                                  border: isToday
                                      ? Border.all(
                                          color: isDark ? const Color(0xFF39D353) : const Color(0xFF216E39),
                                          width: 1.5)
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                      // Tooltip
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
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('Less',
                style: TextStyle(color: Color(0xFF666680), fontSize: 10)),
            const SizedBox(width: 4),
            for (var i = 0; i < 5; i++)
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _getPaletteColor(i, isDark),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            const Text('More',
                style: TextStyle(color: Color(0xFF666680), fontSize: 10)),
          ],
        ),
      ],
    );
  }
}
