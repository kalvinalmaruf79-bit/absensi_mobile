// lib/services/absensi_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pengajuan_absensi.dart';
import '../models/absensi.dart';
import '../utils/app_constants.dart';

class AbsensiService {
  final String _baseUrl = AppConstants.baseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Mengirim data check-in presensi berdasarkan kode sesi QR dengan lokasi.
  ///
  /// **Endpoint**: `POST /absensi/check-in`
  ///
  /// **Request Body**:
  /// ```json
  /// {
  ///   "kodeSesi": "string",
  ///   "latitude": double,
  ///   "longitude": double
  /// }
  /// ```
  ///
  /// **Success Response (200)**:
  /// ```json
  /// {
  ///   "message": "Presensi berhasil!"
  /// }
  /// ```
  ///
  /// **Error Responses**:
  /// - 400: Kode sesi tidak valid atau sudah kedaluwarsa
  /// - 400: Sudah melakukan presensi (termasuk konflik izin/sakit)
  /// - 403: Tidak terdaftar di kelas atau di luar radius
  Future<String> checkIn(
    String kodeSesi,
    double latitude,
    double longitude,
  ) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/absensi/check-in'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'kodeSesi': kodeSesi,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      final body = jsonDecode(response.body);

      // Handle berbagai status code dengan pesan yang spesifik
      if (response.statusCode == 200) {
        return body['message'] ?? 'Presensi berhasil!';
      } else if (response.statusCode == 400) {
        // Konflik absensi atau kode tidak valid
        throw AbsensiException(
          body['message'] ?? 'Gagal melakukan presensi',
          statusCode: 400,
        );
      } else if (response.statusCode == 403) {
        // Di luar radius atau tidak terdaftar di kelas
        throw AbsensiException(
          body['message'] ?? 'Akses ditolak',
          statusCode: 403,
        );
      } else {
        throw AbsensiException(
          body['message'] ?? 'Gagal melakukan presensi',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw AbsensiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on FormatException {
      throw AbsensiException('Format data tidak valid dari server.');
    } catch (e) {
      if (e is AbsensiException) rethrow;
      throw AbsensiException('Terjadi kesalahan: ${e.toString()}');
    }
  }

  /// Mengirim data check-in presensi berdasarkan kode absen manual (tanpa lokasi).
  /// Untuk siswa yang tidak bisa scan QR code.
  ///
  /// **Endpoint**: `POST /absensi/check-in-code`
  ///
  /// **Request Body**:
  /// ```json
  /// {
  ///   "kodeAbsen": "string"
  /// }
  /// ```
  ///
  /// **Success Response (200)**:
  /// ```json
  /// {
  ///   "message": "Presensi berhasil!"
  /// }
  /// ```
  ///
  /// **Error Responses**:
  /// - 400: Kode absen tidak valid atau sudah kedaluwarsa
  /// - 400: Sudah melakukan presensi (termasuk konflik izin/sakit)
  /// - 403: Tidak terdaftar di kelas
  Future<String> checkInWithCode(String kodeAbsen) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/absensi/check-in-code'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'kodeAbsen': kodeAbsen}),
      );

      final body = jsonDecode(response.body);

