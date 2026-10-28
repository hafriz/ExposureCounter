import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkIns = ref.watch(checkInsProvider);
    final activeSession = ref.watch(activeSessionProvider);
    final today = DateFormat('EEEE, MMMM d').format(DateTime.now());
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(today, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        Text('How are you right now?', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        checkIns.when(
          data: (items) => items.isEmpty
              ? const _StatusCard(
                  title: 'No check-in recorded today',
                  detail: 'A quick check-in is optional and takes a moment.',
                )
              : _LatestCheckInCard(
                  anxiety: items.first.anxiety,
                  urge: items.first.compulsionUrge,
                  timestamp: items.first.createdAt,
                ),
          loading: () => const LinearProgressIndicator(),
          error: (error, stack) => const _StatusCard(
            title: 'Your check-ins are unavailable',
            detail: 'You can try again in a moment.',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => context.push('/check-in'),
          icon: const Icon(Icons.favorite_outline),
          label: const Text('Quick check-in'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push('/urge'),
          icon: const Icon(Icons.touch_app_outlined),
          label: const Text('I feel an urge'),
        ),
        const SizedBox(height: 28),
        Text('Exposure practice', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        activeSession.when(
          data: (session) => session == null
              ? _StatusCard(
                  title: 'Choose a practice when you’re ready',
                  detail: 'Your hierarchy stays on this device.',
                  action: TextButton(
                    onPressed: () => context.go('/exposures'),
                    child: const Text('View exposure hierarchy'),
                  ),
                )
              : _StatusCard(
                  title: 'Exposure in progress',
                  detail: session.title,
                  action: FilledButton.tonal(
                    onPressed: () => context.push('/session/${session.id}'),
                    child: const Text('Resume exposure'),
                  ),
                ),
          loading: () => const LinearProgressIndicator(),
          error: (error, stack) => const _StatusCard(
            title: 'Exposure session unavailable',
            detail: 'Your local session could not be loaded.',
          ),
        ),
        const SizedBox(height: 28),
        const _StatusCard(
          title: 'A note about this companion',
          detail:
              'This is a self-monitoring tool, not a diagnosis or a replacement for professional care.',
        ),
      ],
    );
  }
}

class _LatestCheckInCard extends StatelessWidget {
  const _LatestCheckInCard({
    required this.anxiety,
    required this.urge,
    required this.timestamp,
  });

  final int anxiety;
  final int urge;
  final DateTime timestamp;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Most recent check-in · ${DateFormat.jm().format(timestamp)}'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _Score(label: 'Anxiety', score: anxiety)),
                  Expanded(child: _Score(label: 'Compulsion urge', score: urge)),
                ],
              ),
            ],
          ),
        ),
      );
}

class _Score extends StatelessWidget {
  const _Score({required this.label, required this.score});

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            '$score / 10',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.detail,
    this.action,
  });

  final String title;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(detail),
              if (action != null) ...[
                const SizedBox(height: 8),
                action!,
              ],
            ],
          ),
        ),
      );
}
