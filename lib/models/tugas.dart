class Tugas {
  final String id;
  final String judul;
  final String deskripsi;
  final DateTime deadline;
  final Map<String, dynamic> mataPelajaran;

  Tugas({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.deadline,
    required this.mataPelajaran,
  });

  factory Tugas.fromJson(Map<String, dynamic> json) {
    return Tugas(
      id: json['_id'],
      judul: json['judul'],
      deskripsi: json['deskripsi'],
      deadline: DateTime.parse(json['deadline']),
      mataPelajaran: json['mataPelajaran'] ?? {},
    );
  }
}
