import 'package:codemania/models/problem_model.dart';
import 'package:codemania/providers/problem_provider.dart';
import 'package:codemania/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProblemListScreen extends ConsumerStatefulWidget {
  const ProblemListScreen({
    super.key,
    this.embedded = false,
    this.initialTopic,
    this.onOpenProblem,
  });

  final bool embedded;
  final String? initialTopic;
  final ValueChanged<ProblemModel>? onOpenProblem;

  @override
  ConsumerState<ProblemListScreen> createState() => _ProblemListScreenState();
}

class _ProblemListScreenState extends ConsumerState<ProblemListScreen> {
  String _selectedTab = 'All';
  String? _selectedTopic;
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTopic = widget.initialTopic;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(problemListProvider.notifier).fetchProblems();
    });
  }

  @override
  void didUpdateWidget(covariant ProblemListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTopic != oldWidget.initialTopic && widget.initialTopic != null) {
      setState(() {
        _selectedTopic = widget.initialTopic;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(problemListProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter problems by selected tab
    List<ProblemModel> filteredProblems = state.problems;
    if (_selectedTab == 'Easy') {
      filteredProblems = state.problems.where((p) => p.difficulty.toLowerCase() == 'easy').toList();
    } else if (_selectedTab == 'Mid') {
      filteredProblems = state.problems.where((p) => p.difficulty.toLowerCase() == 'medium').toList();
    } else if (_selectedTab == 'Hard') {
      filteredProblems = state.problems.where((p) => p.difficulty.toLowerCase() == 'hard').toList();
    }

    if (_search.isNotEmpty) {
      final query = _search.toLowerCase();
      filteredProblems = filteredProblems.where((p) {
        return p.title.toLowerCase().contains(query) ||
               p.topics.any((t) => t.toLowerCase().contains(query)) ||
               (p.problemNumber?.toString() ?? '').contains(query);
      }).toList();
    }

    if (_selectedTopic != null) {
      filteredProblems = filteredProblems.where((p) => p.topics.contains(_selectedTopic)).toList();
    }

    final allTopics = state.problems
        .expand((p) => p.topics)
        .toSet()
        .toList()
        ..sort();

    final content = Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) {
                setState(() {
                  _search = value;
                });
              },
            ),
          ),
        ),
        
        // Tabs
        Container(
          height: 48,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildDifficultyTab('All'),
                const SizedBox(width: 8),
                _buildDifficultyTab('Easy'),
                const SizedBox(width: 8),
                _buildDifficultyTab('Mid'),
                const SizedBox(width: 8),
                _buildDifficultyTab('Hard'),
              ],
            ),
          ),
        ),

        // Topics
        if (allTopics.isNotEmpty)
          Container(
            height: 48,
            margin: const EdgeInsets.only(bottom: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: allTopics.map((topic) {
                  final isActive = _selectedTopic == topic;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(topic),
                      selected: isActive,
                      onSelected: (selected) {
                        setState(() {
                          _selectedTopic = selected ? topic : null;
                        });
                      },
                      backgroundColor: Colors.transparent,
                      selectedColor: colorScheme.primaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isActive ? Colors.transparent : colorScheme.outline.withOpacity(0.5),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

        // Problem list
        Expanded(
          child: RefreshIndicator(
            color: colorScheme.primary,
            onRefresh: () => ref.read(problemListProvider.notifier).fetchProblems(),
            child: state.isLoading
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.5,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(color: colorScheme.primary),
                    ),
                  )
                : filteredProblems.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.5,
                          alignment: Alignment.center,
                          child: Text(
                            'No problems found',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: filteredProblems.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final problem = filteredProblems[index];
                          return _ProblemListItem(
                            problem: problem,
                            onTap: () => _openProblem(problem),
                          );
                        },
                      ),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Problems'),
      ),
      body: SafeArea(child: content),
    );
  }


  Widget _buildDifficultyTab(String label) {
    final isActive = _selectedTab == label;
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.surfaceVariant : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive
                ? colorScheme.onSurface
                : colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
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

class _ProblemListItem extends StatelessWidget {
  const _ProblemListItem({
    required this.problem,
    required this.onTap,
  });

  final ProblemModel problem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Difficulty color
    final difficultyColor = AppTheme.getDifficultyColor(problem.difficulty, isDark);
    final difficultyLabel = problem.difficulty == 'Medium' ? 'Med.' : problem.difficulty;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Difficulty badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: difficultyColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        difficultyLabel,
                        style: TextStyle(
                          color: difficultyColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Problem title
                    Expanded(
                      child: Text(
                        problem.title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Status dash (placeholder)
                    Icon(
                      Icons.remove,
                      size: 16,
                      color: colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                
                // Acceptance and Frequency
                Row(
                  children: [
                    Text(
                      'Acceptance 45%',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.lock,
                      size: 12,
                      color: colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Frequency',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Divider(
          color: colorScheme.outline,
          height: 1,
          thickness: 0.5,
        ),
      ],
    );
  }
}
