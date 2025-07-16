import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_service.dart';
import 'configurations.dart';

class AuthService {
  // Make authenticated HTTP GET request
  static Future<http.Response?> authenticatedGet(String endpoint) async {
    try {
      final headers = await TokenService.getAuthHeaders();
      if (headers == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('http://${AppConfig.baseURL}$endpoint'),
        headers: headers,
      );

      return response;
    } catch (e) {
      print('Error in authenticated GET request: $e');
      return null;
    }
  }

  // Make authenticated HTTP POST request
  static Future<http.Response?> authenticatedPost(
    String endpoint, 
    Map<String, dynamic> body
  ) async {
    try {
      final headers = await TokenService.getAuthHeaders();
      if (headers == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('http://${AppConfig.baseURL}$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      return response;
    } catch (e) {
      print('Error in authenticated POST request: $e');
      return null;
    }
  }

  // Make authenticated HTTP PUT request
  static Future<http.Response?> authenticatedPut(
    String endpoint, 
    Map<String, dynamic> body
  ) async {
    try {
      final headers = await TokenService.getAuthHeaders();
      if (headers == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.put(
        Uri.parse('http://${AppConfig.baseURL}$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      return response;
    } catch (e) {
      print('Error in authenticated PUT request: $e');
      return null;
    }
  }

  // Make authenticated HTTP DELETE request
  static Future<http.Response?> authenticatedDelete(String endpoint) async {
    try {
      final headers = await TokenService.getAuthHeaders();
      if (headers == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.delete(
        Uri.parse('http://${AppConfig.baseURL}$endpoint'),
        headers: headers,
      );

      return response;
    } catch (e) {
      print('Error in authenticated DELETE request: $e');
      return null;
    }
  }

  // Check if token is still valid by making a test request
  static Future<bool> isTokenValid() async {
    try {
      final response = await authenticatedGet(AppConfig.userProfileEndpoint);
      return response != null && response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Logout user by clearing stored data
  static Future<void> logout() async {
    await TokenService.clearToken();
  }
}
