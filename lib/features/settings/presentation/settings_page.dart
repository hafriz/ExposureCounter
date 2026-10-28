import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all application data?'),
        content: const Text(
          'This permanently removes check-ins, exposures, sessions, measurements, urges, and response delays from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete all data'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(repositoryProvider).deleteAllData();
    ref
      ..invalidate(checkInsProvider)
      ..invalidate(exposureItemsProvider)
      ..invalidate(activeSessionProvider)
      ..invalidate(sessionsProvider)
      ..invalidate(urgesProvider)
      ..invalidate(activeDelayProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application data was deleted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Settings and privacy')),
        body: ListView(
          children: [
            const ListTile(
              title: Text('Privacy'),
              subtitle: Text(
                'Your records are stored locally on this device. This application does not create an account or send data to a service.',
              ),
              isThreeLine: true,
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Application lock'),
              subtitle: Text(
                'Biometric locking is not available in this initial version. Use your device security to protect this information.',
              ),
              isThreeLine: true,
            ),
            const Divider(),
            const ListTile(
              title: Text('Support & Safety'),
              subtitle: Text(
                'This companion is for self-monitoring and practice support. It does not provide diagnosis, replace professional healthcare, or provide emergency support. Discuss treatment decisions with a qualified healthcare professional.',
              ),
              isThreeLine: true,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined),
              title: const Text('Delete all application data'),
              subtitle: const Text('This cannot be undone.'),
              onTap: () => _deleteAll(context, ref),
            ),
          ],
        ),
      );
}
