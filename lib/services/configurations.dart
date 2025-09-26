class AppConfig {
  String _baseURL = '192.168.8.186';

  // Getter for baseURL
  String get baseURL => _baseURL;

  // Setter for baseURL to allow runtime configuration
  set baseURL(String url) {
    _baseURL = url;
  }

  // Endpoint getters that use the current baseURL
  String get loginEndpoint => 'http://$_baseURL/auth/login';
  String get registerEndpoint => 'http://$_baseURL/auth/register';
  String get userProfileEndpoint => '/user/profile';
  String get fetchDataEndpoint => '/data/fetch';

  // Method to update configuration at runtime
  void updateBaseURL(String newBaseURL) {
    _baseURL = newBaseURL;
  }

  // Method to get full URL for any endpoint
  String getFullURL(String endpoint) {
    return 'http://$_baseURL$endpoint';
  }

  // Method to reset to default configuration
  void resetToDefault() {
    _baseURL = '192.168.8.186';
  }
}