import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_constants.dart';

class ApiService {
  final String _baseUrl = AppConstants.baseUrl;

  // Fungsi untuk mendapatkan token dari SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Fungsi helper untuk membuat header dengan token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // Metode GET
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: await _getHeaders(),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  // Metode POST
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  // Metode POST khusus untuk login (tanpa token)
  Future<dynamic> postLogin(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(data),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  // Metode PUT
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  // Metode PATCH
  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  // Memproses respons dari server
  dynamic _processResponse(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      throw Exception(body['message'] ?? 'Terjadi kesalahan');
    }
  }
}
