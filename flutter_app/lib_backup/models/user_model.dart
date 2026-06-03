class UserModel {
  final int id;
  final String username;
  final String email;
  final String role;
  final int rating;
  final String? avatarUrl;
  final String? googleUid;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.rating,
    this.avatarUrl,
    this.googleUid,
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'user',
      rating: json['rating'] as int? ?? 1200,
      avatarUrl: json['avatar_url'] as String?,
      googleUid: json['google_uid'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'rating': rating,
      'avatar_url': avatarUrl,
      'google_uid': googleUid,
    };
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? role,
    int? rating,
    String? avatarUrl,
    String? googleUid,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      rating: rating ?? this.rating,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      googleUid: googleUid ?? this.googleUid,
    );
  }
}
