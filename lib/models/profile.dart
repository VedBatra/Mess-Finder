// lib/models/profile.dart

class Profile {
  final String id;
  final String role;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.role,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      role: json['role'] as String? ?? 'user',
      fullName: json['full_name'] as String? ?? 'User',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'created_at': createdAt.toIso8601String(),
      };

  Profile copyWith({
    String? role,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) {
    return Profile(
      id: id,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
    );
  }

  @override
  String toString() => 'Profile(id: $id, role: $role, fullName: $fullName)';
}
