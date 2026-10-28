import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final csv = await ref.read(repositoryProvider).exportCsv();
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/exposure-companion-${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(csv, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Personal exposure companion data',
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkIns = ref.watch(checkInsProvider);
    final sessions = ref.watch(sessionsProvider);
    final urges = ref.watch(urgesProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                await _export(context, ref);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export could not be created.')),
                  );
                }
              }
            },
            icon: const Icon(Icons.ios_share),
            label: const Text('Export CSV'),
          ),
        ),
        _SectionTitle(title: 'Daily check-ins'),
        checkIns.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, stack) =>
              const Text('Check-in history is unavailable.'),
          data: (items) => items.isEmpty
              ? const _EmptyHistory()
              : Column(
                  children: items
                      .map(
                        (item) => Card(
                          child: ListTile(
                            title: Text(
                              '${item.anxiety}/10 anxiety · ${item.compulsionUrge}/10 urge',
                            ),
                            subtitle: Text(
                              '${DateFormat.yMMMd().add_jm().format(item.createdAt)} · ${item.mood}${item.trigger == null ? '' : ' · ${item.trigger}'}',
                            ),
                            trailing: IconButton(
                              tooltip: 'Delete check-in',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await ref
                                    .read(repositoryProvider)
                                    .deleteCheckIn(item.id);
                                ref.invalidate(checkInsProvider);
                              },
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        _SectionTitle(title: 'Exposure sessions'),
        sessions.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, stack) =>
              const Text('Exposure history is unavailable.'),
          data: (items) => items.isEmpty
              ? const _EmptyHistory()
              : Column(
                  children: items
                      .map(
                        (item) => Card(
                          child: ListTile(
                            title: Text(item.title),
                            subtitle: Text(
                              '${DateFormat.yMMMd().add_jm().format(item.startedAt)} · ${_durationLabel(item.duration)} · ${item.responseResult ?? 'In progress'}',
                            ),
                            trailing: item.endedAt == null
                                ? null
                                : IconButton(
                                    tooltip: 'Delete exposure session',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () async {
                                      await ref
                                          .read(repositoryProvider)
                                          .deleteSession(item.id);
                                      ref.invalidate(sessionsProvider);
                                    },
                                  ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        _SectionTitle(title: 'Compulsion urges'),
        urges.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, stack) => const Text('Urge history is unavailable.'),
          data: (items) => items.isEmpty
              ? const _EmptyHistory()
              : Column(
                  children: items
                      .map(
                        (item) => Card(
                          child: ListTile(
                            title: Text('Compulsion urge · ${item.level}/10'),
                            subtitle: Text(
                              DateFormat.yMMMd().add_jm().format(item.recordedAt),
                            ),
                            trailing: IconButton(
                              tooltip: 'Delete compulsion urge',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await ref
                                    .read(repositoryProvider)
                                    .deleteUrge(item.id);
                                ref.invalidate(urgesProvider);
                              },
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No records yet.'),
      );
}

String _durationLabel(Duration duration) =>
    '${duration.inMinutes} min ${duration.inSeconds.remainder(60)} sec';
