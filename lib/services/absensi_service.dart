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

  /// Mengirim data check-in presensi berdasarkan kode sesi QR.
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
  /// **Error Response (400/403/500)**:
  /// ```json
  /// {
  ///   "message": "Pesan error spesifik (misal: kode tidak valid, di luar radius, dll)"
  /// }
  /// ```
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
      if (response.statusCode == 200) {
        return body['message'];
      } else {
        throw Exception(body['message'] ?? 'Gagal melakukan presensi');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
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
  ///   "data": { ... } // Objek pengajuan yang baru dibuat
  /// }
  /// ```
  ///
  /// **Error Response (400/500)**:
  /// ```json
  /// {
  ///   "message": "Pesan error spesifik"
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
        return body['message'];
      } else {
        throw Exception(body['message'] ?? 'Gagal membuat pengajuan');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  /// Mengambil riwayat pengajuan absensi milik pengguna yang sedang login.
  ///
  /// **Endpoint**: `GET /absensi/pengajuan/riwayat-saya`
  ///
  /// **Success Response (200)**: `List<PengajuanAbsensi>`
  /// ```json
  /// [
  ///   {
  ///     "_id": "string",
  ///     "tanggal": "YYYY-MM-DD",
  ///     "keterangan": "string",
  ///     "alasan": "string",
  ///     "status": "string ('pending', 'disetujui', 'ditolak')",
  ///     "jadwalTerkait": [ ... ],
  ///     "fileBukti": { "url": "string", "public_id": "string" },
  ///     "ditinjauOleh": { "name": "string" }
  ///   }
  /// ]
  /// ```
  ///
  /// **Error Response (500)**:
  /// ```json
  /// {
  ///   "message": "Gagal mengambil riwayat pengajuan."
  /// }
  /// ```
  Future<List<PengajuanAbsensi>> getRiwayatPengajuan() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/absensi/pengajuan/riwayat-saya'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final List<dynamic> data = body;
        return data.map((json) => PengajuanAbsensi.fromJson(json)).toList();
      } else {
        throw Exception(body['message'] ?? 'Gagal memuat riwayat');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  /// Mengambil riwayat presensi milik siswa yang sedang login.
  ///
  /// **Endpoint**: `GET /siswa/presensi?page=<num>&limit=<num>`
  ///
  /// **Success Response (200)**: Objek Paginasi
  /// ```json
  /// {
  ///   "docs": [
  ///     {
  ///       "_id": "string",
  ///       "keterangan": "string ('hadir', 'sakit', 'izin', 'alpa')",
  ///       "waktuMasuk": "ISO_Date_String | null",
  ///       "tanggal": "YYYY-MM-DD",
  ///       "jadwal": { ... } // Objek jadwal
  ///     }
  ///   ],
  ///   "totalDocs": int,
  ///   "limit": int,
  ///   "totalPages": int,
  ///   "page": int,
  ///   ...
  /// }
  /// ```
  ///
  /// **Error Response (500)**:
  /// ```json
  /// {
  ///   "message": "Gagal memuat riwayat presensi"
  /// }
  /// ```
  Future<List<Absensi>> getRiwayatPresensi({
    int page = 1,
    int limit = 15,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        // Endpoint ini ada di siswaController, bukan absensiController
        Uri.parse('$_baseUrl/siswa/presensi?page=$page&limit=$limit'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final List<dynamic> data = body['docs'];
        return data.map((json) => Absensi.fromJson(json)).toList();
      } else {
        throw Exception(body['message'] ?? 'Gagal memuat riwayat presensi');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }
}
