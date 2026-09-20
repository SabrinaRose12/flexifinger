// lib/services/api_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://bijakmahir.com/flexi/flexifinger/mobile/api';

  static String? _token;
  static Map<String, dynamic>? _cachedUser;

  // Initialize - load token from storage on app start
  static Future<void> init() async {
    await loadToken();
  }

  // Load token from SharedPreferences
  static Future<void> loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      if (_token != null && _token!.isNotEmpty) {
        print('🔑 Token loaded from storage: ${_token!.substring(0, min(50, _token!.length))}...');
      } else {
        print('⚠️ No token found in storage');
      }
    } catch (e) {
      print('❌ Failed to load token: $e');
    }
  }

  // Save token to SharedPreferences
  static Future<void> _saveTokenToStorage(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('💾 Token saved to storage');
    } catch (e) {
      print('❌ Failed to save token: $e');
    }
  }

  // Remove token from SharedPreferences
  static Future<void> _removeTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      print('🗑️ Token removed from storage');
    } catch (e) {
      print('❌ Failed to remove token: $e');
    }
  }

  static void setToken(String token) {
    _token = token;
    _saveTokenToStorage(token);
    print('🔑 Token saved');
  }

  static Future<void> clearToken() async {
    _token = null;
    _cachedUser = null;
    await _removeTokenFromStorage();
    print('🗑️ Token cleared');
  }

  static void setCachedUser(Map<String, dynamic> user) {
    _cachedUser = user;
    print('👤 User cached: ${user['full_name'] ?? user['email']}');
  }

  static Map<String, dynamic>? getCachedUser() => _cachedUser;

  // Helper function for min
  static int min(int a, int b) => a < b ? a : b;

  static Future<Map<String, String>> _getHeaders() async {
    // Ensure token is loaded
    if (_token == null) {
      await loadToken();
    }

    print('🔑 Current token exists: ${_token != null}');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
      String tokenPreview = _token!;
      if (tokenPreview.length > 50) {
        tokenPreview = tokenPreview.substring(0, 50) + '...';
      }
      print('🔑 Using token: $tokenPreview');
    } else {
      print('❌ NO TOKEN FOUND!');
    }
    return headers;
  }

  // POST with timeout and auto-retry on 401
  static Future<Map<String, dynamic>> post(
      String endpoint,
      Map<String, dynamic> body, {
        Duration timeout = const Duration(seconds: 15),
        int retryCount = 0,
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

      // Handle 401 Unauthorized - try to refresh token
      if (response.statusCode == 401 && retryCount == 0) {
        print('🔄 401 Unauthorized, attempting to refresh token...');
        final refreshed = await _refreshToken();
        if (refreshed) {
          print('✅ Token refreshed, retrying request...');
          return await post(endpoint, body, retryCount: retryCount + 1);
        }
      }

      return _handleResponse(response);
    } on TimeoutException {
      print('⏰ Timeout: $endpoint');
      return {'success': false, 'message': 'Connection timeout. Please try again.'};
    } catch (e) {
      print('❌ POST Error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // GET with timeout and auto-retry on 401
  static Future<Map<String, dynamic>> get(
      String endpoint, {
        Duration timeout = const Duration(seconds: 15),
        int retryCount = 0,
      }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();
      print('📤 GET $url');
      print('📤 Headers: $headers');

      final response = await http.get(url, headers: headers).timeout(timeout);

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      // Handle 401 Unauthorized - try to refresh token
      if (response.statusCode == 401 && retryCount == 0) {
        print('🔄 401 Unauthorized, attempting to refresh token...');
        final refreshed = await _refreshToken();
        if (refreshed) {
          print('✅ Token refreshed, retrying request...');
          return await get(endpoint, retryCount: retryCount + 1);
        }
      }

      return _handleResponse(response);
    } on TimeoutException {
      print('⏰ Timeout: $endpoint');
      return {'success': false, 'message': 'Connection timeout. Please try again.'};
    } catch (e) {
      print('❌ GET Error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Refresh token endpoint
  static Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null) {
        print('❌ No refresh token available');
        return false;
      }

      final url = Uri.parse('$baseUrl/refresh_token.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data']['token'] != null) {
          _token = data['data']['token'];
          await _saveTokenToStorage(_token!);

          // Save new refresh token if provided
          if (data['data']['refresh_token'] != null) {
            await prefs.setString('refresh_token', data['data']['refresh_token']);
          }

          return true;
        }
      }
      return false;
    } catch (e) {
      print('❌ Token refresh failed: $e');
      return false;
    }
  }

  // PUT with timeout
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

  // DELETE with timeout
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

    // Handle 401 Unauthorized
    if (response.statusCode == 401) {
      return {
        'success': false,
        'message': 'Unauthorized',
        'unauthorized': true
      };
    }

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

  // Helper method to check if response is successful
  static bool isSuccessful(Map<String, dynamic> response) {
    return response['success'] == true;
  }

  // Helper method to get error message
  static String getErrorMessage(Map<String, dynamic> response) {
    return response['message'] ?? 'Unknown error occurred';
  }

  // Helper method to get data safely
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