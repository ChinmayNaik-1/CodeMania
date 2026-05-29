class ActivityModel {
  final int id;
  final int userId;
  final String username;
  final String? avatarUrl;
  final String activityType;
  final int? problemId;
  final String? problemTitle;
  final int? contestId;
  final String? contestTitle;
  final DateTime createdAt;

  ActivityModel({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.activityType,
    this.problemId,
    this.problemTitle,
    this.contestId,
    this.contestTitle,
    required this.createdAt,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? 'Unknown',
      avatarUrl: json['avatar_url'],
      activityType: json['activity_type'] ?? '',
      problemId: json['problem_id'],
      problemTitle: json['problem_title'],
      contestId: json['contest_id'],
      contestTitle: json['contest_title'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}
