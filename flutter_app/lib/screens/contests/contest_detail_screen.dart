import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:codemania/models/contest.dart';
import 'package:codemania/models/team.dart';
import 'package:codemania/providers/auth_provider.dart';
import 'package:codemania/providers/contest_provider.dart';
import 'package:codemania/screens/contests/create_team_sheet.dart';
import 'package:codemania/screens/contests/invite_member_sheet.dart';
import 'package:codemania/widgets/leaderboard_widget.dart';

class ContestDetailScreen extends ConsumerWidget {
  const ContestDetailScreen({super.key, required this.contestId});

  final int contestId;

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  List<String> _tabsForStatus(String status) {
    if (status == 'registration_open') return ['Team', 'Info'];
    if (status == 'in_progress' || status == 'ended') return ['Problems', 'Leaderboard', 'Team'];
    return ['Info'];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contestDetailAsync = ref.watch(contestDetailProvider(contestId));

    return contestDetailAsync.when(
      data: (detail) {
        final contest = detail.contest;
        final tabs = _tabsForStatus(contest.status);

        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            appBar: AppBar(
              title: Text(contest.title),
              bottom: TabBar(
                tabs: tabs.map((label) => Tab(text: label)).toList(),
              ),
            ),
            body: TabBarView(
              children: tabs.map((label) {
                switch (label) {
                  case 'Team':
                    return _TeamTab(contest: contest, contestId: contestId);
                  case 'Problems':
                    return _ProblemsTab(contest: contest, detail: detail, contestId: contestId);
                  case 'Leaderboard':
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: LeaderboardWidget(
                        contestId: contestId,
                        contestStatus: contest.status,
                      ),
                    );
                  default:
                    return _InfoTab(contest: contest, formattedStart: _formatDate(contest.startsAt), formattedEnd: _formatDate(contest.endsAt));
                }
              }).toList(),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Failed to load contest: $error')),
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  const _InfoTab({
    required this.contest,
    required this.formattedStart,
    required this.formattedEnd,
  });

  final Contest contest;
  final String formattedStart;
  final String formattedEnd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (contest.description != null && contest.description!.isNotEmpty)
          Text(contest.description!, style: const TextStyle(color: Color(0xFF7A839E), height: 1.5)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFDFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6E0F3)),
          ),
          child: Column(
            children: [
              _DetailRow(label: 'Start time', value: formattedStart),
              const Divider(height: 20),
              _DetailRow(label: 'End time', value: formattedEnd),
              const Divider(height: 20),
              _DetailRow(label: 'Max team size', value: contest.maxTeamSize.toString()),
              const Divider(height: 20),
              _DetailRow(label: 'Penalty per wrong attempt', value: '${contest.penaltyMinutes} min'),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Color(0xFF7A839E), fontWeight: FontWeight.w600)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _TeamTab extends ConsumerWidget {
  const _TeamTab({required this.contest, required this.contestId});

  final Contest contest;
  final int contestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(myTeamProvider(contestId));
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.id;

    return teamAsync.when(
      data: (team) {
        if (team == null && contest.status == 'registration_open') {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.group_add, size: 64, color: Color(0xFFB8B1CC)),
                const SizedBox(height: 12),
                const Text("You're not in a team yet.", style: TextStyle(color: Color(0xFF7A839E))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => CreateTeamSheet(contestId: contestId),
                    );
                  },
                  child: const Text('Create a Team'),
                ),
              ],
            ),
          );
        }

        if (team == null) {
          return const Center(child: Text('Teams are not available yet.'));
        }

        final isLeader = currentUserId != null && currentUserId == team.leaderId;
        final canInvite = isLeader && team.members.length < contest.maxTeamSize && contest.status == 'registration_open';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(team.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        ),
                        if (isLeader)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDEAF8),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'You are the leader',
                              style: TextStyle(color: Color(0xFF5E2ED5), fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: team.members.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final member = team.members[index];
                        final initials = member.username.isNotEmpty
                            ? member.username.substring(0, 1).toUpperCase()
                            : '?';
                        final isMemberLeader = member.userId == team.leaderId;
                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFFEDEAF8),
                              child: Text(initials, style: const TextStyle(color: Color(0xFF5E2ED5))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(member.username, style: const TextStyle(fontWeight: FontWeight.w600))),
                            if (isMemberLeader)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F1FB),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text('Leader', style: TextStyle(fontSize: 12, color: Color(0xFF5E2ED5))),
                              ),
                          ],
                        );
                      },
                    ),
                    if (canInvite) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => InviteMemberSheet(teamId: team.id),
                            );
                          },
                          icon: const Icon(Icons.person_add),
                          label: const Text('Invite Member'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Failed to load team: $error')),
    );
  }
}

class _ProblemsTab extends ConsumerWidget {
  const _ProblemsTab({required this.contest, required this.detail, required this.contestId});

  final Contest contest;
  final ContestDetail detail;
  final int contestId;

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF49C889);
      case 'medium':
        return const Color(0xFFF5AD2E);
      case 'hard':
        return const Color(0xFFFF6F6A);
      default:
        return const Color(0xFF7A839E);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final problems = detail.problems;
    final teamAsync = ref.watch(myTeamProvider(contestId));

    if (problems.isEmpty) {
      return const Center(child: Text('No problems yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: problems.length,
      itemBuilder: (context, index) {
        final problem = problems[index];
        final difficulty = (problem is dynamic && (problem as dynamic).difficulty != null)
            ? (problem as dynamic).difficulty.toString()
            : 'Unknown';
        final badgeColor = _difficultyColor(difficulty);

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            title: Text(problem.title),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    difficulty,
                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${problem.points} pts', style: const TextStyle(color: Color(0xFF7A839E))),
              ],
            ),
            trailing: _SolvedIndicator(teamAsync: teamAsync),
            onTap: () => context.push('/contests/$contestId/problems/${problem.id}'),
          ),
        );
      },
    );
  }
}

class _SolvedIndicator extends StatelessWidget {
  const _SolvedIndicator({required this.teamAsync});

  final AsyncValue<Team?> teamAsync;

  @override
  Widget build(BuildContext context) {
    return teamAsync.when(
      data: (team) {
        if (team == null) {
          return const Icon(Icons.remove, color: Color(0xFFB8B1CC));
        }
        return const Icon(Icons.check_circle_outline, color: Color(0xFF2EAF57));
      },
      loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => const Icon(Icons.remove, color: Color(0xFFB8B1CC)),
    );
  }
}
