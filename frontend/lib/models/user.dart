class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String bio;
  final String? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'USER',
    this.bio = '',
    this.createdAt,
  });

  bool get isAdmin => role == 'ADMIN';

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        role: (json['role'] ?? 'USER').toString().toUpperCase(),
        bio: (json['bio'] ?? '').toString(),
        createdAt: json['created_at']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'bio': bio,
        if (createdAt != null) 'created_at': createdAt,
      };
}
