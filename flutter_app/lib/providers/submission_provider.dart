import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codemania/models/submission_model.dart';
import 'package:codemania/services/api_service.dart';

class SubmissionState {
  final bool isSubmitting;
  final String? lastVerdict;
  final List<Map<String, dynamic>> runResults;
  final String? runError;
  final String? runErrorType;
  final String? submitError;
  final Map<String, dynamic>? submitDetails;
  final List<SubmissionModel> history;
  final String? error;
  final bool isLoading;

  SubmissionState({
    this.isSubmitting = false,
    this.lastVerdict,
    this.runResults = const [],
    this.runError,
    this.runErrorType,
    this.submitError,
    this.submitDetails,
    this.history = const [],
    this.error,
    this.isLoading = false,
  });

  SubmissionState copyWith({
    bool? isSubmitting,
    String? lastVerdict,
    List<Map<String, dynamic>>? runResults,
    String? runError,
    String? runErrorType,
    String? submitError,
    Map<String, dynamic>? submitDetails,
    List<SubmissionModel>? history,
    String? error,
    bool? isLoading,
    bool clearRun = false,
    bool clearSubmit = false,
  }) {
    return SubmissionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      lastVerdict: lastVerdict ?? this.lastVerdict,
      runResults: runResults ?? this.runResults,
      runError: clearRun ? null : (runError ?? this.runError),
      runErrorType: clearRun ? null : (runErrorType ?? this.runErrorType),
      submitError: clearSubmit ? null : (submitError ?? this.submitError),
      submitDetails: clearSubmit ? null : (submitDetails ?? this.submitDetails),
      history: history ?? this.history,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SubmissionNotifier extends StateNotifier<SubmissionState> {
  SubmissionNotifier() : super(SubmissionState());

  Future<Map<String, dynamic>> runCode({
    required int problemId,
    required String language,
    required String version,
    required String code,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null, clearRun: true);
    try {
      final response = await ApiService.post(
        '/submit/run',
        data: {
          'problemId': problemId,
          'language': language,
          'version': version,
          'code': code,
        },
      );

      final results = response.data['results'] as List;
      state = state.copyWith(
        runResults: results.cast<Map<String, dynamic>>(),
        runError: response.data['run_error'] as String?,
        runErrorType: response.data['run_error_type'] as String?,
        isSubmitting: false,
      );

      return {'status': 'success', 'results': results};
    } catch (e) {
      state = state.copyWith(error: e.toString(), isSubmitting: false);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitCode({
    required int problemId,
    required int? contestId,
    required int? teamId,
    required String language,
    required String version,
    required String code,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null, clearSubmit: true);
    try {
      final response = await ApiService.post(
        '/submit',
        data: {
          'problemId': problemId,
          'contestId': contestId,
          'teamId': teamId,
          'language': language,
          'version': version,
          'code': code,
        },
      );

      state = state.copyWith(isSubmitting: false);

      return {
        'submissionId': response.data['submissionId'],
        'status': response.data['status'] ?? 'queued',
      };
    } catch (e) {
      state = state.copyWith(error: e.toString(), isSubmitting: false);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchSubmissionById(int submissionId) async {
    try {
      final response = await ApiService.get('/submit/$submissionId');
      return response.data['submission'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  void applySocketVerdict(Map<String, dynamic> payload) {
    state = state.copyWith(
      lastVerdict: payload['verdict'] as String?,
      submitError: payload['errorMessage'] as String?,
      submitDetails: {
        'errorMessage': payload['errorMessage'],
        'failedCase': payload['failedCase'],
        'passed': payload['passed'],
        'total': payload['total'],
      },
      isSubmitting: false,
    );
  }

  Future<void> fetchHistory({
    int? userId,
    int? problemId,
    int? contestId,
    int page = 1,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      String url;
      
      if (problemId != null) {
        // Use the specific endpoint for problem submissions
        url = '/api/submissions/problem/$problemId?page=$page';
      } else {
        // Fallback to general submit endpoint with query params
        url = '/submit?page=$page';
        if (userId != null) url += '&userId=$userId';
        if (contestId != null) url += '&contestId=$contestId';
      }

      final response = await ApiService.get(url);
      final submissions = (response.data['submissions'] as List)
          .map((s) => SubmissionModel.fromJson(s as Map<String, dynamic>))
          .toList();

      state = state.copyWith(history: submissions, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }
}

final submissionProvider =
    StateNotifierProvider<SubmissionNotifier, SubmissionState>((ref) {
  return SubmissionNotifier();
});
