import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/app_lock.dart';

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
            Builder(
              builder: (context) {
                final lock = AppLockScope.of(context);
                return SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text('Application lock'),
                  subtitle: Text(
                    lock.enabled
                        ? 'Require biometrics or device authentication when opening the app.'
                        : 'Protect this app with biometrics or your device passcode.',
                  ),
                  value: lock.enabled,
                  onChanged: lock.busy
                      ? null
                      : (enabled) async {
                          if (enabled) {
                            final success = await lock.enable();
                            if (!context.mounted || success) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  lock.error ??
                                      'Could not enable application lock.',
                                ),
                              ),
                            );
                          } else {
                            await lock.disable();
                          }
                        },
                );
              },
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
            Card(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/branding/exposure_counter_mark.png',
                        width: 72,
                        height: 72,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Exposure Counter',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text('A calm companion for practicing courageous steps.'),
                          SizedBox(height: 12),
                          Text(
                            'Developed by RareCreation',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
