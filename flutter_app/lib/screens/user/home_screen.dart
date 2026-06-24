import 'package:codemania/models/problem_model.dart';
import 'package:codemania/providers/auth_provider.dart';
import 'package:codemania/providers/problem_provider.dart';
import 'package:codemania/providers/submission_provider.dart';
import 'package:codemania/features/contests/providers/contest_provider.dart';
import 'package:codemania/core/models/contest_model.dart';
import 'package:codemania/features/contests/screens/contests_screen.dart';
import 'package:codemania/screens/user/profile_screen.dart';
import 'package:codemania/screens/user/problem_list_screen.dart';
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
  String? _initialTopic;

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
      _LibraryPage(
        problemState: problemState,
        onOpenProblem: _openProblem,
        onSelectTab: _selectTab,
      ),
      const ContestsScreen(embedded: true),
      ProblemListScreen(
        embedded: true,
        initialTopic: _initialTopic,
        onOpenProblem: _openProblem,
      ),
      user != null
          ? ProfileScreen(userId: user.id)
          : _SignInPromptPage(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: false,
      // SafeArea keeps embedded pages below the status bar. Bottom is handled by
      // the bottomNavigationBar (which already pads the system gesture inset).
      body: SafeArea(
        bottom: false,
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        height: 64 + MediaQuery.of(context).padding.bottom,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
        ),
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

  void _selectTab(int index, {String? topic}) {
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
      if (topic != null) {
        _initialTopic = topic;
      }
    });
  }

  void _openProblem(ProblemModel problem) {
    ref.read(problemListProvider.notifier).fetchProblemById(problem.id);
    context.push('/problems/${problem.id}');
  }
}

class _LibraryPage extends ConsumerWidget {
  const _LibraryPage({
    required this.problemState,
    required this.onOpenProblem,
    required this.onSelectTab,
  });

