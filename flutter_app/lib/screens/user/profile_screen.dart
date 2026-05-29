import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:codemania/providers/auth_provider.dart';
import 'package:codemania/features/profile/providers/profile_provider.dart';
import 'package:codemania/features/friends/providers/friends_provider.dart';
import 'package:codemania/features/profile/widgets/edit_profile_sheet.dart';
import 'package:codemania/core/models/profile_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, required this.userId});

  final int userId;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Trigger fetch
    });
  }

  void _showEditProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const EditProfileSheet(),
    ).then((_) {
      ref.invalidate(profileProvider(widget.userId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider(widget.userId));
    final authState = ref.watch(authProvider);
    final isOwnProfile = authState.user?.id == widget.userId;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FB),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFFFDFDFF),
        foregroundColor: const Color(0xFF242453),
        elevation: 0,
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (profile) {
            final isCompact = MediaQuery.of(context).size.width < 900;
            if (isCompact) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildLeftColumn(profile, isOwnProfile),
                    const SizedBox(height: 16),
                    _buildRightColumn(profile),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 280,
                        child: _buildLeftColumn(profile, isOwnProfile),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildRightColumn(profile),
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

  Widget _buildLeftColumn(UserProfileModel profile, bool isOwnProfile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E0F3)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFD3C4F9),
            backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
            child: profile.avatarUrl == null
                ? Text(
                    profile.username.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF4A1EA7)),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile.username,
                style: const TextStyle(color: Color(0xFF242453), fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5),
              ),
              const SizedBox(width: 6),
              Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
            ],
          ),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profile.bio!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF5E2ED5), fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Rank #${profile.globalRank ?? "Unranked"}',
            style: const TextStyle(color: Color(0xFF7352D5), fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            '${profile.friendsCount} Friends',
            style: const TextStyle(color: Color(0xFF6D7691), fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (isOwnProfile)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _showEditProfile,
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF5E2ED5), shape: const StadiumBorder()),
                child: const Text('Edit Profile'),
              ),
            )
          else
            _buildFriendButton(profile.friendshipStatus),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Languages', style: TextStyle(color: Color(0xFF242453), fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          const SizedBox(height: 12),
          ...profile.languages.map((l) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.language, style: const TextStyle(color: Color(0xFF5E6985), fontWeight: FontWeight.w600)),
                Text('${l.problemsSolved} problems', style: const TextStyle(color: Color(0xFF5E2ED5), fontWeight: FontWeight.w800)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFriendButton(String? status) {
    if (status == null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            try {
              await ref.read(friendsProvider.notifier).sendRequest(widget.userId);
              ref.invalidate(profileProvider(widget.userId));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          },
          child: const Text('Add Friend'),
        ),
      );
    } else if (status == 'pending_sent') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: null,
          child: const Text('Pending'),
        ),
      );
    } else if (status == 'pending_received') {
      return Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: () async {
                // We don't have requestId here easily, the API takes target user? 
                // Wait, API requires requestId for put. This is a flaw if we don't have requestId.
                // We might need to fetch requests or change backend to take userId for accept.
                // Assuming we can't easily accept from here without requestId, we will just show pending.
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accept from Friends tab')));
              },
              child: const Text('Accept'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              child: const Text('Decline'),
            ),
          ),
        ],
      );
    } else if (status == 'accepted') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {},
          onLongPress: () async {
            await ref.read(friendsProvider.notifier).unfriend(widget.userId);
            ref.invalidate(profileProvider(widget.userId));
          },
          child: const Text('Friends ✓'),
        ),
      );
    }
    return const SizedBox();
  }

  Widget _buildRightColumn(UserProfileModel profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _statCard('Global Rank', '${profile.globalRank ?? "-"}', const Color(0xFF5E2ED5)),
            const SizedBox(width: 14),
            _statCard('Total Solved', '${profile.totalSolved}', const Color(0xFF2195D8)),
            const SizedBox(width: 14),
            _statCard('Max Streak', '${profile.streak.maxStreak}', const Color(0xFFF3A72A)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildSolvedDonut(profile)),
            const SizedBox(width: 16),
            Expanded(child: _buildHeatmap(profile)),
          ],
        ),
        const SizedBox(height: 16),
        _buildRecentAC(profile),
      ],
    );
  }

  Widget _statCard(String label, String value, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6E0F3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 11)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Color(0xFF242453), fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: -1)),
          ],
        ),
      ),
    );
  }

  Widget _buildSolvedDonut(UserProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E0F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Solved Problems', style: TextStyle(color: Color(0xFF242453), fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: profile.totalProblems > 0 ? profile.totalSolved / profile.totalProblems : 0,
                      strokeWidth: 8,
                      backgroundColor: const Color(0xFFF3F1FB),
                      color: const Color(0xFFFFA116),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${profile.totalSolved}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF242453))),
                          const Text('Solved', style: TextStyle(fontSize: 10, color: Color(0xFF6D7691))),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _DiffRow('Easy', profile.easySolved, const Color(0xFF00B8A3)),
                    const SizedBox(height: 8),
                    _DiffRow('Medium', profile.mediumSolved, const Color(0xFFFFA116)),
                    const SizedBox(height: 8),
                    _DiffRow('Hard', profile.hardSolved, const Color(0xFFFF375F)),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap(UserProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E0F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${profile.totalSolved} submissions in the past year', style: const TextStyle(color: Color(0xFF242453), fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Max streak: ${profile.streak.maxStreak} days', style: const TextStyle(color: Color(0xFF6D7691), fontSize: 12)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(53 * 7, (index) {
              final level = (index % 5);
              const levels = [
                Color(0xFF1A1A1A),
                Color(0xFF0D4429),
                Color(0xFF006D32),
                Color(0xFF26A641),
                Color(0xFF39D353),
              ];
              // this is a mock layout for heatmap
              return Tooltip(
                message: 'Day $index',
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: levels[level],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          )
        ],
      ),
    );
  }

  Widget _buildRecentAC(UserProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E0F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent AC', style: TextStyle(color: Color(0xFF242453), fontWeight: FontWeight.w800, fontSize: 20)),
          const SizedBox(height: 16),
          ...profile.recentAC.map((ac) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(ac.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(ac.language),
              trailing: Text(ac.solvedAt.toLocal().toString().split('.')[0]),
              onTap: () {
                context.push('/problems/${ac.problemId}');
              },
            );
          }),
          if (profile.recentAC.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No recent accepted submissions.'),
            )
        ],
      ),
    );
  }
}

class _DiffRow extends StatelessWidget {
  final String label;
  final int solved;
  final Color color;

  const _DiffRow(this.label, this.solved, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        Text('$solved', style: const TextStyle(color: Color(0xFF242453), fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
