import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codemania/core/models/problem_model.dart';
import 'package:codemania/providers/problem_provider.dart';
import 'package:codemania/features/problem/providers/testcase_provider.dart';
import 'package:codemania/screens/code_editor_screen.dart';
import 'package:codemania/core/theme/app_theme.dart';

class TestcaseBottomSheet extends ConsumerWidget {
  const TestcaseBottomSheet({
    super.key,
    required this.problem,
    required this.problemId,
    required this.onRun,
    required this.onSubmit,
    required this.onClose,
  });

  final Problem problem;
  final int problemId;
  final VoidCallback onRun;
  final VoidCallback onSubmit;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedTab = ref.watch(consoleSheetTabProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colorScheme.outline)),
            ),
            child: Row(
              children: [
                // Tabs
                Expanded(
                  child: Row(
                    children: [
                      _TabButton(
                        label: 'Testcase',
                        isSelected: selectedTab == 0,
                        onTap: () {
                          ref.read(consoleSheetTabProvider.notifier).state = 0;
                        },
                      ),
                      const SizedBox(width: 16),
                      _TabButton(
                        label: 'Run Result',
                        isSelected: selectedTab == 1,
                        onTap: () {
                          ref.read(consoleSheetTabProvider.notifier).state = 1;
                        },
                      ),
                    ],
                  ),
                ),
                // Close button
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: selectedTab == 0
                ? _TestcaseTab(
                    problem: problem,
                    problemId: problemId,
                    onRun: onRun,
                    onSubmit: onSubmit,
                  )
                : _RunResultTab(problem: problem, problemId: problemId),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colorScheme.onBackground : colorScheme.onSurface.withOpacity(0.6),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Testcase Tab
// ═══════════════════════════════════════════════════════════════════════════

class _TestcaseTab extends ConsumerWidget {
  const _TestcaseTab({
    required this.problem,
    required this.problemId,
    required this.onRun,
    required this.onSubmit,
  });

  final Problem problem;
  final int problemId;
  final VoidCallback onRun;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final testcases = ref.watch(testcaseProvider(problemId.toString()));
    final selectedIndex = ref.watch(selectedCaseIndexProvider(problemId.toString()));

    if (testcases.isEmpty) {
      return const Center(child: Text('No test cases'));
    }

    final selectedCase = testcases[selectedIndex];

    return Column(
      children: [
        // Case selector chips
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: testcases.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isSelected = index == selectedIndex;
              return ChoiceChip(
                label: Text('Case ${index + 1}'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(selectedCaseIndexProvider(problemId.toString()).notifier).state = index;
                  }
                },
                selectedColor: colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            },
          ),
        ),

        Divider(height: 1, color: colorScheme.outline),

        // Case inputs
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: selectedCase.params.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.outline),
                        ),
                        child: Text(
                          entry.value,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Bottom buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colorScheme.outline)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Reset test cases to defaults
                    final defaults = problem.examples.isNotEmpty
                        ? problem.examples
                            .map((example) => {
                                  'input': example.input,
                                  '_expectedOutput': example.expectedOutput,
                                })
                            .toList()
                        : <Map<String, String>>[
                            {'input': ''},
                          ];
                    ref.read(testcaseProvider(problemId.toString()).notifier).initWithDefaults(defaults);
                    ref.read(selectedCaseIndexProvider(problemId.toString()).notifier).state = 0;
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRun,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Run'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B84C),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Run Result Tab
// ═══════════════════════════════════════════════════════════════════════════

class _RunResultTab extends ConsumerWidget {
  const _RunResultTab({
    required this.problem,
    required this.problemId,
  });

  final Problem problem;
  final int problemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final runResult = ref.watch(runResultProvider);
    final selectedCaseIndex = ref.watch(selectedCaseIndexProvider(problemId.toString()));

    if (runResult == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'You must run your code first.',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final status = runResult['status'] as String;
    final isSubmission = runResult['isSubmission'] == true;
    final caseResults = (runResult['caseResults'] as List<dynamic>?) ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = AppTheme.getVerdictColor(status, isDark);
    final isAccepted = status.toLowerCase().contains('accept');

    return Column(
      children: [
        // Status header
        Container(
          padding: const EdgeInsets.all(16),
          color: isAccepted
              ? const Color(0xFF00B84C).withOpacity(0.1)
              : const Color(0xFFFF375F).withOpacity(0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isAccepted ? Icons.check_circle : Icons.cancel,
                    color: statusColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      status,
                      style: textTheme.titleLarge?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (runResult['runtimeMs'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Runtime: ${runResult['runtimeMs']} ms',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
              if (runResult['errorMessage'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  runResult['errorMessage'] as String,
                  style: textTheme.bodySmall?.copyWith(color: statusColor),
                ),
              ],
            ],
          ),
        ),

        // Case results (if available)
        if (caseResults.isNotEmpty) ...[
          // Case selector chips
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: caseResults.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final caseResult = caseResults[index] as Map<String, dynamic>;
                final passed = caseResult['passed'] == true;
                final isSelected = index == selectedCaseIndex;

                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Case ${index + 1}'),
                      const SizedBox(width: 4),
                      Icon(
                        passed ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: passed ? const Color(0xFF00B84C) : const Color(0xFFFF375F),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(selectedCaseIndexProvider(problemId.toString()).notifier).state = index;
                    }
                  },
                  selectedColor: colorScheme.surfaceVariant,
                );
              },
            ),
          ),

          Divider(height: 1, color: colorScheme.outline),

          // Selected case details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: () {
                if (selectedCaseIndex >= caseResults.length) {
                  return const Text('Invalid case selected');
                }

                final caseResult = caseResults[selectedCaseIndex] as Map<String, dynamic>;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (caseResult['input'] != null) ...[
                      Text(
                        'Input',
                        style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _CodeBlock(text: caseResult['input'] as String),
                      const SizedBox(height: 16),
                    ],
                    if (caseResult['stdout'] != null && (caseResult['stdout'] as String).isNotEmpty) ...[
                      Text(
                        'Your Output',
                        style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _CodeBlock(text: caseResult['stdout'] as String),
                      const SizedBox(height: 16),
                    ],
                    if (caseResult['expected'] != null && (caseResult['expected'] as String).isNotEmpty) ...[
                      Text(
                        'Expected',
                        style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _CodeBlock(text: caseResult['expected'] as String),
                      const SizedBox(height: 16),
                    ],
                    if (caseResult['stderr'] != null && (caseResult['stderr'] as String).isNotEmpty) ...[
                      Text(
                        'Error',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF375F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _CodeBlock(
                        text: caseResult['stderr'] as String,
                        isError: true,
                      ),
                    ],
                  ],
                );
              }(),
            ),
          ),
        ],
      ],
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({
    required this.text,
    this.isError = false,
  });

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError
            ? const Color(0xFFFF375F).withOpacity(0.1)
            : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? const Color(0xFFFF375F) : colorScheme.outline,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: isError ? const Color(0xFFFF375F) : colorScheme.onBackground,
        ),
      ),
    );
  }
}
