import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codemania/models/problem_model.dart';
import 'package:codemania/services/api_service.dart';
import 'package:codemania/features/admin/widgets/testcase_editor_section.dart';

class CreateProblemNotifier extends StateNotifier<AsyncValue<ProblemModel?>> {
  CreateProblemNotifier() : super(const AsyncValue.data(null));

  Future<ProblemModel?> loadProblem(int id) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiService.get('/problems/$id');
      final problem = ProblemModel.fromJson(response.data as Map<String, dynamic>);
      state = AsyncValue.data(problem);
      return problem;
    } catch (error, stack) {
      print('Load problem error: $error\n$stack');
      state = AsyncValue.error(error, stack);
      return null;
    }
  }

  Future<ProblemModel?> saveProblem({
    required Map<String, dynamic> payload,
    required List<TestCaseEntry> entries,
    required List<int> deletedIds,
    required Map<String, Map<String, String>> driverCode,
    int? problemId,
  }) async {
    state = const AsyncValue.loading();
    try {
      if (problemId == null) {
        final response = await ApiService.post(
          '/problems',
          data: {
            ...payload,
            'testCases': entries.map((entry) => entry.toPayload()).toList(),
          },
        );
        final problem = ProblemModel.fromJson(response.data as Map<String, dynamic>);
        state = AsyncValue.data(problem);
        return problem;
      }

      await ApiService.put('/problems/$problemId', data: payload);

      for (final entry in entries) {
        if (!entry.hasRequiredFields) {
          continue;
        }

        if (entry.savedId == null) {
          await ApiService.post(
            '/api/admin/problems/$problemId/testcases',
            data: entry.toPayload(),
          );
        } else {
          await ApiService.put(
            '/api/admin/problems/$problemId/testcases/${entry.savedId}',
            data: entry.toPayload(),
          );
        }
      }

      for (final id in deletedIds) {
        await ApiService.delete('/api/admin/problems/$problemId/testcases/$id');
      }

      for (final entry in driverCode.entries) {
        final prefix = entry.value['prefix'] ?? '';
        final suffix = entry.value['suffix'] ?? '';
        if (prefix.trim().isEmpty && suffix.trim().isEmpty) {
          continue;
        }
        await ApiService.post(
          '/api/admin/problems/$problemId/driver',
          data: {
            'language': entry.key,
            'driver_prefix': prefix,
            'driver_suffix': suffix,
          },
        );
      }

      final response = await ApiService.get('/problems/$problemId');
      final updated = ProblemModel.fromJson(response.data as Map<String, dynamic>);
      state = AsyncValue.data(updated);
      return updated;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      return null;
    }
  }
}

final createProblemProvider =
    StateNotifierProvider<CreateProblemNotifier, AsyncValue<ProblemModel?>>(
  (ref) => CreateProblemNotifier(),
);
