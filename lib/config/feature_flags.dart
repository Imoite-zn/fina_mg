/// Feature flags for controlling optional features
///
/// This allows for easy rollback of features by setting flags to false
class FeatureFlags {
  /// Master switch for the entire import feature
  /// Set to false to completely disable SMS and Email import functionality
  static const bool enableImportFeature = true;

  /// Enable SMS import functionality (Android only)
  static const bool enableSmsImport = true;

  /// Enable Email import functionality (All platforms)
  static const bool enableEmailImport = true;

  /// Enable import history tracking
  static const bool enableImportHistory = true;
}
