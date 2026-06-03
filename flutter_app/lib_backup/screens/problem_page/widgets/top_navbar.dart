import 'dart:math' show Random;

import 'package:codemania/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TopNavBar extends StatelessWidget {
  const TopNavBar({
    super.key,
    required this.problemId,
    required this.problemTitle,
    this.contestId,
    required this.onPrevProblem,
    required this.onNextProblem,
    required this.onRun,
    required this.onSubmit,
    required this.isRunning,
    required this.isSubmitting,
  });

  final int problemId;
  final String problemTitle;
  final int? contestId;
  final VoidCallback onPrevProblem;
  final VoidCallback onNextProblem;
  final VoidCallback onRun;
  final VoidCallback onSubmit;
  final bool isRunning;
  final bool isSubmitting;

  int _randomProblemId() => Random().nextInt(100) + 1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF7F7F7);
    final foregroundColor = isDark ? const Color(0xFFEBEBEB) : const Color(0xFF1F1F1F);
    final secondaryText = isDark ? const Color(0xFF8A8A8A) : const Color(0xFF7A7A7A);
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFDADADA);
    final runBorderColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFB7B7B7);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                IconButton(
                  iconSize: 20,
                  splashRadius: 18,
                  tooltip: contestId != null ? 'Back to Contest' : 'Problem List',
                  icon: Icon(
                    contestId != null ? Icons.arrow_back : Icons.menu,
                    color: foregroundColor,
                  ),
                  onPressed: () {
                    if (contestId != null) {
                      context.go('/contests/$contestId');
                    } else {
                      context.go('/problems');
                    }
                  },
                ),
                Text(
                  contestId != null ? 'Back to Contest' : 'Problem List',
                  style: TextStyle(
                    fontSize: 13,
                    color: secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  iconSize: 20,
                  splashRadius: 18,
                  tooltip: 'Previous Problem',
                  icon: Icon(Icons.chevron_left, color: foregroundColor),
                  onPressed: onPrevProblem,
                ),
                IconButton(
                  iconSize: 20,
                  splashRadius: 18,
                  tooltip: 'Next Problem',
                  icon: Icon(Icons.chevron_right, color: foregroundColor),
                  onPressed: onNextProblem,
                ),
                IconButton(
                  iconSize: 20,
                  splashRadius: 18,
                  tooltip: 'Random Problem',
                  icon: Icon(Icons.shuffle_outlined, color: foregroundColor),
                  onPressed: () {
                    final randomId = _randomProblemId();
                    context.go('/problems/$randomId');
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      onPressed: isRunning ? null : onRun,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: runBorderColor),
                        foregroundColor: foregroundColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: isRunning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_arrow, size: 16, color: foregroundColor),
                                const SizedBox(width: 4),
                                Text(
                                  'Run',
                                  style: TextStyle(
                                    color: foregroundColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2CBB5D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Submit',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                iconSize: 20,
                splashRadius: 18,
                tooltip: 'Settings',
                icon: Icon(Icons.settings_outlined, color: foregroundColor),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              Consumer(
                builder: (context, ref, child) {
                  final username = ref.watch(authProvider).user?.username ?? 'U';
                  final initial = username.isNotEmpty
                      ? username.substring(0, 1).toUpperCase()
                      : 'U';

                  return CircleAvatar(
                    radius: 15,
                    backgroundColor: isDark ? const Color(0xFF303030) : const Color(0xFFE2E2E2),
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
    );
  }
}
