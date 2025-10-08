import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/user.dart';

class AuthService {
  final ApiService _apiService = ApiService();

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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('userName');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  Future<User> getProfile() async {
    try {
      final response = await _apiService.get('auth/profile');
      return User.fromJson(response);
    } catch (e) {
      throw Exception('Gagal mengambil profil: $e');
    }
  }

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
