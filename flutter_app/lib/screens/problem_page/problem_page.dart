import 'dart:async';

import 'package:codemania/core/models/submission_model.dart';
import 'package:codemania/core/utils/monaco_error_helper.dart';
import 'package:codemania/config.dart';
import 'package:codemania/features/problem/providers/user_code_provider.dart';
import 'package:codemania/features/problem/providers/testcase_provider.dart';
import 'package:codemania/features/submissions/submission_provider.dart';
import 'package:codemania/features/submissions/widgets/verdict_panel.dart';
import 'package:codemania/providers/contest_provider.dart';
import 'package:codemania/providers/problem_provider.dart';
import 'package:codemania/screens/problem_page/widgets/code_editor_panel.dart';
import 'package:codemania/screens/problem_page/widgets/tab_bar_panel.dart';
import 'package:codemania/screens/problem_page/widgets/testcase_panel.dart';
import 'package:codemania/screens/problem_page/widgets/top_navbar.dart';
import 'package:codemania/services/api_service.dart';
import 'package:codemania/services/runtime_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProblemPage extends ConsumerStatefulWidget {
  const ProblemPage({
    super.key,
    required this.problemId,
    this.contestId,
  });

  final int problemId;
  final int? contestId;

  @override
  ConsumerState<ProblemPage> createState() => _ProblemPageState();
}

