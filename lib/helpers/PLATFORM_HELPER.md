# Platform Helper Utility

## Overview

The `PlatformHelper` class provides a clean, centralized API for detecting the current platform and checking feature availability across all platforms.

## Usage

```dart
import 'package:fintracker/helpers/platform_helper.dart';

// Check current platform
if (PlatformHelper.isWeb) {
  // Web-specific code
} else if (PlatformHelper.isMobile) {
  // Mobile-specific code
} else if (PlatformHelper.isDesktop) {
  // Desktop-specific code
}

// Check feature availability
if (PlatformHelper.supportsSMS) {
  // SMS import available
}

if (PlatformHelper.supportsFileOperations) {
  // File operations available
}

// Get platform information
print('Running on: ${PlatformHelper.platformName}');
print('Database: ${PlatformHelper.databaseType}');
```

## Available Properties

### Platform Detection

- `isWeb` - Running on web browser
- `isMobile` - Running on Android or iOS
- `isDesktop` - Running on Windows, macOS, or Linux
- `isAndroid` - Running on Android
- `isIOS` - Running on iOS
- `isWindows` - Running on Windows
- `isMacOS` - Running on macOS
- `isLinux` - Running on Linux

### Feature Availability

- `supportsFileOperations` - File system access available
- `supportsSMS` - SMS inbox access available
- `supportsEmailImport` - Email import available
- `supportsPermissions` - Runtime permissions available

### Platform Information

- `platformName` - Human-readable platform name
- `databaseType` - Database implementation for current platform

## Benefits

1. **Clean Code**: Replace scattered `kIsWeb` and `Platform.is*` checks with semantic helpers
2. **Maintainability**: Single source of truth for platform detection
3. **Feature Flags**: Easy to check if features are available on current platform
4. **Cross-Platform**: Works seamlessly on all platforms without breaking

## Implementation

The helper uses conditional imports to work on all platforms:

- On native platforms: Uses `dart:io` Platform class
- On web: Uses stub implementation that returns appropriate values

This ensures the app compiles and runs correctly on any platform without runtime errors.
