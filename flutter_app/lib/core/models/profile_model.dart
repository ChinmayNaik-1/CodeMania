class HeatmapEntry {
  final DateTime date;
  final int count;
  HeatmapEntry({required this.date, required this.count});

  factory HeatmapEntry.fromJson(Map<String, dynamic> json) {
    return HeatmapEntry(
      date: DateTime.parse(json['date']),
      count: json['count'] ?? 0,
    );
  }
}

class StreakModel {
  final int currentStreak;
  final int maxStreak;
  StreakModel({required this.currentStreak, required this.maxStreak});

  factory StreakModel.fromJson(Map<String, dynamic> json) {
    return StreakModel(
      currentStreak: json['current_streak'] ?? 0,
      maxStreak: json['max_streak'] ?? 0,
    );
  }
}

class LanguageStat {
  final String language;
  final int problemsSolved;
  LanguageStat({required this.language, required this.problemsSolved});

  factory LanguageStat.fromJson(Map<String, dynamic> json) {
    return LanguageStat(
      language: json['language'] ?? '',
      problemsSolved: json['problems_solved'] ?? 0,
    );
  }
}

class ContestHistoryEntry {
  final String contestTitle;
  final int rank;
  final int score;
  final int ratingAfter;
  final DateTime participatedAt;

  ContestHistoryEntry({
    required this.contestTitle,
    required this.rank,
    required this.score,
    required this.ratingAfter,
    required this.participatedAt,
  });

  factory ContestHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ContestHistoryEntry(
      contestTitle: json['contest_title'] ?? '',
      rank: json['rank'] ?? 0,
      score: json['score'] ?? 0,
      ratingAfter: json['rating_after'] ?? 1500,
      participatedAt: DateTime.parse(json['participated_at']),
    );
  }
}

class RecentAC {
  final int problemId;
  final String title;
  final String language;
  final DateTime solvedAt;

  RecentAC({
    required this.problemId,
    required this.title,
    required this.language,
    required this.solvedAt,
  });

  factory RecentAC.fromJson(Map<String, dynamic> json) {
    return RecentAC(
      problemId: json['problem_id'] ?? 0,
      title: json['title'] ?? '',
      language: json['language'] ?? '',
      solvedAt: DateTime.parse(json['solved_at']),
    );
  }
}

class UserProfileModel {
  final int id;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final int? globalRank;
  final int totalSolved;
  final int easySolved;
  final int mediumSolved;
  final int hardSolved;
  final int totalProblems;
  final int friendsCount;
  final String? friendshipStatus;
  final List<LanguageStat> languages;
  final List<HeatmapEntry> heatmap;
  final StreakModel streak;
  final List<ContestHistoryEntry> contestHistory;
  final List<RecentAC> recentAC;
  final DateTime? createdAt;


  UserProfileModel({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.bio,
    this.globalRank,
    required this.totalSolved,
    required this.easySolved,
    required this.mediumSolved,
    required this.hardSolved,
    required this.totalProblems,
    required this.friendsCount,
    this.friendshipStatus,
    required this.languages,
    required this.heatmap,
    required this.streak,
    required this.contestHistory,
    required this.recentAC,
    this.createdAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    final stats = json['stats'] ?? {};
    
    return UserProfileModel(
      id: user['id'] ?? 0,
      username: user['username'] ?? 'Unknown',
      avatarUrl: user['avatar_url'],
      bio: user['bio'],
      globalRank: user['global_rank'],
      totalSolved: stats['total_solved'] ?? 0,
      easySolved: stats['easy_solved'] ?? 0,
      mediumSolved: stats['medium_solved'] ?? 0,
      hardSolved: stats['hard_solved'] ?? 0,
      totalProblems: stats['total_problems'] ?? 0,
      friendsCount: json['friends_count'] ?? 0,
      friendshipStatus: json['friendship_status'],
      languages: (json['languages'] as List?)?.map((l) => LanguageStat.fromJson(l)).toList() ?? [],
      heatmap: (json['heatmap'] as List?)?.map((h) => HeatmapEntry.fromJson(h)).toList() ?? [],
      streak: StreakModel.fromJson(json['streak'] ?? {}),
      contestHistory: (json['contest_history'] as List?)?.map((c) => ContestHistoryEntry.fromJson(c)).toList() ?? [],
      recentAC: (json['recent_ac'] as List?)?.map((r) => RecentAC.fromJson(r)).toList() ?? [],
      createdAt: user['created_at'] != null
          ? DateTime.tryParse(user['created_at'] as String)
          : null,
    );
  }
}
