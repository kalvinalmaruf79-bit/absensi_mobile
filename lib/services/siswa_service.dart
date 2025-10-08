import 'api_service.dart';
import '../models/jadwal.dart';
import '../models/tugas.dart';
import '../models/nilai.dart';
import '../models/notifikasi.dart';
import '../models/histori_aktivitas.dart';

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
      // Mengambil dari 'docs' karena backend menggunakan pagination
      final List<dynamic> data = response['docs'];
      return data.map((json) => Nilai.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal memuat nilai: $e');
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
}
