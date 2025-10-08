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

  // Check-in menggunakan QR Code
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

  // Membuat pengajuan izin/sakit (dengan upload file)
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

  // Melihat riwayat pengajuan izin/sakit
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

  // Riwayat presensi (sudah ada di siswa_service, tapi bisa juga ditaruh sini)
  Future<List<Absensi>> getRiwayatPresensi({
    int page = 1,
    int limit = 15,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/siswa/presensi?page=$page&limit=$limit'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final List<dynamic> data = body['docs']; // Perbaikan paginasi
        return data.map((json) => Absensi.fromJson(json)).toList();
      } else {
        throw Exception(body['message'] ?? 'Gagal memuat riwayat presensi');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }
}
