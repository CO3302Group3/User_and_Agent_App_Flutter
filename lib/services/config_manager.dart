import '../main.dart' as main;

/// Utility class to manage app configuration at runtime
class ConfigManager {
  /// Get the current base URL
  static String get baseURL => main.appConfig.baseURL;
  
  /// Update the base URL at runtime
  static void updateBaseURL(String newBaseURL) {
    main.appConfig.updateBaseURL(newBaseURL);
  }
  
  /// Reset configuration to default values
  static void resetToDefault() {
    main.appConfig.resetToDefault();
  }
  
  /// Get full URL for any endpoint
  static String getFullURL(String endpoint) {
    return main.appConfig.getFullURL(endpoint);
  }
  
  /// Get all endpoint URLs for debugging or display purposes
  static Map<String, String> getAllEndpoints() {
    return {
      'login': main.appConfig.loginEndpoint,
      'register': main.appConfig.registerEndpoint,
      'userProfile': main.appConfig.getFullURL(main.appConfig.userProfileEndpoint),
      'fetchData': main.appConfig.getFullURL(main.appConfig.fetchDataEndpoint),
    };
  }
  
  /// Validate if the current base URL is reachable
  /// This is a placeholder - you can implement actual connectivity check
  static Future<bool> validateBaseURL() async {
    // You can implement a simple connectivity check here
    // For example, make a simple HTTP request to check if the server is reachable
    try {
      // This is just a placeholder - implement actual validation
      return main.appConfig.baseURL.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}