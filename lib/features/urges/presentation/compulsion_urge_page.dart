import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/rating_slider.dart';
import '../../exposure/domain/exposure_models.dart';

class CompulsionUrgePage extends ConsumerStatefulWidget {
  const CompulsionUrgePage({super.key});

  @override
  ConsumerState<CompulsionUrgePage> createState() =>
      _CompulsionUrgePageState();
}

class _CompulsionUrgePageState extends ConsumerState<CompulsionUrgePage> {
  int _level = 5;
  Timer? _timer;
  DateTime _now = DateTime.now();
  bool _saving = false;
  bool _urgeRecorded = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _recordUrge() async {
    setState(() => _saving = true);
    final session = await ref.read(repositoryProvider).getActiveSession();
    await ref
        .read(repositoryProvider)
        .recordUrge(_level, sessionId: session?.id);
    ref.invalidate(urgesProvider);
    if (mounted) {
      setState(() {
        _urgeRecorded = true;
        _saving = false;
      });
    }
  }

  Future<void> _startDelay(int minutes) async {
    setState(() => _saving = true);
    try {
      await ref.read(repositoryProvider).startDelay(
            minutes: minutes,
            urge: _level,
          );
      ref.invalidate(activeDelayProvider);
      if (mounted) setState(() => _urgeRecorded = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _finishDelay(CompulsionDelay delay, String result) async {
    await ref.read(repositoryProvider).finishDelay(delay.id, result);
    ref.invalidate(activeDelayProvider);
  }

  Future<void> _extendDelay(CompulsionDelay delay) async {
    await ref.read(repositoryProvider).extendDelay(delay.id, 5);
    ref.invalidate(activeDelayProvider);
  }

  @override
  Widget build(BuildContext context) {
    final activeDelay = ref.watch(activeDelayProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notice an urge')),
      body: activeDelay.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('The response delay is unavailable.')),
        data: (delay) => delay == null ? _buildUrgeForm() : _buildDelay(delay),
      ),
    );
  }

  Widget _buildUrgeForm() => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'You noticed an urge to check.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'You can observe the urge without needing to resolve the uncertainty immediately.',
          ),
          const SizedBox(height: 24),
          AbsorbPointer(
            absorbing: _urgeRecorded,
            child: RatingSlider(
              label: 'How strong is the urge?',
              value: _level,
              onChanged: (value) => setState(() => _level = value),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving || _urgeRecorded ? null : _recordUrge,
            child: Text(_urgeRecorded ? 'Urge recorded' : 'Record this urge'),
          ),
          if (_urgeRecorded) ...[
            const SizedBox(height: 20),
            Text('Choose what feels useful', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Observe the urge, or choose a response delay.'),
            for (final minutes in [5, 10, 20])
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton(
                  onPressed: _saving ? null : () => _startDelay(minutes),
                  child: Text('Delay response for $minutes minutes'),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue without responding'),
            ),
          ],
        ],
      );

  Widget _buildDelay(CompulsionDelay delay) {
    final remaining = delay.dueAt.difference(_now);
    final isOver = remaining <= Duration.zero;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Response delay', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text('You chose to delay the response.'),
                const SizedBox(height: 16),
                Text(
                  isOver ? '00:00' : _formatRemaining(remaining),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const Text('remaining'),
                const SizedBox(height: 16),
                Text('Current urge: ${delay.initialUrge} / 10'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!isOver)
          OutlinedButton(
            onPressed: () => _extendDelay(delay),
            child: const Text('Continue delay for 5 more minutes'),
          ),
        const SizedBox(height: 8),
        const Text('What happened? There is no right or wrong response.'),
        for (final result in [
          'Continued without performing the compulsion',
          'Delayed it longer',
          'Partially performed the compulsion',
          'Performed the compulsion',
        ])
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton(
              onPressed: () async {
                await _finishDelay(delay, result);
                if (mounted) Navigator.pop(context);
              },
              child: Text(result),
            ),
          ),
      ],
    );
  }
}

String _formatRemaining(Duration duration) {
  final seconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
}
