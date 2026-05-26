import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codemania/providers/contest_provider.dart';

class LeaderboardWidget extends ConsumerStatefulWidget {
  const LeaderboardWidget({
    super.key,
    required this.contestId,
    required this.contestStatus,
  });

  final int contestId;
  final String contestStatus;

  @override
  ConsumerState<LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends ConsumerState<LeaderboardWidget> {
  Timer? _timer;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _syncTimer(widget.contestStatus);
  }

  @override
  void didUpdateWidget(covariant LeaderboardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contestStatus != widget.contestStatus) {
      _syncTimer(widget.contestStatus);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncTimer(String status) {
    final shouldRun = status == 'in_progress';
    if (shouldRun && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 30), (_) {
        ref.invalidate(leaderboardProvider(widget.contestId));
        setState(() => _lastUpdated = DateTime.now());
      });
    } else if (!shouldRun && _timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Color _medalColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFF5C542);
      case 2:
        return const Color(0xFFBFC5D2);
      case 3:
        return const Color(0xFFCD8B61);
      default:
        return const Color(0xFF7A839E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardProvider(widget.contestId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Leaderboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            if (widget.contestStatus == 'in_progress')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F6EE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('Live', style: TextStyle(color: Color(0xFF2EAF57), fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            const Spacer(),
            if (_lastUpdated != null)
              Text('Updated ${_formatTime(_lastUpdated!)}', style: const TextStyle(color: Color(0xFF7A839E), fontSize: 12)),
            IconButton(
              onPressed: () {
                ref.invalidate(leaderboardProvider(widget.contestId));
                setState(() => _lastUpdated = DateTime.now());
              },
              icon: const Icon(Icons.refresh, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFDFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6E0F3)),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Expanded(flex: 1, child: Text('Rank', style: TextStyle(color: Color(0xFF7A839E), fontWeight: FontWeight.w700))),
                  Expanded(flex: 3, child: Text('Team', style: TextStyle(color: Color(0xFF7A839E), fontWeight: FontWeight.w700))),
                  Expanded(flex: 3, child: Text('Members', style: TextStyle(color: Color(0xFF7A839E), fontWeight: FontWeight.w700))),
                  Expanded(flex: 1, child: Text('Solved', style: TextStyle(color: Color(0xFF7A839E), fontWeight: FontWeight.w700))),
                  Expanded(flex: 1, child: Text('Penalty', style: TextStyle(color: Color(0xFF7A839E), fontWeight: FontWeight.w700))),
                ],
              ),
              const SizedBox(height: 12),
              leaderboardAsync.when(
                data: (entries) {
                  if (entries.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Text('No submissions yet.'),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final medalColor = _medalColor(entry.rank);
                      return Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: entry.rank <= 3
                                ? Icon(Icons.emoji_events, color: medalColor, size: 18)
                                : Text(entry.rank.toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(entry.teamName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          Expanded(
                            flex: 3,
                            child: _MemberAvatars(members: entry.memberUsernames),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              entry.problemsSolved.toString(),
                              style: const TextStyle(color: Color(0xFF2EAF57), fontWeight: FontWeight.w700),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              entry.totalPenalty.toString(),
                              style: const TextStyle(color: Color(0xFF7A839E)),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text('Failed to load leaderboard: $error'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MemberAvatars extends StatelessWidget {
  const _MemberAvatars({required this.members});

  final List<String> members;

  @override
  Widget build(BuildContext context) {
    final maxShown = members.length > 4 ? 4 : members.length;
    final remaining = members.length - maxShown;

    return SizedBox(
      height: 28,
      child: Stack(
        children: [
          for (int i = 0; i < maxShown; i++)
            Positioned(
              left: i * 18.0,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFFEDEAF8),
                child: Text(
                  members[i].isNotEmpty ? members[i][0].toUpperCase() : '?',
                  style: const TextStyle(color: Color(0xFF5E2ED5), fontSize: 12),
                ),
              ),
            ),
          if (remaining > 0)
            Positioned(
              left: maxShown * 18.0,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFFF4F1FB),
                child: Text(
                  '+$remaining',
                  style: const TextStyle(color: Color(0xFF7A839E), fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
