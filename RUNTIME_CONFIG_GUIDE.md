# Runtime App Configuration Guide

This document explains how to change app configuration parameters at runtime.

## Overview

The app configuration has been restructured to allow runtime changes to server settings, primarily the base URL that the app connects to.

## Key Components

### 1. AppConfig Class (`lib/services/configurations.dart`)
- Contains all server configuration settings
- Allows runtime updates to the base URL
- Provides methods to get full endpoint URLs

### 2. Global appConfig Instance (`lib/main.dart`)
- Global instance accessible throughout the app
- Initialized at app startup
- Can be modified at runtime

### 3. ConfigManager Utility (`lib/services/config_manager.dart`)
- Provides convenient static methods to manage configuration
- Wraps access to the global appConfig instance
- Includes validation and utility methods

### 4. ConfigurationScreen Widget (`lib/users/configuration_screen.dart`)
- UI for changing configuration at runtime
- Shows current endpoints
- Allows users to update server settings

## Usage Examples

### Basic Configuration Changes

```dart
import '../services/config_manager.dart';

// Get current base URL
String currentURL = ConfigManager.baseURL;

// Update base URL at runtime
ConfigManager.updateBaseURL('192.168.1.100');

// Reset to default configuration
ConfigManager.resetToDefault();

// Get full URL for any endpoint
String fullURL = ConfigManager.getFullURL('/api/users');
```

### Direct Access to Global Instance

```dart
import '../main.dart' as main;

// Access the global appConfig instance
String baseURL = main.appConfig.baseURL;

// Update configuration directly
main.appConfig.updateBaseURL('10.0.0.1');

// Get endpoint URLs
String loginURL = main.appConfig.loginEndpoint;
String userProfileEndpoint = main.appConfig.userProfileEndpoint;
```

### Using the Configuration Screen

Add the ConfigurationScreen to your navigation:

```dart
import 'package:computer_engineering_project/users/configuration_screen.dart';

// Navigate to configuration screen
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const ConfigurationScreen()),
);
```

## Available Configuration Options

- **Base URL**: The server IP address or hostname
- **Login Endpoint**: Full URL for user authentication
- **Register Endpoint**: Full URL for user registration  
- **User Profile Endpoint**: Endpoint path for user profile operations
- **Fetch Data Endpoint**: Endpoint path for data retrieval

## Benefits

1. **Runtime Flexibility**: Change server settings without rebuilding the app
2. **Environment Switching**: Easy switching between development, staging, and production servers
3. **User Control**: Users can configure their own server endpoints
4. **Testing**: Developers can quickly test against different server instances
5. **Centralized Configuration**: All server settings managed in one place

## Important Notes

- Configuration changes take effect immediately for new requests
- The app retains the last configuration until manually changed
- Always validate server connectivity after changing base URL
- Use the ConfigManager utility class for consistent access patterns
- All network requests throughout the app use the global configuration

## File Structure

```
lib/
├── main.dart                          # Global appConfig instance
├── services/
│   ├── configurations.dart           # AppConfig class definition
│   ├── config_manager.dart          # Utility for config management
│   ├── auth_service.dart            # Uses global config for API calls
│   └── user_data_service.dart       # Uses global config for API calls
└── users/
    └── configuration_screen.dart     # UI for runtime config changes
```

This structure ensures that configuration changes propagate throughout the entire application seamlessly.