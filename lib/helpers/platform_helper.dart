import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' if (dart.library.html) 'platform_stub.dart';

/// Platform detection helper for cross-platform compatibility
class PlatformHelper {
  /// Check if running on web platform
  static bool get isWeb => kIsWeb;

  /// Check if running on mobile (Android or iOS)
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Check if running on desktop (Windows, macOS, or Linux)
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Check if running on Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Check if running on iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Check if running on Windows
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Check if running on macOS
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Check if running on Linux
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  /// Check if platform supports file operations
  static bool get supportsFileOperations => !kIsWeb;

  /// Check if platform supports SMS access
  static bool get supportsSMS =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Check if platform supports email import
  static bool get supportsEmailImport => !kIsWeb;

  /// Check if platform supports permissions
  static bool get supportsPermissions =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Get platform name as string
  static String get platformName {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  /// Get database type for current platform
  static String get databaseType {
    if (kIsWeb) return 'IndexedDB';
    if (Platform.isWindows) return 'SQLite (FFI)';
    return 'SQLite';
  }
}
