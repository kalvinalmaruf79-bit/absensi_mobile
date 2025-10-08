class Nilai {
  final String id;
  final double nilai;
  final String jenisPenilaian;
  final String? deskripsi;
  final DateTime tanggalPenilaian;
  final Map<String, dynamic> mataPelajaran;
  final Map<String, dynamic> guru;

  Nilai({
    required this.id,
    required this.nilai,
    required this.jenisPenilaian,
    this.deskripsi,
    required this.tanggalPenilaian,
    required this.mataPelajaran,
    required this.guru,
  });

  factory Nilai.fromJson(Map<String, dynamic> json) {
    return Nilai(
      id: json['_id'],
      nilai: (json['nilai'] as num).toDouble(),
      jenisPenilaian: json['jenisPenilaian'],
      deskripsi: json['deskripsi'],
      tanggalPenilaian: DateTime.parse(json['tanggalPenilaian']),
      mataPelajaran: json['mataPelajaran'] ?? {},
      guru: json['guru'] ?? {},
    );
  }
}
