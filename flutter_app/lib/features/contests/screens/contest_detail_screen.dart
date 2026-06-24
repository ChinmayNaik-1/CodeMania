import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:codemania/core/models/contest_model.dart';
import 'package:codemania/features/contests/providers/contest_provider.dart';
import 'package:codemania/providers/auth_provider.dart';
import 'package:codemania/services/socket_service.dart';

// ─── Theme ────────────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF6C5CE7);
const _kBg = Color(0xFFF7F7FB);
const _kSurface = Colors.white;
const _kTextPri = Color(0xFF1A1A2E);
const _kTextSec = Color(0xFF6B7280);
const _kAccepted = Color(0xFF00B8A3);
const _kError = Color(0xFFFF375F);
const _kPoints = Color(0xFFFF9F1C);
const _kEasy = Color(0xFF00B8A3);
const _kMedium = Color(0xFFFFA116);
const _kHard = Color(0xFFFF375F);

// Status visuals
Color _statusColor(String s) {
  switch (s) {
    case 'live':
      return _kAccepted;
    case 'upcoming':
      return _kPrimary;
    case 'ended':
    default:
      return _kTextSec;
  }
}

String _statusLabel(String s) {
  switch (s) {
    case 'live':
      return 'Live';
    case 'upcoming':
      return 'Upcoming';
    case 'ended':
    default:
      return 'Ended';
  }
}

String _formatContestDate(DateTime utc) {
  final local = utc.toLocal();
  final base = DateFormat('EEE, MMM d, HH:mm').format(local);
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final h = offset.inHours.abs();
  final m = (offset.inMinutes.abs() % 60);
  final off = m == 0 ? '$h' : '$h${m.toString().padLeft(2, '0')}';
  return '$base GMT$sign$off';
}

BoxDecoration _cardDeco() => BoxDecoration(
      color: _kSurface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4))
      ],
    );

// ─────────────────────────────────────────────────────────────────────────────
// ContestDetailScreen
// ─────────────────────────────────────────────────────────────────────────────

class ContestDetailScreen extends ConsumerWidget {
  const ContestDetailScreen({super.key, required this.contestId});
  final int contestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(contestDetailProvider(contestId));

    return detailAsync.when(
      loading: () => const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kPrimary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(backgroundColor: _kSurface, elevation: 0),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Failed to load contest',
                style: TextStyle(color: _kTextSec)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  ref.read(contestDetailProvider(contestId).notifier).refresh(),
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
              child:
                  const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ]),
        ),
      ),
      data: (contest) =>
          _ContestDetailBody(contest: contest, contestId: contestId),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ContestDetailBody
// ─────────────────────────────────────────────────────────────────────────────

class _ContestDetailBody extends ConsumerStatefulWidget {
  const _ContestDetailBody({required this.contest, required this.contestId});
  final ContestDetailModel contest;
  final int contestId;

  @override
  ConsumerState<_ContestDetailBody> createState() => _ContestDetailBodyState();
}

