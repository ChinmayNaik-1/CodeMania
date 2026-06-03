import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:codemania/core/models/problem_model.dart';
import 'package:codemania/providers/problem_provider.dart';
import 'package:codemania/providers/submission_provider.dart';
import 'package:codemania/core/theme/app_theme.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class ProblemDetailScreen extends ConsumerStatefulWidget {
  const ProblemDetailScreen({
    super.key,
    required this.problemId,
    this.contestId,
  });

  final int problemId;
  final int? contestId;

  @override
  ConsumerState<ProblemDetailScreen> createState() => _ProblemDetailScreenState();
}

class _ProblemDetailScreenState extends ConsumerState<ProblemDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(problemProvider(widget.problemId).notifier).fetchProblem(widget.problemId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final problemState = ref.watch(problemProvider(widget.problemId));
    final problem = problemState.problem;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(problem?.title ?? 'Problem'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.onBackground,
          unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
          tabs: const [
            Tab(text: 'Description'),
            Tab(text: 'Submissions'),
            Tab(text: 'Editorial'),
          ],
        ),
      ),
      body: problemState.isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : problemState.error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: colorScheme.error, size: 48),
                      const SizedBox(height: 16),
                      Text(problemState.error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(problemProvider(widget.problemId).notifier).fetchProblem(widget.problemId);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    DescriptionTab(problem: problem),
                    SubmissionsTab(problemId: widget.problemId),
                    const EditorialTab(),
                  ],
                ),
      floatingActionButton: problem != null
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF00B84C),
              onPressed: () {
                final contestId = widget.contestId;
                if (contestId != null) {
                  context.push('/contests/$contestId/problems/${widget.problemId}/editor');
                } else {
                  context.push('/problems/${widget.problemId}/editor');
                }
              },
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Description Tab
// ═══════════════════════════════════════════════════════════════════════════

class DescriptionTab extends StatelessWidget {
  const DescriptionTab({super.key, required this.problem});

  final Problem? problem;