  final ProblemState problemState;
  final void Function(ProblemModel problem) onOpenProblem;
  final void Function(int index, {String? topic}) onSelectTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contestsAsync = ref.watch(contestListProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final problems = problemState.problems;
    final easyCount =
        problems.where((p) => p.difficulty.toLowerCase() == 'easy').length;
    final medCount =
        problems.where((p) => p.difficulty.toLowerCase() == 'medium').length;
    final hardCount =
        problems.where((p) => p.difficulty.toLowerCase() == 'hard').length;
    final solvedCount = problems.where((p) => p.isSolved == true).length;
    final totalCount = problems.length;
    final progress = totalCount == 0 ? 0.0 : solvedCount / totalCount;

    // A deterministic "daily" problem so it stays stable through the day.
    final ProblemModel? daily = problems.isEmpty
        ? null
        : problems[DateTime.now().day % problems.length];

    // Trending = first few problems (backend returns ordered list).
    final trending = problems.take(5).toList();

    return RefreshIndicator(
      color: colorScheme.primary,
      onRefresh: () async {
        ref.read(problemListProvider.notifier).fetchProblems();
        ref.invalidate(contestListProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting header ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user != null ? user.username : 'Welcome, Coder',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    if (user != null) {
                      context.push('/profile/${user.id}');
                    } else {
                      context.go('/login');
                    }
                  },
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.primary.withOpacity(0.15),
                    backgroundImage: user?.avatarUrl != null
                        ? NetworkImage(user!.avatarUrl!)
                        : null,
                    child: user?.avatarUrl == null
                        ? Text(
                            user != null && user.username.isNotEmpty
                                ? user.username[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Daily challenge hero ──
            _DailyChallengeCard(
              problem: daily,
              onTap: daily == null ? null : () => onOpenProblem(daily),
            ),
            const SizedBox(height: 20),

            // ── Stats strip ──
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.check_circle_outline,
                    label: 'Solved',
                    value: '$solvedCount',
                    color: AppTheme.getDifficultyColor('easy', isDark),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    icon: Icons.bolt_outlined,
                    label: 'Total',
                    value: '$totalCount',
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    icon: Icons.military_tech_outlined,
                    label: 'Rating',
                    value: user != null ? '${user.rating}' : '—',
                    color: const Color(0xFF28A0ED),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Progress card ──
            _ProgressCard(
              solved: solvedCount,
              total: totalCount,
              progress: progress,
            ),
            const SizedBox(height: 24),

            // ── Topics ──
            Text('Topics', style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 12),
            SizedBox(
              height: 96,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _TopicChip(
                    label: 'Arrays',
                    icon: Icons.data_array,
                    color: const Color(0xFF6A3BDE),
                    onTap: () => onSelectTab(2, topic: 'Array'),
                  ),
                  _TopicChip(
                    label: 'Strings',
                    icon: Icons.text_fields,
                    color: const Color(0xFF24B88A),
                    onTap: () => onSelectTab(2, topic: 'String'),
                  ),
                  _TopicChip(
                    label: 'DP',
                    icon: Icons.account_tree_outlined,
                    color: const Color(0xFFF4A51B),
                    onTap: () => onSelectTab(2, topic: 'Dynamic Programming'),
                  ),
                  _TopicChip(
                    label: 'Graphs',
                    icon: Icons.hub_outlined,
                    color: const Color(0xFF28A0ED),
                    onTap: () => onSelectTab(2, topic: 'Graph'),
                  ),
                  _TopicChip(
                    label: 'Trees',
                    icon: Icons.park_outlined,
                    color: const Color(0xFFE5264A),
                    onTap: () => onSelectTab(2, topic: 'Tree'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Difficulty breakdown ──
            Text('By Difficulty', style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DifficultyCard(
                    label: 'Easy',
                    count: easyCount,
                    color: AppTheme.getDifficultyColor('easy', isDark),
                    onTap: () => onSelectTab(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DifficultyCard(
                    label: 'Medium',
                    count: medCount,
                    color: AppTheme.getDifficultyColor('medium', isDark),
                    onTap: () => onSelectTab(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DifficultyCard(
                    label: 'Hard',
                    count: hardCount,
                    color: AppTheme.getDifficultyColor('hard', isDark),
                    onTap: () => onSelectTab(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Trending problems ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Trending Problems', style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onSelectTab(2),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      'See all',
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (problemState.isLoading && trending.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: CircularProgressIndicator(color: colorScheme.primary)),
              )
            else if (trending.isEmpty)
              _EmptyHint(text: 'No problems available yet')
            else
              ...trending.asMap().entries.map((e) => _TrendingProblemTile(
                    index: e.key + 1,
                    problem: e.value,
                    onTap: () => onOpenProblem(e.value),
                  )),
            const SizedBox(height: 24),

            // ── Contests ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Contests', style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onSelectTab(1),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      'See all',
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            contestsAsync.when(
              data: (contestsList) {
                final upcoming = [
                  ...?contestsList['live'],
                  ...?contestsList['upcoming'],
                ].take(3).toList();
                if (upcoming.isEmpty) {
                  return _EmptyHint(text: 'No upcoming contests');
                }
                return Column(
                  children: upcoming
                      .map((contest) => _ContestCard(
                            contest: contest,
                            onTap: () => context.push('/contests/${contest.id}'),
                          ))
                      .toList(),
                );
              },
              loading: () => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                    child: CircularProgressIndicator(color: colorScheme.primary)),
              ),
              error: (e, s) => _EmptyHint(text: 'No contests available'),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }
}

// ─── _DailyChallengeCard ──────────────────────────────────────────────────────

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({required this.problem, this.onTap});

  final ProblemModel? problem;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, const Color(0xFFFF8C00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department,
                    color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  'DAILY CHALLENGE',
                  style: textTheme.labelMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              problem?.title ?? 'Loading today\'s problem…',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              problem != null
                  ? problem!.difficulty
                  : 'Come back daily to keep your streak',
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Solve now',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward,
                      size: 18, color: colorScheme.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _StatTile ────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _ProgressCard ────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.solved,
    required this.total,
    required this.progress,
  });

  final int solved;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pct = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 6,
                    backgroundColor: colorScheme.outline.withOpacity(0.3),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colorScheme.secondary),
                  ),
                ),
                Text(
                  '$pct%',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Progress',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  total == 0
                      ? 'Start solving to track progress'
                      : '$solved of $total problems solved',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _TopicChip ───────────────────────────────────────────────────────────────

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 84,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── _TrendingProblemTile ─────────────────────────────────────────────────────

class _TrendingProblemTile extends StatelessWidget {
  const _TrendingProblemTile({
    required this.index,
    required this.problem,
    required this.onTap,
  });

  final int index;
  final ProblemModel problem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final diffColor = AppTheme.getDifficultyColor(problem.difficulty, isDark);
    final solved = problem.isSolved == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  '$index',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.4),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      problem.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: diffColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            problem.difficulty,
                            style: textTheme.labelSmall?.copyWith(
                              color: diffColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (problem.topics.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              problem.topics.first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                solved ? Icons.check_circle : Icons.chevron_right,
                color: solved
                    ? AppTheme.getDifficultyColor('easy', isDark)
                    : colorScheme.onSurface.withOpacity(0.4),
                size: solved ? 20 : 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── _EmptyHint ───────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
      ),
      child: Center(
        child: Text(
          text,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
    required this.label,
    required this.count,
    required this.color,
    this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$count',
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContestCard extends StatelessWidget {
  const _ContestCard({required this.contest, this.onTap});

  final ContestModel contest;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLive = contest.status == 'live';
    final statusColor = isLive ? const Color(0xFF00B8A3) : colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.emoji_events, color: statusColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isLive) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00B8A3),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            contest.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLive
                          ? 'Live now'
                          : _getCountdown(contest.startTime),
                      style: textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: colorScheme.onSurface.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
  }

  String _getCountdown(DateTime startTime) {
    final now = DateTime.now();
    final diff = startTime.difference(now);
    if (diff.isNegative) return 'Started';
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    if (days > 0) return 'Starts in ${days}d ${hours}h';
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

