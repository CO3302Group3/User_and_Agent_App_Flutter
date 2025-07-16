# JWT Token Management Implementation

This implementation provides secure JWT token storage and management for the Flutter app using `shared_preferences`.

## Files Added/Modified:

### 1. `lib/services/token_service.dart`
- Handles JWT token storage and retrieval using SharedPreferences
- Provides methods to save/get token, user info, and check login status
- Includes token cleanup functionality for logout

### 2. `lib/services/auth_service.dart`
- Provides authenticated HTTP methods (GET, POST, PUT, DELETE)
- Automatically includes JWT token in Authorization header
- Handles token validation

### 3. `lib/services/auth_wrapper.dart`
- Checks login status on app startup
- Automatically redirects to appropriate screen based on authentication

### 4. `lib/services/user_data_service.dart`
- Example service showing how to use authenticated API calls
- Demonstrates fetching and updating user data

### 5. Updated `lib/users/Loginscreen.dart`
- Enhanced login function with proper error handling
- Saves JWT token after successful login
- Shows user feedback with SnackBars
- Improved navigation logic

### 6. Updated `lib/users/profile.dart`
- Added proper logout functionality with confirmation dialog
- Clears stored token and redirects to login screen

### 7. Updated `pubspec.yaml`
- Added `shared_preferences: ^2.2.2` dependency

### 8. Updated `lib/main.dart`
- Uses AuthWrapper to check authentication on app start

## How to Use:

### 1. Login and Save Token:
```dart
// In your login method
final token = await loginuser(baseURL, password, email);
if (token != null) {
  await TokenService.saveToken(token);
  await TokenService.saveUserInfo(email: email);
}
```

### 2. Make Authenticated API Calls:
```dart
// GET request
final response = await AuthService.authenticatedGet('/api/endpoint');

// POST request
final response = await AuthService.authenticatedPost('/api/endpoint', {
  'key': 'value'
});
```

### 3. Check Login Status:
```dart
final isLoggedIn = await TokenService.isLoggedIn();
```

### 4. Get User Info:
```dart
final userInfo = await TokenService.getUserInfo();
final email = userInfo['email'];
```

### 5. Logout:
```dart
await AuthService.logout(); // Clears all stored data
```

### 6. Get Authorization Headers:
```dart
final headers = await TokenService.getAuthHeaders();
// Returns: {'Authorization': 'Bearer <token>', 'Content-Type': 'application/json'}
```

## Features:

1. **Secure Storage**: Uses SharedPreferences to store tokens locally
2. **Auto-Login**: Checks authentication status on app startup
3. **Token Validation**: Can verify if token is still valid
4. **Easy Logout**: One method clears all stored authentication data
5. **Error Handling**: Comprehensive error handling throughout
6. **User Feedback**: SnackBars inform users of success/failure
7. **Authenticated Requests**: Simplified methods for API calls with authentication

## Security Notes:

- Tokens are stored in SharedPreferences which is secure for mobile apps
- Consider implementing token refresh mechanism for production
- Add token expiration checking if your backend provides expiry information
- For sensitive data, consider using flutter_secure_storage instead of SharedPreferences

## Usage Example in Other Screens:

```dart
import '../services/user_data_service.dart';

// In your widget
Future<void> loadUserData() async {
  final userData = await UserDataService.fetchUserProfile();
  if (userData != null) {
    // Use the data
    setState(() {
      // Update your UI
    });
  }
}
```

The implementation is now ready to use throughout your app!
