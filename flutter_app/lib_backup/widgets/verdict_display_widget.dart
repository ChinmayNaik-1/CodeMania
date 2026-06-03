import 'package:flutter/material.dart';

class VerdictDisplayWidget extends StatelessWidget {
  const VerdictDisplayWidget({
    super.key,
    required this.verdict,
    required this.passed,
    required this.total,
    this.errorMessage,
  });

  final String verdict;
  final int passed;
  final int total;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final color = _verdictColor(verdict);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            verdict.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Passed: $passed / $total',
            style: const TextStyle(
              color: Color(0xFF2B3151),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (errorMessage != null && errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(
                color: Color(0xFF4A4F68),
                fontFamily: 'monospace',
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _verdictColor(String value) {
    switch (value) {
      case 'accepted':
        return const Color(0xFF22A861);
      case 'wrong_answer':
        return const Color(0xFFD64545);
      case 'time_limit_exceeded':
        return const Color(0xFFF2A900);
      case 'runtime_error':
        return const Color(0xFFF26A2E);
      case 'compilation_error':
        return const Color(0xFF7D879C);
      default:
        return const Color(0xFF6D748C);
    }
  }
}
