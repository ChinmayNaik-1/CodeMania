import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codemania/core/models/friend_model.dart';
import 'package:codemania/core/models/activity_model.dart';
import 'package:codemania/services/api_service.dart';

class FriendsState {
  final List<FriendModel> friends;
  final List<FriendModel> pendingRequests;
  final List<ActivityModel> feed;
  final List<FriendModel> friendLeaderboard;
  final bool isLoading;
  final String? error;

  FriendsState({
    this.friends = const [],
    this.pendingRequests = const [],
    this.feed = const [],
    this.friendLeaderboard = const [],
    this.isLoading = false,
    this.error,
  });

  FriendsState copyWith({
    List<FriendModel>? friends,
    List<FriendModel>? pendingRequests,
    List<ActivityModel>? feed,
    List<FriendModel>? friendLeaderboard,
    bool? isLoading,
    String? error,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      feed: feed ?? this.feed,
      friendLeaderboard: friendLeaderboard ?? this.friendLeaderboard,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class FriendsNotifier extends StateNotifier<FriendsState> {
  FriendsNotifier() : super(FriendsState());

  Future<void> loadFriends() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.get('/api/friends');
      if (res.statusCode == 200) {
        final list = (res.data as List).map((i) => FriendModel.fromJson(i)).toList();
        state = state.copyWith(friends: list, isLoading: false);
      } else {
        state = state.copyWith(error: res.data['error'] ?? 'Error loading friends', isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadRequests() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.get('/api/friends/requests');
      if (res.statusCode == 200) {
        final list = (res.data as List).map((i) => FriendModel.fromJson(i)).toList();
        state = state.copyWith(pendingRequests: list, isLoading: false);
      } else {
        state = state.copyWith(error: res.data['error'] ?? 'Error loading requests', isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadFeed() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.get('/api/friends/feed');
      if (res.statusCode == 200) {
        final list = (res.data as List).map((i) => ActivityModel.fromJson(i)).toList();
        state = state.copyWith(feed: list, isLoading: false);
      } else {
        state = state.copyWith(error: res.data['error'] ?? 'Error loading feed', isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadLeaderboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.get('/api/leaderboard/friends');
      if (res.statusCode == 200) {
        final list = (res.data as List).map((i) => FriendModel.fromJson(i)).toList();
        state = state.copyWith(friendLeaderboard: list, isLoading: false);
      } else {
        state = state.copyWith(error: res.data['error'] ?? 'Error loading leaderboard', isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> sendRequest(int userId) async {
    try {
      final res = await ApiService.post('/api/friends/request/$userId', data: {});
      if (res.statusCode != 200) {
        throw Exception(res.data['error'] ?? 'Error sending request');
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> respondRequest(int requestId, String action) async {
    try {
      final res = await ApiService.put('/api/friends/request/$requestId', data: {'action': action});
      if (res.statusCode == 200) {
        await loadRequests();
        if (action == 'accept') {
          await loadFriends();
        }
      } else {
        throw Exception(res.data['error'] ?? 'Error responding to request');
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> unfriend(int userId) async {
    try {
      final res = await ApiService.delete('/api/friends/$userId');
      if (res.statusCode == 200) {
        await loadFriends();
      } else {
        throw Exception(res.data['error'] ?? 'Error unfriending');
      }
    } catch (e) {
      throw e;
    }
  }
}

final friendsProvider = StateNotifierProvider<FriendsNotifier, FriendsState>((ref) {
  return FriendsNotifier();
});
