import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:codemania/providers/submission_provider.dart';
import 'package:codemania/screens/submission_detail_screen.dart';
import 'package:codemania/core/theme/app_theme.dart';

class SubmissionDetailFullScreen extends ConsumerWidget {
  const SubmissionDetailFullScreen({
    super.key,
    required this.submissionId,
  });

  final int submissionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final submissionAsync = ref.watch(submissionDetailProvider(submissionId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text('Submission', style: TextStyle(color: colorScheme.onBackground)),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: colorScheme.onSurface),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: submissionAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: colorScheme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load submission',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        data: (submission) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          final verdict = (submission['verdict'] as String?) ?? 'Unknown';
          final problemTitle = (submission['problemTitle'] ?? submission['problem_title'] as String?) ?? 'Problem';
          final passedCases = submission['passedCases'] ?? submission['passed_cases'];
          final totalCases = submission['totalCases'] ?? submission['total_cases'];
          final timeMs = submission['timeMs'] ?? submission['time_ms'];
          final memoryKb = submission['memoryKb'] ?? submission['memory_kb'];
          final runtimePercentile = submission['runtimePercentile'] ?? submission['runtime_percentile'];
          final memoryPercentile = submission['memoryPercentile'] ?? submission['memory_percentile'];
          final language = (submission['language'] as String?) ?? '';
          final code = (submission['code'] as String?) ?? '';
          
          final verdictColor = AppTheme.getVerdictColor(
            verdict,
            isDark,
          );
          final isAccepted = verdict.toLowerCase().contains('accept');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Problem title
                Text(
                  problemTitle,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: colorScheme.outline),
                const SizedBox(height: 16),

                // Verdict row
                Row(
                  children: [
                    Icon(
                      isAccepted ? Icons.check_circle : Icons.cancel,
                      color: verdictColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      verdict,
                      style: textTheme.titleMedium?.copyWith(
                        color: verdictColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (passedCases != null && totalCases != null)
                      Text(
                        '$passedCases / $totalCases testcases passed',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Runtime row
                if (timeMs != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 20,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Runtime',
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$timeMs ms',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (runtimePercentile != null)
                          Text(
                            'Beats $runtimePercentile%',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                      ],
                    ),
                  ),

                // Memory row
                if (memoryKb != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.memory,
                          size: 20,
                          color: Colors.purple,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Memory',
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(memoryKb / 1024).toStringAsFixed(2)} MB',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (memoryPercentile != null)
                          Text(
                            'Beats $memoryPercentile%',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Code card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Code',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              language.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.copy, size: 20),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: code),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Code copied to clipboard'),
                                  backgroundColor: colorScheme.primary,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            code,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: colorScheme.onBackground,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
