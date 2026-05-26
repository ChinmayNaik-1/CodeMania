import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:codemania/config.dart';
import 'package:codemania/models/problem_model.dart';
import 'package:codemania/providers/auth_provider.dart';
import 'package:codemania/services/api_service.dart';
import 'package:codemania/services/runtime_service.dart';

class ProblemState {
  final List<ProblemModel> problems;
  final ProblemModel? selectedProblem;
  final Map<String, String> filters;
  final int currentPage;
  final int total;
  final Problem? problem;
  final bool isLoading;
  final String? error;
  final String selectedLanguage;
  final String currentCode;
  final bool isSolved;
  final bool isRunning;
  final bool isSubmitting;
  final Map<String, dynamic>? runResult;

  const ProblemState({
    this.problems = const [],
    this.selectedProblem,
    this.filters = const {},
    this.currentPage = 1,
    this.total = 0,
    this.problem,
    this.isLoading = false,
    this.error,
    this.selectedLanguage = 'python',
    this.currentCode = '',
    this.isSolved = false,
    this.isRunning = false,
    this.isSubmitting = false,
    this.runResult,
  });

  ProblemState copyWith({
    List<ProblemModel>? problems,
    ProblemModel? selectedProblem,
    Map<String, String>? filters,
    int? currentPage,
    int? total,
    Problem? problem,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? selectedLanguage,
    String? currentCode,
    bool? isSolved,
    bool? isRunning,
    bool? isSubmitting,
    Map<String, dynamic>? runResult,
    bool clearRunResult = false,
  }) {
    return ProblemState(
      problems: problems ?? this.problems,
      selectedProblem: selectedProblem ?? this.selectedProblem,
      filters: filters ?? this.filters,
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
      problem: problem ?? this.problem,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      currentCode: currentCode ?? this.currentCode,
      isSolved: isSolved ?? this.isSolved,
      isRunning: isRunning ?? this.isRunning,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      runResult: clearRunResult ? null : (runResult ?? this.runResult),
    );
  }
}

class ProblemNotifier extends StateNotifier<ProblemState> {
  ProblemNotifier(this.ref) : super(const ProblemState());

  final Ref ref;

  String _resolveStub(CodeStubs? stubs, String language) {
    if (stubs == null) return '';

    switch (language) {
      case 'python':
        return stubs.python ?? '';
      case 'cpp':
        return stubs.cpp ?? '';
      case 'java':
        return stubs.java ?? '';
      case 'javascript':
        return stubs.javascript ?? '';
      default:
        return '';
    }
  }

  String resolveStub(CodeStubs? stubs, String language) {
    return _resolveStub(stubs, language);
  }

  String _runtimeVersion(String language) {
    return RuntimeService.resolveVersion(language);
  }

