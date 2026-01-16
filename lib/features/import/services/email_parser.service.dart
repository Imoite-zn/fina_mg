import 'package:enough_mail/enough_mail.dart';
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
import 'package:fintracker/features/import/services/sms_parser.service.dart';

/// Configuration for email connection
class EmailConfig {
  final String email;
  final String password;
  final String imapServer;
  final int imapPort;
  final bool useSsl;

  EmailConfig({
    required this.email,
    required this.password,
    required this.imapServer,
    this.imapPort = 993,
    this.useSsl = true,
  });
}

/// Service for parsing and importing transactions from email
class EmailParserService {
  final ImportRuleDao _ruleDao = ImportRuleDao();
  final ImportHistoryDao _historyDao = ImportHistoryDao();
  final PaymentDao _paymentDao = PaymentDao();
  final AccountDao _accountDao = AccountDao();
  final CategoryDao _categoryDao = CategoryDao();

  /// Connect to email server
  Future<ImapClient> connect(EmailConfig config) async {
    final client = ImapClient(isLogEnabled: false);

    try {
      await client.connectToServer(
        config.imapServer,
        config.imapPort,
        isSecure: config.useSsl,
      );

      await client.login(config.email, config.password);
      return client;
    } catch (e) {
      throw Exception('Failed to connect to email server: $e');
    }
  }

  /// Get emails from inbox
  Future<List<MimeMessage>> getEmails({
    required EmailConfig config,
    DateTime? startDate,
    DateTime? endDate,
    String? fromAddress,
    int limit = 100,
  }) async {
    final client = await connect(config);

    try {
      await client.selectInbox();

      // Fetch recent messages
      final fetchResult = await client.fetchRecentMessages(
        messageCount: limit,
        criteria: 'BODY.PEEK[]',
      );

      List<MimeMessage> messages = [];
      for (var msg in fetchResult.messages) {
        // Filter by date if specified
        if (startDate != null && msg.decodeDate() != null) {
          if (msg.decodeDate()!.isBefore(startDate)) continue;
        }
        if (endDate != null && msg.decodeDate() != null) {
          if (msg.decodeDate()!.isAfter(endDate)) continue;
        }

        // Filter by sender if specified
        if (fromAddress != null) {
          final from = msg.from?.first.email;
          if (from == null || !from.contains(fromAddress)) continue;
        }

        messages.add(msg);
      }

      await client.logout();
      return messages;
    } catch (e) {
      await client.logout();
      throw Exception('Failed to fetch emails: $e');
    }
  }

  /// Parse a single email and extract transaction data
  Future<ParsedEmailTransaction?> parseEmail(
    MimeMessage email,
    List<ImportRule> rules,
  ) async {
    final messageId =
        email.getHeaderValue('message-id') ?? email.sequenceId.toString();

    // Check if already imported
    bool alreadyImported = await _historyDao.isImported('email', messageId);
    if (alreadyImported) {
      return null;
    }

    String subject = email.decodeSubject() ?? '';
    String body =
        email.decodeTextPlainPart() ?? email.decodeTextHtmlPart() ?? '';
    String fullText = '$subject $body';

    // Try each rule until one matches
    for (var rule in rules) {
      if (!rule.enabled || rule.source != 'email') continue;

      // Check sender filter if specified
      if (rule.senderFilter != null) {
        final from = email.from?.first.email ?? '';
        if (!from.contains(rule.senderFilter!)) continue;
      }

      // Check subject filter if specified
      if (rule.subjectFilter != null) {
        if (!subject.contains(rule.subjectFilter!)) continue;
      }

      if (rule.matches(fullText)) {
        double? amount = rule.extractAmount(fullText);
        if (amount == null || amount == 0) continue;

        return ParsedEmailTransaction(
          email: email,
          rule: rule,
          amount: amount,
          datetime: email.decodeDate() ?? DateTime.now(),
          description: _extractDescription(subject, body),
        );
      }
    }

    return null;
  }

  /// Import emails and create payments
  Future<ImportResult> importEmails({
    required EmailConfig config,
    DateTime? startDate,
    DateTime? endDate,
    String? fromAddress,
  }) async {
    int imported = 0;
    int skipped = 0;
    int failed = 0;
    List<String> errors = [];

    try {
      // Get all enabled email rules
      List<ImportRule> rules =
          await _ruleDao.find(source: 'email', enabled: true);
      if (rules.isEmpty) {
        return ImportResult(
          imported: 0,
          skipped: 0,
          failed: 0,
          errors: ['No enabled email import rules found'],
        );
      }

      // Get emails
      List<MimeMessage> emails = await getEmails(
        config: config,
        startDate: startDate,
        endDate: endDate,
        fromAddress: fromAddress,
      );

      // Get accounts and categories for matching
      List<Account> accounts = await _accountDao.find();
      List<Category> categories = await _categoryDao.find();

      // Parse and import each email
      for (var email in emails) {
        try {
          ParsedEmailTransaction? parsed = await parseEmail(email, rules);
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
          final messageId =
              email.getHeaderValue('message-id') ?? email.sequenceId.toString();
          ImportHistory history = ImportHistory(
            source: 'email',
            sourceId: messageId,
            paymentId: paymentId,
            rawContent: email.decodeSubject() ?? '',
          );

          await _historyDao.create(history);
          imported++;
        } catch (e) {
          failed++;
          errors.add('Failed to import email: $e');
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

  /// Extract description from email
  String _extractDescription(String subject, String body) {
    // Use subject as primary description
    if (subject.isNotEmpty) {
      return subject.length > 100 ? '${subject.substring(0, 100)}...' : subject;
    }

    // Fallback to body
    String cleanBody = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleanBody.length > 100
        ? '${cleanBody.substring(0, 100)}...'
        : cleanBody;
  }
}

/// Parsed transaction data from email
class ParsedEmailTransaction {
  final MimeMessage email;
  final ImportRule rule;
  final double amount;
  final DateTime datetime;
  final String description;

  ParsedEmailTransaction({
    required this.email,
    required this.rule,
    required this.amount,
    required this.datetime,
    required this.description,
  });
}
