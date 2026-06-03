import 'package:codemania/core/models/submission_model.dart';
import 'package:codemania/features/submissions/submission_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SubmissionsTab extends ConsumerStatefulWidget {
  const SubmissionsTab({
    super.key,
    required this.problemId,
  });

  final String problemId;

  @override
  ConsumerState<SubmissionsTab> createState() => _SubmissionsTabState();
}

class _SubmissionsTabState extends ConsumerState<SubmissionsTab> {
  String? _selectedSubmissionId;

  @override
  Widget build(BuildContext context) {
    if (_selectedSubmissionId != null) {
      return _SubmissionDetailView(
        submissionId: _selectedSubmissionId!,
        onBack: () => setState(() => _selectedSubmissionId = null),
      );
    }

    final historyAsync = ref.watch(submissionHistoryProvider(widget.problemId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(submissionHistoryProvider(widget.problemId));
        await ref.read(submissionHistoryProvider(widget.problemId).future);
      },
      child: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          children: [
            const SizedBox(height: 80),
            Center(child: Text('Failed to load submissions: $error')),
          ],
        ),
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 80),
                Icon(Icons.code, size: 40, color: Color(0xFF9CA3AF)),
                SizedBox(height: 10),
                Center(child: Text('No submissions yet. Write some code and hit Submit!')),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              return _SubmissionListTile(
                item: item,
                onTap: () => setState(() => _selectedSubmissionId = item.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _SubmissionListTile extends StatelessWidget {
  const _SubmissionListTile({
    required this.item,
    required this.onTap,
  });

  final SubmissionModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2F3645)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: item.statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.status,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.language,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF374151)),
                        ),
                      ),
                      if (item.runtimeMs != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Runtime: ${item.runtimeMs} ms',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                      if (item.memoryKb != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Memory: ${(item.memoryKb! / 1024).toStringAsFixed(1)} MB',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo(item.createdAt),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _SubmissionDetailView extends ConsumerWidget {
  const _SubmissionDetailView({
    required this.submissionId,
    required this.onBack,
  });

  final String submissionId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(submissionDetailProvider(submissionId));

    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Failed to load submission: $error')),
      data: (detail) {
        return Column(
          children: [
            ListTile(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
              title: Text(
                detail.status,
                style: TextStyle(color: detail.statusColor, fontWeight: FontWeight.w800),
              ),
              subtitle: Text('${detail.language} • ${timeAgo(detail.createdAt)}'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        detail.code,
                        style: const TextStyle(
                          color: Color(0xFFF3F4F6),
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if ((detail.errorMessage ?? '').isNotEmpty ||
                        (detail.stderr ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2937),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          detail.errorMessage ?? detail.stderr ?? '',
                          style: const TextStyle(
                            color: Color(0xFFFCA5A5),
                            fontFamily: 'JetBrains Mono',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

String timeAgo(DateTime utc) {
  final dt = utc.toLocal();
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
