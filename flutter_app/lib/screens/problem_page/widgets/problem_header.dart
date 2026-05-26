import 'package:codemania/models/problem_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProblemHeader extends StatelessWidget {
  const ProblemHeader({
    super.key,
    required this.problem,
  });

  final Problem problem;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFEBEBEB) : const Color(0xFF262626);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${problem.id}. ${problem.title}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
              ),
              if (problem.isSolved == true)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2CBB5D),
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: problem.difficultyBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  problem.difficulty,
                  style: TextStyle(
                    color: problem.difficultyColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _tagButton(
                context,
                Icons.label_outline,
                'Topics',
                () {
                  final topics = problem.topics ?? const <String>[];
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (ctx) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: topics
                              .map((topic) => Chip(label: Text(topic)))
                              .toList(),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
              _tagButton(
                context,
                Icons.business_outlined,
                'Companies',
                () {
                  final companies = problem.companies ?? const <String>[];
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (ctx) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: companies
                              .map((company) => Chip(label: Text(company)))
                              .toList(),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
              _tagButton(
                context,
                Icons.lightbulb_outline,
                'Hint',
                () {
                  final hint = problem.hint;
                  if (hint != null && hint.trim().isNotEmpty) {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) {
                        return AlertDialog(
                          title: const Text('Hint'),
                          content: Text(hint),
                          actions: [
                            TextButton(
                              onPressed: () => ctx.pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        );
                      },
                    );
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No hint available')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tagButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFEBEBEB) : const Color(0xFF262626);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD0D0D0),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
