// lib/models/materi.dart
// lib/models/materi.dart

class MateriFile {
  final String fileName;
  final String url;
  final String publicId;
  final String fileType;
  final DateTime uploadedAt;

  MateriFile({
    required this.fileName,
    required this.url,
    required this.publicId,
    required this.fileType,
    required this.uploadedAt,
  });

  factory MateriFile.fromJson(Map<String, dynamic> json) {
    return MateriFile(
      fileName: json['fileName'] ?? '',
      url: json['url'] ?? '',
      publicId: json['public_id'] ?? '',
      fileType: json['fileType'] ?? '',
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'url': url,
      'public_id': publicId,
      'fileType': fileType,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  String get fileExtension {
    final parts = fileName.split('.');
    return parts.isNotEmpty ? parts.last.toLowerCase() : '';
  }

  bool get isPdf => fileExtension == 'pdf';
  bool get isWord => ['doc', 'docx'].contains(fileExtension);
  bool get isPowerPoint => ['ppt', 'pptx'].contains(fileExtension);
  bool get isExcel => ['xls', 'xlsx'].contains(fileExtension);
  bool get isDocument => isPdf || isWord || isPowerPoint || isExcel;
}

class MateriLink {
  final String title;
  final String url;

  MateriLink({required this.title, required this.url});

  factory MateriLink.fromJson(Map<String, dynamic> json) {
    return MateriLink(title: json['title'] ?? '', url: json['url'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'url': url};
  }
}

class MateriGuru {
  final String id;
  final String name;

  MateriGuru({required this.id, required this.name});

  factory MateriGuru.fromJson(Map<String, dynamic> json) {
    return MateriGuru(id: json['_id'] ?? '', name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'name': name};
  }
}

class MateriMataPelajaran {
  final String id;
  final String nama;
  final String kode;

  MateriMataPelajaran({
    required this.id,
    required this.nama,
    required this.kode,
  });

  factory MateriMataPelajaran.fromJson(Map<String, dynamic> json) {
    return MateriMataPelajaran(
      id: json['_id'] ?? '',
      nama: json['nama'] ?? '',
      kode: json['kode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'nama': nama, 'kode': kode};
  }
}

class MateriKelas {
  final String id;
  final String nama;
  final String tingkat;
  final String? jurusan;

  MateriKelas({
    required this.id,
    required this.nama,
    required this.tingkat,
    this.jurusan,
  });

  factory MateriKelas.fromJson(Map<String, dynamic> json) {
    return MateriKelas(
      id: json['_id'] ?? '',
      nama: json['nama'] ?? '',
      tingkat: json['tingkat'] ?? '',
      jurusan: json['jurusan'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'nama': nama, 'tingkat': tingkat, 'jurusan': jurusan};
  }
}

class Materi {
  final String id;
  final String judul;
  final String deskripsi;
  final MateriMataPelajaran mataPelajaran;
  final MateriKelas kelas;
  final MateriGuru guru;
  final List<MateriFile> files;
  final List<MateriLink> links;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  Materi({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.mataPelajaran,
    required this.kelas,
    required this.guru,
    required this.files,
    required this.links,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Materi.fromJson(Map<String, dynamic> json) {
    List<MateriFile> filesList = [];
    if (json['files'] != null) {
      filesList = (json['files'] as List)
          .map((file) => MateriFile.fromJson(file))
          .toList();
    }

    List<MateriLink> linksList = [];
    if (json['links'] != null) {
      linksList = (json['links'] as List)
          .map((link) => MateriLink.fromJson(link))
          .toList();
    }

    return Materi(
      id: json['_id'] ?? '',
      judul: json['judul'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      mataPelajaran: MateriMataPelajaran.fromJson(
        json['mataPelajaran'] is String
            ? {'_id': json['mataPelajaran'], 'nama': '', 'kode': ''}
            : json['mataPelajaran'] ?? {},
      ),
      kelas: MateriKelas.fromJson(
        json['kelas'] is String
            ? {'_id': json['kelas'], 'nama': '', 'tingkat': ''}
            : json['kelas'] ?? {},
      ),
      guru: MateriGuru.fromJson(
        json['guru'] is String
            ? {'_id': json['guru'], 'name': ''}
            : json['guru'] ?? {},
      ),
      files: filesList,
      links: linksList,
      isPublished: json['isPublished'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'judul': judul,
      'deskripsi': deskripsi,
      'mataPelajaran': mataPelajaran.toJson(),
      'kelas': kelas.toJson(),
      'guru': guru.toJson(),
      'files': files.map((f) => f.toJson()).toList(),
      'links': links.map((l) => l.toJson()).toList(),
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get hasFiles => files.isNotEmpty;
  bool get hasLinks => links.isNotEmpty;
  bool get hasContent => hasFiles || hasLinks;

  int get totalFiles => files.length;
  int get totalLinks => links.length;

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Baru saja';
        }
        return '${difference.inMinutes} menit yang lalu';
      }
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks minggu yang lalu';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months bulan yang lalu';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years tahun yang lalu';
    }
  }
}
