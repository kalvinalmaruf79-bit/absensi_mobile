// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/user.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  /// Mengotentikasi pengguna dan menyimpan token.
  ///
  /// **Endpoint**: `POST /auth/login`
  Future<User> login(String identifier, String password) async {
    try {
      final response = await _apiService.postLogin('auth/login', {
        'identifier': identifier,
        'password': password,
      });

      if (response['token'] != null && response['user'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response['token']);
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

  /// Mengirim permintaan kode verifikasi reset password ke email pengguna.
  ///
  /// **Endpoint**: `POST /auth/forgot-password`
  ///
  /// **Request Body**:
  /// ```json
  /// {
  ///   "email": "<Email Pengguna>"
  /// }
  /// ```
  ///
  /// **Success Response (200)**:
  /// ```json
  /// {
  ///   "message": "Kode verifikasi telah berhasil dikirim ke email Anda."
  /// }
  /// ```
  Future<String> forgotPassword(String email) async {
    try {
      final response = await _apiService.postLogin('auth/forgot-password', {
        'email': email,
      });
      return response['message'] ??
          'Kode verifikasi telah dikirim ke email Anda.';
    } catch (e) {
      throw Exception('Gagal mengirim kode verifikasi: $e');
    }
  }

  /// Memverifikasi kode reset password 6 digit.
  ///
  /// **Endpoint**: `POST /auth/verify-reset-code`
  ///
  /// **Request Body**:
  /// ```json
  /// {
  ///   "code": "<Kode 6 Digit>"
  /// }
  /// ```
  ///
  /// **Success Response (200)**:
  /// ```json
  /// {
  ///   "message": "Kode verifikasi valid.",
  ///   "tempToken": "<Temporary Token>"
  /// }
  /// ```
  ///
  /// **Error Response (400)**:
  /// ```json
  /// {
  ///   "message": "Kode verifikasi tidak valid atau sudah kedaluwarsa."
  /// }
  /// ```
  Future<String> verifyResetCode(String code) async {
    try {
      final response = await _apiService.postLogin('auth/verify-reset-code', {
        'code': code,
      });

      if (response['tempToken'] != null) {
        return response['tempToken'];
      } else {
        throw Exception('Token tidak diterima dari server.');
      }
    } catch (e) {
      throw Exception('Kode tidak valid atau sudah kedaluwarsa: $e');
    }
  }

  /// Mereset password pengguna menggunakan temporary token.
  ///
  /// **Endpoint**: `POST /auth/reset-password`
  ///
  /// **Request Body**:
  /// ```json
  /// {
  ///   "tempToken": "<Temporary Token>",
  ///   "password": "<Password Baru>"
  /// }
  /// ```
  ///
  /// **Success Response (200)**:
  /// ```json
  /// {
  ///   "message": "Password berhasil direset."
  /// }
  /// ```
  Future<String> resetPassword(String tempToken, String newPassword) async {
    try {
      final response = await _apiService.postLogin('auth/reset-password', {
        'tempToken': tempToken,
        'password': newPassword,
      });
      return response['message'] ?? 'Password berhasil direset.';
    } catch (e) {
      throw Exception('Gagal mereset password: $e');
    }
  }
}
