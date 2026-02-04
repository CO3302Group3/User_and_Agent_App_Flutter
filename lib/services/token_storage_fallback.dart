import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class TokenStorageFallback {
  // In-memory storage as fallback
  static String? _token;
  static String? _userId;
  static String? _email;
  static bool _useMemoryStorage = false;

  // Test if SharedPreferences is working
  static Future<bool> _testSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('test_key', 'test_value');
      final value = prefs.getString('test_key');
      await prefs.remove('test_key');
      return value == 'test_value';
    } catch (e) {
      print('SharedPreferences test failed: $e');
      return false;
    }
  }

  // Initialize storage method
  static Future<void> init() async {
    final isWorking = await _testSharedPreferences();
    _useMemoryStorage = !isWorking;
    if (_useMemoryStorage) {
      print('WARNING: Using in-memory storage. Data will not persist between app sessions.');
    }
  }

  // Save token
  static Future<void> saveToken(String token) async {
    if (_useMemoryStorage) {
      _token = token;
      print('Token saved to memory storage');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      print('Token saved to SharedPreferences');
    } catch (e) {
      print('Error saving to SharedPreferences, using memory: $e');
      _token = token;
      _useMemoryStorage = true;
    }
  }

  // Get token
  static Future<String?> getToken() async {
    if (_useMemoryStorage) {
      return _token;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('jwt_token');
    } catch (e) {
      print('Error getting from SharedPreferences, using memory: $e');
      _useMemoryStorage = true;
      return _token;
    }
  }

  // Save user info
  static Future<void> saveUserInfo({String? userId, String? email, String? username}) async {
    if (_useMemoryStorage) {
      if (userId != null) _userId = userId;
      if (email != null) _email = email;
       // We can store username in a static var if needed, but for now let's just use prefs for simplicity or add a var
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) await prefs.setString('user_id', userId);
      if (email != null) await prefs.setString('user_email', email);
      if (username != null) await prefs.setString('user_name', username);
    } catch (e) {
      print('Error saving user info: $e');
      _useMemoryStorage = true;
    }
  }

  // Get user info
  static Future<Map<String, String?>> getUserInfo() async {
    if (_useMemoryStorage) {
      return {
        'userId': _userId,
        'email': _email,
        'username': null, // In-memory fallback incomplete for username for now, prioritizing prefs
      };
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'userId': prefs.getString('user_id'),
        'email': prefs.getString('user_email'),
        'username': prefs.getString('user_name'),
      };
    } catch (e) {
      return {
        'userId': _userId,
        'email': _email,
        'username': null,
      };
    }
  }

  // Check if logged in
  static Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Clear all data
  static Future<void> clearAll() async {
    if (_useMemoryStorage) {
      _token = null;
      _userId = null;
      _email = null;
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      await prefs.remove('user_id');
      await prefs.remove('user_email');
    } catch (e) {
      print('Error clearing SharedPreferences, using memory: $e');
      _token = null;
      _userId = null;
      _email = null;
      _useMemoryStorage = true;
    }
  }

  // Get auth headers
  static Future<Map<String, String>?> getAuthHeaders() async {
    try {
      final token = await getToken();
      if (token != null) {
        return {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        };
      }
      return null;
    } catch (e) {
      print('Error getting auth headers: $e');
      return null;
    }
  }
}
