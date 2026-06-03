import 'package:codemania/models/problem_model.dart';
import 'package:codemania/providers/auth_provider.dart';
import 'package:codemania/providers/problem_provider.dart';
import 'package:codemania/providers/submission_provider.dart';
import 'package:codemania/features/contests/providers/contest_provider.dart';
import 'package:codemania/core/models/contest_model.dart';
import 'package:codemania/features/contests/screens/contests_screen.dart';
import 'package:codemania/screens/user/problem_list_screen.dart';
import 'package:codemania/screens/user/profile_screen.dart';
import 'package:codemania/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(problemListProvider.notifier).fetchProblems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final problemState = ref.watch(problemListProvider);
    final user = authState.user;
    final colorScheme = Theme.of(context).colorScheme;

    final pages = [
      _LibraryPage(problemState: problemState),
      const ContestsScreen(embedded: true),
      ProblemListScreen(
        embedded: true,
        onOpenProblem: _openProblem,
      ),
      user != null
          ? ProfileScreen(userId: user.id)
          : _SignInPromptPage(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: SafeArea(
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(color: colorScheme.outline, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.menu_book_outlined, 'Library'),
              _buildNavItem(1, Icons.emoji_events_outlined, 'Contests'),
              _buildNavItem(2, Icons.search, 'Search'),
              _buildNavItem(3, Icons.person_outline, 'You'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Expanded(
      child: InkWell(
        onTap: () => _selectTab(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.activeTab : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isActive
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface.withOpacity(0.6),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: isActive
                    ? colorScheme.onBackground
                    : colorScheme.onSurface.withOpacity(0.6),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectTab(int index) {
    // Handle "You" tab (index 3) - check authentication
    if (index == 3) {
      final authState = ref.read(authProvider);
      if (authState.user == null) {
        // Not logged in, navigate to login
        context.go('/login');
        return;
      }
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openProblem(ProblemModel problem) {
    ref.read(problemListProvider.notifier).fetchProblemById(problem.id);
    context.go('/problems/${problem.id}');
  }
}

class _LibraryPage extends ConsumerWidget {
  const _LibraryPage({required this.problemState});

  final ProblemState problemState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contestsAsync = ref.watch(contestListProvider);
    final submissionsAsync = AsyncValue.data([]);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Library',
            style: textTheme.displayMedium,
          ),
          const SizedBox(height: 16),
          // Banner card
          InkWell(
            onTap: () => context.go('/contests'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, Color(0xFFFF8C00)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Active Contests',
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(Icons.emoji_events, color: Colors.white, size: 32),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Problems section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Problems', style: textTheme.headlineSmall),
              InkWell(
                onTap: () => context.go('/problems'),
                child: Icon(Icons.arrow_forward, color: colorScheme.onSurface.withOpacity(0.6)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DifficultyCard(
                  label: 'Easy',
                  count: problemState.problems.where((p) => p.difficulty == 'Easy').length,
                  color: AppTheme.getDifficultyColor('easy', isDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DifficultyCard(
                  label: 'Medium',
                  count: problemState.problems.where((p) => p.difficulty == 'Medium').length,
                  color: AppTheme.getDifficultyColor('medium', isDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DifficultyCard(
                  label: 'Hard',
                  count: problemState.problems.where((p) => p.difficulty == 'Hard').length,
                  color: AppTheme.getDifficultyColor('hard', isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Recent Submissions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Submissions', style: textTheme.headlineSmall),
              Icon(Icons.arrow_forward, color: colorScheme.onSurface.withOpacity(0.6)),
            ],
          ),
          const SizedBox(height: 12),
          submissionsAsync.when(
            data: (submissions) {
              final recent = submissions.take(3).toList();
              if (recent.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'No submissions yet',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: recent.map((sub) {
                  final isAccepted = sub.verdict?.toLowerCase().contains('accept') ?? false;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            sub.problemTitle ?? 'Problem',
                            style: textTheme.titleMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.getVerdictColor(sub.verdict ?? '', isDark),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            sub.verdict ?? 'Unknown',
                            style: textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(sub.submittedAt),
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => CircularProgressIndicator(color: colorScheme.primary),
            error: (e, s) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'No submissions yet',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Contests
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Contests', style: textTheme.headlineSmall),
              Icon(Icons.arrow_forward, color: colorScheme.onSurface.withOpacity(0.6)),
            ],
          ),
          const SizedBox(height: 12),
          contestsAsync.when(
            data: (contestsList) {
              final upcoming = [...?contestsList['upcoming']].take(2).toList();
              if (upcoming.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'No upcoming contests',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: upcoming.map((contest) => _ContestCard(contest: contest)).toList(),
              );
            },
            loading: () => CircularProgressIndicator(color: colorScheme.primary),
            error: (e, s) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'No contests available',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContestCard extends StatelessWidget {
  const _ContestCard({required this.contest});

  final ContestModel contest;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contest.title,
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _formatDateTime(contest.startTime),
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            _getCountdown(contest.startTime),
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getCountdown(DateTime startTime) {
    final now = DateTime.now();
    final diff = startTime.difference(now);
    if (diff.isNegative) return 'Started';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return 'Starts in ${hours}h ${minutes}m';
  }
}

class _SignInPromptPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 80,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 24),
            Text(
              'Sign in to track your progress',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Sign In'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('Create an account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.selectedIndex,
    required this.onItemTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (label: 'Home', icon: Icons.home_outlined),
      (label: 'Problems', icon: Icons.code_outlined),
      (label: 'Contests', icon: Icons.emoji_events_outlined),
      (label: 'Friends', icon: Icons.people_outline),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFEDEAF8),
        border: Border(right: BorderSide(color: Color(0xFFE4DFF2))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '<Codemania/>',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1F2148),
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 22),
            ...List.generate(items.length, (index) {
              final item = items[index];
              final isActive = selectedIndex == index;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color:
                      isActive ? const Color(0xFF5E2ED5) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => onItemTap(index),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF68708D),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            item.label,
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF68708D),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.username,
    required this.rating,
    required this.onLogout,
    this.onMenuTap,
  });

  final String username;
  final int rating;
  final VoidCallback onLogout;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFDFF),
        border: Border(bottom: BorderSide(color: Color(0xFFE9E4F4))),
      ),
      child: Row(
        children: [
          if (onMenuTap != null) ...[
            IconButton(
              onPressed: onMenuTap,
              icon: const Icon(Icons.menu),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F0FA),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 14),
                  Icon(Icons.search, size: 18, color: Color(0xFF96A0B5)),
                  SizedBox(width: 10),
                  Text(
                    'Search contests, problems...',
                    style: TextStyle(color: Color(0xFF96A0B5), fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                username,
                style: const TextStyle(
                  color: Color(0xFF202547),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Rank #$rating',
                style: const TextStyle(
                  color: Color(0xFF7352D5),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () {
              final authState = ref.read(authProvider);
              if (authState.user != null) {
                context.push('/profile/${authState.user!.id}');
              }
            },
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFD6C9F8),
              child: Icon(Icons.person, size: 18, color: Color(0xFF47308B)),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF7B7892)),
          ),
        ],
      ),
    );
  }
}

class _DashboardPage extends ConsumerWidget {
  const _DashboardPage({
    required this.problemState,
  });

  final ProblemState problemState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contestsAsync = ref.watch(contestListProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1320),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, Coder',
                        style: TextStyle(
                          color: Color(0xFF242453),
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Rank: #420  •  12 day streak',
                        style: TextStyle(
                          color: Color(0xFF6E6A89),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: Color(0xFF5C2CD5),
                    shape: StadiumBorder(),
                    padding: EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                  ),
                  child: Text('Solve Today\'s Problem'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _MetricCard(
                  title: 'Problems Solved',
                  value: '${problemState.problems.length}',
                  accent: const Color(0xFF24B88A),
                ),
                const _MetricCard(
                  title: 'Global Rank',
                  value: '420',
                  accent: Color(0xFF6A3BDE),
                ),
                const _MetricCard(
                  title: 'Day Streak',
                  value: '12',
                  accent: Color(0xFFF4A51B),
                ),
                const _MetricCard(
                  title: 'Total Points',
                  value: '2,450',
                  accent: Color(0xFF28A0ED),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Contests',
                        style: TextStyle(
                          color: Color(0xFF262651),
                          fontWeight: FontWeight.w800,
                          fontSize: 34,
                        ),
                      ),
                      const SizedBox(height: 12),
                      contestsAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (e, _) => const Text('Failed to load contests'),
                        data: (contestsList) {
                          final active = [
                            ...?contestsList['live'],
                            ...?contestsList['upcoming'],
                          ].take(2).toList();
                          
                          if (active.isEmpty) {
                            return const Text('No active contests right now', style: TextStyle(color: Color(0xFF6E6A89)));
                          }
                          
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: active.map((contest) {
                              return _ContestMiniCard(contest: contest);
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Recommended For You',
                        style: TextStyle(
                          color: Color(0xFF262651),
                          fontWeight: FontWeight.w800,
                          fontSize: 34,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _PracticeCard(
                              'Valid Palindrome', 'Easy', '64% solved this'),
                          _PracticeCard(
                              'Climbing Stairs', 'Medium', '42% solved this'),
                          _PracticeCard(
                              'Merge K Lists', 'Hard', '18% solved this'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                const SizedBox(
                  width: 300,
                  child: _DashboardSide(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.accent,
  });

  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E1F3)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.circle, size: 10, color: accent),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Color(0xFF6D7691), fontSize: 14),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF21274B),
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContestMiniCard extends StatelessWidget {
  const _ContestMiniCard({required this.contest});

  final ContestModel contest;

  @override
  Widget build(BuildContext context) {
    final isLive = contest.status == 'live';
    
    return Container(
      width: 360,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E1F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  contest.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF242453),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLive ? const Color(0xFFEBE6FA) : const Color(0xFFE7E1F3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isLive ? 'LIVE' : 'UPCOMING',
                  style: TextStyle(
                    color: isLive ? const Color(0xFF5E2ED5) : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF5E2ED5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  contest.contestType == 'team' ? 'Team' : 'Solo',
                  style: const TextStyle(
                      color: Color(0xFF5E2ED5),
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const Spacer(),
              const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF75809A)),
              const SizedBox(width: 4),
              _MiniTimer(contest: contest),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.go('/contests/${contest.id}'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5E2ED5),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              ),
              child: Text(isLive ? 'Enter Contest' : 'Register'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTimer extends StatefulWidget {
  const _MiniTimer({required this.contest});
  final ContestModel contest;

  @override
  State<_MiniTimer> createState() => _MiniTimerState();
}

class _MiniTimerState extends State<_MiniTimer> {
  late Duration _rem;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _update();
    _tick();
  }
  
  void _tick() async {
    while (!_disposed) {
      await Future.delayed(const Duration(seconds: 1));
      if (_disposed) break;
      if (mounted) setState(_update);
    }
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
    _disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.contest.status == 'ended' || _rem == Duration.zero) {
      return const Text('Ended', style: TextStyle(color: Color(0xFF75809A), fontSize: 13));
    }
    final h = _rem.inHours.toString().padLeft(2, '0');
    final m = (_rem.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_rem.inSeconds % 60).toString().padLeft(2, '0');
    return Text('$h:$m:$s', style: const TextStyle(color: Color(0xFF75809A), fontSize: 13, fontWeight: FontWeight.w600));
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard(this.title, this.level, this.progress);

  final String title;
  final String level;
  final String progress;

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    switch (level.toLowerCase()) {
      case 'easy':
        badgeColor = const Color(0xFF49C889);
        break;
      case 'medium':
        badgeColor = const Color(0xFFF5AD2E);
        break;
      default:
        badgeColor = const Color(0xFFFF6F6A);
    }

    return Container(
      width: 230,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E1F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              level,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF262651),
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress,
            style: const TextStyle(
              color: Color(0xFF7A829D),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFE9E5F4),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A3BDE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5E2ED5),
                shape: const StadiumBorder(),
              ),
              child: const Text('Solve Now'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSide extends StatelessWidget {
  const _DashboardSide();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFDFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE7E1F3)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Activity',
                style: TextStyle(
                  color: Color(0xFF262651),
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                ),
              ),
              SizedBox(height: 12),
              _ActivityRow('Two Sum', 'Accepted'),
              _ActivityRow('Reverse Integer', 'Accepted'),
              _ActivityRow('Longest Substring', 'Runtime Error'),
              _ActivityRow('Valid Parentheses', 'Accepted'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6A35E4), Color(0xFF4A1EA7)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join Discussion',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 30,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Discuss problems with 50k+ developers on Discord.',
                style: TextStyle(color: Color(0xFFD6CCF5)),
              ),
              SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Join Channel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF5E2ED5),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow(this.problem, this.verdict);

  final String problem;
  final String verdict;

  @override
  Widget build(BuildContext context) {
    final accepted = verdict.toLowerCase() == 'accepted';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F5FC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                problem,
                style: const TextStyle(
                  color: Color(0xFF242A4A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accepted
                    ? const Color(0xFFDAF4E9)
                    : const Color(0xFFFFE2E2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                verdict,
                style: TextStyle(
                  color: accepted
                      ? const Color(0xFF1D9E70)
                      : const Color(0xFFE25A5A),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