  Future<void> fetchProblems({
    String? difficulty,
    String? tag,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      String url = '/problems?page=$page&limit=$limit';
      if (difficulty != null) url += '&difficulty=$difficulty';
      if (tag != null) url += '&tag=$tag';
      if (search != null) url += '&search=$search';

      final response = await ApiService.get(url);
      final rawProblems = (response.data['problems'] as List? ?? const []);
      final parsedProblems = rawProblems
          .map((p) => ProblemModel.fromJson(p as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        problems: parsedProblems,
        currentPage: page,
        total: (response.data['total'] as num?)?.toInt() ?? parsedProblems.length,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load problems: $e',
        isLoading: false,
      );
    }
  }

  Future<void> fetchProblem(int problemId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final authState = ref.read(authProvider);
      if (authState.user == null || Config.currentToken.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Not authenticated',
        );
        return;
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: Config.apiBaseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer ${Config.currentToken}',
          },
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final response = await dio.get('/problems/$problemId');
      final problem = Problem.fromJson(response.data as Map<String, dynamic>);
      final selectedLanguage = state.selectedLanguage;
      final initialCode = _resolveStub(problem.codeStubs, selectedLanguage);

      state = state.copyWith(
        problem: problem,
        selectedProblem: problem,
        currentCode: initialCode,
        isSolved: problem.isSolved ?? false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load problem: $e',
        isLoading: false,
      );
    }
  }

  Future<void> fetchProblemById(int id) async {
    await fetchProblem(id);
  }

  void setFilters(Map<String, String> newFilters) {
    state = state.copyWith(filters: newFilters);
  }

  Future<void> refresh() async {
    state = state.copyWith(
      problems: const [],
      isLoading: true,
      clearError: true,
    );
    await fetchProblems();
  }

  void changeLanguage(String lang) {
    final nextCode = _resolveStub(state.problem?.codeStubs, lang);
    state = state.copyWith(
      selectedLanguage: lang,
      currentCode: nextCode,
      clearRunResult: true,
    );
  }

  void updateCode(String code) {
    state = state.copyWith(currentCode: code);
  }

  void setIsRunning(bool value) {
    state = state.copyWith(isRunning: value);
  }

  void setIsSubmitting(bool value) {
    state = state.copyWith(isSubmitting: value);
  }

  void setRunResult(Map<String, dynamic>? value) {
    state = state.copyWith(runResult: value, clearRunResult: value == null);
  }

  Future<void> runCode(String code, String language, {String? customInput}) async {
    if (state.problem == null) return;

    state = state.copyWith(isRunning: true, clearRunResult: true);

    try {
      final token = Config.currentToken;
      final dio = Dio(
        BaseOptions(
          baseUrl: Config.apiBaseUrl,
          headers: {
            if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
        ),
      );

      final response = await dio.post(
        '/submit/run',
        data: {
          'problem_id': state.problem!.id,
          'problemId': state.problem!.id,
          'language': language,
          'version': _runtimeVersion(language),
          'code': code,
          'test_input': customInput ??
              ((state.problem!.examples?.isNotEmpty ?? false)
                  ? (state.problem!.examples!.first.input ?? '')
                  : ''),
        },
      );

      final data = response.data as Map<String, dynamic>;
      final results = (data['results'] as List?) ?? const [];
      final runError = data['run_error'];

      if (runError != null) {
        state = state.copyWith(
          isRunning: false,
          runResult: {
            'status': 'Compilation Error',
            'expected': results.isNotEmpty ? results.first['expected'] : null,
            'got': results.isNotEmpty ? results.first['actual'] : null,
          },
        );
        return;
      }

      if (results.isNotEmpty && results.every((r) => r['passed'] == true)) {
        state = state.copyWith(
          isRunning: false,
          runResult: {
            'status': 'Accepted',
            'runtime': '${results.first['time_ms'] ?? 0} ms',
            'memory': '- KB',
          },
        );
        return;
      }

      if (results.isNotEmpty) {
        final firstFailed = results.firstWhere(
          (r) => r['passed'] != true,
          orElse: () => results.first,
        );
        state = state.copyWith(
          isRunning: false,
          runResult: {
            'status': 'Wrong Answer',
            'expected': firstFailed['expected']?.toString() ?? '',
            'got': firstFailed['actual']?.toString() ?? '',
          },
        );
        return;
      }

      state = state.copyWith(
        isRunning: false,
        runResult: {'status': 'Run Failed'},
      );
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        runResult: {
          'status': 'Error',
          'message': e.toString(),
        },
      );
    }
  }

  Future<void> submitCode(String code, String language) async {
    if (state.problem == null) return;

    state = state.copyWith(isSubmitting: true, clearRunResult: true);

    try {
      final token = Config.currentToken;
      final dio = Dio(
        BaseOptions(
          baseUrl: Config.apiBaseUrl,
          headers: {
            if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
        ),
      );

      final response = await dio.post(
        '/submit',
        data: {
          'problem_id': state.problem!.id,
          'problemId': state.problem!.id,
          'language': language,
          'version': _runtimeVersion(language),
          'code': code,
        },
      );

      final result = response.data as Map<String, dynamic>;
      state = state.copyWith(
        isSubmitting: false,
        runResult: result,
        isSolved: result['status'] == 'Accepted' ? true : state.isSolved,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        runResult: {
          'status': 'Error',
          'message': e.toString(),
        },
      );
    }
  }
}

final problemListProvider = StateNotifierProvider<ProblemNotifier, ProblemState>(
  (ref) => ProblemNotifier(ref),
);

final problemProvider =
    StateNotifierProvider.family<ProblemNotifier, ProblemState, int>(
  (ref, problemId) => ProblemNotifier(ref),
);

final problemPageProvider = problemProvider;
