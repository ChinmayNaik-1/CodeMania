import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codemania/core/models/contest_model.dart';
import 'package:codemania/services/api_service.dart';

// ─── contestListProvider ──────────────────────────────────────────────────────

final contestListProvider =
    FutureProvider<Map<String, List<ContestModel>>>((ref) async {
  final res = await ApiService.get('/api/contests');
  final data = res.data as Map<String, dynamic>? ?? {};

  List<ContestModel> parseList(dynamic raw) => (raw as List? ?? [])
      .map((j) => ContestModel.fromJson(j as Map<String, dynamic>))
      .toList();

  return {
    'upcoming': parseList(data['upcoming']),
    'live': parseList(data['live']),
    'ended': parseList(data['ended']),
  };
});

// ─── contestDetailProvider ────────────────────────────────────────────────────

class ContestDetailNotifier
    extends StateNotifier<AsyncValue<ContestDetailModel>> {
  ContestDetailNotifier(this._contestId) : super(const AsyncValue.loading()) {
    loadContest();
  }

  final int _contestId;

  Future<void> loadContest() async {
    state = const AsyncValue.loading();
    try {
      final res = await ApiService.get('/api/contests/$_contestId');
      final detail =
          ContestDetailModel.fromJson(res.data as Map<String, dynamic>);
      state = AsyncValue.data(detail);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => loadContest();

  Future<void> registerSolo() async {
    await ApiService.post('/api/contests/$_contestId/register');
    await loadContest();
  }

  Future<void> createTeam(String teamName) async {
    await ApiService.post(
      '/api/contests/$_contestId/register',
      data: {'team_name': teamName},
    );
    await loadContest();
  }

  Future<void> unregister() async {
    await ApiService.delete('/api/contests/$_contestId/register');
    await loadContest();
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final res = await ApiService.get(
      '/api/contests/$_contestId/team/search-users',
      params: {'q': query},
    );
    final data = res.data as Map<String, dynamic>? ?? {};
    return (data['users'] as List? ?? [])
        .map((u) => u as Map<String, dynamic>)
        .toList();
  }

  Future<void> inviteUser(int inviteeId) async {
    await ApiService.post(
      '/api/contests/$_contestId/team/invite',
      data: {'invitee_id': inviteeId},
    );
  }

  Future<void> respondInvitation(int invitationId, String action) async {
    await ApiService.put(
      '/api/contests/$_contestId/invitations/$invitationId',
      data: {'action': action},
    );
    await loadContest();
  }
}

final contestDetailProvider = StateNotifierProvider.family<
    ContestDetailNotifier,
    AsyncValue<ContestDetailModel>,
    int>((ref, contestId) => ContestDetailNotifier(contestId));

// ─── contestLeaderboardProvider ───────────────────────────────────────────────

final contestLeaderboardProvider =
    FutureProvider.family<List<LeaderboardEntryModel>, int>(
        (ref, contestId) async {
  final res = await ApiService.get('/api/contests/$contestId/leaderboard');
  final raw = res.data;
  final list = (raw is List)
      ? raw
      : (raw as Map<String, dynamic>?)?['leaderboard'] as List? ?? [];
  return (list)
      .map((e) =>
          LeaderboardEntryModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ─── contestSubmitProvider ────────────────────────────────────────────────────

class ContestSubmitState {
  final bool isLoading;
  final String? verdict;
  final int? scoreAwarded;
  final bool firstSolve;
  final String? error;
  final Map<String, dynamic>? runResult;

  const ContestSubmitState({
    this.isLoading = false,
    this.verdict,
    this.scoreAwarded,
    this.firstSolve = false,
    this.error,
    this.runResult,
  });

  ContestSubmitState copyWith({
    bool? isLoading,
    String? verdict,
    int? scoreAwarded,
    bool? firstSolve,
    String? error,
    Map<String, dynamic>? runResult,
    bool clearVerdict = false,
    bool clearError = false,
  }) =>
      ContestSubmitState(
        isLoading: isLoading ?? this.isLoading,
        verdict: clearVerdict ? null : (verdict ?? this.verdict),
        scoreAwarded: clearVerdict ? null : (scoreAwarded ?? this.scoreAwarded),
        firstSolve: clearVerdict ? false : (firstSolve ?? this.firstSolve),
        error: clearError ? null : (error ?? this.error),
        runResult: runResult ?? this.runResult,
      );
}

class ContestSubmitNotifier extends StateNotifier<ContestSubmitState> {
  ContestSubmitNotifier() : super(const ContestSubmitState());

  Future<void> submit(
      int contestId, int problemId, String language, String code) async {
    state = state.copyWith(isLoading: true, clearVerdict: true, clearError: true);
    try {
      final res = await ApiService.post(
        '/api/contests/$contestId/problems/$problemId/submit',
        data: {'language': language, 'code': code},
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        // Verdict arrives via Socket.IO; just clear loading
        state = state.copyWith(isLoading: false);
      } else {
        final err = (res.data as Map<String, dynamic>?)?['error'] ?? 'Submission failed';
        state = state.copyWith(isLoading: false, error: err.toString());
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> run(
      int contestId, int problemId, String language, String code) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await ApiService.post(
        '/api/contests/$contestId/problems/$problemId/run',
        data: {'language': language, 'code': code},
      );
      state = state.copyWith(
        isLoading: false,
        runResult: res.data as Map<String, dynamic>?,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setVerdictFromSocket(String verdict, {int? score, bool firstSolve = false}) {
    state = state.copyWith(
      isLoading: false,
      verdict: verdict,
      scoreAwarded: score,
      firstSolve: firstSolve,
    );
  }
}

final contestSubmitProvider =
    StateNotifierProvider<ContestSubmitNotifier, ContestSubmitState>(
        (ref) => ContestSubmitNotifier());
