// lib/services/api_service.dart
import 'dart:convert';
import 'package:absensi_mobile/utils/app_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Base URL API Backend
  static const String baseUrl = AppConstants.baseUrl;

  /// Method untuk mendapatkan token dari SharedPreferences (PUBLIC)
  /// Digunakan oleh service lain untuk multipart request
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Method PRIVATE untuk mendapatkan token (backward compatibility)
  Future<String?> _getToken() async {
    return await getToken();
  }

  /// Method untuk membuat header dengan token
  Future<Map<String, String>> _getHeaders({bool needsAuth = true}) async {
    Map<String, String> headers = {'Content-Type': 'application/json'};

    if (needsAuth) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// POST request khusus untuk login (tanpa token)
  Future<dynamic> postLogin(String endpoint, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      print('POST Request to: $url');
      print('Request Body: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('POST Login Error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      final headers = await _getHeaders();

      print('GET Request to: $url');
      print('Headers: $headers');

      final response = await http.get(url, headers: headers);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('GET Error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// POST request (dengan token)
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      final headers = await _getHeaders();

      print('POST Request to: $url');
      print('Headers: $headers');
      print('Request Body: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('POST Error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// PUT request
  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      final headers = await _getHeaders();

      print('PUT Request to: $url');
      print('Headers: $headers');
      print('Request Body: ${jsonEncode(body)}');

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('PUT Error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// DELETE request
  Future<dynamic> delete(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      final headers = await _getHeaders();

      print('DELETE Request to: $url');
      print('Headers: $headers');

      final response = await http.delete(url, headers: headers);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('DELETE Error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// PATCH request
  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      final headers = await _getHeaders();

      print('PATCH Request to: $url');
      print('Headers: $headers');
      print('Request Body: ${jsonEncode(body)}');

      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('PATCH Error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Method untuk handle response dari API
  dynamic _handleResponse(http.Response response) {
    print('Handling response with status: ${response.statusCode}');

    switch (response.statusCode) {
      case 200:
      case 201:
        // Success
        try {
          return jsonDecode(response.body);
        } catch (e) {
          print('JSON Decode Error: $e');
          throw Exception('Invalid response format');
        }

      case 400:
        // Bad Request
        final errorBody = _parseErrorBody(response.body);
        throw Exception(errorBody ?? 'Bad request');

      case 401:
        // Unauthorized - Token invalid atau expired
        final errorBody = _parseErrorBody(response.body);
        throw Exception('401: ${errorBody ?? 'Unauthorized - Token invalid'}');

      case 403:
        // Forbidden
        final errorBody = _parseErrorBody(response.body);
        throw Exception(errorBody ?? 'Access forbidden');

      case 404:
        // Not Found
        final errorBody = _parseErrorBody(response.body);
        throw Exception(errorBody ?? 'Resource not found');

      case 500:
        // Internal Server Error
        final errorBody = _parseErrorBody(response.body);
        throw Exception(errorBody ?? 'Server error');

      default:
        final errorBody = _parseErrorBody(response.body);
        throw Exception(
          errorBody ?? 'Unexpected error: ${response.statusCode}',
        );
    }
  }

  /// Helper method untuk parse error message dari response body
  String? _parseErrorBody(String body) {
    try {
      final json = jsonDecode(body);
      return json['message'] ?? json['error'];
    } catch (e) {
      return body.isNotEmpty ? body : null;
    }
  }
}
