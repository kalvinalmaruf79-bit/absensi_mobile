// lib/models/pengumuman.dart

class Pengumuman {
  final String id;
  final String judul;
  final String isi;
  final Pembuat pembuat;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? targetRole;
  final List<dynamic>? targetKelas;
  final bool? isPublished;
  final DateTime? publishedAt;

  Pengumuman({
    required this.id,
    required this.judul,
    required this.isi,
    required this.pembuat,
    required this.createdAt,
    required this.updatedAt,
    this.targetRole,
    this.targetKelas,
    this.isPublished,
    this.publishedAt,
  });

  factory Pengumuman.fromJson(Map<String, dynamic> json) {
    return Pengumuman(
      id: json['_id'] ?? '',
      judul: json['judul'] ?? '',
      isi: json['isi'] ?? '',
      pembuat: Pembuat.fromJson(json['pembuat'] ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      targetRole: json['targetRole'],
      targetKelas: json['targetKelas'],
      isPublished: json['isPublished'],
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'judul': judul,
      'isi': isi,
      'pembuat': pembuat.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'targetRole': targetRole,
      'targetKelas': targetKelas,
      'isPublished': isPublished,
      'publishedAt': publishedAt?.toIso8601String(),
    };
  }
}

class Pembuat {
  final String id;
  final String name;
  final String role;

  Pembuat({required this.id, required this.name, required this.role});

  factory Pembuat.fromJson(Map<String, dynamic> json) {
    return Pembuat(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      role: json['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'name': name, 'role': role};
  }
}