      // Handle berbagai status code dengan pesan yang spesifik
      if (response.statusCode == 200) {
        return body['message'] ?? 'Presensi berhasil!';
      } else if (response.statusCode == 400) {
        // Konflik absensi atau kode tidak valid
        throw AbsensiException(
          body['message'] ?? 'Gagal melakukan presensi',
          statusCode: 400,
        );
      } else if (response.statusCode == 403) {
        // Tidak terdaftar di kelas
        throw AbsensiException(
          body['message'] ?? 'Akses ditolak',
          statusCode: 403,
        );
      } else {
        throw AbsensiException(
          body['message'] ?? 'Gagal melakukan presensi',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw AbsensiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on FormatException {
      throw AbsensiException('Format data tidak valid dari server.');
    } catch (e) {
      if (e is AbsensiException) rethrow;
      throw AbsensiException('Terjadi kesalahan: ${e.toString()}');
    }
  }

  /// Membuat pengajuan absensi (izin/sakit) dengan kemungkinan lampiran.
  ///
  /// **Endpoint**: `POST /absensi/pengajuan` (Multipart Form Data)
  ///
  /// **Request Fields**:
  /// - `tanggal`: "YYYY-MM-DD" (string)
  /// - `keterangan`: "izin" atau "sakit" (string)
  /// - `alasan`: "Alasan lengkap" (string)
  /// - `jadwalIds`: JSON string array dari ID jadwal, contoh: '["id1", "id2"]'
  /// - `fileBukti`: File (opsional)
  ///
  /// **Success Response (201)**:
  /// ```json
  /// {
  ///   "message": "Pengajuan berhasil dikirim.",
  ///   "data": { ... }
  /// }
  /// ```
  Future<String> createPengajuan({
    required String tanggal,
    required String keterangan,
    required String alasan,
    required List<String> jadwalIds,
    File? fileBukti,
  }) async {
    try {
      final token = await _getToken();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/absensi/pengajuan'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['tanggal'] = tanggal;
      request.fields['keterangan'] = keterangan;
      request.fields['alasan'] = alasan;
      request.fields['jadwalIds'] = jsonEncode(jadwalIds);

      if (fileBukti != null) {
        request.files.add(
          await http.MultipartFile.fromPath('fileBukti', fileBukti.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return body['message'] ?? 'Pengajuan berhasil dikirim';
      } else if (response.statusCode == 400) {
        throw AbsensiException(
          body['message'] ?? 'Data pengajuan tidak valid',
          statusCode: 400,
        );
      } else {
        throw AbsensiException(
          body['message'] ?? 'Gagal membuat pengajuan',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw AbsensiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } catch (e) {
      if (e is AbsensiException) rethrow;
      throw AbsensiException('Terjadi kesalahan: ${e.toString()}');
    }
  }

  /// Mengambil riwayat pengajuan absensi milik pengguna yang sedang login.
  ///
  /// **Endpoint**: `GET /absensi/pengajuan/riwayat-saya`
  ///
  /// **Success Response (200)**: `List<PengajuanAbsensi>`
  Future<List<PengajuanAbsensi>> getRiwayatPengajuan() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/absensi/pengajuan/riwayat-saya'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PengajuanAbsensi.fromJson(json)).toList();
      } else {
        final body = jsonDecode(response.body);
        throw AbsensiException(
          body['message'] ?? 'Gagal memuat riwayat pengajuan',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw AbsensiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } catch (e) {
      if (e is AbsensiException) rethrow;
      throw AbsensiException('Terjadi kesalahan: ${e.toString()}');
    }
  }

  /// Mengambil riwayat presensi milik siswa yang sedang login.
  ///
  /// **Endpoint**: `GET /siswa/presensi?page=<num>&limit=<num>`
  ///
  /// **Success Response (200)**: Objek Paginasi dengan `docs` berisi `List<Absensi>`
  ///
  /// **Returns**: Tuple (List<Absensi>, totalPages, currentPage)
  Future<AbsensiPaginatedResponse> getRiwayatPresensi({
    int page = 1,
    int limit = 15,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/siswa/presensi?page=$page&limit=$limit'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> docs = body['docs'] ?? [];
        final List<Absensi> absensiList = docs
            .map((json) => Absensi.fromJson(json))
            .toList();

        return AbsensiPaginatedResponse(
          docs: absensiList,
          totalDocs: body['totalDocs'] ?? 0,
          limit: body['limit'] ?? limit,
          totalPages: body['totalPages'] ?? 1,
          page: body['page'] ?? page,
          hasNextPage: body['hasNextPage'] ?? false,
          hasPrevPage: body['hasPrevPage'] ?? false,
        );
      } else {
        final body = jsonDecode(response.body);
        throw AbsensiException(
          body['message'] ?? 'Gagal memuat riwayat presensi',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw AbsensiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } catch (e) {
      if (e is AbsensiException) rethrow;
      throw AbsensiException('Terjadi kesalahan: ${e.toString()}');
    }
  }

  /// Helper: Get simple list for backward compatibility
  Future<List<Absensi>> getRiwayatPresensiList({
    int page = 1,
    int limit = 15,
  }) async {
    final response = await getRiwayatPresensi(page: page, limit: limit);
    return response.docs;
  }
}

// Custom exception untuk error handling yang lebih baik
class AbsensiException implements Exception {
  final String message;
  final int? statusCode;

  AbsensiException(this.message, {this.statusCode});

  @override
  String toString() => message;

  // Helper untuk UI
  bool get isNetworkError => statusCode == null;
  bool get isValidationError => statusCode == 400;
  bool get isAuthError => statusCode == 401;
  bool get isForbiddenError => statusCode == 403;
  bool get isNotFoundError => statusCode == 404;
  bool get isServerError => statusCode != null && statusCode! >= 500;
}

// Model untuk paginated response
class AbsensiPaginatedResponse {
  final List<Absensi> docs;
  final int totalDocs;
  final int limit;
  final int totalPages;
  final int page;
  final bool hasNextPage;
  final bool hasPrevPage;

  AbsensiPaginatedResponse({
    required this.docs,
    required this.totalDocs,
    required this.limit,
    required this.totalPages,
    required this.page,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  // Helpers
  int get nextPage => hasNextPage ? page + 1 : page;
  int get prevPage => hasPrevPage ? page - 1 : page;
  bool get isEmpty => docs.isEmpty;
  int get itemCount => docs.length;
}
