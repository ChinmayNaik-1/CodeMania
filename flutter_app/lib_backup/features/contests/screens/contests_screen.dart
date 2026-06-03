import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:codemania/core/models/contest_model.dart';
import 'package:codemania/features/contests/providers/contest_provider.dart';
import 'package:codemania/providers/auth_provider.dart';

// ─── Theme constants ──────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF6C5CE7);
const _kPrimaryDark = Color(0xFF5A4BD1);
const _kBg = Color(0xFFF5F3FF);
const _kSurface = Colors.white;
const _kTextPri = Color(0xFF1A1A2E);
const _kTextSec = Color(0xFF6B7280);
const _kAccepted = Color(0xFF00B8A3);
const _kError = Color(0xFFFF375F);

BoxDecoration get _cardDeco => BoxDecoration(
      color: _kSurface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4))
      ],
    );

// ─────────────────────────────────────────────────────────────────────────────
// ContestsScreen
// ─────────────────────────────────────────────────────────────────────────────

class ContestsScreen extends ConsumerStatefulWidget {
  const ContestsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<ContestsScreen> createState() => _ContestsScreenState();
}

class _ContestsScreenState extends ConsumerState<ContestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final username = authState.user?.username ?? '';
    final contestsAsync = ref.watch(contestListProvider);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top bar ──────────────────────────────────────────────────────
        if (!widget.embedded) _TopBar(username: username),
        if (!widget.embedded) const SizedBox(height: 16),
        // ── Title ────────────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Contests',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _kTextPri,
                    letterSpacing: -0.5),
              ),
            ),
            const SizedBox(height: 12),
            // ── Pill tabs ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: _kTextSec,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Live'),
                    Tab(text: 'Ended'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ── Body ──────────────────────────────────────────────────────────
            Expanded(
              child: contestsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator(color: _kPrimary)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Failed to load contests', style: const TextStyle(color: _kTextSec)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(contestListProvider),
                        style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                data: (data) => TabBarView(
                  controller: _tab,
                  children: [
                    _ContestList(contests: data['upcoming'] ?? [], type: 'upcoming'),
                    _ContestList(contests: data['live'] ?? [], type: 'live'),
                    _ContestList(contests: data['ended'] ?? [], type: 'ended'),
                  ],
                ),
              ),
            ),
          ],
        );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(child: content),
    );
  }
}

// ─── _TopBar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.username});
  final String username;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEDE9FF), width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/home'),
            child: const Text(
              '<Codemania/>',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _kPrimary,
                  letterSpacing: -0.5),
            ),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(username,
                style: const TextStyle(
                    color: _kPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─── _ContestList ─────────────────────────────────────────────────────────────

class _ContestList extends StatelessWidget {
  const _ContestList({required this.contests, required this.type});
  final List<ContestModel> contests;
  final String type; // 'upcoming' | 'live' | 'ended'

  @override
  Widget build(BuildContext context) {
    if (contests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 56, color: _kPrimary.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text('No $type contests',
                style: const TextStyle(color: _kTextSec, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: contests.length,
        itemBuilder: (ctx, i) => _ContestCard(contest: contests[i], type: type),
      ),
    );
  }
}

// ─── _ContestCard ─────────────────────────────────────────────────────────────

class _ContestCard extends StatelessWidget {
  const _ContestCard({required this.contest, required this.type});
  final ContestModel contest;
  final String type;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/contests/${contest.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: _cardDeco,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row + type badge
            Row(
              children: [
                Expanded(
                  child: Text(contest.title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kTextPri)),
                ),
                _TypeBadge(contestType: contest.contestType),
              ],
            ),
            const SizedBox(height: 8),
            // Time info
            Row(children: [
              const Icon(Icons.schedule_outlined, size: 14, color: _kTextSec),
              const SizedBox(width: 4),
              Text(_timeLabel(), style: const TextStyle(color: _kTextSec, fontSize: 13)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.assignment_outlined, size: 14, color: _kTextSec),
              const SizedBox(width: 4),
              Text('${contest.problemCount} problems',
                  style: const TextStyle(color: _kTextSec, fontSize: 13)),
            ]),
            const SizedBox(height: 14),
            // Countdown + action button
            Row(
              children: [
                _CountdownTimer(contest: contest, type: type),
                const Spacer(),
                _ActionButton(contest: contest, type: type),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel() {
    final dt = type == 'ended' ? contest.endTime : contest.startTime;
    final local = dt.toLocal();
    final pad = (int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${pad(local.month)}-${pad(local.day)} ${pad(local.hour)}:${pad(local.minute)}';
  }
}

// ─── _TypeBadge ───────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.contestType});
  final String contestType;

  @override
  Widget build(BuildContext context) {
    final isSolo = contestType == 'solo';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSolo ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isSolo ? 'Solo' : 'Team',
        style: TextStyle(
            color: isSolo ? const Color(0xFF2E7D32) : const Color(0xFF1565C0),
            fontSize: 11,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─── _CountdownTimer ──────────────────────────────────────────────────────────

class _CountdownTimer extends StatefulWidget {
  const _CountdownTimer({required this.contest, required this.type});
  final ContestModel contest;
  final String type;

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _updateRemaining());
    });
  }

  void _updateRemaining() {
    final target = widget.type == 'live'
        ? widget.contest.endTime
        : widget.contest.startTime;
    final now = DateTime.now().toUtc();
    _remaining = target.isAfter(now) ? target.difference(now) : Duration.zero;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining == Duration.zero) {
      return const SizedBox.shrink();
    }

    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    final label = widget.type == 'live' ? 'Ends in' : 'Starts in';
    final color = widget.type == 'live' ? _kError : _kPrimary;

    return Row(children: [
      Icon(Icons.timer_outlined, size: 14, color: color),
      const SizedBox(width: 4),
      Text('$label $h:$m:$s',
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 13)),
    ]);
  }
}

// ─── _ActionButton ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.contest, required this.type});
  final ContestModel contest;
  final String type;

  @override
  Widget build(BuildContext context) {
    String label;
    if (type == 'live') label = 'Enter Contest';
    else if (type == 'ended') label = 'View Results';
    else if (contest.isRegistered) label = 'Registered ✓';
    else label = 'Register';

    final isOutlined = type == 'ended' || (type == 'upcoming' && contest.isRegistered);

    if (isOutlined) {
      return OutlinedButton(
        onPressed: () => context.push('/contests/${contest.id}'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _kPrimary,
          side: const BorderSide(color: _kPrimary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      );
    }

    return ElevatedButton(
      onPressed: () => context.push('/contests/${contest.id}'),
      style: ElevatedButton.styleFrom(
        backgroundColor: type == 'live' ? _kAccepted : _kPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    );
  }
}
