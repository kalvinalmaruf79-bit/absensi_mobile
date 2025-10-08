class Notifikasi {
  final String id;
  final String tipe;
  final String judul;
  final String pesan;
  final bool isRead;
  final DateTime createdAt;
  final String? resourceId;

  Notifikasi({
    required this.id,
    required this.tipe,
    required this.judul,
    required this.pesan,
    required this.isRead,
    required this.createdAt,
    this.resourceId,
  });

  factory Notifikasi.fromJson(Map<String, dynamic> json) {
    return Notifikasi(
      id: json['_id'],
      tipe: json['tipe'],
      judul: json['judul'],
      pesan: json['pesan'],
      isRead: json['isRead'],
      createdAt: DateTime.parse(json['createdAt']),
      resourceId: json['resourceId'],
    );
  }
}
