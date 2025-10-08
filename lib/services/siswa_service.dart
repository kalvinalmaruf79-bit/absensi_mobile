import 'api_service.dart';
import '../models/jadwal.dart';
import '../models/tugas.dart';
import '../models/nilai.dart';
import '../models/notifikasi.dart';
import '../models/histori_aktivitas.dart';

class SiswaService {
  final ApiService _apiService = ApiService();

  // Dashboard
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      return await _apiService.get('siswa/dashboard');
    } catch (e) {
      throw Exception('Gagal memuat data dashboard: $e');
    }
  }

  // Jadwal
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

  // Tugas
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

  // Nilai
  Future<List<Nilai>> getNilaiSiswa(String tahunAjaran, String semester) async {
    try {
      final response = await _apiService.get(
        'siswa/nilai?tahunAjaran=$tahunAjaran&semester=$semester',
      );
      // Mengambil dari 'docs' karena backend menggunakan pagination
      final List<dynamic> data = response['docs'];
      return data.map((json) => Nilai.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal memuat nilai: $e');
    }
  }

  // Teman Sekelas
  Future<List<Map<String, dynamic>>> getTemanSekelas() async {
    try {
      final response = await _apiService.get('siswa/teman-sekelas');
      final List<dynamic> data = response;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Gagal memuat teman sekelas: $e');
    }
  }

  // Notifikasi
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

  Future<String> markNotifikasiAsRead(String notifikasiId) async {
    try {
      final response = await _apiService.patch(
        'siswa/notifikasi/$notifikasiId/read',
        {},
      );
      return response['message'];
    } catch (e) {
      throw Exception('Gagal menandai notifikasi: $e');
    }
  }

  // Histori Aktivitas
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
}