  @override
  Widget build(BuildContext context) {
    if (problem == null) {
      return const Center(child: Text('No problem loaded'));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Problem title
          Text(
            '${problem!.problemNumber ?? problem!.id}. ${problem!.title}',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Difficulty badge
          Row(
            children: [
              _DifficultyChip(difficulty: problem!.difficulty),
              if (problem!.topics.isNotEmpty) ...[
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    problem!.topics.first,
                    style: const TextStyle(fontSize: 12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Description
          Text(
            'Description',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          MarkdownBody(
            data: problem!.description,
            styleSheet: MarkdownStyleSheet(
              p: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onBackground,
                height: 1.6,
                fontSize: 15,
              ),
              code: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFF1A1A2E),
                backgroundColor: Colors.transparent,
              ),
              codeblockDecoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2A2A3E)
                    : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(6),
              ),
              codeblockPadding: const EdgeInsets.all(12),
              listBullet: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onBackground,
              ),
              h1: textTheme.headlineMedium?.copyWith(
                color: colorScheme.onBackground,
                fontWeight: FontWeight.bold,
              ),
              h2: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onBackground,
                fontWeight: FontWeight.bold,
              ),
              h3: textTheme.titleLarge?.copyWith(
                color: colorScheme.onBackground,
                fontWeight: FontWeight.bold,
              ),
              strong: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onBackground,
                fontWeight: FontWeight.bold,
              ),
              em: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onBackground,
                fontStyle: FontStyle.italic,
              ),
            ),
            builders: {
              'code': _InlineCodeBuilder(context),
            },
            inlineSyntaxes: [_SuperscriptSyntax()],
            selectable: false,
          ),
          const SizedBox(height: 24),

          // Examples
          if (problem!.examples.isNotEmpty) ...[
            Text(
              'Examples',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...problem!.examples.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final example = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Example $index',
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Input:',
                      style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        example.input,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Output:',
                      style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        example.expectedOutput,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      ),
                    ),
                    if (example.explanation != null && example.explanation!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Explanation:',
                        style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        example.explanation!,
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ],

          // Constraints
          if (problem!.constraints?.isNotEmpty == true) ...[
            const SizedBox(height: 24),
            Text(
              'Constraints',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            MarkdownBody(
              data: problem!.constraints!,
              styleSheet: MarkdownStyleSheet(
                p: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onBackground,
                  height: 1.6,
                  fontSize: 15,
                ),
                code: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFF1A1A2E),
                  backgroundColor: Colors.transparent,
                ),
                codeblockDecoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2A2A3E)
                      : const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(6),
                ),
                codeblockPadding: const EdgeInsets.all(12),
                listBullet: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onBackground,
                ),
                strong: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onBackground,
                  fontWeight: FontWeight.bold,
                ),
                em: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onBackground,
                  fontStyle: FontStyle.italic,
                ),
              ),
              builders: {
                'code': _InlineCodeBuilder(context),
              },
              inlineSyntaxes: [_SuperscriptSyntax()],
              selectable: false,
            ),
          ],

          // Follow-up
          if (problem!.followUp?.isNotEmpty == true) ...[
            const SizedBox(height: 24),
            Text(
              'Follow-up',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            MarkdownBody(
              data: problem!.followUp!,
              styleSheet: MarkdownStyleSheet(
                p: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onBackground,
                  height: 1.6,
                  fontSize: 15,
                ),
                code: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFF1A1A2E),
                  backgroundColor: Colors.transparent,
                ),
                codeblockDecoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2A2A3E)
                      : const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(6),
                ),
                codeblockPadding: const EdgeInsets.all(12),
                listBullet: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onBackground,
                ),
                strong: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onBackground,
                  fontWeight: FontWeight.bold,
                ),
                em: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onBackground,
                  fontStyle: FontStyle.italic,
                ),
              ),
              builders: {
                'code': _InlineCodeBuilder(context),
              },
              inlineSyntaxes: [_SuperscriptSyntax()],
              selectable: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({required this.difficulty});

  final String difficulty;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppTheme.getDifficultyColor(difficulty, isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Submissions Tab
// ═══════════════════════════════════════════════════════════════════════════

class SubmissionsTab extends ConsumerStatefulWidget {
  const SubmissionsTab({super.key, required this.problemId});

  final int problemId;

  @override
  ConsumerState<SubmissionsTab> createState() => _SubmissionsTabState();
}

class _SubmissionsTabState extends ConsumerState<SubmissionsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch submissions for this problem
      ref.read(submissionProvider.notifier).fetchHistory(problemId: widget.problemId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final submissionState = ref.watch(submissionProvider);
    final submissions = submissionState.history;

    if (submissionState.isLoading) {
      return Center(child: CircularProgressIndicator(color: colorScheme.primary));
    }

    if (submissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Data',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: submissions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final submission = submissions[index];
        final verdictColor = _getVerdictColor(submission.verdict, context);
        
        return InkWell(
          onTap: () {
            context.push('/problems/${widget.problemId}/submissions/${submission.id}');
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: verdictColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        submission.statusText,
                        style: TextStyle(
                          color: verdictColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTime(submission.createdAt),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      submission.language.toUpperCase(),
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (submission.timeMs != null) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 14, color: colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text(
                        '${submission.timeMs} ms',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                    if (submission.memoryKb != null) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.memory, size: 14, color: colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text(
                        '${(submission.memoryKb! / 1024).toStringAsFixed(2)} MB',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getVerdictColor(String verdict, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppTheme.getVerdictColor(verdict, isDark);
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Editorial Tab
// ═══════════════════════════════════════════════════════════════════════════

class EditorialTab extends StatelessWidget {
  const EditorialTab({super.key});

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
              Icons.article_outlined,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Editorial',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Editorial content coming soon',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Custom Markdown Builders
// ═══════════════════════════════════════════════════════════════════════════

/// Custom builder for inline code with rounded border and theme-aware styling
class _InlineCodeBuilder extends MarkdownElementBuilder {
  final BuildContext context;

  _InlineCodeBuilder(this.context);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF2A2A3E) : const Color(0xFFEEEEEE);
    final borderColor = isDark ? const Color(0xFF4A4A5E) : const Color(0xFFDDDDDD);
    final textColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1A1A2E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: borderColor,
          width: 0.5,
        ),
      ),
      child: Text(
        element.textContent,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: textColor,
        ),
      ),
    );
  }
}

/// Custom inline syntax that converts text like 10^4 to 10⁴ (superscript)
class _SuperscriptSyntax extends md.InlineSyntax {
  _SuperscriptSyntax() : super(r'(\w+)\^(\w+)');

  static const _superMap = {
    '0': '⁰',
    '1': '¹',
    '2': '²',
    '3': '³',
    '4': '⁴',
    '5': '⁵',
    '6': '⁶',
    '7': '⁷',
    '8': '⁸',
    '9': '⁹',
    'n': 'ⁿ',
    'i': 'ⁱ',
  };

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final base = match[1]!;
    final exp = match[2]!;
    final superExp = exp.split('').map((c) => _superMap[c] ?? c).join();
    final node = md.Text('$base$superExp');
    parser.addNode(node);
    return true;
  }
}
