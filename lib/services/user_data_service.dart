import 'dart:convert';
import '../services/auth_service.dart';
import '../services/token_storage_fallback.dart';
import '../main.dart' as main;

class UserDataService {
  // Fetch user profile data
  static Future<Map<String, dynamic>?> fetchUserProfile() async {
    try {
      final response = await AuthService.authenticatedGet(main.appConfig.userProfileEndpoint);
      
      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('Failed to fetch user profile: ${response?.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Fetch any data using authenticated request
  static Future<Map<String, dynamic>?> fetchData() async {
    try {
      final response = await AuthService.authenticatedGet(main.appConfig.fetchDataEndpoint);
      
      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('Failed to fetch data: ${response?.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching data: $e');
      return null;
    }
  }

  // Update user profile
  static Future<bool> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await AuthService.authenticatedPut(
        main.appConfig.userProfileEndpoint, 
        profileData
      );
      
      if (response != null && response.statusCode == 200) {
        print('Profile updated successfully');
        return true;
      } else {
        print('Failed to update profile: ${response?.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Get current user info from stored token
  static Future<Map<String, String?>> getCurrentUserInfo() async {
    return await TokenStorageFallback.getUserInfo();
  }
}
