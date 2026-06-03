import 'package:codemania/core/models/testcase_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final testcaseProvider = StateNotifierProvider.family<TestcaseNotifier, List<TestCase>, String>(
  (ref, problemId) => TestcaseNotifier(problemId),
);

final selectedCaseIndexProvider = StateProvider.family<int, String>((ref, problemId) => 0);

class TestcaseNotifier extends StateNotifier<List<TestCase>> {
  TestcaseNotifier(this.problemId) : super(const []);

  final String problemId;

  void initWithDefaults(List<Map<String, String>> defaults) {
    if (defaults.isEmpty) {
      state = [
        TestCase(
          id: '${problemId}-case-1',
          label: 'Case 1',
          params: {'input': ''},
          expectedOutput: null,
        ),
      ];
      return;
    }

    state = defaults.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final row = Map<String, String>.from(entry.value);
      final expectedOutput = row.remove('_expectedOutput');
      return TestCase(
        id: '${problemId}-case-$index',
        label: 'Case $index',
        params: row,
        expectedOutput: expectedOutput,
      );
    }).toList();
  }
}
