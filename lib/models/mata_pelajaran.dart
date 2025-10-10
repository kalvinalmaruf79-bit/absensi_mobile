// lib/models/mata_pelajaran.dart

class MataPelajaran {
  final String id;
  final String nama;
  final String kode;
  final String? deskripsi;
  final DateTime createdAt;
  final DateTime updatedAt;

  MataPelajaran({
    required this.id,
    required this.nama,
    required this.kode,
    this.deskripsi,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MataPelajaran.fromJson(Map<String, dynamic> json) {
    return MataPelajaran(
      id: json['_id'] ?? '',
      nama: json['nama'] ?? '',
      kode: json['kode'] ?? '',
      deskripsi: json['deskripsi'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nama': nama,
      'kode': kode,
      'deskripsi': deskripsi,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() => '$kode - $nama';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MataPelajaran &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
