# AGENTS.md

This file provides guidance to agentic coding agents working with the EGData Flutter codebase.

## Build Commands

### Development
```bash
# Install dependencies
flutter pub get

# Run code generation (Isar models, etc.)
flutter packages pub run build_runner build --delete-conflicting-outputs

# Run the app on different platforms
flutter run -d windows
flutter run -d macos
flutter run -d android
flutter run -d ios

# Hot reload (when running)
# Press 'r' in terminal for hot reload
# Press 'R' for hot restart
```

### Code Quality
```bash
# Analyze code (linting)
flutter analyze

# Format code
dart format .

# Run all tests
flutter test

# Run single test file
flutter test test/services/api_service_test.dart

# Run tests with coverage
flutter test --coverage

# Run specific test group
flutter test --name "ApiService"
```

### Build Release
```bash
# Build for different platforms
flutter build windows
flutter build macos
flutter build apk
flutter build ios

# Build MSIX package (Windows)
flutter pub run msix:create
```

## Code Style Guidelines

### Import Organization
- Group imports: dart libraries, package imports, local imports
- Use relative imports for local files (e.g., `'../models/api/offer.dart'`)
- Export commonly used types from service files (see `api_service.dart`)
- Conditionally import platform-specific packages with comments

```dart
// Dart libraries
import 'dart:convert';
import 'dart:io';

// Package imports
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Local imports
import '../models/api/offer.dart';
import '../services/api_service.dart';

// Platform-specific imports (conditionally used)
import 'package:window_manager/window_manager.dart'; // Desktop only
```

### Naming Conventions
- **Classes**: PascalCase (e.g., `ApiService`, `GameInfo`)
- **Files**: snake_case (e.g., `api_service.dart`, `game_info.dart`)
- **Variables/Methods**: camelCase (e.g., `finalResult`, `fetchData()`)
- **Constants**: SCREAMING_SNAKE_CASE for app-level constants (e.g., `appVersion`)
- **Private members**: prefix with underscore (e.g., `_client`, `_fetchData()`)

### Model Classes
- Use `final` for all immutable fields
- Create null-safe `fromJson` factories with sensible defaults
- Include `copyWith()` methods for immutable updates
- Add computed getters for derived data (e.g., `formattedSize`)

```dart
class GameInfo {
  final String displayName;
  final String? installLocation;
  final int installSize;

  const GameInfo({
    required this.displayName,
    this.installLocation,
    required this.installSize,
  });

  factory GameInfo.fromJson(Map<String, dynamic> json) => GameInfo(
    displayName: json['displayName'] ?? '',
    installLocation: json['installLocation'],
    installSize: json['installSize'] ?? 0,
  );

  GameInfo copyWith({
    String? displayName,
    String? installLocation,
    int? installSize,
  }) => GameInfo(
    displayName: displayName ?? this.displayName,
    installLocation: installLocation ?? this.installLocation,
    installSize: installSize ?? this.installSize,
  );

  String get formattedSize => _formatBytes(installSize);
}
```

### Error Handling
- Create custom exception types for domain-specific errors
- Use try-catch blocks for network operations and file I/O
- Log errors with `debugPrint()` for non-fatal issues
- Handle `SocketException` gracefully for cancelled requests

```dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message';
}

// Usage
try {
  final response = await _client.get(uri);
  if (response.statusCode != 200) {
    throw ApiException('Request failed', response.statusCode);
  }
  return jsonDecode(response.body);
} on SocketException catch (e) {
  if (e.message.contains('cancelled')) {
    // Gracefully handle cancelled requests
    return null;
  }
  rethrow;
}
```

### Service Classes
- Use dependency injection for HTTP clients and testability
- Create private methods for internal logic
- Export commonly used types from service files
- Use static constants for URLs and configuration

```dart
class ApiService {
  static const String baseUrl = 'https://api.egdata.app';

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Offer>> getOffers() async {
    final data = await _get('/offers');
    return (data as List).map((json) => Offer.fromJson(json)).toList();
  }
}
```

### Testing Guidelines
- Use descriptive test names that explain the scenario
- Group related tests with `group()` blocks
- Create helper factory methods for test data
- Test boundary conditions and edge cases
- Use `createGameInfo()` pattern for test object creation

```dart
void main() {
  group('GameInfo', () {
    GameInfo createGameInfo({int installSize = 0}) {
      return GameInfo(
        displayName: 'Test Game',
        installSize: installSize,
        // ... other required fields
      );
    }

    group('formattedSize', () {
      test('formats bytes correctly', () {
        final game = createGameInfo(installSize: 1024);
        expect(game.formattedSize, '1.0 KB');
      });
    });
  });
}
```

### UI/UX Patterns
- Use platform detection: `Platform.isAndroid || Platform.isIOS`
- Desktop: Full sidebar navigation with glassmorphic design
- Mobile: Bottom navigation with simplified pages
- Follow Unreal Engine-inspired dark theme colors
- Use `AppColors` constants from `main.dart` for consistency

### State Management
- **Mobile**: Use `fluquery` with hooks-based queries (`useQuery`, `useInfiniteQuery`)
- **Desktop**: Use `StatefulWidget` with `setState()` for simpler state
- Store persistent data in Isar database via `DatabaseService`
- Use `useState` and `useEffect` hooks for reactive state

### Platform-Specific Code
- Conditionally import platform-specific packages
- Use comments to indicate platform-only features
- Desktop: Window management, system tray, notifications
- Mobile: Push notifications, home screen widgets, AI chat

### Code Generation
- Run `flutter packages pub run build_runner build` after model changes
- Isar models require code generation for database schema
- Use `--delete-conflicting-outputs` flag when needed

### Dependencies
- Check `pubspec.yaml` for available packages before adding new ones
- Use `cached_network_image` for image loading with caching
- Use `fluquery` for data fetching and state management (mobile)
- Use `isar` for local database persistence

## Platform Detection

Use this pattern to switch between desktop and mobile UIs:
```dart
final isMobile = Platform.isAndroid || Platform.isIOS;

if (isMobile) {
  // Mobile UI with bottom navigation
} else {
  // Desktop UI with sidebar
}
```

## API Integration

- Base URL: `https://api.egdata.app`
- All API models have null-safe `fromJson` factories
- Use `ApiService` for centralized HTTP client
- Handle country-specific pricing with `country` parameter
- WebSocket for AI chat: `wss://ai.egdata.app`