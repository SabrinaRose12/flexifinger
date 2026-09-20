// lib/services/api_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';  // TAMBAHKAN IMPORT INI

class ApiService {
  static const String baseUrl = 'https://bijakmahir.com/flexi/flexifinger/mobile/api';

  static String? _token;
  static Map<String, dynamic>? _cachedUser;

  static void setToken(String token) {
    _token = token;
    print('🔑 Token saved');
    // Optional: Save to SharedPreferences for persistence
    _saveTokenToPrefs(token);
  }

  static Future<void> _saveTokenToPrefs(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('💾 Token saved to SharedPreferences');
    } catch (e) {
      print('❌ Failed to save token: $e');
    }
  }

  static Future<void> clearToken() async {
    _token = null;
    _cachedUser = null;
    print('🗑️ Token cleared');

    // Clear from SharedPreferences as well
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      print('💾 Token removed from SharedPreferences');
    } catch (e) {
      print('❌ Failed to clear token: $e');
    }
  }

  // Load token from SharedPreferences on app start
  static Future<void> loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      if (_token != null) {
        print('🔑 Token loaded from SharedPreferences');
      }
    } catch (e) {
      print('❌ Failed to load token: $e');
    }
  }

  static void setCachedUser(Map<String, dynamic> user) {
    _cachedUser = user;
    print('👤 User cached: ${user['full_name'] ?? user['email']}');
  }

  static Map<String, dynamic>? getCachedUser() => _cachedUser;

  static Future<Map<String, String>> _getHeaders() async {
    // Make sure token is loaded
    if (_token == null) {
      await loadToken();
    }

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // POST dengan timeout optional
  static Future<Map<String, dynamic>> post(
      String endpoint,
      Map<String, dynamic> body, {
        Duration timeout = const Duration(seconds: 15),
      }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();
      print('📤 POST $url');
      print('📤 Body: ${jsonEncode(body)}');

      final response = await http
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(timeout);

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');
      return _handleResponse(response);
    } on TimeoutException {
      print('⏰ Timeout: $endpoint');
      return {'success': false, 'message': 'Connection timeout. Please try again.'};
    } catch (e) {
      print('❌ POST Error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // GET dengan timeout optional
  static Future<Map<String, dynamic>> get(
      String endpoint, {
        Duration timeout = const Duration(seconds: 15),
      }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();
      print('📤 GET $url');
      print('📤 Headers: $headers');

      final response = await http.get(url, headers: headers).timeout(timeout);

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');
      return _handleResponse(response);
    } on TimeoutException {
      print('⏰ Timeout: $endpoint');
      return {'success': false, 'message': 'Connection timeout. Please try again.'};
    } catch (e) {
      print('❌ GET Error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // PUT dengan timeout optional
  static Future<Map<String, dynamic>> put(
      String endpoint,
      Map<String, dynamic> body, {
        Duration timeout = const Duration(seconds: 15),
      }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();
      print('📤 PUT $url');
      print('📤 Body: ${jsonEncode(body)}');

      final response = await http
          .put(url, headers: headers, body: jsonEncode(body))
          .timeout(timeout);

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');
      return _handleResponse(response);
    } on TimeoutException {
      print('⏰ Timeout: $endpoint');
      return {'success': false, 'message': 'Connection timeout. Please try again.'};
    } catch (e) {
      print('❌ PUT Error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // DELETE dengan timeout optional
  static Future<Map<String, dynamic>> delete(
      String endpoint, {
        Duration timeout = const Duration(seconds: 15),
      }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();
      print('📤 DELETE $url');

      final response = await http.delete(url, headers: headers).timeout(timeout);

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');
      return _handleResponse(response);
    } on TimeoutException {
      print('⏰ Timeout: $endpoint');
      return {'success': false, 'message': 'Connection timeout. Please try again.'};
    } catch (e) {
      print('❌ DELETE Error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    print('🔍 Processing response - Status: ${response.statusCode}');

    // Handle empty response
    if (response.body.isEmpty) {
      print('⚠️ Empty response body');
      return {
        'success': false,
        'message': 'Empty response from server (Status: ${response.statusCode})'
      };
    }

    try {
      final decoded = jsonDecode(response.body);
      print('✅ Decoded JSON: $decoded');

      if (decoded is Map) {
        final result = Map<String, dynamic>.from(decoded);

        // If response doesn't have 'success' key, add based on HTTP status
        if (!result.containsKey('success')) {
          result['success'] = response.statusCode == 200;
        }

        return result;
      }

      // If response is a List
      if (decoded is List) {
        return {
          'success': true,
          'data': {'items': decoded}
        };
      }

      // If response is something else (string, number, etc.)
      return {
        'success': true,
        'data': {'value': decoded}
      };

    } on FormatException catch (e) {
      print('❌ JSON Parse Error: $e');
      print('❌ Raw body: ${response.body}');

      // Check if it's HTML (PHP error)
      if (response.body.contains('<!DOCTYPE') || response.body.contains('<html')) {
        return {
          'success': false,
          'message': 'Server returned HTML instead of JSON. Possible PHP error.'
        };
      }

      return {
        'success': false,
        'message': 'Invalid JSON response: ${e.message}',
        'raw_response': response.body.length > 200
            ? response.body.substring(0, 200) + '...'
            : response.body
      };
    } catch (e) {
      print('❌ Unexpected error parsing response: $e');
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}'
      };
    }
  }

  // Helper method untuk check if response is successful
  static bool isSuccessful(Map<String, dynamic> response) {
    return response['success'] == true;
  }

  // Helper method untuk get error message
  static String getErrorMessage(Map<String, dynamic> response) {
    return response['message'] ?? 'Unknown error occurred';
  }

  // Helper method untuk get data safely
  static dynamic getData(Map<String, dynamic> response, [String? key]) {
    if (!isSuccessful(response)) return null;

    final data = response['data'];
    if (data == null || data is! Map) return data;

    if (key != null) {
      return data[key];
    }

    return data;
  }
}