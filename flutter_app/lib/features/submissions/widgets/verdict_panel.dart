import 'package:codemania/core/models/submission_model.dart';
import 'package:codemania/features/submissions/submission_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VerdictPanel extends ConsumerWidget {
  const VerdictPanel({
    super.key,
    required this.onViewInSubmissions,
  });

  final VoidCallback onViewInSubmissions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(verdictPanelVisibleProvider);
    final verdict = ref.watch(activeVerdictProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: isVisible ? 220 : 0,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : const Color(0xFFF8F9FB),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFDCE1EA),
            width: 1,
          ),
        ),
      ),
      child: isVisible
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: verdict == null
                  ? const _JudgingState()
                  : _VerdictBody(
                      verdict: verdict,
                      onClose: () {
                        ref.read(verdictPanelVisibleProvider.notifier).state = false;
                        ref.read(activeVerdictProvider.notifier).state = null;
                      },
                      onViewInSubmissions: onViewInSubmissions,
                    ),
            )
          : null,
    );
  }
}

class _JudgingState extends StatelessWidget {
  const _JudgingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 10),
          Text('Judging your code...'),
        ],
      ),
    );
  }
}

class _VerdictBody extends StatelessWidget {
  const _VerdictBody({
    required this.verdict,
    required this.onClose,
    required this.onViewInSubmissions,
  });

  final SubmissionDetailModel verdict;
  final VoidCallback onClose;
  final VoidCallback onViewInSubmissions;

  @override
  Widget build(BuildContext context) {
    final status = verdict.normalizedStatus;

    if (status == 'accepted') {
      return _AcceptedView(
        verdict: verdict,
        onClose: onClose,
        onViewInSubmissions: onViewInSubmissions,
      );
    }

    if (status == 'wrong answer') {
      return _WrongAnswerView(verdict: verdict, onClose: onClose);
    }

    if (status == 'compile error') {
      return _CompileErrorView(verdict: verdict, onClose: onClose);
    }

    if (status == 'runtime error') {
      return _RuntimeErrorView(verdict: verdict, onClose: onClose);
    }

    if (status == 'time limit exceeded') {
      return _TimeLimitView(onClose: onClose);
    }

    return _RuntimeErrorView(verdict: verdict, onClose: onClose);
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    required this.color,
    required this.icon,
    required this.onClose,
  });

  final String title;
  final Color color;
  final IconData icon;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close),
          tooltip: 'Close',
        ),
      ],
    );
  }
}

class _AcceptedView extends StatelessWidget {
  const _AcceptedView({
    required this.verdict,
    required this.onClose,
    required this.onViewInSubmissions,
  });

  final SubmissionDetailModel verdict;
  final VoidCallback onClose;
  final VoidCallback onViewInSubmissions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PanelHeader(
          title: 'Accepted',
          color: const Color(0xFF2EAF57),
          icon: Icons.check_circle,
          onClose: onClose,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text('Runtime: ${verdict.runtimeMs ?? '-'} ms'),
            const SizedBox(width: 18),
            Text('Memory: ${_memoryText(verdict.memoryKb)}'),
          ],
        ),
        const Spacer(),
        TextButton(
          onPressed: onViewInSubmissions,
          child: const Text('View in Submissions'),
        ),
      ],
    );
  }
}

class _WrongAnswerView extends StatelessWidget {
  const _WrongAnswerView({
    required this.verdict,
    required this.onClose,
  });

  final SubmissionDetailModel verdict;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final progressText = (verdict.passed != null && verdict.total != null)
        ? '${verdict.passed} / ${verdict.total} test cases passed'
        : null;
    final hiddenFailure = verdict.input == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PanelHeader(
          title: 'Wrong Answer',
          color: const Color(0xFFEF4444),
          icon: Icons.cancel,
          onClose: onClose,
        ),
        const SizedBox(height: 8),
        if (progressText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(progressText),
          ),
        if (hiddenFailure)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('(Hidden test case)'),
          )
        else ...[
          _kv('Input', verdict.input ?? 'N/A'),
          _kv('Expected Output', verdict.expectedOutput ?? 'N/A'),
        ],
        _kv('Output', verdict.yourOutput ?? 'N/A'),
      ],
    );
  }
}

class _CompileErrorView extends StatelessWidget {
  const _CompileErrorView({
    required this.verdict,
    required this.onClose,
  });

  final SubmissionDetailModel verdict;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PanelHeader(
          title: 'Compile Error',
          color: const Color(0xFFEF4444),
          icon: Icons.code,
          onClose: onClose,
        ),
        if (verdict.errorLine != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Error on line ${verdict.errorLine}'),
          ),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                verdict.errorMessage ?? 'Compilation failed',
                style: const TextStyle(
                  color: Color(0xFFF3F4F6),
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RuntimeErrorView extends StatelessWidget {
  const _RuntimeErrorView({
    required this.verdict,
    required this.onClose,
  });

  final SubmissionDetailModel verdict;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PanelHeader(
          title: 'Runtime Error',
          color: const Color(0xFFF59E0B),
          icon: Icons.warning_amber_rounded,
          onClose: onClose,
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                verdict.stderr ?? verdict.errorMessage ?? 'Runtime error',
                style: const TextStyle(
                  color: Color(0xFFF3F4F6),
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeLimitView extends StatelessWidget {
  const _TimeLimitView({
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PanelHeader(
          title: 'Time Limit Exceeded',
          color: const Color(0xFFF59E0B),
          icon: Icons.timer_off,
          onClose: onClose,
        ),
        const SizedBox(height: 8),
        const Text('Your solution exceeded the time limit.'),
      ],
    );
  }
}

Widget _kv(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        SelectableText(value),
      ],
    ),
  );
}

String _memoryText(int? kb) {
  if (kb == null) return '-';
  final mb = kb / 1024;
  return '${mb.toStringAsFixed(1)} MB';
}
