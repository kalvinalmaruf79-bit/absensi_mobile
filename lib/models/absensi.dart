class Absensi {
  final String id;
  final String keterangan;
  final DateTime? waktuMasuk;
  final String tanggal;
  final Map<String, dynamic> jadwal;

  Absensi({
    required this.id,
    required this.keterangan,
    this.waktuMasuk,
    required this.tanggal,
    required this.jadwal,
  });

  factory Absensi.fromJson(Map<String, dynamic> json) {
    return Absensi(
      id: json['_id'],
      keterangan: json['keterangan'],
      waktuMasuk: json['waktuMasuk'] != null
          ? DateTime.parse(json['waktuMasuk'])
          : null,
      tanggal: json['tanggal'],
      jadwal: json['jadwal'] ?? {},
    );
  }
}
