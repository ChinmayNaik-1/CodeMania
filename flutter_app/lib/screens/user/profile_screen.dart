import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:codemania/providers/auth_provider.dart';
import 'package:codemania/features/profile/providers/profile_provider.dart';
import 'package:codemania/features/friends/providers/friends_provider.dart';
import 'package:codemania/features/profile/widgets/edit_profile_sheet.dart';
import 'package:codemania/core/models/profile_model.dart';

import 'package:codemania/widgets/submission_heatmap.dart';

// ─── Design tokens (app light theme) ─────────────────────────────────────────
const _kBg      = Color(0xFFF0F0F8);
const _kCard    = Color(0xFFFFFFFF);
const _kBorder  = Color(0xFFE5E5F0);
const _kAccent  = Color(0xFF6C3CE1);
const _kTextPri = Color(0xFF1A1A2E);
const _kTextSec = Color(0xFF666680);
const _kEasy    = Color(0xFF00B8A3);
const _kMedium  = Color(0xFFFFA116);
const _kHard    = Color(0xFFFF375F);
const _kGreen   = Color(0xFF22C55E);
const _kDanger  = Color(0xFFEF4444);



// ─────────────────────────────────────────────────────────────────────────────
// Screen — no sidebar (full-page view; navigate back via AppBar back button)
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, required this.userId});
  final int userId;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _showEditProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EditProfileSheet(),
    ).then((_) => ref.invalidate(profileProvider(widget.userId)));
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: isError ? _kDanger : _kAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider(widget.userId));
    final authState = ref.watch(authProvider);
    final isOwn = authState.user?.id == widget.userId;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(color: _kTextPri, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          if (isOwn)
            IconButton(
              icon: const Icon(Icons.settings, size: 22, color: _kTextSec),
              onPressed: () => context.push('/settings'),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _kAccent)),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: _kDanger, size: 48),
              const SizedBox(height: 12),
              const Text('Failed to load profile',
                  style: TextStyle(color: _kTextPri, fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              Text(err.toString(),
                  style: const TextStyle(color: _kTextSec, fontSize: 12)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(profileProvider(widget.userId)),
                style: FilledButton.styleFrom(backgroundColor: _kAccent),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) => FadeTransition(
          opacity: _fade,
          child: LayoutBuilder(builder: (ctx, bc) {
            final isWide = bc.maxWidth >= 900;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 280,
                          child: _LeftPanel(
                            profile: profile,
                            isOwn: isOwn,
                            onEdit: _showEditProfile,
                            onSnack: _snack,
                            userId: widget.userId,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(child: _RightPanel(profile: profile, userId: widget.userId)),
                      ],
                    )
                  : Column(
                      children: [
                        _LeftPanel(
                          profile: profile,
                          isOwn: isOwn,
                          onEdit: _showEditProfile,
                          onSnack: _snack,
                          userId: widget.userId,
                        ),
                        const SizedBox(height: 16),
                        _RightPanel(profile: profile, userId: widget.userId),
                      ],
                    ),
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Left Panel
// ─────────────────────────────────────────────────────────────────────────────

class _LeftPanel extends ConsumerWidget {
  const _LeftPanel({
    required this.profile,
    required this.isOwn,
    required this.onEdit,
    required this.onSnack,
    required this.userId,
  });
  final UserProfileModel profile;
  final bool isOwn;
  final VoidCallback onEdit;
  final void Function(String, {bool isError}) onSnack;
  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          CircleAvatar(
            radius: 44,
            backgroundColor: _kAccent.withOpacity(0.15),
            backgroundImage:
                profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
            child: profile.avatarUrl == null
                ? Text(
                    profile.username.isNotEmpty ? profile.username[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w900, color: _kAccent),
                  )
                : null,
          ),
          const SizedBox(height: 14),

          // Username
          Text(
            profile.username,
            style: const TextStyle(
                color: _kTextPri, fontWeight: FontWeight.w800, fontSize: 22),
          ),

          // Join date
          if (profile.createdAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Joined ${_fmtDate(profile.createdAt!)}',
              style: const TextStyle(color: _kTextSec, fontSize: 12),
            ),
          ],

          // Bio
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              profile.bio!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kTextSec, fontSize: 13),
            ),
          ],

          const SizedBox(height: 16),

          // Stats row: Solved | Contests | Friends
          _inlineStats(profile),

          const SizedBox(height: 16),

          // Edit / Friend action button
          SizedBox(
            width: double.infinity,
            child: isOwn
                ? FilledButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Profile'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _kAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  )
                : _FriendActionButton(
                    profile: profile,
                    userId: userId,
                    onSnack: onSnack,
                  ),
          ),

          // Languages
          if (profile.languages.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Languages',
                  style: TextStyle(
                      color: _kTextPri, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            const SizedBox(height: 10),
            ...profile.languages.map(
              (l) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l.language,
                        style: const TextStyle(color: _kTextSec, fontSize: 13)),
                    Text('${l.problemsSolved} solved',
                        style: const TextStyle(
                            color: _kAccent, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _inlineStats(UserProfileModel p) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          _statCell('${p.totalSolved}', 'Solved'),
          _divider(),
          _statCell('${p.contestHistory.length}', 'Contests'),
          _divider(),
          _statCell('0', 'Friends'),
        ],
      ),
    );
  }

  Widget _statCell(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: _kTextPri, fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: _kTextSec, fontSize: 11)),
          ],
        ),
      );

  Widget _divider() =>
      Container(width: 1, height: 30, color: _kBorder);

  String _fmtDate(DateTime dt) {
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${m[dt.month]} ${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Friend action button (Add Friend / Pending / Friends ✓)
// ─────────────────────────────────────────────────────────────────────────────

class _FriendActionButton extends ConsumerStatefulWidget {
  const _FriendActionButton({
    required this.profile,
    required this.userId,
    required this.onSnack,
  });
  final UserProfileModel profile;
  final int userId;
  final void Function(String, {bool isError}) onSnack;

  @override
  ConsumerState<_FriendActionButton> createState() => _FriendActionButtonState();
}

class _FriendActionButtonState extends ConsumerState<_FriendActionButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.profile.friendshipStatus;

    if (status == 'accepted') {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.people, size: 16, color: _kGreen),
        label: const Text('Friends', style: TextStyle(color: _kGreen)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _kGreen),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    if (status == 'pending_sent') {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _kBorder),
          foregroundColor: _kTextSec,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('Request Pending'),
      );
    }

    return FilledButton.icon(
      onPressed: _loading ? null : () async {
        setState(() => _loading = true);
        try {
          await ref.read(friendsProvider.notifier).sendFriendRequest(widget.userId);
          widget.onSnack('Friend request sent!');
          ref.invalidate(profileProvider(widget.userId));
        } catch (e) {
          widget.onSnack(e.toString(), isError: true);
        } finally {
          if (mounted) setState(() => _loading = false);
        }
      },
      icon: _loading
          ? const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.person_add, size: 16),
      label: const Text('Add Friend'),
      style: FilledButton.styleFrom(
        backgroundColor: _kAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Right Panel
// ─────────────────────────────────────────────────────────────────────────────

class _RightPanel extends ConsumerWidget {
  const _RightPanel({required this.profile, required this.userId});
  final UserProfileModel profile;
  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top stat cards ────────────────────────────────────────────────
        Row(children: [
          _BigStat(label: 'Global Rank',
              value: profile.globalRank != null ? '#${profile.globalRank}' : '—',
              accent: _kAccent),
          const SizedBox(width: 12),
          _BigStat(label: 'Total Solved', value: '${profile.totalSolved}',
              accent: const Color(0xFF2F81F7)),
          const SizedBox(width: 12),
          _BigStat(label: 'Max Streak', value: '${profile.streak.maxStreak}d',
              accent: _kMedium),
        ]),

        const SizedBox(height: 16),

        // ── Solved by difficulty ──────────────────────────────────────────
        _Section(
          title: 'Problems Solved',
          child: _SolvedPanel(profile: profile),
        ),

        const SizedBox(height: 16),

        // ── Heatmap ───────────────────────────────────────────────────────
        _Section(
          title: 'Submission Activity',
          child: SubmissionHeatmap(userId: userId.toString()),
        ),

        const SizedBox(height: 16),

        // ── Recent AC ─────────────────────────────────────────────────────
        _Section(
          title: 'Recent Accepted',
          child: _RecentAC(profile: profile),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}

// ─── Solved panel ─────────────────────────────────────────────────────────────

class _SolvedPanel extends StatelessWidget {
  const _SolvedPanel({required this.profile});
  final UserProfileModel profile;

  @override
  Widget build(BuildContext context) {
    final total = profile.totalProblems > 0 ? profile.totalProblems : 1;

    return Row(
      children: [
        SizedBox(
          width: 110, height: 110,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: (profile.totalSolved / total).clamp(0.0, 1.0),
                strokeWidth: 10,
                backgroundColor: _kBg,
                valueColor: const AlwaysStoppedAnimation<Color>(_kMedium),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${profile.totalSolved}',
                        style: const TextStyle(
                            color: _kTextPri, fontSize: 26, fontWeight: FontWeight.w900)),
                    const Text('Solved',
                        style: TextStyle(color: _kTextSec, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 28),
        Expanded(
          child: Column(
            children: [
              _DiffBar(label: 'Easy', solved: profile.easySolved, total: total, color: _kEasy),
              const SizedBox(height: 10),
              _DiffBar(label: 'Medium', solved: profile.mediumSolved, total: total, color: _kMedium),
              const SizedBox(height: 10),
              _DiffBar(label: 'Hard', solved: profile.hardSolved, total: total, color: _kHard),
            ],
          ),
        ),
      ],
    );
  }
}

class _DiffBar extends StatelessWidget {
  const _DiffBar({required this.label, required this.solved, required this.total, required this.color});
  final String label;
  final int solved;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? (solved / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          Text('$solved', style: const TextStyle(color: _kTextPri, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: _kBg,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ─── Recent AC ────────────────────────────────────────────────────────────────

class _RecentAC extends StatelessWidget {
  const _RecentAC({required this.profile});
  final UserProfileModel profile;

  @override
  Widget build(BuildContext context) {
    if (profile.recentAC.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text('No accepted submissions yet.',
              style: TextStyle(color: _kTextSec)),
        ),
      );
    }

    return Column(
      children: profile.recentAC.take(10).map((ac) {
        final ago = _timeAgo(ac.solvedAt);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/problems/${ac.problemId}'),
                  child: Text(
                    ac.title,
                    style: const TextStyle(
                      color: _kAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                      decorationColor: _kAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _VerdictChip(verdict: 'Accepted'),
              const SizedBox(width: 10),
              Text(ago, style: const TextStyle(color: _kTextSec, fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}

class _VerdictChip extends StatelessWidget {
  const _VerdictChip({required this.verdict});
  final String verdict;

  @override
  Widget build(BuildContext context) {
    final isAC = verdict.toLowerCase() == 'accepted' || verdict.toLowerCase() == 'ac';
    final bg = isAC ? _kGreen.withOpacity(0.12) : _kDanger.withOpacity(0.12);
    final fg = isAC ? _kGreen : _kDanger;
    final label = isAC ? 'AC' : verdict.substring(0, verdict.length.clamp(0, 3)).toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared card & stat helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({this.title, required this.child});
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!,
                style: const TextStyle(
                    color: _kTextPri, fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({required this.label, required this.value, required this.accent});
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: TextStyle(
                    color: accent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: _kTextPri, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1)),
          ],
        ),
      ),
    );
  }
}
