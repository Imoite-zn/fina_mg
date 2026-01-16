import 'package:fintracker/config/feature_flags.dart';
import 'package:fintracker/features/import/screens/sms_import.screen.dart';
import 'package:fintracker/features/import/screens/email_import.screen.dart';
import 'package:fintracker/features/import/dao/import_history_dao.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

/// Main screen for managing import sources and viewing history
class ImportManagementScreen extends StatefulWidget {
  const ImportManagementScreen({super.key});

  @override
  State<ImportManagementScreen> createState() => _ImportManagementScreenState();
}

class _ImportManagementScreenState extends State<ImportManagementScreen> {
  final ImportHistoryDao _historyDao = ImportHistoryDao();
  Map<String, int> _importCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final counts = await _historyDao.getImportCounts();
    setState(() {
      _importCounts = counts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Auto Import',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                Text(
                  'Import transactions from SMS and Email',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),

                // SMS Import Card
                if (FeatureFlags.enableSmsImport)
                  _buildImportCard(
                    context,
                    title: 'SMS Messages',
                    subtitle:
                        '${_importCounts['sms'] ?? 0} transactions imported',
                    icon: Symbols.sms,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SmsImportScreen(),
                        ),
                      ).then((_) => _loadStats());
                    },
                  ),

                const SizedBox(height: 16),

                // Email Import Card
                if (FeatureFlags.enableEmailImport)
                  _buildImportCard(
                    context,
                    title: 'Email',
                    subtitle:
                        '${_importCounts['email'] ?? 0} transactions imported',
                    icon: Symbols.email,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmailImportScreen(),
                        ),
                      ).then((_) => _loadStats());
                    },
                  ),

                const SizedBox(height: 24),

                // Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Symbols.info,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'How it works',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '1. Set up import rules with patterns to match\n'
                          '2. Grant necessary permissions\n'
                          '3. Import transactions automatically\n'
                          '4. Review and manage imported data',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildImportCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: const Icon(Symbols.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
