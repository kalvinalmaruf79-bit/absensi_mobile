class User {
  final String id;
  final String name;
  final String email;
  final String identifier;
  final String role;
  final bool isWaliKelas;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.identifier,
    required this.role,
    this.isWaliKelas = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      identifier: json['identifier'],
      role: json['role'],
      isWaliKelas: json['isWaliKelas'] ?? false,
    );
  }
}
