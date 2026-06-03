import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:codemania/core/models/contest_model.dart';
import 'package:codemania/features/contests/providers/contest_provider.dart';
import 'package:codemania/providers/auth_provider.dart';
import 'package:codemania/services/socket_service.dart';

// ─── Theme ────────────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF6C5CE7);
const _kBg = Color(0xFFF5F3FF);
const _kSurface = Colors.white;
const _kTextPri = Color(0xFF1A1A2E);
const _kTextSec = Color(0xFF6B7280);
const _kAccepted = Color(0xFF00B8A3);
const _kError = Color(0xFFFF375F);
const _kEasy = Color(0xFF00B8A3);
const _kMedium = Color(0xFFFFA116);
const _kHard = Color(0xFFFF375F);

BoxDecoration _cardDeco() => BoxDecoration(
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
// ContestDetailScreen
// ─────────────────────────────────────────────────────────────────────────────

class ContestDetailScreen extends ConsumerWidget {
  const ContestDetailScreen({super.key, required this.contestId});
  final int contestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync =
        ref.watch(contestDetailProvider(contestId));

    return detailAsync.when(
      loading: () => Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kSurface,
          elevation: 0,
          title: const Text('Loading…', style: TextStyle(color: _kTextPri)),
        ),
        body: const Center(
            child: CircularProgressIndicator(color: _kPrimary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(backgroundColor: _kSurface, elevation: 0),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Failed to load contest',
                style: const TextStyle(color: _kTextSec)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  ref.read(contestDetailProvider(contestId).notifier).refresh(),
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ]),
        ),
      ),
      data: (contest) => _ContestDetailBody(contest: contest, contestId: contestId),
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

class _ContestDetailBodyState extends ConsumerState<_ContestDetailBody> {
  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  void _initSocket() async {
    try {
      await SocketService.connect();
      final user = ref.read(authProvider).user;
      final teamId = widget.contest.myRegistration?.team?.id ?? 0;
      if (user != null) {
        SocketService.joinContest(widget.contestId, teamId, user.id.toString());
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final contest = widget.contest;
    final contestId = widget.contestId;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/contests'),
          icon: const Icon(Icons.arrow_back, color: _kTextPri),
        ),
        title: Text(contest.title,
            style: const TextStyle(
                color: _kTextPri, fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          _AppBarTimer(contest: contest),
          const SizedBox(width: 12),
        ],
      ),
      body: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _LeftPanel(contest: contest, contestId: contestId),
                ),
                Expanded(
                  flex: 2,
                  child: _RightPanel(contestId: contestId, contest: contest),
                ),
              ],
            )
          : SingleChildScrollView(
              child: Column(children: [
                _LeftPanel(contest: contest, contestId: contestId),
                _RightPanel(contestId: contestId, contest: contest),
              ]),
            ),
    );
  }
}

// ─── _AppBarTimer ─────────────────────────────────────────────────────────────

class _AppBarTimer extends StatefulWidget {
  const _AppBarTimer({required this.contest});
  final ContestDetailModel contest;

  @override
  State<_AppBarTimer> createState() => _AppBarTimerState();
}

class _AppBarTimerState extends State<_AppBarTimer> {
  late Timer _t;
  late Duration _rem;

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
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.contest.status == 'ended' || _rem == Duration.zero) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text('Ended',
            style: TextStyle(color: _kTextSec, fontSize: 13)),
      );
    }
    final h = _rem.inHours.toString().padLeft(2, '0');
    final m = (_rem.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_rem.inSeconds % 60).toString().padLeft(2, '0');
    final label = widget.contest.status == 'live' ? 'Ends' : 'Starts';
    final color = widget.contest.status == 'live' ? _kError : _kPrimary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label $h:$m:$s',
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}

// ─── _LeftPanel ───────────────────────────────────────────────────────────────

class _LeftPanel extends ConsumerWidget {
  const _LeftPanel({required this.contest, required this.contestId});
  final ContestDetailModel contest;
  final int contestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Registration / team section
          if (contest.status == 'upcoming') ...[
            _RegistrationBanner(contest: contest, contestId: contestId),
            const SizedBox(height: 16),
          ],
          // Pending invitations
          if (contest.myTeamInvitations.isNotEmpty) ...[
            _PendingInvitations(contest: contest, contestId: contestId),
            const SizedBox(height: 16),
          ],
          // Problems list (live or ended)
          if (contest.status == 'live' || contest.status == 'ended') ...[
            _ProblemsList(contest: contest, contestId: contestId),
          ],
        ],
      ),
    );
  }
}

// ─── _RegistrationBanner ──────────────────────────────────────────────────────

class _RegistrationBanner extends ConsumerWidget {
  const _RegistrationBanner(
      {required this.contest, required this.contestId});
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
  const _RegistrationActions(
      {required this.contest, required this.contestId});
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
    ));
  }

  @override
  Widget build(BuildContext context) {
    final reg = widget.contest.myRegistration;
    final notifier =
        ref.read(contestDetailProvider(widget.contestId).notifier);

    if (reg == null) {
      // Not registered
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
      // Team — not registered
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
              style: TextStyle(
                  color: Colors.white70, fontSize: 13)),
        ],
      );
    }

    if (reg.type == 'solo') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.check_circle, color: _kAccepted, size: 20),
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

    // Team registration
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
            child: const Text('Create',
                style: TextStyle(color: Colors.white)),
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
      builder: (_) => _InviteSheet(
          notifier: notifier, contestId: widget.contestId),
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      child: Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14)),
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
        if (_searching)
          const CircularProgressIndicator(color: _kPrimary),
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
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
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
  const _PendingInvitations(
      {required this.contest, required this.contestId});
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

