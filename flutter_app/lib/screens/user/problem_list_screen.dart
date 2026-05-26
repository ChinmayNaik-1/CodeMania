import 'package:codemania/models/problem_model.dart';
import 'package:codemania/providers/problem_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProblemListScreen extends ConsumerStatefulWidget {
  const ProblemListScreen({
    super.key,
    this.embedded = false,
    this.onOpenProblem,
  });

  final bool embedded;
  final ValueChanged<ProblemModel>? onOpenProblem;

  @override
  ConsumerState<ProblemListScreen> createState() => _ProblemListScreenState();
}

class _ProblemListScreenState extends ConsumerState<ProblemListScreen> {
  String _selectedDifficulty = 'all';
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(problemListProvider.notifier).fetchProblems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(problemListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1320),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Problems',
              style: TextStyle(
                color: Color(0xFF242453),
                fontWeight: FontWeight.w900,
                fontSize: 52,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sharpen your skills. One problem at a time.',
              style: TextStyle(color: Color(0xFF7A839E), fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _statPill('152', 'Solved', const Color(0xFF35B883)),
                const SizedBox(width: 10),
                _statPill('48', 'Attempted', const Color(0xFFF5A831)),
                const SizedBox(width: 10),
                _statPill('${state.problems.length}', 'Total',
                    const Color(0xFF5E2ED5)),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDFDFF),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE6E0F3)),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _filterChip('All', _selectedDifficulty == 'all',
                                () {
                              _applyDifficulty('all');
                            }),
                            _filterChip('Easy', _selectedDifficulty == 'easy',
                                () {
                              _applyDifficulty('easy');
                            }),
                            _filterChip(
                                'Medium', _selectedDifficulty == 'medium', () {
                              _applyDifficulty('medium');
                            }),
                            _filterChip('Hard', _selectedDifficulty == 'hard',
                                () {
                              _applyDifficulty('hard');
                            }),
                            SizedBox(
                              width: 280,
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search title or tag',
                                  hintStyle:
                                      const TextStyle(color: Color(0xFF919CB2)),
                                  filled: true,
                                  fillColor: const Color(0xFFF4F1FB),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Color(0xFF919CB2),
                                  ),
                                ),
                                onChanged: (value) {
                                  _search = value;
                                    ref
                                      .read(problemListProvider.notifier)
                                      .fetchProblems(
                                        difficulty: _selectedDifficulty == 'all'
                                            ? null
                                            : _selectedDifficulty,
                                        search:
                                            _search.isEmpty ? null : _search,
                                      );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (state.isLoading)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          )
                        else if (state.problems.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(50),
                            child: Text(
                              'No problems available yet.',
                              style: TextStyle(
                                color: Color(0xFF7A839E),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          _ProblemTable(
                            problems: state.problems,
                            onTapProblem: _openProblem,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const SizedBox(width: 290, child: _ProblemProgressPanel()),
              ],
            ),
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FB),
      appBar: AppBar(
        title: const Text('CodeMania'),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF242453),
        actions: [
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Landing'),
          ),
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Home'),
          ),
          TextButton(
            onPressed: () => context.go('/contests'),
            child: const Text('Contests'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: content),
    );
  }

  Widget _statPill(String value, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E0F3)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: accent),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF242453),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF7A839E),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF5E2ED5) : const Color(0xFFF1EEFA),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF626C88),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _applyDifficulty(String difficulty) {
    setState(() {
      _selectedDifficulty = difficulty;
    });

    ref.read(problemListProvider.notifier).fetchProblems(
          difficulty: difficulty == 'all' ? null : difficulty,
          search: _search.isEmpty ? null : _search,
        );
  }

  void _openProblem(ProblemModel problem) {
    if (widget.onOpenProblem != null) {
      widget.onOpenProblem!(problem);
      return;
    }

    ref.read(problemListProvider.notifier).fetchProblemById(problem.id);
    context.go('/problems/${problem.id}');
  }
}

class _ProblemTable extends StatelessWidget {
  const _ProblemTable({
    required this.problems,
    required this.onTapProblem,
  });

  final List<ProblemModel> problems;
  final ValueChanged<ProblemModel> onTapProblem;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F3FD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  '#',
                  style: TextStyle(
                    color: Color(0xFF8B84A9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Title',
                  style: TextStyle(
                    color: Color(0xFF8B84A9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: Text(
                  'Difficulty',
                  style: TextStyle(
                    color: Color(0xFF8B84A9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: Text(
                  'Topics',
                  style: TextStyle(
                    color: Color(0xFF8B84A9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: Text(
                  'Reward',
                  style: TextStyle(
                    color: Color(0xFF8B84A9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...problems.map((problem) {
          final difficulty = problem.difficulty.toLowerCase();
          Color diffColor;
          switch (difficulty) {
            case 'easy':
              diffColor = const Color(0xFF34B983);
              break;
            case 'medium':
              diffColor = const Color(0xFFF5A831);
              break;
            default:
              diffColor = const Color(0xFFFF6F6A);
          }

          final reward = difficulty == 'easy'
              ? '+50 XP'
              : difficulty == 'medium'
                  ? '+100 XP'
                  : '+200 XP';

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: const Color(0xFFFDFDFF),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onTapProblem(problem),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 70,
                        child: Text(
                          '${problem.id}',
                          style: const TextStyle(
                            color: Color(0xFF8A93AC),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          problem.title,
                          style: const TextStyle(
                            color: Color(0xFF262651),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: diffColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            problem.difficulty,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: diffColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: problem.tags.take(3).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECEAF7),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  color: Color(0xFF6C6A89),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text(
                          reward,
                          style: const TextStyle(
                            color: Color(0xFF5E2ED5),
                            fontWeight: FontWeight.w900,
                          ),
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
    );
  }
}

class _ProblemProgressPanel extends StatelessWidget {
  const _ProblemProgressPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFDFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE6E0F3)),
          ),
          child: const Column(
            children: [
              Text(
                'Your Progress',
                style: TextStyle(
                  color: Color(0xFF262651),
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                ),
              ),
              SizedBox(height: 16),
              _ProgressCircle(),
              SizedBox(height: 16),
              _ProgressRow('Easy Solved', 0.8, Color(0xFF34B983)),
              SizedBox(height: 10),
              _ProgressRow('Medium Solved', 0.55, Color(0xFFF5A831)),
              SizedBox(height: 10),
              _ProgressRow('Hard Solved', 0.17, Color(0xFFFF6F6A)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5A24CD), Color(0xFF3E147E)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Codemania Pro',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Unlock editorial solutions and advanced hints for all problems.',
                style: TextStyle(color: Color(0xFFDCCFFD)),
              ),
              SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(
                    'Upgrade Now',
                    style: TextStyle(
                      color: Color(0xFF5E2ED5),
                      fontWeight: FontWeight.w800,
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

class _ProgressCircle extends StatelessWidget {
  const _ProgressCircle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: 0.5,
              strokeWidth: 8,
              backgroundColor: const Color(0xFFECE7F8),
              color: const Color(0xFFE44D50),
            ),
          ),
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '152',
                style: TextStyle(
                  color: Color(0xFF242453),
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '/ 300',
                style: TextStyle(color: Color(0xFF7A839E)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
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
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
