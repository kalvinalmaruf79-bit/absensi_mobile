// lib/services/common_service.dart
import 'api_service.dart';

class CommonService {
  final ApiService _apiService = ApiService();

  /// Mengambil pengaturan global (tahun ajaran dan semester aktif).
  ///
  /// **Endpoint**: `GET /common/settings`
  ///
  /// **Success Response (200)**:
  /// ```json
  /// {
  ///   "tahunAjaranAktif": "string",
  ///   "semesterAktif": "string"
  /// }
  /// ```
  Future<Map<String, dynamic>> getGlobalSettings() async {
    try {
      return await _apiService.get('common/settings');
    } catch (e) {
      throw Exception('Gagal mengambil pengaturan global: $e');
    }
  }

  /// Mengambil riwayat akademik siswa (daftar tahun ajaran dan semester).
  ///
  /// **Endpoint**: `GET /common/academic-history`
  ///
  /// **Success Response (200)**:
  /// ```json
  /// [
  ///   {
  ///     "tahunAjaran": "string",
  ///     "semester": "string"
  ///   }
  /// ]
  /// ```
  Future<List<Map<String, dynamic>>> getSiswaAcademicHistory() async {
    try {
      final response = await _apiService.get('common/academic-history');
      final List<dynamic> data = response;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Gagal mengambil riwayat akademik: $e');
    }
  }
}
