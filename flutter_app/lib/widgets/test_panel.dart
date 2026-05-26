import 'dart:convert';

import 'package:codemania/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LeetTestCase {
  LeetTestCase({
    required this.name,
    required this.input,
    required this.expectedOutput,
  });

  final String name;
  final Map<String, dynamic> input;
  final String expectedOutput;
}

class RunResultData {
  RunResultData({
    required this.result,
    required this.expectedOutput,
    required this.actualOutput,
    this.error,
  });

  final String result;
  final String expectedOutput;
  final String actualOutput;
  final String? error;

  bool get isPassed => result == 'passed';
  bool get isError => result == 'error';
}

class TestPanel extends StatefulWidget {
  const TestPanel({
    super.key,
    required this.testCases,
    required this.getCode,
    required this.problemId,
    required this.language,
    required this.version,
    this.useMockBackend = false,
  });

  final List<LeetTestCase> testCases;
  final Future<String> Function() getCode;
  final int problemId;
  final String language;
  final String version;
  final bool useMockBackend;

  @override
  State<TestPanel> createState() => _TestPanelState();
}

class _TestPanelState extends State<TestPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedCaseIndex = 0;
  bool _isRunning = false;
  RunResultData? _runResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didUpdateWidget(covariant TestPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedCaseIndex >= widget.testCases.length) {
      _selectedCaseIndex = widget.testCases.isEmpty ? 0 : widget.testCases.length - 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E0F3)),
      ),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE9E4F4))),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1B223E),
              unselectedLabelColor: const Color(0xFF8A93A9),
              indicatorColor: const Color(0xFF5E2ED5),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Testcases'),
                Tab(text: 'Test Result'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                TestcasesTab(
                  testCases: widget.testCases,
                  selectedCaseIndex: _selectedCaseIndex,
                  isRunning: _isRunning,
                  onCaseSelected: (index) {
                    setState(() {
                      _selectedCaseIndex = index;
                    });
                  },
                  onRunPressed: _runSelectedCase,
                ),
                TestResultTab(runResult: _runResult, isRunning: _isRunning),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runSelectedCase() async {
    if (_isRunning || widget.testCases.isEmpty) return;

    setState(() {
      _isRunning = true;
      _runResult = null;
    });

    try {
      final code = await widget.getCode();
      final selectedCase = widget.testCases[_selectedCaseIndex];
      final result = await runCode(
        code: code,
        testCase: selectedCase.input,
        problemId: widget.problemId,
        language: widget.language,
        version: widget.version,
        expectedOutput: selectedCase.expectedOutput,
        useMockBackend: widget.useMockBackend,
      );

      if (!mounted) return;
      setState(() {
        _runResult = result;
      });
      _tabController.animateTo(1);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _runResult = RunResultData(
          result: 'error',
          expectedOutput: widget.testCases[_selectedCaseIndex].expectedOutput,
          actualOutput: '',
          error: error.toString(),
        );
      });
      _tabController.animateTo(1);
    } finally {
      if (!mounted) return;
      setState(() {
        _isRunning = false;
      });
    }
  }
}

class TestcasesTab extends StatelessWidget {
  const TestcasesTab({
    super.key,
    required this.testCases,
    required this.selectedCaseIndex,
    required this.isRunning,
    required this.onCaseSelected,
    required this.onRunPressed,
  });

  final List<LeetTestCase> testCases;
  final int selectedCaseIndex;
  final bool isRunning;
  final ValueChanged<int> onCaseSelected;
  final VoidCallback onRunPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            itemCount: testCases.length,
            itemBuilder: (context, index) {
              final testCase = testCases[index];
              final selected = index == selectedCaseIndex;

              return Card(
                color: selected ? const Color(0xFFF2EEFC) : const Color(0xFFFDFDFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF5E2ED5)
                        : const Color(0xFFE6E0F3),
                  ),
                ),
                child: ListTile(
                  onTap: () => onCaseSelected(index),
                  title: Text(
                    testCase.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? const Color(0xFF5E2ED5)
                          : const Color(0xFF2A2E45),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _formatInputMap(testCase.input),
                      style: const TextStyle(
                        color: Color(0xFF5D6786),
                        height: 1.45,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isRunning ? null : onRunPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5E2ED5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: isRunning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(isRunning ? 'Running...' : 'Run'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatInputMap(Map<String, dynamic> input) {
    return input.entries.map((entry) {
      return '${entry.key} = ${entry.value}';
    }).join('\n');
  }
}

class TestResultTab extends StatelessWidget {
  const TestResultTab({super.key, required this.runResult, required this.isRunning});

  final RunResultData? runResult;
  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    if (isRunning) {
      return const Center(child: CircularProgressIndicator());
    }

    if (runResult == null) {
      return const Center(
        child: Text(
          'Run code to test',
          style: TextStyle(color: Color(0xFFA0A6B6), fontSize: 16),
        ),
      );
    }

    if (runResult!.isPassed) {
      return SuccessWidget(output: runResult!.actualOutput);
    }

    if (runResult!.isError) {
      return RuntimeErrorResultWidget(error: runResult!.error ?? 'Unknown runtime error');
    }

    return FailureWidget(
      expected: runResult!.expectedOutput,
      actual: runResult!.actualOutput,
      error: runResult!.error,
    );
  }
}

class SuccessWidget extends StatelessWidget {
  const SuccessWidget({super.key, required this.output});

  final String output;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F7EF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFA8E2BE)),
          ),
          child: const Text(
            'Accepted',
            style: TextStyle(
              color: Color(0xFF1E9D6D),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _resultTextCard('Output', output),
      ],
    );
  }
}

