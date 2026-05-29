import 'dart:convert';
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
}

void main() {
  try {
    final jsonStr = '[{"id":4,"sender_id":2,"created_at":"2026-05-29T10:44:36.543Z","sender_username":"chinmay_M_Naik","sender_avatar_url":"https://lh3.googleusercontent.com/a/ACg8ocLIpgYuYOBp3T8y9oePqpZqdYDQ9KQpAx72ClmNpO1HuGhC2lg=s96-c"}]';
    final decoded = jsonDecode(jsonStr) as List;
    final typed = decoded.map((i) => FriendRequest.fromJson(i as Map<String, dynamic>)).toList();
    print('SUCCESS: ${typed.length} requests parsed.');
  } catch(e) {
    print('ERROR: $e');
  }
}
