import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codemania/models/contest_model.dart';
import 'package:codemania/models/contest.dart';
import 'package:codemania/models/leaderboard_entry.dart';
import 'package:codemania/models/team.dart';
import 'package:codemania/models/team_invite.dart';
import 'package:codemania/models/submission_model.dart';
import 'package:codemania/services/api_service.dart';

class ContestState {
  final List<ContestModel> contests;
  final ContestModel? activeContest;
  final List<TeamScoreModel> leaderboard;
  final List<Map<String, dynamic>> teamFeed;
  final bool isLoading;
  final String? error;

  ContestState({
    this.contests = const [],
    this.activeContest,
    this.leaderboard = const [],
    this.teamFeed = const [],
    this.isLoading = false,
    this.error,
  });

  ContestState copyWith({
    List<ContestModel>? contests,
    ContestModel? activeContest,
    List<TeamScoreModel>? leaderboard,
    List<Map<String, dynamic>>? teamFeed,
    bool? isLoading,
    String? error,
  }) {
    return ContestState(
      contests: contests ?? this.contests,
      activeContest: activeContest ?? this.activeContest,
      leaderboard: leaderboard ?? this.leaderboard,
      teamFeed: teamFeed ?? this.teamFeed,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final contestListProvider = FutureProvider<List<Contest>>((ref) async {
  final response = await ApiService.get('/api/contests');
  final list = (response.data as List? ?? const []);
  return list
      .whereType<Map>()
      .map((c) => Contest.fromJson(Map<String, dynamic>.from(c)))
      .toList();
});

final contestDetailProvider = FutureProvider.family<ContestDetail, int>((ref, contestId) async {
  final response = await ApiService.get('/api/contests/$contestId');
  return ContestDetail.fromJson(Map<String, dynamic>.from(response.data as Map));
});

final myTeamProvider = FutureProvider.family<Team?, int>((ref, contestId) async {
  try {
    final response = await ApiService.get('/api/contests/$contestId/my-team');
    final payload = response.data as Map<String, dynamic>;
    final teamJson = payload['team'];
    if (teamJson == null) return null;
    return Team.fromJson(Map<String, dynamic>.from(teamJson));
  } catch (_) {
    return null;
  }
});

final pendingInvitesProvider = FutureProvider<List<TeamInvite>>((ref) async {
  final response = await ApiService.get('/api/contests/invites/pending');
  final list = (response.data as Map<String, dynamic>)['invites'] as List? ?? const [];
  return list
      .whereType<Map>()
      .map((inv) => TeamInvite.fromJson(Map<String, dynamic>.from(inv)))
      .toList();
});

final leaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, int>((ref, contestId) async {
  final response = await ApiService.get('/api/contests/$contestId/leaderboard');
  final list = (response.data as Map<String, dynamic>)['leaderboard'] as List? ?? const [];
  return list
      .whereType<Map>()
      .map((entry) => LeaderboardEntry.fromJson(Map<String, dynamic>.from(entry)))
      .toList();
});

class ContestNotifier extends StateNotifier<AsyncValue<void>> {
  ContestNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<void> createTeam(int contestId, String teamName) async {
    state = const AsyncValue.loading();
    try {
      await ApiService.post(
        '/api/contests/$contestId/teams',
        data: {'teamName': teamName},
      );
      ref.invalidate(myTeamProvider(contestId));
      state = const AsyncValue.data(null);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<void> inviteUser(int teamId, int inviteeId) async {
    state = const AsyncValue.loading();
    try {
      await ApiService.post(
        '/api/contests/teams/$teamId/invite',
        data: {'inviteeId': inviteeId},
      );
      state = const AsyncValue.data(null);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<void> respondToInvite(int inviteId, bool accept) async {
    state = const AsyncValue.loading();
    try {
      await ApiService.post(
        '/api/contests/invites/$inviteId/respond',
        data: {'accept': accept},
      );
      ref.invalidate(pendingInvitesProvider);
      ref.invalidate(myTeamProvider);
      state = const AsyncValue.data(null);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }
}

final contestNotifierProvider = StateNotifierProvider<ContestNotifier, AsyncValue<void>>((ref) {
  return ContestNotifier(ref);
});

class LegacyContestNotifier extends StateNotifier<ContestState> {
  LegacyContestNotifier() : super(ContestState());

  Future<void> fetchContests() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.get('/contests');
      final contests = (response.data as List)
          .map((c) => ContestModel.fromJson(c as Map<String, dynamic>))
          .toList();

      state = state.copyWith(contests: contests, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> fetchContestById(int contestId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.get('/contests/$contestId');
      final contest = ContestModel.fromJson(response.data);
      state = state.copyWith(activeContest: contest, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> fetchLeaderboard(int contestId) async {
    try {
      final response = await ApiService.get('/contests/$contestId/leaderboard');
      final teams = (response.data['teams'] as List)
          .map((t) => TeamScoreModel.fromJson(t as Map<String, dynamic>))
          .toList();

      state = state.copyWith(leaderboard: teams);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> joinContest(int contestId, String joinCode) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiService.post(
        '/contests/$contestId/join',
        data: {'joinCode': joinCode},
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  void updateLeaderboard(List<TeamScoreModel> newLeaderboard) {
    state = state.copyWith(leaderboard: newLeaderboard);
  }

  void addTeamFeedEntry(Map<String, dynamic> entry) {
    final newFeed = [entry, ...state.teamFeed];
    state = state.copyWith(teamFeed: newFeed);
  }
}

final contestProvider = StateNotifierProvider<LegacyContestNotifier, ContestState>((ref) {
  return LegacyContestNotifier();
});
