import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class TokenService {
  static const String _tokenKey = 'jwt_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

  // Save JWT token to SharedPreferences
  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      print('Error saving token: $e');
      if (e is PlatformException) {
        print('Platform exception: ${e.message}');
        print('Code: ${e.code}');
      }
      rethrow;
    }
  }

  // Get JWT token from SharedPreferences
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Error getting token: $e');
      if (e is PlatformException) {
        print('Platform exception: ${e.message}');
        print('Code: ${e.code}');
      }
      return null;
    }
  }

  // Check if user is logged in (has valid token)
  static Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Save user information
  static Future<void> saveUserInfo({String? userId, String? email}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        await prefs.setString(_userIdKey, userId);
      }
      if (email != null) {
        await prefs.setString(_userEmailKey, email);
      }
    } catch (e) {
      print('Error saving user info: $e');
      if (e is PlatformException) {
        print('Platform exception: ${e.message}');
        print('Code: ${e.code}');
      }
      rethrow;
    }
  }

  // Get user information
  static Future<Map<String, String?>> getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'userId': prefs.getString(_userIdKey),
        'email': prefs.getString(_userEmailKey),
      };
    } catch (e) {
      print('Error getting user info: $e');
      return {
        'userId': null,
        'email': null,
      };
    }
  }

  // Clear all stored data (logout)
  static Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userEmailKey);
    } catch (e) {
      print('Error clearing token: $e');
      if (e is PlatformException) {
        print('Platform exception: ${e.message}');
        print('Code: ${e.code}');
      }
      rethrow;
    }
  }

  // Get authorization header with token
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
