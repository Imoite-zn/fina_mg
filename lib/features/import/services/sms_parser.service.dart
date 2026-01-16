import 'dart:io';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:fintracker/features/import/models/import_rule.model.dart';
import 'package:fintracker/features/import/models/import_history.model.dart';
import 'package:fintracker/features/import/dao/import_rule_dao.dart';
import 'package:fintracker/features/import/dao/import_history_dao.dart';
import 'package:fintracker/dao/payment_dao.dart';
import 'package:fintracker/dao/account_dao.dart';
import 'package:fintracker/dao/category_dao.dart';
import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/model/account.model.dart';
import 'package:fintracker/model/category.model.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for parsing and importing transactions from SMS messages
class SmsParserService {
  final SmsQuery _smsQuery = SmsQuery();
  final ImportRuleDao _ruleDao = ImportRuleDao();
  final ImportHistoryDao _historyDao = ImportHistoryDao();
  final PaymentDao _paymentDao = PaymentDao();
  final AccountDao _accountDao = AccountDao();
  final CategoryDao _categoryDao = CategoryDao();

  /// Check if SMS permission is granted
  Future<bool> hasPermission() async {
    if (!Platform.isAndroid) return false;

    var status = await Permission.sms.status;
    return status.isGranted;
  }

  /// Request SMS permission
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;

    var status = await Permission.sms.request();
    return status.isGranted;
  }

  /// Get SMS messages within a date range
  Future<List<SmsMessage>> getMessages({
    DateTime? startDate,
    DateTime? endDate,
    String? address, // Filter by sender
  }) async {
    if (!await hasPermission()) {
      throw Exception('SMS permission not granted');
    }

    List<SmsMessage> messages = await _smsQuery.querySms(
      kinds: [SmsQueryKind.inbox],
      start: startDate?.millisecondsSinceEpoch ?? 0,
      count: 1000,
      address: address,
    );

    return messages;
  }

  /// Parse a single SMS message and extract transaction data
  Future<ParsedTransaction?> parseMessage(
    SmsMessage message,
    List<ImportRule> rules,
  ) async {
    // Check if already imported
    bool alreadyImported =
        await _historyDao.isImported('sms', message.id.toString());
    if (alreadyImported) {
      return null;
    }

    String body = message.body ?? '';

    // Try each rule until one matches
    for (var rule in rules) {
      if (!rule.enabled || rule.source != 'sms') continue;

      if (rule.matches(body)) {
        double? amount = rule.extractAmount(body);
        if (amount == null || amount == 0) continue;

        return ParsedTransaction(
          message: message,
          rule: rule,
          amount: amount,
          datetime: message.date ?? DateTime.now(),
          description: _extractDescription(body),
        );
      }
    }

    return null;
  }

  /// Import SMS messages and create payments
  Future<ImportResult> importMessages({
    DateTime? startDate,
    DateTime? endDate,
    String? address,
  }) async {
    int imported = 0;
    int skipped = 0;
    int failed = 0;
    List<String> errors = [];

    try {
      // Get all enabled SMS rules
      List<ImportRule> rules =
          await _ruleDao.find(source: 'sms', enabled: true);
      if (rules.isEmpty) {
        return ImportResult(
          imported: 0,
          skipped: 0,
          failed: 0,
          errors: ['No enabled SMS import rules found'],
        );
      }

      // Get messages
      List<SmsMessage> messages = await getMessages(
        startDate: startDate,
        endDate: endDate,
        address: address,
      );

      // Get accounts and categories for matching
      List<Account> accounts = await _accountDao.find();
      List<Category> categories = await _categoryDao.find();

      // Parse and import each message
      for (var message in messages) {
        try {
          ParsedTransaction? parsed = await parseMessage(message, rules);
          if (parsed == null) {
            skipped++;
            continue;
          }

          // Find or use default account/category
          Account? account;
          Category? category;

          if (parsed.rule.accountId != null) {
            account = accounts.firstWhere(
              (a) => a.id == parsed.rule.accountId,
              orElse: () => accounts.first,
            );
          } else {
            account = accounts.first;
          }

          if (parsed.rule.categoryId != null) {
            category = categories.firstWhere(
              (c) => c.id == parsed.rule.categoryId,
              orElse: () => categories.first,
            );
          } else {
            category = categories.first;
          }

          // Create payment
          Payment payment = Payment(
            account: account,
            category: category,
            amount: parsed.amount,
            type: parsed.rule.type,
            datetime: parsed.datetime,
            title: parsed.rule.name,
            description: parsed.description,
          );

          int paymentId = await _paymentDao.create(payment);

          // Record import history
          ImportHistory history = ImportHistory(
            source: 'sms',
            sourceId: message.id.toString(),
            paymentId: paymentId,
            rawContent: message.body ?? '',
          );

          await _historyDao.create(history);
          imported++;
        } catch (e) {
          failed++;
          errors.add('Failed to import SMS ${message.id}: $e');
        }
      }
    } catch (e) {
      errors.add('Import failed: $e');
    }

    return ImportResult(
      imported: imported,
      skipped: skipped,
      failed: failed,
      errors: errors,
    );
  }

  /// Extract merchant/description from SMS body
  String _extractDescription(String body) {
    // Try to extract merchant name or description
    // This is a simple implementation, can be enhanced

    // Common patterns:
    // "at MERCHANT_NAME"
    // "to MERCHANT_NAME"
    // "from MERCHANT_NAME"

    final patterns = [
      RegExp(r'at\s+([A-Z][A-Z0-9\s]+)', caseSensitive: false),
      RegExp(r'to\s+([A-Z][A-Z0-9\s]+)', caseSensitive: false),
      RegExp(r'from\s+([A-Z][A-Z0-9\s]+)', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      var match = pattern.firstMatch(body);
      if (match != null && match.groupCount > 0) {
        return match.group(1)?.trim() ?? 'SMS Transaction';
      }
    }

    // Fallback: use first 50 characters
    return body.length > 50 ? '${body.substring(0, 50)}...' : body;
  }
}

/// Parsed transaction data from SMS
class ParsedTransaction {
  final SmsMessage message;
  final ImportRule rule;
  final double amount;
  final DateTime datetime;
  final String description;

  ParsedTransaction({
    required this.message,
    required this.rule,
    required this.amount,
    required this.datetime,
    required this.description,
  });
}

/// Result of import operation
class ImportResult {
  final int imported;
  final int skipped;
  final int failed;
  final List<String> errors;

  ImportResult({
    required this.imported,
    required this.skipped,
    required this.failed,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
  int get total => imported + skipped + failed;
}
