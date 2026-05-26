import 'package:codemania/core/models/testcase_model.dart';
import 'package:codemania/features/problem/providers/testcase_provider.dart';
import 'package:codemania/models/problem_model.dart' hide TestCase;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TestcasePanel extends ConsumerStatefulWidget {
  const TestcasePanel({
    super.key,
    required this.problem,
    required this.problemId,
    required this.onRun,
    required this.onSubmit,
    required this.isRunning,
    required this.isSubmitting,
    required this.runResult,
  });

  final Problem problem;
  final int problemId;
  final VoidCallback onRun;
  final VoidCallback onSubmit;
  final bool isRunning;
  final bool isSubmitting;
  final Map<String, dynamic>? runResult;

  @override
  ConsumerState<TestcasePanel> createState() => _TestcasePanelState();
}

class _TestcasePanelState extends ConsumerState<TestcasePanel> {
  int _activeTab = 0;
  int _selectedResultCase = 0;

  String get _problemKey => widget.problemId.toString();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF7F7F7),
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
              ),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              _tab(Icons.check_box_outlined, 'Testcase', 0),
              const SizedBox(width: 4),
              _tab(Icons.terminal_outlined, 'Test Result', 1),
              const Spacer(),
            ],
          ),
        ),
        Expanded(
          child: _activeTab == 0 ? _buildTestcaseBody(context, isDark) : _buildResultBody(context, isDark),
        ),
      ],
    );
  }

  Widget _tab(IconData icon, String label, int index) {
    final active = _activeTab == index;

    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? const Color(0xFFFFA116) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? const Color(0xFFFFA116) : const Color(0xFF8A8A8A),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w500 : FontWeight.normal,
                color: active ? const Color(0xFFFFA116) : const Color(0xFF8A8A8A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestcaseBody(BuildContext context, bool isDark) {
    final cases = ref.watch(testcaseProvider(_problemKey));
    final selectedIndex = ref.watch(selectedCaseIndexProvider(_problemKey));

    if (cases.isEmpty) {
      return const Center(
        child: Text(
          'No test cases available for this problem.',
          style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 13),
        ),
      );
    }

    final clampedIndex = selectedIndex.clamp(0, cases.length - 1);
    final selectedCase = cases[clampedIndex];

    if (clampedIndex != selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedCaseIndexProvider(_problemKey).notifier).state = clampedIndex;
      });
    }

    return Column(
      children: [
        SizedBox(
          height: 44,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                for (int i = 0; i < cases.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _casePill(isDark, cases[i], i == clampedIndex, () {
                      ref.read(selectedCaseIndexProvider(_problemKey).notifier).state = i;
                    }),
                  ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              for (final entry in selectedCase.params.entries) ...[
                Text(
                  '${entry.key} =',
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  initialValue: entry.value,
                  readOnly: true,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 13,
                    color: Color(0xFFE5E7EB),
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? const Color(0xFF23272F) : const Color(0xFF111827),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF374151)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF374151)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _casePill(bool isDark, TestCase testCase, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF323945) : const Color(0xFFE5E7EB))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? const Color(0xFFFFA116)
                : (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD0D0D0)),
          ),
        ),
        child: Text(
          testCase.label,
          style: TextStyle(
            fontSize: 12,
            color: selected
                ? const Color(0xFFFFA116)
                : (isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151)),
          ),
        ),
      ),
    );
  }

  Widget _buildResultBody(BuildContext context, bool isDark) {
    final runResult = widget.runResult;
    final cases = ref.watch(testcaseProvider(_problemKey));
    if (runResult == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terminal_outlined, size: 36, color: Color(0xFF3A3A3A)),
            SizedBox(height: 10),
            Text(
              'Run your code to see results',
              style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 13),
            ),
          ],
        ),
      );
    }

    final status = (runResult['status'] ?? 'Unknown').toString();
    final errorMessage = (runResult['errorMessage'] ?? runResult['message'] ?? '').toString();
    final caseResults = (runResult['caseResults'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
            .toList() ??
        <Map<String, dynamic>>[];

    if (status == 'Compile Error') {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: _errorBox(errorMessage.isEmpty ? 'Compilation failed' : errorMessage, isDark),
      );
    }

    if (caseResults.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: _errorBox(errorMessage.isEmpty ? 'No run results available.' : errorMessage, isDark),
      );
    }

    if (_selectedResultCase >= caseResults.length) {
      _selectedResultCase = caseResults.length - 1;
    }

    final selected = caseResults[_selectedResultCase];
    final selectedPassed = selected['passed'] == true;
    final selectedInputCase = cases.isNotEmpty
        ? cases[_selectedResultCase.clamp(0, cases.length - 1)]
        : null;
    final statusText = (runResult['status'] ?? 'Unknown').toString();
    final runtimeText = selected['runtime_ms'] != null ? '${selected['runtime_ms']} ms' : 'N/A';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Row(
            children: [
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: selectedPassed ? const Color(0xFF2CBB5D) : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Runtime: $runtimeText',
                style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                for (int i = 0; i < caseResults.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => setState(() => _selectedResultCase = i),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedResultCase == i
                                ? const Color(0xFFFFA116)
                                : (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD0D0D0)),
                          ),
                        ),
                        child: Text(
                          'Case ${i + 1} ${caseResults[i]['passed'] == true ? '✓' : '✗'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: caseResults[i]['passed'] == true
                                ? const Color(0xFF2CBB5D)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0)),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: selectedPassed
                            ? const Color(0x1A2CBB5D)
                            : const Color(0x1AEF4444),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        selectedPassed ? 'Passed' : 'Failed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selectedPassed
                              ? const Color(0xFF2CBB5D)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (selected['runtime_ms'] != null)
                      Text(
                        'Runtime: ${selected['runtime_ms']} ms',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (selectedInputCase != null) ...[
                  const Text(
                    'Input',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final entry in selectedInputCase.params.entries) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF23272F) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB),
                        ),
                      ),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${entry.key} =\n',
                              style: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 12,
                              ),
                            ),
                            TextSpan(
                              text: entry.value,
                              style: TextStyle(
                                color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827),
                                fontFamily: 'JetBrains Mono',
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                ],
                _resultBlock('Stdout', (selected['stdout'] ?? selected['actual'] ?? '').toString(), isDark),
                if ((selected['expected'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _resultBlock('Expected', (selected['expected'] ?? '').toString(), isDark),
                ],
                if ((selected['stderr'] ?? selected['error_message'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _errorBox((selected['stderr'] ?? selected['error_message']).toString(), isDark),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _resultBlock(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF23272F) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB)),
          ),
          child: SelectableText(
            value,
            style: TextStyle(
              color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827),
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorBox(String value, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A1F1F) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEF4444)),
      ),
      child: SelectableText(
        value,
        style: TextStyle(
          color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
          fontFamily: 'JetBrains Mono',
          fontSize: 12,
        ),
      ),
    );
  }
}
