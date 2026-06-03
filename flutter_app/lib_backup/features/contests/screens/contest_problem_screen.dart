import 'dart:async';
import 'package:codemania/core/models/contest_model.dart';
import 'package:codemania/features/contests/providers/contest_provider.dart';
import 'package:codemania/models/problem_model.dart';
import 'package:codemania/providers/auth_provider.dart';
import 'package:codemania/providers/problem_provider.dart';
import 'package:codemania/screens/problem_page/widgets/code_editor_panel.dart';
import 'package:codemania/screens/problem_page/widgets/problem_body.dart';
import 'package:codemania/screens/problem_page/widgets/testcase_panel.dart';
import 'package:codemania/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ContestProblemScreen extends ConsumerStatefulWidget {
  const ContestProblemScreen({
    super.key,
    required this.contestId,
    required this.problemId,
  });

  final int contestId;
  final int problemId;

  @override
  ConsumerState<ContestProblemScreen> createState() => _ContestProblemScreenState();
}

class _ContestProblemScreenState extends ConsumerState<ContestProblemScreen> {
  late double _leftWidth;
  late double _editorHeight;
  bool _sizesReady = false;
  int? _loadedProblemId;

  String _selectedLanguage = 'cpp';
  String _currentCode = '';
  bool _isRunning = false;
  bool _isSubmitting = false;
  Map<String, dynamic>? _mappedRunResult;
  Map<String, dynamic>? _verdict;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      if (!mounted) return;
      setState(() {
        _leftWidth = size.width * 0.42;
        _editorHeight = (size.height - 44) * 0.62;
        _sizesReady = true;
      });
      ref.read(problemProvider(widget.problemId).notifier).fetchProblem(widget.problemId);
    });
  }

  void _onLanguageChanged(String lang, Problem problem) {
    setState(() {
      _selectedLanguage = lang;
      _currentCode = ref.read(problemProvider(widget.problemId).notifier).resolveStub(problem.codeStubs, lang);
    });
  }

  void _onCodeChanged(String code) {
    _currentCode = code;
  }

  Future<void> _runCode() async {
    setState(() {
      _isRunning = true;
      _mappedRunResult = null;
    });

    try {
      final res = await ApiService.post(
        '/api/contests/${widget.contestId}/problems/${widget.problemId}/run',
        data: {
          'language': _selectedLanguage,
          'code': _currentCode,
        },
      );

      final results = res.data['results'] as List?;
      if (results != null) {
        final caseResults = results.map((r) {
          final m = Map<String, dynamic>.from(r as Map);
          return {
            'passed': m['verdict'] == 'Accepted',
            'stdout': m['actual_output'] ?? '',
            'expected': m['expected_output'] ?? '',
            'runtime_ms': m['time_ms'] ?? 0,
            'stderr': m['stderr'] ?? '',
            'error_message': m['compile_output'] ?? '',
          };
        }).toList();

        final status = caseResults.isNotEmpty && caseResults.every((r) => r['passed'] == true)
            ? 'Accepted'
            : 'Wrong Answer';

        setState(() {
          _mappedRunResult = {
            'status': status,
            'caseResults': caseResults,
          };
        });
      }
    } catch (e) {
      setState(() {
        _mappedRunResult = {
          'status': 'Runtime Error',
          'errorMessage': e.toString(),
          'caseResults': const [],
        };
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRunning = false;
        });
      }
    }
  }

  Future<void> _submitCode() async {
    setState(() {
      _isSubmitting = true;
      _verdict = null;
    });

    try {
      final res = await ApiService.post(
        '/api/contests/${widget.contestId}/problems/${widget.problemId}/submit',
        data: {
          'language': _selectedLanguage,
          'code': _currentCode,
        },
      );

      setState(() {
        _verdict = {
          'verdict': res.data['verdict'],
          'message': res.data['message'],
        };
      });

      Future.delayed(const Duration(seconds: 6), () {
        if (mounted) setState(() => _verdict = null);
      });
    } catch (e) {
      setState(() {
        _verdict = {
          'verdict': 'Error',
          'message': e.toString(),
        };
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildVerdictBanner() {
    if (_verdict == null) return const SizedBox.shrink();

    final isAccepted = _verdict!['verdict'] == 'Accepted';
    final color = isAccepted ? const Color(0xFF00B8A3) : const Color(0xFFFF375F);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: color.withOpacity(0.15),
      child: Row(
        children: [
          Icon(
            isAccepted ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _verdict!['message'] ?? '',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(problemProvider(widget.problemId));
    final contestState = ref.watch(contestDetailProvider(widget.contestId));
    final problem = state.problem;
    final contest = contestState.valueOrNull;

    if (state.error != null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF),
        body: Center(
          child: Text(state.error!, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        ),
      );
    }

    if (problem != null && _loadedProblemId != problem.id) {
      _loadedProblemId = problem.id;
      _currentCode = ref.read(problemProvider(widget.problemId).notifier).resolveStub(problem.codeStubs, _selectedLanguage);
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalW = constraints.maxWidth;
            final totalH = constraints.maxHeight;
            final rightH = totalH - 44;
            final minLeft = 280.0;
            final maxLeft = (totalW - 350.0) < minLeft ? minLeft : (totalW - 350.0);
            final verdictHeight = _verdict != null ? 40.0 : 0.0;
            final maxEditorRaw = rightH - 4 - 100 - verdictHeight;
            final maxEditor = maxEditorRaw < 120 ? 120.0 : maxEditorRaw;

            if (!_sizesReady) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFFFA116)));
            }

            final leftWidth = _leftWidth.clamp(minLeft, maxLeft);
            final editorHeight = _editorHeight.clamp(120.0, maxEditor);
            final testcaseHeight = rightH - editorHeight - 4 - verdictHeight;

            return Column(
              children: [
                _ContestTopNavBar(
                  problem: problem,
                  contest: contest,
                  onRun: _runCode,
                  onSubmit: _submitCode,
                  isRunning: _isRunning,
                  isSubmitting: _isSubmitting,
                  contestId: widget.contestId,
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: leftWidth,
                        child: problem == null
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFA116)))
                            : SingleChildScrollView(
                                child: ProblemBody(problem: problem),
                              ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeColumn,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragUpdate: (d) {
                            setState(() {
                              _leftWidth = (_leftWidth + d.delta.dx).clamp(minLeft, maxLeft);
                            });
                          },
                          child: Container(
                            width: 4,
                            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFDDDDDD),
                          ),
                        ),
                      ),
                      Expanded(
                        child: problem == null
                            ? Container(
                                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA),
                                child: const Center(
                                    child: CircularProgressIndicator(color: Color(0xFFFFA116))),
                              )
                            : Column(
                                children: [
                                  _buildVerdictBanner(),
                                  SizedBox(
                                    height: editorHeight,
                                    child: CodeEditorPanel(
                                      problem: problem,
                                      selectedLanguage: _selectedLanguage,
                                      currentCode: _currentCode,
                                      saveStatusText: '',
                                      onLanguageChanged: (lang) => _onLanguageChanged(lang, problem),
                                      onCodeChanged: _onCodeChanged,
                                    ),
                                  ),
                                  MouseRegion(
                                    cursor: SystemMouseCursors.resizeRow,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onVerticalDragUpdate: (d) {
                                        setState(() {
                                          _editorHeight = (_editorHeight + d.delta.dy).clamp(120.0, maxEditor);
                                        });
                                      },
                                      child: Container(
                                        height: 4,
                                        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFDDDDDD),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: testcaseHeight,
                                    child: TestcasePanel(
                                      problem: problem,
                                      problemId: widget.problemId,
                                      onRun: _runCode,
                                      onSubmit: _submitCode,
                                      isRunning: _isRunning,
                                      isSubmitting: _isSubmitting,
                                      runResult: _mappedRunResult,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ContestTopNavBar extends ConsumerWidget {
  const _ContestTopNavBar({
    required this.problem,
    required this.contest,
    required this.onRun,
    required this.onSubmit,
    required this.isRunning,
    required this.isSubmitting,
    required this.contestId,
  });

  final Problem? problem;
  final ContestDetailModel? contest;
  final VoidCallback onRun;
  final VoidCallback onSubmit;
  final bool isRunning;
  final bool isSubmitting;
  final int contestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF7F7F7);
    final foregroundColor = isDark ? const Color(0xFFEBEBEB) : const Color(0xFF1F1F1F);
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFDADADA);
    final runBorderColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFB7B7B7);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                TextButton.icon(
                  icon: Icon(Icons.arrow_back_ios, size: 14, color: foregroundColor.withOpacity(0.7)),
                  label: Text("Back to Contest",
                    style: TextStyle(color: foregroundColor.withOpacity(0.7), fontSize: 13)),
                  onPressed: () => context.go('/contests/$contestId'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  iconSize: 20,
                  splashRadius: 18,
                  icon: Icon(Icons.chevron_left, color: foregroundColor),
                  onPressed: () {
                    if (contest == null || problem == null) return;
                    final idx = contest!.problems.indexWhere((p) => p.id == problem!.id);
                    if (idx > 0) {
                      final prevId = contest!.problems[idx - 1].id;
                      context.go('/contests/$contestId/problems/$prevId');
                    }
                  },
                ),
                IconButton(
                  iconSize: 20,
                  splashRadius: 18,
                  icon: Icon(Icons.chevron_right, color: foregroundColor),
                  onPressed: () {
                    if (contest == null || problem == null) return;
                    final idx = contest!.problems.indexWhere((p) => p.id == problem!.id);
                    if (idx != -1 && idx < contest!.problems.length - 1) {
                      final nextId = contest!.problems[idx + 1].id;
                      context.go('/contests/$contestId/problems/$nextId');
                    }
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: isRunning
                          ? const SizedBox(
                              width: 16, height: 16,
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (contest != null)
                _ContestCountdownTimer(endTime: contest!.endTime),
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
                  final initial = username.isNotEmpty ? username.substring(0, 1).toUpperCase() : 'U';

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

class _ContestCountdownTimer extends StatefulWidget {
  const _ContestCountdownTimer({required this.endTime});
  final DateTime endTime;

  @override
  State<_ContestCountdownTimer> createState() => _ContestCountdownTimerState();
}

class _ContestCountdownTimerState extends State<_ContestCountdownTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.endTime.difference(DateTime.now());

    if (remaining.isNegative) {
      return Text("Ended", style: TextStyle(color: Colors.red[400], fontSize: 13));
    }

    final hh = remaining.inHours.toString().padLeft(2, '0');
    final mm = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    final isCritical = remaining.inMinutes < 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isCritical ? Colors.red.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCritical ? Colors.red[400]! : Colors.grey[600]!,
          width: 1,
        ),
      ),
      child: Text(
        "$hh:$mm:$ss",
        style: TextStyle(
          color: isCritical ? Colors.red[400] : Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
