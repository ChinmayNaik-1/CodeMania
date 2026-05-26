import 'package:codemania/providers/auth_provider.dart';
import 'package:codemania/providers/submission_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(authProvider).user?.id;
      if (userId != null) {
        ref.read(submissionProvider.notifier).fetchHistory(userId: userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final submissionState = ref.watch(submissionProvider);
    final user = authState.user;

    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1320),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFDFF),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE6E0F3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: const Color(0xFFD3C4F9),
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Text(
                            user.username.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF4A1EA7),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.username,
                          style: const TextStyle(
                            color: Color(0xFF242453),
                            fontWeight: FontWeight.w900,
                            fontSize: 42,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Full-stack Dev | Competitive Coder',
                          style: TextStyle(
                            color: Color(0xFF5E2ED5),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _softButton('GitHub'),
                            const SizedBox(width: 8),
                            _softButton('LinkedIn'),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () {},
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF5E2ED5),
                                shape: const StadiumBorder(),
                              ),
                              child: const Text('Edit Profile'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _statCard('Total Points', '2,450', const Color(0xFF5E2ED5)),
                const SizedBox(width: 10),
                _statCard('Solved', '${submissionState.history.length}',
                    const Color(0xFF2195D8)),
                const SizedBox(width: 10),
                _statCard('Contests Won', '3', const Color(0xFFF3A72A)),
                const SizedBox(width: 10),
                _statCard('Streak', '12 days', const Color(0xFF27B683)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _skillBreakdown(),
                      const SizedBox(height: 12),
                      _activityHeatmap(),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 320,
                  child: Column(
                    children: [
                      _badgeShelf(),
                      const SizedBox(height: 12),
                      _recentlySolved(submissionState),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FB),
      body: SafeArea(child: body),
    );
  }

  Widget _softButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF5F6985),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6E0F3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF242453),
                fontWeight: FontWeight.w900,
                fontSize: 38,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skillBreakdown() {
    return _panel(
      title: 'Skill Breakdown',
      child: const Column(
        children: [
          _SkillLine('Arrays & Hashing', 0.85),
          _SkillLine('Strings', 0.70),
          _SkillLine('Trees', 0.60),
          _SkillLine('DP', 0.45),
          _SkillLine('Graphs', 0.30),
        ],
      ),
    );
  }

  Widget _activityHeatmap() {
    return _panel(
      title: 'Activity Heatmap',
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: List.generate(96, (index) {
          final level = (index * 37) % 5;
          const levels = [
            Color(0xFFE9E3F7),
            Color(0xFFD4C5F8),
            Color(0xFFB692F2),
            Color(0xFF915EE8),
            Color(0xFF6632D4),
          ];
          return Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: levels[level],
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }

  Widget _badgeShelf() {
    return _panel(
      title: 'Badges Shelf',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: const [
          _BadgeTile('Fast Solver', Icons.bolt, true),
          _BadgeTile('Streak Master', Icons.local_fire_department, true),
          _BadgeTile('Problem Solver', Icons.check_circle_outline, false),
          _BadgeTile('Contest Veteran', Icons.emoji_events_outlined, false),
        ],
      ),
    );
  }

  Widget _recentlySolved(SubmissionState submissionState) {
    return _panel(
      title: 'Recently Solved',
      child: Column(
        children: [
          ...submissionState.history.take(4).map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F4FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Problem ${item.problemId}',
                      style: const TextStyle(
                        color: Color(0xFF242453),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: item.verdict == 'accepted'
                          ? const Color(0xFFDDF4E8)
                          : const Color(0xFFFFE4E4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.verdict == 'accepted' ? 'Easy' : 'Medium',
                      style: TextStyle(
                        color: item.verdict == 'accepted'
                            ? const Color(0xFF1A9A69)
                            : const Color(0xFFE06060),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (submissionState.history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No recent submissions yet.',
                style: TextStyle(color: Color(0xFF7A839E)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _panel({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E0F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF242453),
              fontWeight: FontWeight.w800,
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SkillLine extends StatelessWidget {
  const _SkillLine(this.label, this.value);

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF5E6985),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                  color: Color(0xFF5E2ED5),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFECE7F8),
              borderRadius: BorderRadius.circular(999),
            ),
            child: FractionallySizedBox(
              widthFactor: value,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5E2ED5), Color(0xFF2195D8)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile(this.label, this.icon, this.active);

  final String label;
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE8E1FB) : const Color(0xFFF4F2FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor:
                active ? const Color(0xFF6A3BDE) : const Color(0xFFC6CCD8),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? const Color(0xFF2B2454) : const Color(0xFF8A93AC),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
