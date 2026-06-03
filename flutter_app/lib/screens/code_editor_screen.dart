import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:codemania/providers/problem_provider.dart';
import 'package:codemania/features/problem/providers/user_code_provider.dart';
import 'package:codemania/features/problem/providers/testcase_provider.dart';
import 'package:codemania/screens/problem_page/widgets/code_editor_panel.dart';
import 'package:codemania/widgets/testcase_bottom_sheet.dart';
import 'package:codemania/widgets/judging_overlay.dart';
import 'package:codemania/services/runtime_service.dart';
import 'package:codemania/services/api_service.dart';
import 'package:codemania/config.dart';
import 'package:codemania/core/utils/monaco_error_helper.dart';

// Provider for bottom sheet state
final consoleSheetVisibleProvider = StateProvider.autoDispose<bool>((ref) => false);
final consoleSheetTabProvider = StateProvider.autoDispose<int>((ref) => 0);

// Provider for run result state  
final runResultProvider = StateProvider.autoDispose<Map<String, dynamic>?>((ref) => null);

class CodeEditorScreen extends ConsumerStatefulWidget {
  const CodeEditorScreen({
    super.key,
    required this.problemId,
    this.contestId,
  });

  final int problemId;
  final int? contestId;

  @override
  ConsumerState<CodeEditorScreen> createState() => _CodeEditorScreenState();
}