class _ContestDetailBodyState extends ConsumerState<_ContestDetailBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initSocket();
  }

  void _initSocket() async {
    try {
      await SocketService.connect();
      final user = ref.read(authProvider).user;
      final teamId = widget.contest.myRegistration?.team?.id ?? 0;
      if (user != null) {
        SocketService.joinContest(
            widget.contestId, teamId, user.id.toString());
      }
      SocketService.onLeaderboardUpdate((_) {
        ref.invalidate(contestLeaderboardProvider(widget.contestId));
      });
    } catch (e) {
      debugPrint('Socket init error: $e');
    }
  }

  @override
  void dispose() {
    final teamId = widget.contest.myRegistration?.team?.id ?? 0;
    SocketService.leaveContest(widget.contestId, teamId);
    _tabController.dispose();
    super.dispose();
  }

  bool get _isRegistered => widget.contest.myRegistration != null;

  @override
  Widget build(BuildContext context) {
    final contest = widget.contest;
    final contestId = widget.contestId;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ContestHeader(contest: contest),
            // "Not registered" banner — only meaningful before/while contest runs
            if (!_isRegistered && contest.status != 'ended')
              _NotRegisteredBanner(
                contest: contest,
                onRegisterTap: contest.status == 'upcoming'
                    ? () => _tabController.animateTo(0)
                    : null,
              ),
            _ContestTabBar(controller: _tabController),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── Problems tab ──
                  _ProblemsTab(
                    contest: contest,
                    contestId: contestId,
                    isRegistered: _isRegistered,
                  ),
                  // ── Ranking tab ──
                  _RankingTab(contest: contest, contestId: contestId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _ContestHeader ───────────────────────────────────────────────────────────

class _ContestHeader extends StatelessWidget {
  const _ContestHeader({required this.contest});
  final ContestDetailModel contest;

  void _share(BuildContext context) {
    Clipboard.setData(
        ClipboardData(text: 'Check out "${contest.title}" on CodeMania!'));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Contest link copied to clipboard'),
      backgroundColor: _kPrimary,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(contest.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    final onSurface = isDark ? Colors.white : _kTextPri;
    final onSurfaceSec = isDark ? Colors.white70 : _kTextSec;
    final iconBg = isDark ? colorScheme.surface.withOpacity(0.5) : Colors.white;

    BoxDecoration decoration;
    if (contest.status == 'ended') {
      decoration = BoxDecoration(
        color: isDark ? colorScheme.surfaceVariant.withOpacity(0.4) : const Color(0xFFF0F0F0),
      );
    } else {
      decoration = BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [const Color(0xFF2C2440), const Color(0xFF382B4A), const Color(0xFF2F2445)]
              : [const Color(0xFFFFE8C7), const Color(0xFFFFD7A8), const Color(0xFFFFE3D0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }

    return Container(
      decoration: decoration,
      child: Column(
        children: [
          // top bar: back + share
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go('/contests'),
                  icon: Icon(Icons.arrow_back, color: onSurface),
                ),
                const Spacer(),
                Material(
                  color: iconBg,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _share(context),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(Icons.ios_share, color: onSurface, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          // 3D cube emblem
          const Padding(
            padding: EdgeInsets.only(top: 4, bottom: 16),
            child: _CubeEmblem(),
          ),
          // title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              contest.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onSurface,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // date
          Text(
            _formatContestDate(contest.startTime),
            style: TextStyle(color: onSurfaceSec, fontSize: 14),
          ),
          const SizedBox(height: 8),
          // status dot
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                _statusLabel(contest.status),
                style: TextStyle(
                    color: statusColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
              if (contest.status != 'ended') ...[
                const SizedBox(width: 10),
                _HeaderCountdown(contest: contest),
              ],
            ],
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _CubeEmblem extends StatelessWidget {
  const _CubeEmblem();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            const Color(0xFFE8E2FF).withOpacity(0.9),
            const Color(0xFFFFE0F0).withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.6),
            blurRadius: 24,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFFFFB37A).withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(Icons.view_in_ar_rounded,
          size: 60, color: _kPrimary),
    );
  }
}

// ─── _HeaderCountdown ─────────────────────────────────────────────────────────

class _HeaderCountdown extends StatefulWidget {
  const _HeaderCountdown({required this.contest});
  final ContestDetailModel contest;

  @override
  State<_HeaderCountdown> createState() => _HeaderCountdownState();
}

class _HeaderCountdownState extends State<_HeaderCountdown> {
  Timer? _t;
  Duration _rem = Duration.zero;

  @override
  void initState() {
    super.initState();
    _update();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(_update);
    });
  }

  void _update() {
    final target = widget.contest.status == 'live'
        ? widget.contest.endTime
        : widget.contest.startTime;
    final diff = target.toUtc().difference(DateTime.now().toUtc());
    _rem = diff.isNegative ? Duration.zero : diff;
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_rem == Duration.zero) return const SizedBox.shrink();
    final d = _rem.inDays;
    final h = (_rem.inHours % 24).toString().padLeft(2, '0');
    final m = (_rem.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_rem.inSeconds % 60).toString().padLeft(2, '0');
    final time = d > 0 ? '${d}d $h:$m:$s' : '$h:$m:$s';
    final label = widget.contest.status == 'live' ? 'ends in' : 'starts in';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : _kTextSec;
    return Text('· $label $time',
        style: TextStyle(color: textColor, fontSize: 13));
  }
}

// ─── _NotRegisteredBanner ─────────────────────────────────────────────────────

class _NotRegisteredBanner extends StatelessWidget {
  const _NotRegisteredBanner({required this.contest, this.onRegisterTap});
  final ContestDetailModel contest;
  final VoidCallback? onRegisterTap;

  @override
  Widget build(BuildContext context) {
    final isUpcoming = contest.status == 'upcoming';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kError.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kError.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: _kError, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isUpcoming
                  ? "You're not registered yet. Register before it starts to participate."
                  : "You're not registered for this contest, so you can view problems but can't submit.",
              style: const TextStyle(
                  color: _kTextPri, fontSize: 13, height: 1.35),
            ),
          ),
          if (isUpcoming && onRegisterTap != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRegisterTap,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _kError,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Register'),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── _ContestTabBar ───────────────────────────────────────────────────────────

class _ContestTabBar extends StatelessWidget {
  const _ContestTabBar({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: TabBar(
        controller: controller,
        isScrollable: false,
        indicator: BoxDecoration(
          color: _kPrimary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: _kPrimary,
        unselectedLabelColor: _kTextSec,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        tabs: const [
          Tab(text: 'Problems'),
          Tab(text: 'Ranking'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProblemsTab
// ─────────────────────────────────────────────────────────────────────────────

class _ProblemsTab extends ConsumerWidget {
  const _ProblemsTab({
    required this.contest,
    required this.contestId,
    required this.isRegistered,
  });
  final ContestDetailModel contest;
  final int contestId;
  final bool isRegistered;

  Color _diffColor(String d) {
    switch (d.toLowerCase()) {
      case 'easy':
        return _kEasy;
      case 'hard':
        return _kHard;
      default:
        return _kMedium;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Upcoming contest → show registration card (problems hidden until live).
    if (contest.status == 'upcoming') {
      return RefreshIndicator(
        color: _kPrimary,
        onRefresh: () =>
            ref.read(contestDetailProvider(contestId).notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _RegistrationCard(contest: contest, contestId: contestId),
            if (contest.myTeamInvitations.isNotEmpty) ...[
              const SizedBox(height: 16),
              _PendingInvitations(contest: contest, contestId: contestId),
            ],
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Icon(Icons.lock_clock,
                      size: 48, color: _kTextSec.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  const Text('Problems unlock when the contest starts',
                      style: TextStyle(color: _kTextSec, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Live or ended → show problem list.
    final problems = contest.problems;
    final canOpen = contest.status == 'live' || contest.status == 'ended';

    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () =>
          ref.read(contestDetailProvider(contestId).notifier).refresh(),
      child: problems.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Text('No problems in this contest',
                      style: TextStyle(color: _kTextSec)),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: problems.length,
              separatorBuilder: (_, __) => Divider(
                  height: 1, color: _kTextSec.withOpacity(0.12), indent: 20, endIndent: 20),
              itemBuilder: (context, i) {
                final p = problems[i];
                final solved = p.isSolvedByMe || p.isSolvedByTeam;
                return InkWell(
                  onTap: canOpen
                      ? () {
                          // Live + not registered → submission is blocked by
                          // backend; warn early but still allow viewing.
                          if (contest.status == 'live' && !isRegistered) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'You are not registered — you can view this problem but cannot submit.'),
                                backgroundColor: _kError,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                          context.push(
                              '/contests/$contestId/problems/${p.id}').then((_) {
                            ref.invalidate(contestDetailProvider(contestId));
                          });
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    child: Row(
                      children: [
                        Icon(
                          solved
                              ? Icons.check_circle
                              : Icons.remove,
                          color: solved ? _kAccepted : _kTextSec,
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: _kTextPri,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.difficulty[0].toUpperCase() +
                                    p.difficulty.substring(1).toLowerCase(),
                                style: TextStyle(
                                    color: _diffColor(p.difficulty),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // points pill (LeetCode shows score on the right)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: _kBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${p.points}',
                            style: const TextStyle(
                                color: _kTextSec,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ─── _RegistrationCard ────────────────────────────────────────────────────────

class _RegistrationCard extends ConsumerWidget {
  const _RegistrationCard({required this.contest, required this.contestId});
  final ContestDetailModel contest;
  final int contestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFF8B80F8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contest Registration',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            contest.contestType == 'team'
                ? 'Team contest — max ${contest.maxTeamSize} members'
                : 'Individual contest',
            style:
                TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
          ),
          const SizedBox(height: 16),
          _RegistrationActions(contest: contest, contestId: contestId),
        ],
      ),
    );
  }
}

class _RegistrationActions extends ConsumerStatefulWidget {
  const _RegistrationActions({required this.contest, required this.contestId});
  final ContestDetailModel contest;
  final int contestId;

  @override
  ConsumerState<_RegistrationActions> createState() =>
      _RegistrationActionsState();
}

class _RegistrationActionsState extends ConsumerState<_RegistrationActions> {
  bool _loading = false;

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? _kError : _kPrimary,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final reg = widget.contest.myRegistration;
    final notifier =
        ref.read(contestDetailProvider(widget.contestId).notifier);

    if (reg == null) {
      if (widget.contest.contestType == 'solo') {
        return _WhiteButton(
          label: _loading ? 'Registering…' : 'Register Now',
          onTap: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  try {
                    await notifier.registerSolo();
                    _snack('Registered!');
                  } catch (e) {
                    _snack('Error: $e', isError: true);
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WhiteButton(
            label: _loading ? 'Creating…' : 'Create a Team',
            onTap: _loading
                ? null
                : () => _showCreateTeamDialog(context, notifier),
          ),
          const SizedBox(height: 8),
          const Text('or accept an invitation below',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      );
    }

    if (reg.type == 'solo') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('You are registered',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ]),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loading
                ? null
                : () async {
                    setState(() => _loading = true);
                    try {
                      await notifier.unregister();
                      _snack('Unregistered');
                    } catch (e) {
                      _snack('Error: $e', isError: true);
                    } finally {
                      if (mounted) setState(() => _loading = false);
                    }
                  },
            child: const Text('Unregister',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      );
    }

    final team = reg.team!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Team: ${team.name}',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        const SizedBox(height: 8),
        ...team.members.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white24,
                  child: Text(m.username[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Text(m.username,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
              ]),
            )),
        if (team.isLeader &&
            team.members.length < widget.contest.maxTeamSize) ...[
          const SizedBox(height: 10),
          _WhiteButton(
            label: '+ Invite Member',
            onTap: () => _showInviteSheet(context, notifier),
          ),
        ],
      ],
    );
  }

  void _showCreateTeamDialog(
      BuildContext ctx, ContestDetailNotifier notifier) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Create Team'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Team name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(d);
              setState(() => _loading = true);
              try {
                await notifier.createTeam(name);
                _snack('Team "$name" created!');
              } catch (e) {
                _snack('Error: $e', isError: true);
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
            child:
                const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showInviteSheet(BuildContext ctx, ContestDetailNotifier notifier) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) =>
          _InviteSheet(notifier: notifier, contestId: widget.contestId),
    );
  }
}

class _WhiteButton extends StatelessWidget {
  const _WhiteButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _kPrimary,
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
    );
  }
}

// ─── _InviteSheet ─────────────────────────────────────────────────────────────

class _InviteSheet extends StatefulWidget {
  const _InviteSheet({required this.notifier, required this.contestId});
  final ContestDetailNotifier notifier;
  final int contestId;

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await widget.notifier.searchUsers(q);
      if (mounted) setState(() => _results = results);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: const Color(0xFFE5E5F0),
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),
        const Text('Invite Member',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: _kTextPri)),
        const SizedBox(height: 12),
        TextField(
          controller: _ctrl,
          decoration: InputDecoration(
            hintText: 'Search username…',
            prefixIcon: const Icon(Icons.search, color: _kTextSec),
            filled: true,
            fillColor: const Color(0xFFF5F3FF),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
          onChanged: _search,
        ),
        const SizedBox(height: 8),
        if (_searching) const CircularProgressIndicator(color: _kPrimary),
        ..._results.map((u) => ListTile(
              leading: CircleAvatar(
                backgroundColor: _kPrimary.withOpacity(0.15),
                child: Text(u['username'][0].toString().toUpperCase(),
                    style: const TextStyle(
                        color: _kPrimary, fontWeight: FontWeight.bold)),
              ),
              title: Text(u['username'] as String),
              trailing: ElevatedButton(
                onPressed: () async {
                  try {
                    await widget.notifier.inviteUser(u['id'] as int);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Invitation sent!'),
                              backgroundColor: _kPrimary));
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: _kError));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: const Text('Invite'),
              ),
            )),
      ]),
    );
  }
}

// ─── _PendingInvitations ──────────────────────────────────────────────────────

class _PendingInvitations extends ConsumerWidget {
  const _PendingInvitations({required this.contest, required this.contestId});
  final ContestDetailModel contest;
  final int contestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(contestDetailProvider(contestId).notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pending Invitations',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _kTextPri)),
          const SizedBox(height: 8),
          ...contest.myTeamInvitations.map((inv) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                    '${inv.inviterUsername} invited you to ${inv.teamName}',
                    style: const TextStyle(fontSize: 14, color: _kTextPri)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () async {
                        await notifier.respondInvitation(inv.id, 'accept');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Joined team!'),
                                  backgroundColor: _kAccepted));
                        }
                      },
                      icon: const Icon(Icons.check, color: _kAccepted),
                    ),
                    IconButton(
                      onPressed: () async {
                        await notifier.respondInvitation(inv.id, 'reject');
                      },
                      icon: const Icon(Icons.close, color: _kError),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RankingTab
// ─────────────────────────────────────────────────────────────────────────────

class _RankingTab extends ConsumerWidget {
  const _RankingTab({required this.contest, required this.contestId});
  final ContestDetailModel contest;
  final int contestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbAsync = ref.watch(contestLeaderboardProvider(contestId));
    final authUserId = ref.read(authProvider).user?.id;

    return lbAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: _kPrimary)),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Error loading ranking',
                style: TextStyle(color: _kTextSec)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  ref.invalidate(contestLeaderboardProvider(contestId)),
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
              child:
                  const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return RefreshIndicator(
            color: _kPrimary,
            onRefresh: () async =>
                ref.invalidate(contestLeaderboardProvider(contestId)),
            child: ListView(
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.emoji_events_outlined,
                          size: 48, color: _kTextSec.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      Text(
                        contest.status == 'upcoming'
                            ? 'Ranking will appear once the contest begins'
                            : 'No participants ranked yet',
                        style: const TextStyle(color: _kTextSec),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final top3 = entries.take(3).toList();

        return RefreshIndicator(
          color: _kPrimary,
          onRefresh: () async =>
              ref.invalidate(contestLeaderboardProvider(contestId)),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (top3.isNotEmpty) ...[
                const SizedBox(height: 16),
                _Podium(top3: top3),
                const SizedBox(height: 16),
              ],
              ...entries.asMap().entries.map((e) {
                final rank = e.key + 1;
                final lb = e.value;
                final isMe = lb.userId != null && lb.userId == authUserId;
                return _RankingRow(
                  rank: rank,
                  entry: lb,
                  isCurrentUser: isMe,
                  isTeam: contest.contestType == 'team',
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// ─── _Podium (top 3) ──────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  const _Podium({required this.top3});
  final List<LeaderboardEntryModel> top3;

  @override
  Widget build(BuildContext context) {
    // Order: 2nd (left), 1st (center), 3rd (right)
    final first = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
              child: second != null
                  ? _PodiumItem(entry: second, rank: 2)
                  : const SizedBox.shrink()),
          Expanded(
              child: first != null
                  ? _PodiumItem(entry: first, rank: 1)
                  : const SizedBox.shrink()),
          Expanded(
              child: third != null
                  ? _PodiumItem(entry: third, rank: 3)
                  : const SizedBox.shrink()),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  const _PodiumItem({required this.entry, required this.rank});
  final LeaderboardEntryModel entry;
  final int rank;

  Color get _ringColor {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      default:
        return const Color(0xFFCD7F32);
    }
  }

  String _timeLabel() {
    final t = entry.lastAcceptedAt;
    if (t == null) return '${entry.totalScore} pts';
    return DateFormat('HH:mm:ss').format(t.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final avatarRadius = rank == 1 ? 34.0 : 28.0;
    return Column(
      children: [
        // rank number above
        Text('$rank',
            style: TextStyle(
                color: _ringColor,
                fontWeight: FontWeight.w800,
                fontSize: rank == 1 ? 22 : 18)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _ringColor, width: 3),
          ),
          child: CircleAvatar(
            radius: avatarRadius,
            backgroundColor: _kPrimary.withOpacity(0.12),
            backgroundImage: entry.avatarUrl != null
                ? NetworkImage(entry.avatarUrl!)
                : null,
            child: entry.avatarUrl == null
                ? Text(
                    entry.displayName.isNotEmpty
                        ? entry.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: _kPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: rank == 1 ? 24 : 20))
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            entry.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: _kTextPri,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
        ),
        const SizedBox(height: 2),
        Text(_timeLabel(),
            style: const TextStyle(color: _kTextSec, fontSize: 12)),
      ],
    );
  }
}

// ─── _RankingRow ──────────────────────────────────────────────────────────────

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.rank,
    required this.entry,
    required this.isCurrentUser,
    required this.isTeam,
  });
  final int rank;
  final LeaderboardEntryModel entry;
  final bool isCurrentUser;
  final bool isTeam;

  String _timeLabel() {
    final t = entry.lastAcceptedAt;
    if (t == null) return '${entry.problemsSolved} solved';
    return DateFormat('HH:mm:ss').format(t.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser ? _kPrimary.withOpacity(0.08) : _kSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('$rank',
                style: const TextStyle(
                    color: _kTextPri,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: _kPrimary.withOpacity(0.12),
            backgroundImage:
                entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
            child: entry.avatarUrl == null
                ? Text(
                    entry.displayName.isNotEmpty
                        ? entry.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: _kPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _kTextPri,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
                if (isTeam && entry.members.isNotEmpty)
                  Text(
                    entry.members.map((m) => m.username).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _kTextSec, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${entry.totalScore} ',
                      style: const TextStyle(
                          color: _kPoints,
                          fontWeight: FontWeight.w800,
                          fontSize: 16),
                    ),
                    const TextSpan(
                      text: 'pt',
                      style: TextStyle(color: _kPoints, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(_timeLabel(),
                  style: const TextStyle(color: _kTextSec, fontSize: 12)),
            ],
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: _kTextSec, size: 18),
        ],
      ),
    );
  }
}
