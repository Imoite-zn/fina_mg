import 'package:fintracker/model/payment.model.dart';

/// User-defined rule for parsing and categorizing imported transactions
class ImportRule {
  int? id;
  String name;
  String source; // 'sms' or 'email'
  String pattern; // Regex pattern to match
  int? accountId;
  int? categoryId;
  PaymentType type;
  bool enabled;
  DateTime createdAt;

  // Optional fields for matching
  String? senderFilter; // For email: filter by sender address
  String? subjectFilter; // For email: filter by subject

  ImportRule({
    this.id,
    required this.name,
    required this.source,
    required this.pattern,
    this.accountId,
    this.categoryId,
    required this.type,
    this.enabled = true,
    DateTime? createdAt,
    this.senderFilter,
    this.subjectFilter,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ImportRule.fromJson(Map<String, dynamic> json) {
    return ImportRule(
      id: json['id'],
      name: json['name'],
      source: json['source'],
      pattern: json['pattern'],
      accountId: json['account_id'],
      categoryId: json['category_id'],
      type: json['type'] == 'CR' ? PaymentType.credit : PaymentType.debit,
      enabled: json['enabled'] == 1,
      createdAt: DateTime.parse(json['created_at']),
      senderFilter: json['sender_filter'],
      subjectFilter: json['subject_filter'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'source': source,
        'pattern': pattern,
        'account_id': accountId,
        'category_id': categoryId,
        'type': type == PaymentType.credit ? 'CR' : 'DR',
        'enabled': enabled ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'sender_filter': senderFilter,
        'subject_filter': subjectFilter,
      };

  /// Check if this rule matches the given text
  bool matches(String text) {
    try {
      final regex = RegExp(pattern, caseSensitive: false);
      return regex.hasMatch(text);
    } catch (e) {
      return false;
    }
  }

  /// Extract amount from text using the pattern
  double? extractAmount(String text) {
    try {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null && match.groupCount > 0) {
        final amountStr = match.group(1);
        if (amountStr != null) {
          return double.tryParse(amountStr.replaceAll(',', ''));
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
