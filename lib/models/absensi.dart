// lib/models/absensi.dart
class Absensi {
  final String id;
  final String keterangan; // 'hadir', 'izin', 'sakit', 'alpa'
  final DateTime? waktuMasuk;
  final String tanggal; // Format: YYYY-MM-DD
  final Map<String, dynamic> jadwal;

  // Field tambahan untuk kompatibilitas penuh dengan backend
  final String? sesiPresensiId;
  final LokasiSiswa? lokasiSiswa;
  final String? pengajuanAbsensiId;
  final bool isManual;
  final Map<String, dynamic>? siswa; // Opsional, untuk beberapa endpoint
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Absensi({
    required this.id,
    required this.keterangan,
    this.waktuMasuk,
    required this.tanggal,
    required this.jadwal,
    this.sesiPresensiId,
    this.lokasiSiswa,
    this.pengajuanAbsensiId,
    this.isManual = false,
    this.siswa,
    this.createdAt,
    this.updatedAt,
  });

  factory Absensi.fromJson(Map<String, dynamic> json) {
    return Absensi(
      id: json['_id'],
      keterangan: json['keterangan'] ?? 'hadir',
      waktuMasuk: json['waktuMasuk'] != null
          ? DateTime.parse(json['waktuMasuk'])
          : null,
      tanggal: json['tanggal'],
      jadwal: json['jadwal'] ?? {},
      sesiPresensiId: json['sesiPresensi'] is String
          ? json['sesiPresensi']
          : json['sesiPresensi']?['_id'],
      lokasiSiswa: json['lokasiSiswa'] != null
          ? LokasiSiswa.fromJson(json['lokasiSiswa'])
          : null,
      pengajuanAbsensiId: json['pengajuanAbsensi'] is String
          ? json['pengajuanAbsensi']
          : json['pengajuanAbsensi']?['_id'],
      isManual: json['isManual'] ?? false,
      siswa: json['siswa'] != null
          ? Map<String, dynamic>.from(json['siswa'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'keterangan': keterangan,
      'waktuMasuk': waktuMasuk?.toIso8601String(),
      'tanggal': tanggal,
      'jadwal': jadwal,
      'sesiPresensi': sesiPresensiId,
      'lokasiSiswa': lokasiSiswa?.toJson(),
      'pengajuanAbsensi': pengajuanAbsensiId,
      'isManual': isManual,
      'siswa': siswa,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Helper getters
  String get namaSiswa => siswa?['name'] ?? 'Unknown';
  String get identifierSiswa => siswa?['identifier'] ?? '-';
  String get namaMataPelajaran => jadwal['mataPelajaran']?['nama'] ?? 'Unknown';
  String get namaKelas => jadwal['kelas']?['nama'] ?? 'Unknown';

  // Status badge color helper
  String get statusColor {
    switch (keterangan.toLowerCase()) {
      case 'hadir':
        return 'green';
      case 'izin':
        return 'blue';
      case 'sakit':
        return 'orange';
      case 'alpa':
        return 'red';
      default:
        return 'grey';
    }
  }

  // Check if this is from QR code check-in
  bool get isFromQRCode => sesiPresensiId != null && !isManual;

  // Check if this is from pengajuan
  bool get isFromPengajuan => pengajuanAbsensiId != null;

  // Check if this is manual entry by teacher
  bool get isManualEntry => isManual;
}

// Model untuk lokasi siswa
class LokasiSiswa {
  final double latitude;
  final double longitude;

  LokasiSiswa({required this.latitude, required this.longitude});

  factory LokasiSiswa.fromJson(Map<String, dynamic> json) {
    return LokasiSiswa(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
  }

  @override
  String toString() => 'Lat: $latitude, Long: $longitude';
}
