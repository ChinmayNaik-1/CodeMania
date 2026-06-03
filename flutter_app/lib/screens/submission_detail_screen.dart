import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:codemania/services/api_service.dart';
import 'package:codemania/core/theme/app_theme.dart';
import 'package:flutter/services.dart';

// Provider for submission detail
final submissionDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, submissionId) async {
  final response = await ApiService.get('/api/submissions/$submissionId');
  return response.data['submission'] as Map<String, dynamic>;
});

class SubmissionDetailScreen extends ConsumerWidget {
  const SubmissionDetailScreen({
    super.key,
    required this.problemId,
    required this.submissionId,
  });

  final int problemId;
  final int submissionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final submissionAsync = ref.watch(submissionDetailProvider(submissionId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Submission Detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          submissionAsync.when(
            data: (submission) => IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                final code = submission['code'] as String?;
                if (code != null) {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copied to clipboard')),
                  );
                }
              },
              tooltip: 'Copy Code',
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: submissionAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: colorScheme.primary)),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: colorScheme.error, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load submission'),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(submissionDetailProvider(submissionId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (submission) {
          final status = submission['status'] ?? submission['verdict'] ?? 'Unknown';
          final language = submission['language'] ?? 'unknown';
          final code = submission['code'] as String? ?? '';
          final runtimeMs = submission['runtime_ms'] ?? submission['time_ms'];
          final memoryKb = submission['memory_kb'];
          final createdAt = submission['created_at'] != null
              ? DateTime.tryParse(submission['created_at'].toString())
              : null;
          final errorMessage = submission['error_message'];
          final stderr = submission['stderr'];

          final isDark = Theme.of(context).brightness == Brightness.dark;
          final statusColor = AppTheme.getVerdictColor(status.toString(), isDark);
          final isAccepted = status.toString().toLowerCase().contains('accept');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isAccepted
                        ? const Color(0xFF00B84C).withOpacity(0.1)
                        : const Color(0xFFFF375F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAccepted
                          ? const Color(0xFF00B84C).withOpacity(0.3)
                          : const Color(0xFFFF375F).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isAccepted ? Icons.check_circle : Icons.cancel,
                            color: statusColor,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              status.toString(),
                              style: textTheme.headlineSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoItem(
                              label: 'Language',
                              value: language.toString().toUpperCase(),
                            ),
                          ),
                          if (runtimeMs != null)
                            Expanded(
                              child: _InfoItem(
                                label: 'Runtime',
                                value: '$runtimeMs ms',
                              ),
                            ),
                          if (memoryKb != null)
                            Expanded(
                              child: _InfoItem(
                                label: 'Memory',
                                value: '$memoryKb KB',
                              ),
                            ),
                        ],
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Submitted ${_formatTime(createdAt)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Error message if present
                if (errorMessage != null || stderr != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF375F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF375F)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Error',
                          style: textTheme.titleMedium?.copyWith(
                            color: const Color(0xFFFF375F),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          errorMessage?.toString() ?? stderr?.toString() ?? '',
                          style: textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: const Color(0xFFFF375F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Code
                const SizedBox(height: 24),
                Text(
                  'Code',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      code,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: colorScheme.onBackground,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
