class PengajuanAbsensi {
  final String id;
  final String tanggal;
  final String keterangan;
  final String alasan;
  final String status;
  final List<dynamic> jadwalTerkait;
  final Map<String, dynamic>? fileBukti;
  final Map<String, dynamic>? ditinjauOleh;

  PengajuanAbsensi({
    required this.id,
    required this.tanggal,
    required this.keterangan,
    required this.alasan,
    required this.status,
    required this.jadwalTerkait,
    this.fileBukti,
    this.ditinjauOleh,
  });

  factory PengajuanAbsensi.fromJson(Map<String, dynamic> json) {
    return PengajuanAbsensi(
      id: json['_id'],
      tanggal: json['tanggal'],
      keterangan: json['keterangan'],
      alasan: json['alasan'],
      status: json['status'],
      jadwalTerkait: json['jadwalTerkait'] as List<dynamic>? ?? [],
      fileBukti: json['fileBukti'],
      ditinjauOleh: json['ditinjauOleh'],
    );
  }
}
