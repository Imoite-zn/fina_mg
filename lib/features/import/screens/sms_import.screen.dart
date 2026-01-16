import 'dart:io';
import 'package:fintracker/features/import/services/sms_parser.service.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

/// Screen for SMS import configuration and execution
class SmsImportScreen extends StatefulWidget {
  const SmsImportScreen({super.key});

  @override
  State<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends State<SmsImportScreen> {
  final SmsParserService _smsService = SmsParserService();
  bool _hasPermission = false;
  bool _loading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    if (!Platform.isAndroid) {
      setState(() {
        _statusMessage = 'SMS import is only available on Android devices';
      });
      return;
    }

    final hasPermission = await _smsService.hasPermission();
    setState(() {
      _hasPermission = hasPermission;
    });
  }

  Future<void> _requestPermission() async {
    setState(() => _loading = true);
    final granted = await _smsService.requestPermission();
    setState(() {
      _hasPermission = granted;
      _loading = false;
      _statusMessage = granted
          ? 'Permission granted! You can now import SMS messages.'
          : 'Permission denied. Please grant SMS permission in settings.';
    });
  }

  Future<void> _importSms() async {
    if (!_hasPermission) {
      await _requestPermission();
      return;
    }

    setState(() {
      _loading = true;
      _statusMessage = 'Importing SMS messages...';
    });

    try {
      final result = await _smsService.importMessages(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
      );

      setState(() {
        _loading = false;
        _statusMessage =
            'Import complete!\n${result.imported} imported, ${result.skipped} skipped, ${result.failed} failed';
      });

      if (result.hasErrors) {
        _showErrorDialog(result.errors);
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _statusMessage = 'Import failed: $e';
      });
    }
  }

  void _showErrorDialog(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Errors'),
        content: SingleChildScrollView(
          child: Text(errors.join('\n')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SMS Import',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _hasPermission
                              ? Symbols.check_circle
                              : Symbols.warning,
                          color: _hasPermission ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _hasPermission
                              ? 'Permission Granted'
                              : 'Permission Required',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(_statusMessage!),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Import Button
            if (!Platform.isAndroid)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'SMS import is only available on Android devices.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (!_hasPermission)
              ElevatedButton.icon(
                onPressed: _loading ? null : _requestPermission,
                icon: const Icon(Symbols.lock_open),
                label: const Text('Grant Permission'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _loading ? null : _importSms,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Symbols.download),
                label: Text(
                    _loading ? 'Importing...' : 'Import SMS (Last 30 days)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),

            const SizedBox(height: 16),

            // Info
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Note:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• You need to create import rules first\n'
                      '• Only bank transaction SMS will be imported\n'
                      '• Duplicate messages are automatically skipped',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
