class Jadwal {
  final String id;
  final String hari;
  final String jamMulai;
  final String jamSelesai;
  final Map<String, dynamic> mataPelajaran;
  final Map<String, dynamic> guru;
  final Map<String, dynamic> kelas;

  Jadwal({
    required this.id,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.mataPelajaran,
    required this.guru,
    required this.kelas,
  });

  factory Jadwal.fromJson(Map<String, dynamic> json) {
    // Helper function untuk mengkonversi field yang bisa String atau Map
    Map<String, dynamic> _parseField(dynamic field, String defaultKey) {
      if (field == null) return {};
      if (field is Map<String, dynamic>) return field;
      if (field is String) return {defaultKey: field};
      return {};
    }

    return Jadwal(
      id: json['_id'] ?? '',
      hari: json['hari'] ?? '',
      jamMulai: json['jamMulai'] ?? '',
      jamSelesai: json['jamSelesai'] ?? '',
      mataPelajaran: _parseField(json['mataPelajaran'], '_id'),
      guru: _parseField(json['guru'], '_id'),
      kelas: _parseField(json['kelas'], '_id'),
    );
  }
}
