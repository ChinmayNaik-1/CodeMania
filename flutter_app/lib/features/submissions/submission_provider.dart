import 'package:codemania/core/models/submission_model.dart';
import 'package:codemania/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final activeVerdictProvider =
    StateProvider<SubmissionDetailModel?>((ref) => null);

final verdictPanelVisibleProvider = StateProvider<bool>((ref) => false);

final submissionHistoryProvider =
    FutureProvider.family<List<SubmissionModel>, String>((ref, problemId) async {
  final response = await ApiService.get(
    '/api/submissions/problem/$problemId',
    params: const {'page': 1, 'limit': 20},
  );

  final rows = (response.data is Map<String, dynamic>)
      ? (response.data['submissions'] as List? ?? const [])
      : const [];

  return rows
      .whereType<Map>()
      .map((row) => SubmissionModel.fromJson(Map<String, dynamic>.from(row)))
      .toList();
});

final submissionDetailProvider =
    FutureProvider.family<SubmissionDetailModel, String>((ref, id) async {
  final response = await ApiService.get('/api/submissions/$id');

  final payload = (response.data is Map<String, dynamic>)
      ? (response.data['submission'] as Map<String, dynamic>? ?? response.data as Map<String, dynamic>)
      : <String, dynamic>{};

  return SubmissionDetailModel.fromJson(payload);
});
