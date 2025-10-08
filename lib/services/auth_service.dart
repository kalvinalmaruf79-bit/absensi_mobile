import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/user.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  /// Mengotentikasi pengguna dan menyimpan token.
  ///
  /// **Endpoint**: `POST /auth/login`
  ///
  /// **Request Body**:
  /// ```json
  /// {
  ///   "identifier": "<NIS atau NIP>",
  ///   "password": "<Password Pengguna>"
  /// }
  /// ```
  ///
  /// **Success Response (200)**:
  /// ```json
  /// {
  ///   "message": "Login berhasil",
  ///   "token": "<JWT Token>",
  ///   "user": {
  ///     "_id": "string",
  ///     "name": "string",
  ///     "email": "string",
  ///     "identifier": "string",
  ///     "role": "string ('siswa' atau 'guru')",
  ///     "isWaliKelas": boolean
  ///   }
  /// }
  /// ```
  ///
  /// **Error Response (400/500)**:
  /// ```json
  /// {
  ///   "message": "Pesan error spesifik"
  /// }
  /// ```
  Future<User> login(String identifier, String password) async {
    try {
      final response = await _apiService.postLogin('auth/login', {
        'identifier': identifier,
        'password': password,
      });

      if (response['token'] != null && response['user'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response['token']);

        // Simpan data user sederhana jika perlu
        await prefs.setString('userId', response['user']['_id']);
        await prefs.setString('userName', response['user']['name']);

        return User.fromJson(response['user']);
      } else {
        throw Exception('Login gagal: data tidak lengkap.');
      }
    } catch (e) {
      throw Exception('Login Gagal: $e');
    }
  }

  /// Menghapus token dan data pengguna dari SharedPreferences.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('userName');
  }

  /// Memeriksa apakah token pengguna ada di SharedPreferences.
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  /// Mengambil data profil pengguna yang sedang login.
  ///
  /// **Endpoint**: `GET /auth/profile`
  ///
  /// **Success Response (200)**:
  /// ```json
  /// {
  ///   "_id": "string",
  ///   "name": "string",
  ///   "email": "string",
  ///   "identifier": "string",
  ///   "role": "string",
  ///   "isWaliKelas": boolean,
  ///   "kelas": { "_id": "string", "nama": "string", ... }, // jika siswa
  ///   "mataPelajaran": [ { "_id": "string", "nama": "string", ... } ] // jika guru
  /// }
  /// ```
  ///
  /// **Error Response (404/500)**:
  /// ```json
  /// {
  ///   "message": "User tidak ditemukan"
  /// }
  /// ```
  Future<User> getProfile() async {
    try {
      final response = await _apiService.get('auth/profile');
      return User.fromJson(response);
    } catch (e) {
      throw Exception('Gagal mengambil profil: $e');
    }
  }

  /// Mengubah password pengguna yang sedang login.
  ///
  /// **Endpoint**: `PUT /auth/change-password`
  ///
  /// **Request Body**:
  /// ```json
  /// {
  ///   "oldPassword": "<Password Lama>",
  ///   "newPassword": "<Password Baru>"
  /// }
  /// ```
  ///
  /// **Success Response (200)**:
  /// ```json
  /// {
  ///   "message": "Password berhasil diganti"
  /// }
  /// ```
  ///
  /// **Error Response (400/500)**:
  /// ```json
  /// {
  ///   "message": "Password lama salah"
  /// }
  /// ```
  Future<String> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await _apiService.put('auth/change-password', {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
      return response['message'];
    } catch (e) {
      throw Exception('Gagal mengubah password: $e');
    }
  }
}