// ─── _ProblemsList ────────────────────────────────────────────────────────────

class _ProblemsList extends ConsumerWidget {
  const _ProblemsList({required this.contest, required this.contestId});
  final ContestDetailModel contest;
  final int contestId;

  Color _diffColor(String d) {
    switch (d.toLowerCase()) {
      case 'easy': return _kEasy;
      case 'hard': return _kHard;
      default: return _kMedium;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Problems',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _kTextPri)),
          const SizedBox(height: 8),
          ...contest.problems.map((p) {
            final solved = p.isSolvedByMe || p.isSolvedByTeam;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: solved
                      ? _kAccepted.withOpacity(0.15)
                      : const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  solved ? Icons.check : Icons.code,
                  color: solved ? _kAccepted : _kPrimary,
                  size: 18,
                ),
              ),
              title: Text(p.title,
                  style: const TextStyle(fontSize: 14, color: _kTextPri)),
              subtitle: Text(p.difficulty,
                  style: TextStyle(
                      color: _diffColor(p.difficulty), fontSize: 12)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${p.points} pts',
                      style: const TextStyle(
                          color: _kPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  if (p.isSolvedByTeam)
                    const Text('team solved',
                        style: TextStyle(color: _kAccepted, fontSize: 11))
                  else if (p.isSolvedByMe)
                    const Text('you solved',
                        style: TextStyle(color: _kAccepted, fontSize: 11)),
                ],
              ),
              onTap: contest.status == 'live'
                  ? () => context.push('/contests/$contestId/problems/${p.id}')
                  : null,
            );
          }),
        ],
      ),
    );
  }
}

// ─── _RightPanel — Leaderboard ────────────────────────────────────────────────

class _RightPanel extends ConsumerWidget {
  const _RightPanel({required this.contestId, required this.contest});
  final int contestId;
  final ContestDetailModel contest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbAsync = ref.watch(contestLeaderboardProvider(contestId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('Leaderboard',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: _kTextPri)),
              const Spacer(),
              const Icon(Icons.emoji_events, color: _kPrimary, size: 20),
            ]),
            const SizedBox(height: 12),
            lbAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: _kPrimary)),
              error: (e, _) => Center(
                  child: Text('Error loading leaderboard',
                      style: const TextStyle(color: _kTextSec))),
              data: (entries) {
                if (entries.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child: Text('No entries yet',
                            style: TextStyle(color: _kTextSec))),
                  );
                }

                final authUserId = ref.read(authProvider).user?.id;

                return Column(
                  children: entries.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final lb = entry.value;
                    final isMe = lb.userId != null && lb.userId == authUserId;

                    if (contest.contestType == 'team' && lb.members.isNotEmpty) {
                      return ExpansionTile(
                        leading: Text('#$rank',
                            style: TextStyle(
                                color: _rankColor(rank),
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        title: Text(lb.displayName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        trailing: Text('${lb.totalScore} pts',
                            style: const TextStyle(
                                color: _kPrimary,
                                fontWeight: FontWeight.w700)),
                        children: lb.members.map((m) => ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    _kPrimary.withOpacity(0.15),
                                child: Text(m.username[0].toUpperCase(),
                                    style: const TextStyle(
                                        color: _kPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ),
                              title: Text(m.username,
                                  style: const TextStyle(fontSize: 13)),
                              trailing: Text('${m.scoreContributed} pts',
                                  style: const TextStyle(
                                      color: _kTextSec, fontSize: 12)),
                            )).toList(),
                      );
                    }

                    return _LeaderboardRow(
                        rank: rank, entry: lb, isCurrentUser: isMe);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _rankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return _kTextSec;
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow(
      {required this.rank, required this.entry, required this.isCurrentUser});
  final int rank;
  final LeaderboardEntryModel entry;
  final bool isCurrentUser;

  Color _rankColor(int r) {
    if (r == 1) return const Color(0xFFFFD700);
    if (r == 2) return const Color(0xFFC0C0C0);
    if (r == 3) return const Color(0xFFCD7F32);
    return _kTextSec;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? _kPrimary.withOpacity(0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        SizedBox(
          width: 28,
          child: Text('#$rank',
              style: TextStyle(
                  color: _rankColor(rank),
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ),
        CircleAvatar(
          radius: 16,
          backgroundColor: _kPrimary.withOpacity(0.15),
          backgroundImage:
              entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
          child: entry.avatarUrl == null
              ? Text(entry.displayName[0].toUpperCase(),
                  style: const TextStyle(
                      color: _kPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13))
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Text(entry.displayName,
                style: const TextStyle(fontSize: 13, color: _kTextPri))),
        Text('${entry.problemsSolved} solved',
            style: const TextStyle(color: _kTextSec, fontSize: 12)),
        const SizedBox(width: 12),
        Text('${entry.totalScore} pts',
            style: const TextStyle(
                color: _kPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
      ]),
    );
  }
}
