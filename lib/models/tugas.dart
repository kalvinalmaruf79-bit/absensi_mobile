// lib/models/tugas.dart

/// Model Tugas - Merepresentasikan data tugas dari backend
class Tugas {
  final String id;
  final String judul;
  final String deskripsi;
  final DateTime deadline;
  final String semester;
  final String tahunAjaran;
  final dynamic mataPelajaran; // Ubah ke dynamic untuk handle String atau Map
  final dynamic kelas; // Ubah ke dynamic untuk handle String atau Map
  final dynamic guru; // Ubah ke dynamic untuk handle String atau Map
  final List<Submission> submissions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Tugas({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.deadline,
    required this.semester,
    required this.tahunAjaran,
    required this.mataPelajaran,
    this.kelas,
    this.guru,
    this.submissions = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Tugas.fromJson(Map<String, dynamic> json) {
    return Tugas(
      id: json['_id'] ?? '',
      judul: json['judul'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      deadline: DateTime.parse(json['deadline']),
      semester: json['semester'] ?? '',
      tahunAjaran: json['tahunAjaran'] ?? '',
      mataPelajaran: json['mataPelajaran'], // Biarkan sebagai dynamic
      kelas: json['kelas'], // Biarkan sebagai dynamic
      guru: json['guru'], // Biarkan sebagai dynamic
      submissions: json['submissions'] != null
          ? (json['submissions'] as List)
                .map((item) => Submission.fromJson(item))
                .toList()
          : [],
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
      'judul': judul,
      'deskripsi': deskripsi,
      'deadline': deadline.toIso8601String(),
      'semester': semester,
      'tahunAjaran': tahunAjaran,
      'mataPelajaran': mataPelajaran,
      'kelas': kelas,
      'guru': guru,
      'submissions': submissions.map((s) => s.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Helper method untuk mendapatkan nama mata pelajaran
  String get namaMataPelajaran {
    if (mataPelajaran is Map) {
      return (mataPelajaran as Map)['nama'] ?? '-';
    }
    return '-';
  }

  /// Helper method untuk mendapatkan kode mata pelajaran
  String get kodeMataPelajaran {
    if (mataPelajaran is Map) {
      return (mataPelajaran as Map)['kode'] ?? '-';
    }
    return '-';
  }

  /// Helper method untuk mendapatkan ID mata pelajaran
  String get mataPelajaranId {
    if (mataPelajaran is String) {
      return mataPelajaran;
    } else if (mataPelajaran is Map) {
      return (mataPelajaran as Map)['_id'] ?? '';
    }
    return '';
  }

  /// Helper method untuk mendapatkan nama kelas
  String get namaKelas {
    if (kelas is Map) {
      return (kelas as Map)['nama'] ?? '-';
    }
    return '-';
  }

  /// Helper method untuk mendapatkan ID kelas
  String get kelasId {
    if (kelas is String) {
      return kelas;
    } else if (kelas is Map) {
      return (kelas as Map)['_id'] ?? '';
    }
    return '';
  }

  /// Helper method untuk mendapatkan nama guru
  String get namaGuru {
    if (guru is Map) {
      return (guru as Map)['name'] ?? '-';
    }
    return '-';
  }

  /// Helper method untuk mendapatkan ID guru
  String get guruId {
    if (guru is String) {
      return guru;
    } else if (guru is Map) {
      return (guru as Map)['_id'] ?? '';
    }
    return '';
  }

  /// Helper method untuk cek apakah deadline sudah lewat
  bool get isDeadlinePassed => DateTime.now().isAfter(deadline);

  /// Helper method untuk mendapatkan submission siswa tertentu
  Submission? getSubmissionBySiswa(String siswaId) {
    try {
      return submissions.firstWhere((sub) => sub.siswaId == siswaId);
    } catch (e) {
      return null;
    }
  }

  /// Helper method untuk cek apakah siswa sudah submit
  bool hasSubmittedBy(String siswaId) {
    return getSubmissionBySiswa(siswaId) != null;
  }
}

/// Model Submission - Merepresentasikan pengumpulan tugas siswa
class Submission {
  final String id;
  final String siswaId;
  final String url;
  final String publicId;
  final String fileName;
  final DateTime submittedAt;
  final double? nilai;
  final String? feedback;
  final dynamic siswa; // Ubah ke dynamic untuk handle String atau Map

  Submission({
    required this.id,
    required this.siswaId,
    required this.url,
    required this.publicId,
    required this.fileName,
    required this.submittedAt,
    this.nilai,
    this.feedback,
    this.siswa,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    // Handle siswa sebagai ObjectId string atau objek populated
    String extractedSiswaId;
    if (json['siswa'] is String) {
      extractedSiswaId = json['siswa'];
    } else if (json['siswa'] is Map) {
      extractedSiswaId = json['siswa']['_id'] ?? '';
    } else {
      extractedSiswaId = '';
    }

    return Submission(
      id: json['_id'] ?? '',
      siswaId: extractedSiswaId,
      url: json['url'] ?? '',
      publicId: json['public_id'] ?? '',
      fileName: json['fileName'] ?? '',
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'])
          : DateTime.now(),
      nilai: json['nilai'] != null ? (json['nilai'] as num).toDouble() : null,
      feedback: json['feedback'],
      siswa: json['siswa'], // Simpan sebagai dynamic
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'siswa': siswaId,
      'url': url,
      'public_id': publicId,
      'fileName': fileName,
      'submittedAt': submittedAt.toIso8601String(),
      'nilai': nilai,
      'feedback': feedback,
    };
  }

  /// Helper method untuk mendapatkan nama siswa
  String get namaSiswa {
    if (siswa is Map) {
      return (siswa as Map)['name'] ?? '-';
    }
    return '-';
  }

  /// Helper method untuk mendapatkan identifier siswa
  String get identifierSiswa {
    if (siswa is Map) {
      return (siswa as Map)['identifier'] ?? '-';
    }
    return '-';
  }

  /// Helper method untuk cek apakah sudah dinilai
  bool get isGraded => nilai != null;

  /// Helper method untuk mendapatkan status nilai
  String get statusNilai {
    if (nilai == null) return 'Belum Dinilai';
    if (nilai! >= 75) return 'Lulus';
    return 'Tidak Lulus';
  }
}
