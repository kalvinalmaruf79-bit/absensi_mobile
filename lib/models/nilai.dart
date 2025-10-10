// lib/models/nilai.dart
class Nilai {
  final String id;
  final double nilai;
  final String jenisPenilaian;
  final String? deskripsi;
  final DateTime tanggalPenilaian;
  final Map<String, dynamic> mataPelajaran;
  final Map<String, dynamic> guru;
  final Map<String, dynamic>? kelas;
  final Map<String, dynamic>? tugas;
  final String semester;
  final String tahunAjaran;

  Nilai({
    required this.id,
    required this.nilai,
    required this.jenisPenilaian,
    this.deskripsi,
    required this.tanggalPenilaian,
    required this.mataPelajaran,
    required this.guru,
    this.kelas,
    this.tugas,
    required this.semester,
    required this.tahunAjaran,
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
      kelas: json['kelas'],
      tugas: json['tugas'],
      semester: json['semester'] ?? '',
      tahunAjaran: json['tahunAjaran'] ?? '',
    );
  }

  // Helper getter untuk nama mata pelajaran
  String get namaMataPelajaran => mataPelajaran['nama'] ?? 'N/A';

  // Helper getter untuk kode mata pelajaran
  String get kodeMataPelajaran => mataPelajaran['kode'] ?? '';

  // Helper getter untuk nama guru
  String get namaGuru => guru['name'] ?? 'N/A';

  // Helper getter untuk nama kelas
  String get namaKelas => kelas?['nama'] ?? '';

  // Helper getter untuk judul tugas (jika ada)
  String get judulTugas => tugas?['judul'] ?? '';

  // Helper untuk menentukan grade berdasarkan nilai
  String get grade {
    if (nilai >= 90) return 'A';
    if (nilai >= 80) return 'B';
    if (nilai >= 70) return 'C';
    if (nilai >= 60) return 'D';
    return 'E';
  }

  // Helper untuk status kelulusan
  bool get lulus => nilai >= 70;
}

// Model untuk statistik nilai per mata pelajaran
class StatistikNilai {
  final Map<String, dynamic> mataPelajaran;
  final double rataRata;
  final double nilaiTertinggi;
  final double nilaiTerendah;
  final int jumlahPenilaian;
  final List<Map<String, dynamic>> jenisNilai;

  StatistikNilai({
    required this.mataPelajaran,
    required this.rataRata,
    required this.nilaiTertinggi,
    required this.nilaiTerendah,
    required this.jumlahPenilaian,
    required this.jenisNilai,
  });

  factory StatistikNilai.fromJson(Map<String, dynamic> json) {
    return StatistikNilai(
      mataPelajaran: json['mataPelajaran'] ?? {},
      rataRata: (json['rataRata'] as num).toDouble(),
      nilaiTertinggi: (json['nilaiTertinggi'] as num).toDouble(),
      nilaiTerendah: (json['nilaiTerendah'] as num).toDouble(),
      jumlahPenilaian: json['jumlahPenilaian'] ?? 0,
      jenisNilai:
          (json['jenisNilai'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [],
    );
  }

  String get namaMataPelajaran => mataPelajaran['nama'] ?? 'N/A';
  String get kodeMataPelajaran => mataPelajaran['kode'] ?? '';
}

// Model untuk ringkasan nilai per semester
class RingkasanNilai {
  final String tahunAjaran;
  final String semester;
  final double rataRata;
  final int jumlahNilai;

  RingkasanNilai({
    required this.tahunAjaran,
    required this.semester,
    required this.rataRata,
    required this.jumlahNilai,
  });

  factory RingkasanNilai.fromJson(Map<String, dynamic> json) {
    return RingkasanNilai(
      tahunAjaran: json['tahunAjaran'] ?? '',
      semester: json['semester'] ?? '',
      rataRata: (json['rataRata'] as num).toDouble(),
      jumlahNilai: json['jumlahNilai'] ?? 0,
    );
  }

  String get periodeLabel => '$tahunAjaran - ${semester.capitalize()}';
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
