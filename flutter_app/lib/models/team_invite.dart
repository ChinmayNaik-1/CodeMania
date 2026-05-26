class TeamInvite {
  final int id;
  final int teamId;
  final String teamName;
  final String contestTitle;
  final String leaderUsername;
  final String status;
  final DateTime expiresAt;

  const TeamInvite({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.contestTitle,
    required this.leaderUsername,
    required this.status,
    required this.expiresAt,
  });

  factory TeamInvite.fromJson(Map<String, dynamic> json) {
    return TeamInvite(
      id: json['id'],
      teamId: json['team_id'],
      teamName: json['team_name'],
      contestTitle: json['contest_title'],
      leaderUsername: json['leader_username'],
      status: json['status'],
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }
}
