import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codemania/core/models/friend_model.dart';
import 'package:codemania/core/models/activity_model.dart';
import 'package:codemania/models/friend_request.dart';
import 'package:codemania/services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class FriendsState {
  final List<FriendModel> friends;
  final List<FriendModel> pendingRequests;       // legacy (FriendModel-shaped)
  final List<FriendRequest> incomingRequests;    // typed model
  final List<ActivityModel> feed;
  final List<FriendModel> friendLeaderboard;

  // Find-users tab
  final List<Map<String, dynamic>> searchResults;
  final bool isSearching;

  final bool isLoading;
  final String? error;

  FriendsState({
    this.friends = const [],
    this.pendingRequests = const [],
    this.incomingRequests = const [],
    this.feed = const [],
    this.friendLeaderboard = const [],
    this.searchResults = const [],
    this.isSearching = false,
    this.isLoading = false,
    this.error,
  });

  FriendsState copyWith({
    List<FriendModel>? friends,
    List<FriendModel>? pendingRequests,
    List<FriendRequest>? incomingRequests,
    List<ActivityModel>? feed,
    List<FriendModel>? friendLeaderboard,
    List<Map<String, dynamic>>? searchResults,
    bool? isSearching,
    bool? isLoading,
    String? error,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      incomingRequests: incomingRequests ?? this.incomingRequests,
      feed: feed ?? this.feed,
      friendLeaderboard: friendLeaderboard ?? this.friendLeaderboard,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class FriendsNotifier extends StateNotifier<FriendsState> {
  FriendsNotifier() : super(FriendsState());

  // ── Load friends list ──────────────────────────────────────────────────────
  Future<void> loadFriends() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.get('/api/friends');
      if (res.statusCode == 200) {
        final list =
            (res.data as List).map((i) => FriendModel.fromJson(i as Map<String, dynamic>)).toList();
        state = state.copyWith(friends: list, isLoading: false);
      } else {
        state = state.copyWith(
            error: _err(res.data, 'Error loading friends'), isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // ── Load incoming requests (typed) ─────────────────────────────────────────
  Future<void> fetchIncomingRequests() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.get('/api/friends/requests/incoming');
      if (res.statusCode == 200) {
        final typed = (res.data as List)
            .map((i) => FriendRequest.fromJson(i as Map<String, dynamic>))
            .toList();
        // Also keep legacy pendingRequests populated (shaped as FriendModel)
        final legacy = typed.map((r) => FriendModel.fromJson({
              'id': r.id,
              'username': r.senderUsername,
              'avatar_url': r.senderAvatarUrl,
              'solved_count': 0,
              'current_streak': 0,
              'is_online': false,
            })).toList();
        state = state.copyWith(
          incomingRequests: typed,
          pendingRequests: legacy,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
            error: _err(res.data, 'Error loading requests'), isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // ── Legacy alias kept so existing call-sites don't break ──────────────────
  Future<void> loadRequests() => fetchIncomingRequests();

  // ── Send friend request by userId ─────────────────────────────────────────
  Future<void> sendFriendRequest(int targetUserId) async {
    final res = await ApiService.post(
      '/api/friends/request',
      data: {'targetUserId': targetUserId},
    );
    if (res.statusCode != 200) {
      throw Exception(_err(res.data, 'Error sending request'));
    }
  }

  // ── Legacy alias (old call-sites pass int userId) ─────────────────────────
  Future<void> sendRequest(int userId) => sendFriendRequest(userId);

  // ── Respond to a request ──────────────────────────────────────────────────
  Future<void> respondToRequest(int requestId, String action) async {
    final res = await ApiService.post(
      '/api/friends/respond',
      data: {'requestId': requestId, 'action': action},
    );
    if (res.statusCode == 200) {
      await fetchIncomingRequests();
      if (action == 'accept') await loadFriends();
    } else {
      throw Exception(_err(res.data, 'Error responding to request'));
    }
  }

  // ── Legacy alias used by old friends_screen.dart ──────────────────────────
  Future<void> respondRequest(int requestId, String action) =>
      respondToRequest(requestId, action);

  // ── Unfriend ──────────────────────────────────────────────────────────────
  Future<void> unfriend(int userId) async {
    final res = await ApiService.delete('/api/friends/$userId');
    if (res.statusCode == 200) {
      await loadFriends();
    } else {
      throw Exception(_err(res.data, 'Error unfriending'));
    }
  }

  // ── Activity feed ─────────────────────────────────────────────────────────
  Future<void> loadFeed() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.get('/api/friends/feed');
      if (res.statusCode == 200) {
        final list = (res.data as List)
            .map((i) => ActivityModel.fromJson(i as Map<String, dynamic>))
            .toList();
        state = state.copyWith(feed: list, isLoading: false);
      } else {
        state = state.copyWith(
            error: _err(res.data, 'Error loading feed'), isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // ── Friends leaderboard ───────────────────────────────────────────────────
  Future<void> loadLeaderboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.get('/api/friends/leaderboard');
      if (res.statusCode == 200) {
        final list = (res.data as List)
            .map((i) => FriendModel.fromJson(i as Map<String, dynamic>))
            .toList();
        state = state.copyWith(friendLeaderboard: list, isLoading: false);
      } else {
        state = state.copyWith(
            error: _err(res.data, 'Error loading leaderboard'), isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // ── User search ───────────────────────────────────────────────────────────
  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(searchResults: [], isSearching: false);
      return;
    }
    state = state.copyWith(isSearching: true);
    try {
      final res = await ApiService.get(
        '/api/friends/search/users',
        params: {'q': query.trim()},
      );
      if (res.statusCode == 200) {
        final results = (res.data as List).cast<Map<String, dynamic>>();
        state = state.copyWith(searchResults: results, isSearching: false);
      } else {
        state = state.copyWith(searchResults: [], isSearching: false);
      }
    } catch (e) {
      state = state.copyWith(searchResults: [], isSearching: false);
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────
  String _err(dynamic data, String fallback) {
    if (data is Map) return (data['error'] ?? fallback).toString();
    return fallback;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final friendsProvider =
    StateNotifierProvider<FriendsNotifier, FriendsState>((ref) {
  return FriendsNotifier();
});
