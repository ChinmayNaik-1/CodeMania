class FriendModel {
  final int id;
  final String username;
  final String? avatarUrl;
  final int? globalRank;
  final int solvedCount;
  final int currentStreak;
  final bool isOnline;
  final String? friendshipStatus; 

  FriendModel({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.globalRank,
    required this.solvedCount,
    required this.currentStreak,
    required this.isOnline,
    this.friendshipStatus,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'] ?? json['requester_id'] ?? 0, 
      username: json['username'] ?? 'Unknown',
      avatarUrl: json['avatar_url'],
      globalRank: json['global_rank'],
      solvedCount: json['solved_count'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
      isOnline: json['is_online'] ?? false,
      friendshipStatus: json['status'],
    );
  }
}