class _CodeEditorScreenState extends ConsumerState<CodeEditorScreen> {
  Timer? _saveDebouncer;
  String? _loadedLanguage;
  int? _loadedProblemId;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final problem = ref.read(problemProvider(widget.problemId)).problem;
      if (problem == null) {
        ref.read(problemProvider(widget.problemId).notifier).fetchProblem(widget.problemId);
      }
    });
  }

  @override
  void dispose() {
    _saveDebouncer?.cancel();
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

  Future<void> _runCode() async {
    final notifier = ref.read(problemProvider(widget.problemId).notifier);
    final state = ref.read(problemProvider(widget.problemId));
    final problem = state.problem;
    if (problem == null) return;

    MonacoErrorHelper.clearMarkers();
    notifier.setIsRunning(true);
    ref.read(runResultProvider.notifier).state = null;

    // Show console sheet on Run tab
    ref.read(consoleSheetVisibleProvider.notifier).state = true;
    ref.read(consoleSheetTabProvider.notifier).state = 1; // Run Result tab

    try {
      final cases = ref.read(testcaseProvider(problem.id.toString()));
      final inputs = cases.isNotEmpty
          ? cases.map((tc) => _buildTestInput(tc.params)).toList()
          : <String>[
              problem.examples.isNotEmpty ? problem.examples.first.input : '',
            ];

      final responses = await Future.wait(
        inputs.map(
          (stdin) => ApiService.post(
            '/submit/run',
            data: {
              'problemId': problem.id,
              'problem_id': problem.id,
              'language': state.selectedLanguage,
              'version': RuntimeService.resolveVersion(state.selectedLanguage),
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
          'input': inputs[i],
        });

        // Update overall status - PRIORITY: Compile Error > Runtime Error > Wrong Answer > Accepted
        // If ANY test case fails, the overall verdict must reflect that failure
        if (!passed || caseStatus != 'Accepted') {
          if (caseStatus == 'Compile Error' || errorMessage?.contains('CompileError') == true) {
            status = 'Compile Error';
            firstErrorMessage ??= errorMessage;
          } else if (caseStatus == 'Runtime Error' || errorMessage?.isNotEmpty == true) {
            // Only set to Runtime Error if status isn't already Compile Error
            if (status != 'Compile Error') {
              status = 'Runtime Error';
              firstErrorMessage ??= errorMessage;
            }
          } else if (caseStatus == 'Time Limit Exceeded') {
            // Only set TLE if status isn't already Compile Error or Runtime Error
            if (status != 'Compile Error' && status != 'Runtime Error') {
              status = 'Time Limit Exceeded';
              firstErrorMessage ??= errorMessage;
            }
          } else {
            // Default to Wrong Answer for any other failure
            if (status == 'Accepted') {
              status = 'Wrong Answer';
            }
          }
        }
      }

      MonacoErrorHelper.clearMarkers();
      if (status == 'Compile Error') {
        final line = MonacoErrorHelper.parseErrorLine(firstErrorMessage);
        MonacoErrorHelper.setErrorMarker(line, firstErrorMessage);
      }

      ref.read(runResultProvider.notifier).state = {
        'status': status,
        'errorMessage': firstErrorMessage,
        'caseResults': caseResults,
      };
    } catch (e) {
      MonacoErrorHelper.clearMarkers();
      ref.read(runResultProvider.notifier).state = {
        'status': 'Runtime Error',
        'errorMessage': e.toString(),
        'caseResults': const [],
      };
    } finally {
      notifier.setIsRunning(false);
    }
  }

  String _buildTestInput(Map<String, String> params) {
    return params.values.map((v) => v.trim()).join('\n');
  }

  Future<void> _submitCode() async {
    final notifier = ref.read(problemProvider(widget.problemId).notifier);
    final state = ref.read(problemProvider(widget.problemId));
    final problem = state.problem;
    if (problem == null) return;

    MonacoErrorHelper.clearMarkers();
    notifier.setIsSubmitting(true);

    // Show judging overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const JudgingOverlay(),
    );

    try {
      final contestId = widget.contestId;
      final String submitPath;
      final Map<String, dynamic> submitData;

      if (contestId != null) {
        submitPath = '/api/contests/$contestId/problems/${problem.id}/submit';
        submitData = {
          'language': state.selectedLanguage,
          'code': state.currentCode,
        };
      } else {
        submitPath = '/submit';
        submitData = {
          'problemId': problem.id,
          'problem_id': problem.id,
          'language': state.selectedLanguage,
          'version': RuntimeService.resolveVersion(state.selectedLanguage),
          'code': state.currentCode,
          'test_input': problem.examples.isNotEmpty ? problem.examples.first.input : '',
        };
      }

      final response = await ApiService.post(submitPath, data: submitData);

      final submissionId = (response.data['submission_id'] as num?)?.toInt()
          ?? (response.data['submissionId'] as num?)?.toInt();
      
      if (submissionId != null) {
        // Poll for result
        await _pollSubmissionResult(submissionId);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close judging overlay
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submit failed: $e')),
        );
      }
    } finally {
      notifier.setIsSubmitting(false);
    }
  }

  Future<void> _pollSubmissionResult(int submissionId) async {
    const maxAttempts = 20;
    for (int i = 0; i < maxAttempts; i++) {
      final response = await ApiService.get('/submit/$submissionId');
      final submission = response.data['submission'] as Map<String, dynamic>?;
      if (submission == null) break;

      final verdict = (submission['verdict'] ?? 'pending').toString().toLowerCase();

      if (verdict == 'pending' || verdict == 'running' || verdict == 'queued') {
        await Future.delayed(const Duration(milliseconds: 900));
        continue;
      }

      // Verdict received
      if (mounted) {
        Navigator.of(context).pop(); // Close judging overlay
        
        // Show result in bottom sheet
        final status = _statusFromVerdict(verdict);
        final runtimeMs = submission['runtime_ms'] ?? submission['time_ms'];
        
        ref.read(runResultProvider.notifier).state = {
          'status': status,
          'runtimeMs': runtimeMs,
          'errorMessage': submission['error_message'],
          'isSubmission': true,
        };
        
        ref.read(consoleSheetVisibleProvider.notifier).state = true;
        ref.read(consoleSheetTabProvider.notifier).state = 1; // Run Result tab
        
        // Show snackbar
        final isAccepted = verdict == 'accepted';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status),
            backgroundColor: isAccepted ? const Color(0xFF00B84C) : const Color(0xFFFF375F),
          ),
        );
      }
      return;
    }

    // Timeout
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission is still being judged')),
      );
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final problemState = ref.watch(problemProvider(widget.problemId));
    final problem = problemState.problem;
    final consoleVisible = ref.watch(consoleSheetVisibleProvider);

    if (problem != null) {
      if (_loadedProblemId != problem.id || _loadedLanguage != problemState.selectedLanguage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _loadUserCodeForLanguage(problemState.selectedLanguage);
        });
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // TODO: Show problem switcher dropdown
                },
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        problem?.title ?? 'Problem',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Language selector
          PopupMenuButton<String>(
            initialValue: problemState.selectedLanguage,
            onSelected: _onLanguageChanged,
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                problemState.selectedLanguage.toUpperCase(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'python', child: Text('Python')),
              PopupMenuItem(value: 'javascript', child: Text('JavaScript')),
              PopupMenuItem(value: 'cpp', child: Text('C++')),
              PopupMenuItem(value: 'java', child: Text('Java')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              // TODO: Show editor settings
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Code editor
          Expanded(
            child: problem == null
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : CodeEditorPanel(
                    problem: problem,
                    selectedLanguage: problemState.selectedLanguage,
                    currentCode: problemState.currentCode,
                    saveStatusText: '',
                    onLanguageChanged: _onLanguageChanged,
                    onCodeChanged: _onEditorCodeChanged,
                  ),
          ),

          // Bottom action bar
          Container(
            height: 56 + MediaQuery.of(context).padding.bottom,
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(top: BorderSide(color: colorScheme.outline)),
            ),
            child: Row(
              children: [
                // Console button
                TextButton.icon(
                  onPressed: () {
                    ref.read(consoleSheetVisibleProvider.notifier).state = !consoleVisible;
                    if (!consoleVisible) {
                      ref.read(consoleSheetTabProvider.notifier).state = 0; // Testcase tab
                    }
                  },
                  icon: const Icon(Icons.terminal, size: 20),
                  label: const Text('Console'),
                ),
                const Spacer(),
                
                // Run button
                IconButton(
                  onPressed: problemState.isRunning ? null : _runCode,
                  icon: problemState.isRunning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow, size: 28),
                  tooltip: 'Run',
                ),
                const SizedBox(width: 16),
                
                // Submit button
                ElevatedButton(
                  onPressed: problemState.isSubmitting ? null : _submitCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B84C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: problemState.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Submit'),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: consoleVisible && problem != null
          ? Builder(
              builder: (context) {
                // Capture bottom padding before bottom sheet context
                final bottomPadding = MediaQuery.of(context).padding.bottom;
                return MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: TestcaseBottomSheet(
                    problem: problem,
                    problemId: widget.problemId,
                    onRun: _runCode,
                    onSubmit: _submitCode,
                    onClose: () {
                      ref.read(consoleSheetVisibleProvider.notifier).state = false;
                    },
                    systemBottomPadding: bottomPadding,
                  ),
                );
              },
            )
          : null,
    );
  }
}
