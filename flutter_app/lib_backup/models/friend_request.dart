class FriendRequest {
  final int id;
  final int senderId;
  final String senderUsername;
  final String? senderAvatarUrl;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.senderId,
    required this.senderUsername,
    this.senderAvatarUrl,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as int,
      senderId: json['sender_id'] as int,
      senderUsername: json['sender_username'] as String? ?? 'Unknown',
      senderAvatarUrl: json['sender_avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_id': senderId,
        'sender_username': senderUsername,
        'sender_avatar_url': senderAvatarUrl,
        'created_at': createdAt.toIso8601String(),
      };
}
