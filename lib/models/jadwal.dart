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
    return Jadwal(
      id: json['_id'],
      hari: json['hari'],
      jamMulai: json['jamMulai'],
      jamSelesai: json['jamSelesai'],
      mataPelajaran: json['mataPelajaran'] ?? {},
      guru: json['guru'] ?? {},
      kelas: json['kelas'] ?? {},
    );
  }
}