class FailureWidget extends StatelessWidget {
  const FailureWidget({
    super.key,
    required this.expected,
    required this.actual,
    this.error,
  });

  final String expected;
  final String actual;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFECEC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFC8C8)),
          ),
          child: const Text(
            'Wrong Answer',
            style: TextStyle(
              color: Color(0xFFE06060),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _resultTextCard('Expected Output', expected),
        const SizedBox(height: 10),
        _resultTextCard('Your Output', actual),
        if (error != null && error!.isNotEmpty) ...[
          const SizedBox(height: 10),
          _resultTextCard('Error Message', error!),
        ],
      ],
    );
  }
}

class RuntimeErrorResultWidget extends StatelessWidget {
  const RuntimeErrorResultWidget({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFECEC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFC8C8)),
          ),
          child: const Text(
            'Runtime Error',
            style: TextStyle(
              color: Color(0xFFE06060),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _resultTextCard('Error Message', error),
      ],
    );
  }
}

Widget _resultTextCard(String label, String content) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F6FA),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE2E6EF)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF67708C),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: const TextStyle(
            color: Color(0xFF23273D),
            fontFamily: 'monospace',
            height: 1.35,
          ),
        ),
      ],
    ),
  );
}

Future<RunResultData> runCode({
  required String code,
  required Map<String, dynamic> testCase,
  required int problemId,
  required String language,
  required String version,
  required String expectedOutput,
  bool useMockBackend = false,
}) async {
  if (useMockBackend) {
    return mockRunCode(code: code, testCase: testCase, expectedOutput: expectedOutput);
  }

  final headers = <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  if (Config.currentToken.isNotEmpty) {
    headers['Authorization'] = 'Bearer ${Config.currentToken}';
  }

  final body = jsonEncode({
    'problemId': problemId,
    'language': language,
    'version': version,
    'code': code,
    'testCase': testCase,
  });

  try {
    final singleRunUri = Uri.parse('${Config.apiBaseUrl}/submit/run-single');
    final singleRunResponse =
        await http.post(singleRunUri, headers: headers, body: body);

    if (singleRunResponse.statusCode >= 200 && singleRunResponse.statusCode < 300) {
      final data = jsonDecode(singleRunResponse.body) as Map<String, dynamic>;
      return RunResultData(
        result: (data['result'] ?? 'error').toString(),
        expectedOutput: (data['expectedOutput'] ?? expectedOutput).toString(),
        actualOutput: (data['actualOutput'] ?? '').toString(),
        error: data['error']?.toString(),
      );
    }

    if (singleRunResponse.statusCode != 404) {
      return RunResultData(
        result: 'error',
        expectedOutput: expectedOutput,
        actualOutput: '',
        error: 'Failed to run code (${singleRunResponse.statusCode})',
      );
    }
  } catch (_) {
    // If the dedicated endpoint is unavailable, fallback to the current API.
  }

  try {
    final fallbackUri = Uri.parse('${Config.apiBaseUrl}/submit/run');
    final fallbackResponse = await http.post(
      fallbackUri,
      headers: headers,
      body: body,
    );

    if (fallbackResponse.statusCode < 200 || fallbackResponse.statusCode >= 300) {
      return RunResultData(
        result: 'error',
        expectedOutput: expectedOutput,
        actualOutput: '',
        error: 'Failed to run code (${fallbackResponse.statusCode})',
      );
    }

    final payload = jsonDecode(fallbackResponse.body) as Map<String, dynamic>;
    final results = (payload['results'] as List?) ?? const [];

    if (results.isEmpty) {
      return RunResultData(
        result: 'error',
        expectedOutput: expectedOutput,
        actualOutput: '',
        error: 'No testcase result returned from server.',
      );
    }

    final first = results.first as Map<String, dynamic>;
    final passed = first['passed'] == true;
    final error = first['error']?.toString();

    return RunResultData(
      result: error != null && error.isNotEmpty
          ? 'error'
          : (passed ? 'passed' : 'failed'),
      expectedOutput: (first['expected'] ?? expectedOutput).toString(),
      actualOutput: (first['actual'] ?? '').toString(),
      error: error,
    );
  } catch (error) {
    return RunResultData(
      result: 'error',
      expectedOutput: expectedOutput,
      actualOutput: '',
      error: 'Runtime error: $error',
    );
  }
}

Future<RunResultData> mockRunCode({
  required String code,
  required Map<String, dynamic> testCase,
  required String expectedOutput,
}) async {
  await Future.delayed(const Duration(seconds: 1));

  if (code.contains('return [0, 1]') || code.contains('return {0, 1}')) {
    return RunResultData(
      result: 'passed',
      expectedOutput: expectedOutput,
      actualOutput: expectedOutput,
    );
  }

  return RunResultData(
    result: 'failed',
    expectedOutput: expectedOutput,
    actualOutput: '[1, 0]',
    error: 'Wrong Answer',
  );
}
