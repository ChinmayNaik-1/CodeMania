import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:codemania/models/contest.dart';
import 'package:codemania/models/team_invite.dart';
import 'package:codemania/providers/contest_provider.dart';

class ContestListScreen extends ConsumerWidget {
  const ContestListScreen({super.key});

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contestsAsync = ref.watch(contestListProvider);
    final invitesAsync = ref.watch(pendingInvitesProvider);
    final pendingCount = invitesAsync.value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contests'),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (pendingCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        pendingCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: pendingCount == 0
                ? null
                : () => _showInvitesSheet(context, ref, invitesAsync.value ?? const []),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: contestsAsync.when(
        data: (contests) {
          if (contests.isEmpty) {
            return const Center(child: Text('No contests yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: contests.length,
            itemBuilder: (context, index) {
              final contest = contests[index];
              return _ContestCard(
                contest: contest,
                formattedStarts: _formatDate(contest.startsAt),
                onTap: () => context.push('/contests/${contest.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load contests: $error'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(contestListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInvitesSheet(BuildContext context, WidgetRef ref, List<TeamInvite> invites) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _InvitesSheet(invites: invites),
    );
  }
}

class _ContestCard extends StatefulWidget {
  const _ContestCard({
    required this.contest,
    required this.formattedStarts,
    required this.onTap,
  });

  final Contest contest;
  final String formattedStarts;
  final VoidCallback onTap;

  @override
  State<_ContestCard> createState() => _ContestCardState();
}

class _ContestCardState extends State<_ContestCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.3,
      upperBound: 1.0,
    );

    if (widget.contest.status == 'in_progress') {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _ContestCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contest.status == 'in_progress' && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.contest.status != 'in_progress' && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  ({Color color, String label}) _statusStyle(String status) {
    switch (status) {
      case 'registration_open':
        return (color: const Color(0xFF2D8CFF), label: 'Open');
      case 'in_progress':
        return (color: const Color(0xFF2EAF57), label: 'Live');
      case 'ended':
        return (color: const Color(0xFF7A839E), label: 'Ended');
      default:
        return (color: const Color(0xFF7A839E), label: 'Upcoming');
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusStyle(widget.contest.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.contest.status == 'in_progress')
                    FadeTransition(
                      opacity: _pulseController,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2EAF57),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        color: status.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Color(0xFF7A839E)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.contest.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_month, size: 16, color: Color(0xFF7A839E)),
                  const SizedBox(width: 6),
                  Text(
                    widget.formattedStarts,
                    style: const TextStyle(color: Color(0xFF7A839E)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.people_alt_outlined, size: 16, color: Color(0xFF7A839E)),
                  const SizedBox(width: 6),
                  Text(
                    'Up to ${widget.contest.maxTeamSize} players',
                    style: const TextStyle(color: Color(0xFF7A839E)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvitesSheet extends ConsumerWidget {
  const _InvitesSheet({required this.invites});

  final List<TeamInvite> invites;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE6E0F3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Pending Invites', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (invites.isEmpty)
            const Text('No invites right now.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final invite = invites[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(invite.contestTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Team: ${invite.teamName}', style: const TextStyle(color: Color(0xFF7A839E))),
                        Text('Leader: ${invite.leaderUsername}', style: const TextStyle(color: Color(0xFF7A839E))),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  await ref.read(contestNotifierProvider.notifier).respondToInvite(invite.id, false);
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: const Text('Decline'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  await ref.read(contestNotifierProvider.notifier).respondToInvite(invite.id, true);
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: const Text('Accept'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