class _ProblemPageState extends ConsumerState<ProblemPage>
    with SingleTickerProviderStateMixin {
  late double _leftWidth;
  late double _editorHeight;
  late TabController _leftTabController;
  bool _sizesReady = false;
  String _lastSeedSignature = '';
  Timer? _saveDebouncer;
  String? _loadedLanguage;
  int? _loadedProblemId;

  String _versionForLanguage(String language) {
    return RuntimeService.resolveVersion(language);
  }

  @override
  void initState() {
    super.initState();
    _leftTabController = TabController(length: 3, vsync: this);
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

  @override
  void dispose() {
    _saveDebouncer?.cancel();
    _leftTabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserCodeForLanguage(String language) async {
    final problem = ref.read(problemProvider(widget.problemId)).problem;
    if (problem == null) return;

    final problemKey = problem.id.toString();
    final jwt = Config.currentToken;
    final service = ref.read(userCodeServiceProvider);

    final initialStub = ref
      .read(problemProvider(widget.problemId).notifier)
      .resolveStub(problem.codeStubs, language);
    final loadedCode = await service.loadCode(
      problemKey,
      language,
      jwt,
      fallbackCode: initialStub,
    );
    if (!mounted) return;

    final currentState = ref.read(problemProvider(widget.problemId));
    if (currentState.selectedLanguage != language) {
      return;
    }

    ref.read(currentCodeProvider(problemKey).notifier).state = loadedCode;
    ref.read(saveStatusProvider(problemKey).notifier).state = SaveStatus.idle;
    ref.read(problemProvider(widget.problemId).notifier).updateCode(loadedCode);

    _loadedLanguage = language;
    _loadedProblemId = problem.id;
  }

  void _scheduleCodeSave({
    required String problemId,
    required String language,
    required String code,
  }) {
    _saveDebouncer?.cancel();
    _saveDebouncer = Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;

      final jwt = Config.currentToken;
      final service = ref.read(userCodeServiceProvider);
      ref.read(saveStatusProvider(problemId).notifier).state = SaveStatus.saving;

      try {
        await service.saveCode(problemId, language, code, jwt);
        if (!mounted) return;
        ref.read(saveStatusProvider(problemId).notifier).state = SaveStatus.saved;
        await Future.delayed(const Duration(seconds: 3));
        if (!mounted) return;
        ref.read(saveStatusProvider(problemId).notifier).state = SaveStatus.idle;
      } catch (_) {
        if (!mounted) return;
        ref.read(saveStatusProvider(problemId).notifier).state = SaveStatus.idle;
      }
    });
  }

  void _onEditorCodeChanged(String newCode) {
    final state = ref.read(problemProvider(widget.problemId));
    final problem = state.problem;
    if (problem == null) return;

    final problemKey = problem.id.toString();
    ref.read(currentCodeProvider(problemKey).notifier).state = newCode;
    ref.read(problemProvider(widget.problemId).notifier).updateCode(newCode);
    _scheduleCodeSave(
      problemId: problemKey,
      language: state.selectedLanguage,
      code: newCode,
    );
  }

  Future<void> _onLanguageChanged(String language) async {
    _saveDebouncer?.cancel();
    ref.read(problemProvider(widget.problemId).notifier).changeLanguage(language);
    await _loadUserCodeForLanguage(language);
  }

  String _saveStatusText(SaveStatus status) {
    switch (status) {
      case SaveStatus.saving:
        return 'Saving...';
      case SaveStatus.saved:
        return 'Saved';
      case SaveStatus.idle:
        return '';
    }
  }

  Future<void> _runCode() async {
    final notifier = ref.read(problemProvider(widget.problemId).notifier);
    final state = ref.read(problemProvider(widget.problemId));
    final problem = state.problem;
    if (problem == null) return;

    MonacoErrorHelper.clearMarkers();
    notifier.setIsRunning(true);
    notifier.setRunResult(null);

    try {
      final cases = ref.read(testcaseProvider(problem.id.toString()));
      final inputs = cases.isNotEmpty
          ? cases.map((tc) => _buildTestInput(tc.params)).toList()
          : <String>[
            problem.examples.isNotEmpty
              ? (problem.examples.first.input ?? '')
                  : '',
            ];

      final responses = await Future.wait(
        inputs.map(
          (stdin) => ApiService.post(
            '/submit/run',
            data: {
              'problemId': problem.id,
              'problem_id': problem.id,
              'language': state.selectedLanguage,
              'version': _versionForLanguage(state.selectedLanguage),
              'code': state.currentCode,
              'test_input': stdin,
            },
          ),
        ),
      );

      final caseResults = <Map<String, dynamic>>[];
      String status = 'Accepted';
      String? firstErrorMessage;

      for (int i = 0; i < responses.length; i++) {
        final data = Map<String, dynamic>.from(responses[i].data as Map);
        final caseStatus = (data['status'] ?? 'Run Failed').toString();
        final results = (data['results'] as List?) ?? const [];
        final firstResult = results.isNotEmpty && results.first is Map
            ? Map<String, dynamic>.from(results.first as Map)
            : <String, dynamic>{};

        final passed = firstResult['passed'] == true || caseStatus == 'Accepted';
        final errorMessage = (data['error_message'] ?? data['run_error'])?.toString();

        caseResults.add({
          'case': i + 1,
          'status': caseStatus,
          'passed': passed,
          'stdout': (data['stdout'] ?? firstResult['actual'] ?? '').toString(),
          'expected': firstResult['expected']?.toString() ?? '',
          'runtime_ms': data['runtime_ms'] ?? firstResult['runtime_ms'] ?? firstResult['time_ms'],
          'stderr': (data['stderr'] ?? firstResult['error'] ?? '').toString(),
          'error_message': errorMessage ?? '',
        });

        if (status != 'Compile Error') {
          if (caseStatus == 'Compile Error') {
            status = 'Compile Error';
            firstErrorMessage ??= errorMessage;
          } else if (status != 'Runtime Error' && caseStatus == 'Runtime Error') {
            status = 'Runtime Error';
            firstErrorMessage ??= errorMessage;
          } else if (status == 'Accepted' && caseStatus == 'Wrong Answer') {
            status = 'Wrong Answer';
          } else if (status == 'Accepted' && caseStatus == 'Time Limit Exceeded') {
            status = 'Time Limit Exceeded';
            firstErrorMessage ??= errorMessage;
          }
        }
      }

      MonacoErrorHelper.clearMarkers();
      if (status == 'Compile Error') {
        final line = MonacoErrorHelper.parseErrorLine(firstErrorMessage);
        MonacoErrorHelper.setErrorMarker(line, firstErrorMessage);
      } else {
        MonacoErrorHelper.clearMarkers();
      }

      notifier.setRunResult({
        'status': status,
        'errorMessage': firstErrorMessage,
        'caseResults': caseResults,
      });
    } catch (e) {
      MonacoErrorHelper.clearMarkers();
      notifier.setRunResult({
        'status': 'Runtime Error',
        'errorMessage': e.toString(),
        'caseResults': const [],
      });
    } finally {
      notifier.setIsRunning(false);
    }
  }

  String _buildTestInput(Map<String, String> params) {
    return params.values.map((v) => v.trim()).join('\n');
  }

  void _seedTestcasesFromProblem() {
    final problem = ref.read(problemProvider(widget.problemId)).problem;
    if (problem == null) return;

    final sourceCases = problem.testCases.isNotEmpty
      ? problem.testCases
      : (problem.sampleTestCases ?? const []);

    final defaults = sourceCases.isNotEmpty
      ? sourceCases
        .map((tc) => {
            ...tc.inputs,
            '_expectedOutput': tc.expectedOutput,
          })
        .toList()
      : <Map<String, String>>[
        {'input': ''}
        ];

    final signature = defaults
        .map((row) => row.entries.map((e) => '${e.key}:${e.value}').join('|'))
        .join('||');

    if (signature == _lastSeedSignature) return;

    _lastSeedSignature = signature;
    ref.read(testcaseProvider(widget.problemId.toString()).notifier).initWithDefaults(defaults);
    ref.read(selectedCaseIndexProvider(widget.problemId.toString()).notifier).state = 0;
  }

  Future<void> _submitCode() async {
    final notifier = ref.read(problemProvider(widget.problemId).notifier);
    final state = ref.read(problemProvider(widget.problemId));
    final problem = state.problem;
    if (problem == null) return;

    MonacoErrorHelper.clearMarkers();
    ref.read(activeVerdictProvider.notifier).state = null;
    ref.read(verdictPanelVisibleProvider.notifier).state = true;

    notifier.setIsSubmitting(true);
    notifier.setRunResult(null);

    try {
      int? teamId;
      final contestId = widget.contestId;
      if (contestId != null) {
        final team = await ref.read(myTeamProvider(contestId).future);
        if (team == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Join a team before submitting in a contest.')),
            );
          }
          notifier.setIsSubmitting(false);
          return;
        }
        teamId = team.id;
      }

      final response = await ApiService.post(
        '/submit',
        data: {
          'problemId': problem.id,
          'problem_id': problem.id,
          'language': state.selectedLanguage,
          'version': _versionForLanguage(state.selectedLanguage),
          'code': state.currentCode,
          if (contestId != null) 'contestId': contestId,
          if (contestId != null) 'teamId': teamId,
            'test_input': problem.examples.isNotEmpty
              ? (problem.examples.first.input ?? '')
              : '',
        },
      );

      final submissionId = (response.data['submissionId'] as num?)?.toInt();
      if (submissionId == null) {
        notifier.setRunResult({'status': 'Submit Failed', 'got': 'Missing submission id'});
        return;
      }

      final verdict = await _pollSubmissionResult(
        submissionId,
        state.selectedLanguage,
        state.currentCode,
      );

      ref.read(activeVerdictProvider.notifier).state = verdict;
      ref.read(verdictPanelVisibleProvider.notifier).state = true;
      ref.invalidate(submissionHistoryProvider(problem.id.toString()));

      if (verdict.normalizedStatus == 'compile error') {
        MonacoErrorHelper.setErrorMarker(
          verdict.errorLine,
          verdict.errorMessage ?? verdict.stderr,
        );
      } else {
        MonacoErrorHelper.clearMarkers();
      }

      notifier.setRunResult({
        'status': verdict.status,
        'runtime': verdict.runtimeMs != null ? '${verdict.runtimeMs} ms' : '-',
        'memory': verdict.memoryKb != null ? '${verdict.memoryKb} KB' : '-',
        'expected': verdict.expectedOutput,
        'got': verdict.yourOutput,
        'message': verdict.errorMessage ?? verdict.stderr,
      });
    } catch (e) {
      notifier.setRunResult({
        'status': 'Submit Failed',
        'got': e.toString(),
      });
    } finally {
      notifier.setIsSubmitting(false);
    }
  }

  String _statusFromVerdict(String verdict) {
    switch (verdict) {
      case 'accepted':
        return 'Accepted';
      case 'wrong_answer':
        return 'Wrong Answer';
      case 'compilation_error':
        return 'Compile Error';
      case 'runtime_error':
        return 'Runtime Error';
      case 'time_limit_exceeded':
        return 'Time Limit Exceeded';
      default:
        return 'Pending';
    }
  }

  Future<SubmissionDetailModel> _pollSubmissionResult(
    int submissionId,
    String language,
    String code,
  ) async {
    const maxAttempts = 20;
    for (int i = 0; i < maxAttempts; i++) {
      final response = await ApiService.get('/submit/$submissionId');
      final submission = response.data['submission'] as Map<String, dynamic>?;
      if (submission == null) {
        return SubmissionDetailModel(
          id: submissionId.toString(),
          status: 'Submit Failed',
          language: language,
          runtimeMs: null,
          memoryKb: null,
          createdAt: DateTime.now(),
          code: code,
          errorMessage: 'No submission payload',
          stderr: null,
          errorLine: null,
        );
      }

      final verdict = (submission['verdict'] ?? 'pending').toString().toLowerCase();

      if (verdict == 'pending' || verdict == 'running' || verdict == 'queued') {
        await Future.delayed(const Duration(milliseconds: 900));
        continue;
      }

      final detailResponse = await ApiService.get('/api/submissions/$submissionId');
      final payload = detailResponse.data['submission'] as Map<String, dynamic>?;
      if (payload != null) {
        return SubmissionDetailModel.fromJson(payload);
      }

      return SubmissionDetailModel(
        id: submissionId.toString(),
        status: _statusFromVerdict(verdict),
        language: (submission['language'] ?? language).toString(),
        runtimeMs: (submission['runtime_ms'] as num?)?.toInt() ??
            (submission['time_ms'] as num?)?.toInt(),
        memoryKb: (submission['memory_kb'] as num?)?.toInt(),
        createdAt: DateTime.tryParse((submission['created_at'] ?? '').toString()) ?? DateTime.now(),
        code: code,
        errorMessage: submission['error_message']?.toString(),
        stderr: submission['stderr']?.toString(),
        errorLine: (submission['error_line'] as num?)?.toInt(),
      );
    }

    return SubmissionDetailModel(
      id: submissionId.toString(),
      status: 'Pending',
      language: language,
      runtimeMs: null,
      memoryKb: null,
      createdAt: DateTime.now(),
      code: code,
      errorMessage: 'Submission is still being judged. Please check again.',
      stderr: null,
      errorLine: null,
    );
  }

  void _goToProblem(int id) {
    if (id < 1) return;
    final contestId = widget.contestId;
    if (contestId != null) {
      context.go('/contests/$contestId/problems/$id');
    } else {
      context.go('/problems/$id');
    }
  }

  Widget _buildLeftLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFFFFA116)),
    );
  }

  Widget _buildRightLoading(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFA116)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(problemProvider(widget.problemId));
    final verdictPanelVisible = ref.watch(verdictPanelVisibleProvider);

    if (state.error != null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.error!,
                style: TextStyle(
                  color: isDark ? const Color(0xFFEBEBEB) : const Color(0xFF262626),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                    ref
                      .read(problemProvider(widget.problemId).notifier)
                      .fetchProblem(widget.problemId);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalW = constraints.maxWidth;
            final totalH = constraints.maxHeight;
            final rightH = totalH - 44;
            final verdictHeight = verdictPanelVisible ? 220.0 : 0.0;
            final minLeft = 280.0;
            final maxLeft = (totalW - 350.0) < minLeft ? minLeft : (totalW - 350.0);
            final maxEditorRaw = rightH - 4 - 100 - verdictHeight;
            final maxEditor = maxEditorRaw < 120 ? 120.0 : maxEditorRaw;

            if (!_sizesReady) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFA116)),
              );
            }

            final leftWidth = _leftWidth.clamp(minLeft, maxLeft);
            final editorHeight = _editorHeight.clamp(120.0, maxEditor);
            final testcaseHeight = rightH - editorHeight - 4 - verdictHeight;
            final problem = state.problem;
            final saveStatus = problem == null
              ? SaveStatus.idle
              : ref.watch(saveStatusProvider(problem.id.toString()));

            if (problem != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _seedTestcasesFromProblem();
              });

              if (_loadedProblemId != problem.id || _loadedLanguage != state.selectedLanguage) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _loadUserCodeForLanguage(state.selectedLanguage);
                });
              }
            }

            return Column(
              children: [
                SizedBox(
                  height: 44,
                  child: TopNavBar(
                    problemId: widget.problemId,
                    problemTitle: problem?.title ?? 'Problem List',
                    contestId: widget.contestId,
                    onPrevProblem: () => _goToProblem(widget.problemId - 1),
                    onNextProblem: () => _goToProblem(widget.problemId + 1),
                    onRun: _runCode,
                    onSubmit: _submitCode,
                    isRunning: state.isRunning,
                    isSubmitting: state.isSubmitting,
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: leftWidth,
                        child: problem == null
                            ? _buildLeftLoading()
                            : TabBarPanel(
                                problem: problem,
                                panelWidth: leftWidth,
                                problemId: widget.problemId,
                                tabController: _leftTabController,
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
                            ? _buildRightLoading(isDark)
                            : Column(
                                children: [
                                  SizedBox(
                                    height: editorHeight,
                                    child: CodeEditorPanel(
                                      problem: problem,
                                      selectedLanguage: state.selectedLanguage,
                                      currentCode: state.currentCode,
                                      saveStatusText: _saveStatusText(saveStatus),
                                      onLanguageChanged: (lang) {
                                        _onLanguageChanged(lang);
                                      },
                                      onCodeChanged: _onEditorCodeChanged,
                                    ),
                                  ),
                                  MouseRegion(
                                    cursor: SystemMouseCursors.resizeRow,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onVerticalDragUpdate: (d) {
                                        setState(() {
                                          _editorHeight = (_editorHeight + d.delta.dy)
                                              .clamp(120.0, maxEditor);
                                        });
                                      },
                                      child: Container(
                                        height: 4,
                                        color: isDark
                                            ? const Color(0xFF2A2A2A)
                                            : const Color(0xFFDDDDDD),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: verdictHeight,
                                    child: VerdictPanel(
                                      onViewInSubmissions: () {
                                        _leftTabController.animateTo(2);
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    height: testcaseHeight,
                                    child: TestcasePanel(
                                      problem: problem,
                                      problemId: widget.problemId,
                                      onRun: _runCode,
                                      onSubmit: _submitCode,
                                      isRunning: state.isRunning,
                                      isSubmitting: state.isSubmitting,
                                      runResult: state.runResult,
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
