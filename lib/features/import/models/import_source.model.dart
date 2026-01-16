import 'package:flutter/material.dart';

/// Represents a source for importing transactions
enum ImportSourceType {
  sms,
  email,
}

/// Configuration for an import source
class ImportSource {
  final ImportSourceType type;
  final String name;
  final bool enabled;
  final Map<String, dynamic>? config;

  ImportSource({
    required this.type,
    required this.name,
    this.enabled = true,
    this.config,
  });

  factory ImportSource.fromJson(Map<String, dynamic> json) {
    return ImportSource(
      type:
          json['type'] == 'sms' ? ImportSourceType.sms : ImportSourceType.email,
      name: json['name'],
      enabled: json['enabled'] ?? true,
      config: json['config'],
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type == ImportSourceType.sms ? 'sms' : 'email',
        'name': name,
        'enabled': enabled,
        'config': config,
      };

  IconData get icon => type == ImportSourceType.sms ? Icons.sms : Icons.email;

  String get displayName =>
      type == ImportSourceType.sms ? 'SMS Messages' : 'Email';
}
