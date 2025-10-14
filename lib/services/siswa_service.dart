// lib/services/siswa_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // <-- PERBAIKAN: Impor ditambahkan
import 'package:path/path.dart' as path;

import 'api_service.dart';
import '../models/jadwal.dart';
import '../models/tugas.dart';
import '../models/nilai.dart';
import '../models/notifikasi.dart';
import '../models/histori_aktivitas.dart';
import "../models/pengumuman.dart";
import '../models/absensi.dart';

class SiswaService {
  final ApiService _apiService = ApiService();

  /// Mengambil data ringkasan untuk dashboard siswa.
  ///
  /// **Endpoint**: `GET /siswa/dashboard`
  ///
  /// **Success Response (200)**:
  /// ```json
  /// {
  ///   "siswa": { "name": "string", "identifier": "string", "kelas": { ... } },
  ///   "jadwalMendatang": { ... } | null, // Objek Jadwal
  ///   "tugasMendatang": [ { ... } ], // List Objek Tugas
  ///   "statistikPresensi": {
  ///     "hadir": int, "izin": int, "sakit": int, "alpa": int
  ///   }
  /// }
  /// ```
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      return await _apiService.get('siswa/dashboard');
    } catch (e) {
      throw Exception('Gagal memuat data dashboard: $e');
    }
  }

  /// Mengambil jadwal siswa per hari untuk semester tertentu.
  ///
  /// **Endpoint**: `GET /siswa/jadwal?tahunAjaran=<string>&semester=<string>`
  ///
  /// **Success Response (200)**: Map hari ke list jadwal
  /// ```json
  /// {
  ///   "senin": [ { ... } ], // List Objek Jadwal
  ///   "selasa": [ { ... } ],
  ///   ...
  /// }
  /// ```
  Future<Map<String, List<Jadwal>>> getJadwalSiswa(
    String tahunAjaran,
    String semester,
  ) async {
    try {
      final response = await _apiService.get(
        'siswa/jadwal?tahunAjaran=$tahunAjaran&semester=$semester',
      );
      final Map<String, dynamic> data = response as Map<String, dynamic>;
      return data.map((key, value) {
        final List<dynamic> jadwalList = value;
        return MapEntry(
          key,
          jadwalList.map((item) => Jadwal.fromJson(item)).toList(),
        );
      });
    } catch (e) {
      throw Exception('Gagal memuat jadwal: $e');
    }
  }

  Future<void> registerDeviceToken(String deviceToken) async {
    try {
      // Menggunakan metode .post dari ApiService Anda
      await _apiService.post('auth/register-device', {
        'deviceToken': deviceToken,
      });
      print('✅ Device token berhasil didaftarkan ke backend.');
    } catch (e) {
      // Melempar kembali error agar bisa ditangkap di tempat pemanggilan jika perlu
      print('❌ Gagal mendaftarkan device token ke backend: $e');
      throw Exception('Gagal mendaftarkan perangkat.');
    }
  }

  /// Mengambil satu jadwal terdekat yang akan datang.
  ///
  /// **Endpoint**: `GET /siswa/jadwal/mendatang`
  ///
  /// **Success Response (200)**:
  /// ```json
  /// {
  ///   "jadwalMendatang": { ... } | null // Objek Jadwal
  /// }
  /// ```
  Future<Jadwal?> getJadwalMendatang() async {
    try {
      final response = await _apiService.get('siswa/jadwal/mendatang');
      if (response['jadwalMendatang'] != null) {
        return Jadwal.fromJson(response['jadwalMendatang']);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal memuat jadwal mendatang: $e');
    }
  }

  /// Mengambil detail notifikasi berdasarkan ID
  ///
  /// **Endpoint**: `GET /siswa/notifikasi/:id`
  ///
  /// **Success Response (200)**:
  /// ```json
  /// {
  ///   "notifikasi": {
  ///     "_id": "string",
  ///     "tipe": "string",
  ///     "judul": "string",
  ///     "pesan": "string",
  ///     "resourceId": "string | null",
  ///     "isRead": boolean,
  ///     "createdAt": "ISO_Date_String",
  ///     "updatedAt": "ISO_Date_String"
  ///   },
  ///   "detailResource": {
  ///     "type": "tugas" | "nilai" | "pengumuman" | "jadwal",
  ///     "data": { ... }
  ///   } | null
  /// }
  /// ```
  Future<Map<String, dynamic>> getDetailNotifikasi(String notifikasiId) async {
    try {
      final response = await _apiService.get('siswa/notifikasi/$notifikasiId');
      return response;
    } catch (e) {
      throw Exception('Gagal memuat detail notifikasi: $e');
    }
  }

  /// Mengambil daftar tugas yang akan datang (deadline belum lewat).
  ///
  /// **Endpoint**: `GET /siswa/tugas/mendatang?limit=<num>`
  ///
  /// **Success Response (200)**: `List<Tugas>`
  /// ```json
  /// [
  ///   {
  ///     "_id": "string",
  ///     "judul": "string",
  ///     "deskripsi": "string",
  ///     "deadline": "ISO_Date_String",
  ///     "mataPelajaran": { "nama": "string", "kode": "string" },
  ///     "guru": { "name": "string" }
  ///   }
  /// ]
  /// ```
  Future<List<Tugas>> getTugasMendatang({int limit = 5}) async {
    try {
      final response = await _apiService.get(
        'siswa/tugas/mendatang?limit=$limit',
      );
      final List<dynamic> data = response;
      return data.map((json) => Tugas.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal memuat tugas mendatang: $e');
    }
  }

  /// Mengambil daftar nilai siswa untuk semester tertentu.
  ///
  /// **Endpoint**: `GET /siswa/nilai?tahunAjaran=<string>&semester=<string>`
  ///
  /// **Success Response (200)**: Objek Paginasi
  /// ```json
  /// {
  ///   "docs": [
  ///     {
  ///       "_id": "string",
  ///       "nilai": double,
  ///       "jenisPenilaian": "string",
  ///       ...
  ///     }
  ///   ],
  ///   ... // Properti paginasi lainnya
  /// }
  /// ```
  Future<List<Nilai>> getNilaiSiswa(String tahunAjaran, String semester) async {
    try {
      final response = await _apiService.get(
        'siswa/nilai?tahunAjaran=$tahunAjaran&semester=$semester',
      );
      final List<dynamic> data = response['docs'];
      return data.map((json) => Nilai.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal memuat nilai: $e');
    }
  }

  /// BARU: Mengambil statistik nilai per mata pelajaran
  ///
  /// **Endpoint**: `GET /siswa/nilai/statistik?tahunAjaran=<string>&semester=<string>`
  ///
  /// **Success Response (200)**:
  /// ```json
  /// {
  ///   "tahunAjaran": "string",
  ///   "semester": "string",
  ///   "rataRataKeseluruhan": double,
  ///   "perMataPelajaran": [
  ///     {
  ///       "mataPelajaran": { "nama": "string", "kode": "string" },
  ///       "rataRata": double,
  ///       "nilaiTertinggi": double,
  ///       "nilaiTerendah": double,
  ///       "jumlahPenilaian": int,
  ///       "jenisNilai": [ ... ]
  ///     }
  ///   ]
  /// }
  /// ```
  Future<Map<String, dynamic>> getStatistikNilai(
    String tahunAjaran,
    String semester,
  ) async {
    try {
      final response = await _apiService.get(
        'siswa/nilai/statistik?tahunAjaran=$tahunAjaran&semester=$semester',
      );

      return {
        'tahunAjaran': response['tahunAjaran'],
        'semester': response['semester'],
        'rataRataKeseluruhan': (response['rataRataKeseluruhan'] as num)
            .toDouble(),
        'perMataPelajaran': (response['perMataPelajaran'] as List<dynamic>)
            .map((item) => StatistikNilai.fromJson(item))
            .toList(),
      };
    } catch (e) {
      throw Exception('Gagal memuat statistik nilai: $e');
    }
  }

  /// BARU: Mengambil ringkasan nilai untuk semua semester
  ///
  /// **Endpoint**: `GET /siswa/nilai/ringkasan`
  ///
  /// **Success Response (200)**:
  /// ```json
  /// [
  ///   {
  ///     "tahunAjaran": "string",
  ///     "semester": "string",
  ///     "rataRata": double,
  ///     "jumlahNilai": int
  ///   }
  /// ]
  /// ```
  Future<List<RingkasanNilai>> getRingkasanNilai() async {
    try {
      final response = await _apiService.get('siswa/nilai/ringkasan');
      final List<dynamic> data = response;
      return data.map((json) => RingkasanNilai.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal memuat ringkasan nilai: $e');
    }
  }

  /// BARU: Mengambil semua nilai (tanpa filter semester)
  ///
  /// Berguna untuk melihat seluruh riwayat nilai siswa
  Future<List<Nilai>> getAllNilai({int page = 1, int limit = 100}) async {
    try {
      final response = await _apiService.get(
        'siswa/nilai?page=$page&limit=$limit',
      );
      final List<dynamic> data = response['docs'];
      return data.map((json) => Nilai.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal memuat semua nilai: $e');
    }
  }

  /// Mengambil daftar teman sekelas.
  ///
  /// **Endpoint**: `GET /siswa/teman-sekelas`
  ///
  /// **Success Response (200)**: `List<Map>`
  /// ```json
  /// [
  ///   {
  ///     "_id": "string",
  ///     "name": "string",
  ///     "identifier": "string"
  ///   }
  /// ]
  /// ```
  Future<List<Map<String, dynamic>>> getTemanSekelas() async {
    try {
      final response = await _apiService.get('siswa/teman-sekelas');
      final List<dynamic> data = response;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Gagal memuat teman sekelas: $e');
    }
  }

  /// Mengambil daftar notifikasi untuk siswa (dengan paginasi).
  ///
  /// **Endpoint**: `GET /siswa/notifikasi?page=<num>&limit=<num>`
  ///
  /// **Success Response (200)**: Objek Paginasi
  /// ```json
  /// {
  ///   "docs": [
  ///     {
  ///       "_id": "string",
  ///       "tipe": "string",
  ///       "judul": "string",
  ///       "pesan": "string",
  ///       "isRead": boolean,
  ///       "createdAt": "ISO_Date_String",
  ///       "resourceId": "string | null"
  ///     }
  ///   ],
  ///   ... // Properti paginasi lainnya
  /// }
  /// ```
  Future<List<Notifikasi>> getNotifikasi({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiService.get(
        'siswa/notifikasi?page=$page&limit=$limit',
      );
      // Mengambil dari 'docs' karena backend menggunakan pagination
      final List<dynamic> data = response['docs'];
      return data.map((json) => Notifikasi.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal memuat notifikasi: $e');
    }
  }

  /// Menandai notifikasi sebagai sudah dibaca.
  ///
  /// **Endpoint**: `PATCH /siswa/notifikasi/:notifikasiId/read` atau `PATCH /siswa/notifikasi/all/read`
  ///
  /// **Success Response (200)**:
  /// ```json
  /// {
  ///   "message": "<num> notifikasi ditandai telah dibaca."
  /// }
  /// ```
  Future<String> markNotifikasiAsRead(String notifikasiId) async {
    try {
      // Backend menggunakan 'id' sebagai parameter, bukan 'notifikasiId'
      final response = await _apiService.patch(
        'siswa/notifikasi/$notifikasiId/read',
        {},
      );
      return response['message'];
    } catch (e) {
      throw Exception('Gagal menandai notifikasi: $e');
    }
  }

  /// Mengambil daftar semua pengumuman yang relevan untuk siswa.
  ///
  /// **Endpoint**: `GET /pengumuman`
  Future<List<Pengumuman>> getPengumuman() async {
    try {
      final response = await _apiService.get('pengumuman');
      final List<dynamic> data = response;
      return data.map((json) => Pengumuman.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal memuat pengumuman: $e');
    }
  }

  /// Mengambil detail satu pengumuman berdasarkan ID.
  ///
  /// **Endpoint**: `GET /pengumuman/:id`
  Future<Pengumuman> getPengumumanById(String id) async {
    try {
      final response = await _apiService.get('pengumuman/$id');
      return Pengumuman.fromJson(response);
    } catch (e) {
      throw Exception('Gagal memuat detail pengumuman: $e');
    }
  }

  /// Mengambil histori aktivitas siswa (dengan paginasi).
  ///
  /// **Endpoint**: `GET /siswa/histori-aktivitas?page=<num>&limit=<num>`
  ///
  /// **Success Response (200)**: Objek Paginasi
  /// ```json
  /// {
  ///   "docs": [
  ///     {
  ///       "_id": "string",
  ///       "action": "string",
  ///       "details": "string | null",
  ///       "createdAt": "ISO_Date_String"
  ///     }
  ///   ],
  ///   ... // Properti paginasi lainnya
  /// }
  /// ```
  Future<List<HistoriAktivitas>> getHistoriAktivitas({
    int page = 1,
    int limit = 15,
  }) async {
    try {
      final response = await _apiService.get(
        'siswa/histori-aktivitas?page=$page&limit=$limit',
      );
      // Mengambil dari 'docs' karena backend menggunakan pagination
      final List<dynamic> data = response['docs'];
      return data.map((json) => HistoriAktivitas.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal memuat histori aktivitas: $e');
    }
  }

  /// Mengambil daftar tugas berdasarkan kelas dan mata pelajaran.
  ///
  /// **Endpoint**: `GET /tugas?kelasId=<string>&mataPelajaranId=<string>`
  ///
  /// **Success Response (200)**: `List<Tugas>`
  /// ```json
  /// [
  ///   {
  ///     "_id": "string",
  ///     "judul": "string",
  ///     "deskripsi": "string",
  ///     "deadline": "ISO_Date_String",
  ///     "mataPelajaran": { "nama": "string", "kode": "string" },
  ///     "kelas": { "nama": "string", "tingkat": "string", "jurusan": "string" },
  ///     "guru": { "name": "string", "identifier": "string" },
  ///     "semester": "string",
  ///     "tahunAjaran": "string",
  ///     "submissions": [ ... ]
  ///   }
  /// ]
  /// ```
  Future<List<Tugas>> getTugasByKelas({
    required String kelasId,
    required String mataPelajaranId,
  }) async {
    try {
      final response = await _apiService.get(
        'tugas?kelasId=$kelasId&mataPelajaranId=$mataPelajaranId',
      );
      final List<dynamic> data = response;
      return data.map((json) => Tugas.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal memuat daftar tugas: $e');
    }
  }

  /// Mengambil detail tugas berdasarkan ID.
  ///
  /// **Endpoint**: `GET /tugas/:id`
  ///
  /// **Success Response (200)**: Objek Tugas lengkap dengan submissions
  /// ```json
  /// {
  ///   "_id": "string",
  ///   "judul": "string",
  ///   "deskripsi": "string",
  ///   "deadline": "ISO_Date_String",
  ///   "mataPelajaran": { "nama": "string", "kode": "string" },
  ///   "kelas": { "nama": "string", "tingkat": "string", "jurusan": "string" },
  ///   "guru": { "name": "string", "identifier": "string" },
  ///   "semester": "string",
  ///   "tahunAjaran": "string",
  ///   "submissions": [
  ///     {
  ///       "_id": "string",
  ///       "siswa": { "name": "string", "identifier": "string" },
  ///       "url": "string",
  ///       "fileName": "string",
  ///       "submittedAt": "ISO_Date_String",
  ///       "nilai": number | null,
  ///       "feedback": "string | null"
  ///     }
  ///   ]
  /// }
  /// ```
  Future<Map<String, dynamic>> getTugasById(String tugasId) async {
    try {
      final response = await _apiService.get('tugas/$tugasId');
      return response;
    } catch (e) {
      throw Exception('Gagal memuat detail tugas: $e');
    }
  }

  /// Mengambil daftar tugas siswa dengan filter status
  ///
  /// **Endpoint**: `GET /tugas/siswa/list?status=<string>&mataPelajaranId=<string>`
  ///
  /// **Status Options**: 'active', 'submitted', 'graded', 'late', 'all'
  Future<List<Tugas>> getTugasSiswaByStatus({
    required String status,
    String? mataPelajaranId,
  }) async {
    try {
      String endpoint = 'tugas/siswa/list?status=$status';
      if (mataPelajaranId != null && mataPelajaranId.isNotEmpty) {
        endpoint += '&mataPelajaranId=$mataPelajaranId';
      }

      final response = await _apiService.get(endpoint);
      final List<dynamic> data = response;
      return data.map((json) => Tugas.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal memuat daftar tugas: $e');
    }
  }

  /// Re-upload tugas yang sudah dikumpulkan (belum dinilai)
  ///
  /// **Endpoint**: `PUT /tugas/:id/resubmit` (Multipart Form Data)
  Future<String> resubmitTugas({
    required String tugasId,
    required File file,
  }) async {
    try {
      final token = await _apiService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final url = Uri.parse('${ApiService.baseUrl}/tugas/$tugasId/resubmit');
      var request = http.MultipartRequest('PUT', url);
      request.headers['Authorization'] = 'Bearer $token';

      final fileName = path.basename(file.path);
      final fileExtension = path.extension(file.path).toLowerCase();

      String mimeType;
      switch (fileExtension) {
        case '.pdf':
          mimeType = 'application/pdf';
          break;
        case '.doc':
          mimeType = 'application/msword';
          break;
        case '.docx':
          mimeType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        case '.jpg':
        case '.jpeg':
          mimeType = 'image/jpeg';
          break;
        case '.png':
          mimeType = 'image/png';
          break;
        default:
          mimeType = 'application/octet-stream';
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          throw Exception('Upload timeout. Periksa koneksi internet Anda.');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final body = jsonDecode(response.body);
          return body['message'] ?? 'Tugas berhasil diperbarui.';
        } catch (e) {
          return response.body.isNotEmpty
              ? response.body
              : 'Tugas berhasil diperbarui.';
        }
      } else if (response.statusCode == 400) {
        try {
          final body = jsonDecode(response.body);
          throw Exception(body['message'] ?? 'Request tidak valid.');
        } catch (e) {
          throw Exception('Request tidak valid: ${response.body}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Sesi Anda telah berakhir. Silakan login kembali.');
      } else if (response.statusCode == 404) {
        throw Exception('Tugas tidak ditemukan.');
      } else if (response.statusCode == 413) {
        throw Exception('Ukuran file terlalu besar. Maksimal 20MB.');
      } else {
        try {
          final body = jsonDecode(response.body);
          throw Exception(
            body['message'] ??
                'Gagal memperbarui tugas (${response.statusCode})',
          );
        } catch (e) {
          throw Exception(
            'Gagal memperbarui tugas (${response.statusCode}): ${response.body}',
          );
        }
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on http.ClientException {
      throw Exception('Gagal terhubung ke server. Coba lagi nanti.');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Gagal memperbarui tugas: $e');
    }
  }

  /// Mengumpulkan tugas (submit tugas) dengan file.
  ///
  /// **Endpoint**: `POST /tugas/:id/submit` (Multipart Form Data)
  ///
  /// **Request Fields**:
  /// - `file`: File tugas (required, max 20MB)
  ///
  /// **Success Response (200)**:
  /// ```json
  /// {
  ///   "message": "Tugas berhasil dikumpulkan."
  /// }
  /// ```
  ///
  /// **Error Response (400/404/500)**:
  /// ```json
  /// {
  ///   "message": "Pesan error spesifik"
  /// }
  /// ```
  Future<String> submitTugas({
    required String tugasId,
    required File file,
  }) async {
    try {
      // Dapatkan token dari ApiService
      final token = await _apiService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      // Buat multipart request
      final url = Uri.parse('${ApiService.baseUrl}/tugas/$tugasId/submit');
      var request = http.MultipartRequest('POST', url);

      // Tambahkan header Authorization
      request.headers['Authorization'] = 'Bearer $token';

      // Dapatkan nama file dan extension
      final fileName = path.basename(file.path);
      final fileExtension = path.extension(file.path).toLowerCase();

      // Tentukan mime type berdasarkan extension
      String mimeType;
      switch (fileExtension) {
        case '.pdf':
          mimeType = 'application/pdf';
          break;
        case '.doc':
          mimeType = 'application/msword';
          break;
        case '.docx':
          mimeType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        case '.jpg':
        case '.jpeg':
          mimeType = 'image/jpeg';
          break;
        case '.png':
          mimeType = 'image/png';
          break;
        default:
          mimeType = 'application/octet-stream';
      }

      // Tambahkan file dengan mime type yang benar
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // Nama field harus sesuai dengan backend
          file.path,
          filename: fileName,
          // <-- PERBAIKAN: Menggunakan MediaType dari http_parser, bukan http.MediaType
          contentType: MediaType.parse(mimeType),
        ),
      );

      print('Uploading file: $fileName');
      print('File size: ${await file.length()} bytes');
      print('Mime type: $mimeType');
      print('URL: $url');

      // Kirim request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120), // Timeout 2 menit
        onTimeout: () {
          throw Exception('Upload timeout. Periksa koneksi internet Anda.');
        },
      );

      // Konversi streamed response ke response biasa
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Handle response
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final body = jsonDecode(response.body);
          return body['message'] ?? 'Tugas berhasil dikumpulkan.';
        } catch (e) {
          // Jika response bukan JSON, kembalikan text biasa
          return response.body.isNotEmpty
              ? response.body
              : 'Tugas berhasil dikumpulkan.';
        }
      } else if (response.statusCode == 400) {
        // Bad Request
        try {
          final body = jsonDecode(response.body);
          throw Exception(body['message'] ?? 'Request tidak valid.');
        } catch (e) {
          throw Exception('Request tidak valid: ${response.body}');
        }
      } else if (response.statusCode == 401) {
        // Unauthorized
        throw Exception('Sesi Anda telah berakhir. Silakan login kembali.');
      } else if (response.statusCode == 404) {
        // Not Found
        throw Exception('Tugas tidak ditemukan.');
      } else if (response.statusCode == 413) {
        // Payload Too Large
        throw Exception('Ukuran file terlalu besar. Maksimal 20MB.');
      } else {
        // Error lainnya
        try {
          final body = jsonDecode(response.body);
          throw Exception(
            body['message'] ??
                'Gagal mengumpulkan tugas (${response.statusCode})',
          );
        } catch (e) {
          throw Exception(
            'Gagal mengumpulkan tugas (${response.statusCode}): ${response.body}',
          );
        }
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on http.ClientException {
      throw Exception('Gagal terhubung ke server. Coba lagi nanti.');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Gagal mengumpulkan tugas: $e');
    }
  }
  // ==================== PRESENSI METHODS ====================

  /// Mengambil riwayat presensi siswa dengan pagination
  ///
  /// **Endpoint**: `GET /siswa/presensi?page=<num>&limit=<num>`
  ///
  /// **Success Response (200)**:
  /// ```json
  /// {
  ///   "docs": [ { ... } ], // List Objek Absensi
  ///   "totalDocs": int,
  ///   "limit": int,
  ///   "totalPages": int,
  ///   "page": int,
  ///   "hasNextPage": boolean,
  ///   "hasPrevPage": boolean
  /// }
  /// ```
  Future<Map<String, dynamic>> getRiwayatPresensi({
    int page = 1,
    int limit = 15,
  }) async {
    try {
      final response = await _apiService.get(
        'siswa/presensi?page=$page&limit=$limit',
      );

      return {
        'docs': (response['docs'] as List<dynamic>)
            .map((json) => Absensi.fromJson(json))
            .toList(),
        'totalDocs': response['totalDocs'],
        'limit': response['limit'],
        'totalPages': response['totalPages'],
        'page': response['page'],
        'hasNextPage': response['hasNextPage'] ?? false,
        'hasPrevPage': response['hasPrevPage'] ?? false,
      };
    } catch (e) {
      throw Exception('Gagal memuat riwayat presensi: $e');
    }
  }

  /// Mengambil statistik presensi siswa
  ///
  /// **Endpoint**: `GET /siswa/presensi/statistik?tahunAjaran=<string>&semester=<string>`
  ///
  /// **Success Response (200)**:
  /// ```json
  /// {
  ///   "hadir": int,
  ///   "izin": int,
  ///   "sakit": int,
  ///   "alpa": int,
  ///   "total": int,
  ///   "persentaseHadir": double,
  ///   "perBulan": [ ... ]
  /// }
  /// ```
  Future<Map<String, dynamic>> getStatistikPresensi({
    String? tahunAjaran,
    String? semester,
  }) async {
    try {
      String endpoint = 'siswa/presensi/statistik';
      List<String> params = [];

      if (tahunAjaran != null && tahunAjaran.isNotEmpty) {
        params.add('tahunAjaran=$tahunAjaran');
      }
      if (semester != null && semester.isNotEmpty) {
        params.add('semester=$semester');
      }

      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }

      final response = await _apiService.get(endpoint);
      return response;
    } catch (e) {
      throw Exception('Gagal memuat statistik presensi: $e');
    }
  }

  /// Mengambil presensi hari ini saja
  ///
  /// **Endpoint**: `GET /siswa/presensi/hari-ini`
  ///
  /// **Success Response (200)**: `List<Absensi>`
  Future<List<Absensi>> getPresensiHariIni() async {
    try {
      final response = await _apiService.get('siswa/presensi/hari-ini');
      final List<dynamic> data = response;
      return data.map((json) => Absensi.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal memuat presensi hari ini: $e');
    }
  }

  /// Mengambil detail presensi berdasarkan ID
  ///
  /// **Endpoint**: `GET /siswa/presensi/:id`
  ///
  /// **Success Response (200)**: Objek Absensi lengkap
  Future<Absensi> getDetailPresensi(String presensiId) async {
    try {
      final response = await _apiService.get('siswa/presensi/$presensiId');
      return Absensi.fromJson(response);
    } catch (e) {
      throw Exception('Gagal memuat detail presensi: $e');
    }
  }
}
