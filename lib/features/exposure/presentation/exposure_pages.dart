import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/rating_slider.dart';
import '../domain/exposure_models.dart';

class ExposureListPage extends ConsumerWidget {
  const ExposureListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(exposureItemsProvider);
    return items.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          const Center(child: Text('Exposure hierarchy is unavailable.')),
      data: (entries) => entries.isEmpty
          ? _EmptyExposureList(onCreate: () => context.push('/exposure/new'))
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: entries.length,
              onReorder: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex--;
                await ref
                    .read(repositoryProvider)
                    .reorderExposureItems(oldIndex, newIndex);
                ref.invalidate(exposureItemsProvider);
              },
              itemBuilder: (context, index) {
                final item = entries[index];
                return Card(
                  key: ValueKey(item.id),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Change exposure status',
                              initialValue: item.status,
                              onSelected: (status) async {
                                if (status == 'DELETE') {
                                  await ref
                                      .read(repositoryProvider)
                                      .deleteExposureItem(item.id);
                                  ref.invalidate(exposureItemsProvider);
                                  return;
                                }
                                await ref
                                    .read(repositoryProvider)
                                    .updateExposureStatus(item.id, status);
                                ref.invalidate(exposureItemsProvider);
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'Planned',
                                  child: Text('Planned'),
                                ),
                                PopupMenuItem(
                                  value: 'Active',
                                  child: Text('Active'),
                                ),
                                PopupMenuItem(
                                  value: 'Practicing',
                                  child: Text('Practicing'),
                                ),
                                PopupMenuItem(
                                  value: 'Mastered',
                                  child: Text('Mastered'),
                                ),
                                PopupMenuItem(
                                  value: 'Paused',
                                  child: Text('Paused'),
                                ),
                                PopupMenuItem(
                                  value: 'DELETE',
                                  child: Text('Delete exposure'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(item.description),
                        const SizedBox(height: 8),
                        Text(
                          'Difficulty ${item.difficulty} / 10 · ${item.status}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.tonal(
                            onPressed: () =>
                                context.push('/exposure/start/${item.id}'),
                            child: const Text('Start exposure'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _EmptyExposureList extends StatelessWidget {
  const _EmptyExposureList({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flag_outlined, size: 48),
              const SizedBox(height: 12),
              Text(
                'Your exposure hierarchy is ready when you are.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Add a practice in your own words. You can start with something manageable.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onCreate,
                child: const Text('Create an exposure'),
              ),
            ],
          ),
        ),
      );
}

class ExposureFormPage extends ConsumerStatefulWidget {
  const ExposureFormPage({super.key});

  @override
  ConsumerState<ExposureFormPage> createState() => _ExposureFormPageState();
}

class _ExposureFormPageState extends ConsumerState<ExposureFormPage> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _trigger = TextEditingController();
  final _fearedOutcome = TextEditingController();
  final _plan = TextEditingController();
  int _anxiety = 5;
  int _difficulty = 5;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _trigger.dispose();
    _fearedOutcome.dispose();
    _plan.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a title for this exposure.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(repositoryProvider).saveExposureItem(
            title: _title.text,
            description: _description.text,
            trigger: _trigger.text,
            fearedOutcome: _fearedOutcome.text,
            responsePreventionPlan: _plan.text,
            expectedAnxiety: _anxiety,
            difficulty: _difficulty,
          );
      ref.invalidate(exposureItemsProvider);
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Create exposure')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _TextEntry(controller: _title, label: 'Title', requiredField: true),
            _TextEntry(controller: _description, label: 'Description'),
            _TextEntry(controller: _trigger, label: 'Trigger'),
            _TextEntry(controller: _fearedOutcome, label: 'Feared outcome'),
            _TextEntry(
              controller: _plan,
              label: 'Response prevention plan',
            ),
            const SizedBox(height: 12),
            RatingSlider(
              label: 'Expected anxiety',
              value: _anxiety,
              onChanged: (value) => setState(() => _anxiety = value),
            ),
            RatingSlider(
              label: 'Difficulty',
              value: _difficulty,
              onChanged: (value) => setState(() => _difficulty = value),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save exposure'),
            ),
          ],
        ),
      );
}

class _TextEntry extends StatelessWidget {
  const _TextEntry({
    required this.controller,
    required this.label,
    this.requiredField = false,
  });

  final TextEditingController controller;
  final String label;
  final bool requiredField;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: requiredField ? '$label *' : '$label (optional)',
          ),
          maxLines: label == 'Title' ? 1 : 2,
        ),
      );
}

class ExposureStartPage extends ConsumerStatefulWidget {
  const ExposureStartPage({required this.itemId, super.key});

  final String itemId;

  @override
  ConsumerState<ExposureStartPage> createState() => _ExposureStartPageState();
}

class _ExposureStartPageState extends ConsumerState<ExposureStartPage> {
  int _anxiety = 5;
  int _urge = 5;
  bool _starting = false;

  Future<void> _start(ExposureHierarchyItem item) async {
    setState(() => _starting = true);
    try {
      final session = await ref.read(repositoryProvider).startExposure(
            title: item.title,
            exposureItemId: item.id,
            anxiety: _anxiety,
            compulsionUrge: _urge,
          );
      ref
        ..invalidate(activeSessionProvider)
        ..invalidate(sessionsProvider)
        ..invalidate(exposureItemsProvider);
      if (mounted) context.go('/session/${session.id}');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An exposure session may already be in progress.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(exposureItemsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Start exposure')),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('This exposure is unavailable.')),
        data: (entries) {
          final matches = entries.where((item) => item.id == widget.itemId);
          if (matches.isEmpty) {
            return const Center(child: Text('This exposure is no longer available.'));
          }
          final item = matches.first;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              _DetailLine(label: 'Trigger', value: item.trigger),
              _DetailLine(label: 'Feared outcome', value: item.fearedOutcome),
              _DetailLine(
                label: 'Response prevention goal',
                value: item.responsePreventionPlan,
              ),
              const SizedBox(height: 16),
              RatingSlider(
                label: 'How strong is your anxiety right now?',
                value: _anxiety,
                onChanged: (value) => setState(() => _anxiety = value),
              ),
              RatingSlider(
                label: 'How strong is your urge to perform the compulsion?',
                value: _urge,
                onChanged: (value) => setState(() => _urge = value),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _starting ? null : () => _start(item),
                child: Text(_starting ? 'Starting…' : 'Start exposure'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 2),
            Text(value.isEmpty ? 'Not recorded' : value),
          ],
        ),
      );
}

class ExposureSessionPage extends ConsumerStatefulWidget {
  const ExposureSessionPage({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<ExposureSessionPage> createState() =>
      _ExposureSessionPageState();
}

class _ExposureSessionPageState extends ConsumerState<ExposureSessionPage> {
  Timer? _timer;
  DateTime _now = DateTime.now();

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

  Future<void> _recordMeasurement() async {
    var anxiety = 5;
    var urge = 5;
    final values = await showDialog<(int, int)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Record how you feel'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingSlider(
                label: 'Anxiety',
                value: anxiety,
                onChanged: (value) => setDialogState(() => anxiety = value),
              ),
              RatingSlider(
                label: 'Compulsion urge',
                value: urge,
                onChanged: (value) => setDialogState(() => urge = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, (anxiety, urge)),
              child: const Text('Save measurement'),
            ),
          ],
        ),
      ),
    );
    if (values == null) return;
    await ref.read(repositoryProvider).recordMeasurement(
          sessionId: widget.sessionId,
          anxiety: values.$1,
          compulsionUrge: values.$2,
        );
    ref.invalidate(measurementsProvider(widget.sessionId));
  }

  Future<void> _endSession() async {
    final result = await showDialog<_SessionEndValues>(
      context: context,
      builder: (context) => const _EndSessionDialog(),
    );
    if (result == null) return;
    await ref.read(repositoryProvider).endExposure(
          sessionId: widget.sessionId,
          anxiety: result.anxiety,
          compulsionUrge: result.urge,
          responseResult: result.responseResult,
          difficulty: result.difficulty,
          reflection: result.reflection,
        );
    ref
      ..invalidate(activeSessionProvider)
      ..invalidate(sessionsProvider)
      ..invalidate(measurementsProvider(widget.sessionId));
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionsProvider);
    final measurements = ref.watch(measurementsProvider(widget.sessionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Exposure in progress')),
      body: sessions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('This exposure session is unavailable.')),
        data: (entries) {
          final matches = entries.where((entry) => entry.id == widget.sessionId);
          if (matches.isEmpty) {
            return const Center(child: Text('This exposure session is unavailable.'));
          }
          final session = matches.first;
          final elapsed = (session.endedAt ?? _now).difference(session.startedAt);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(session.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        _formatDuration(elapsed),
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const Text('Elapsed time'),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _SessionScore(
                            label: 'Anxiety',
                            value: measurements.valueOrNull?.lastOrNull?.anxiety ??
                                session.startingAnxiety,
                          ),
                          _SessionScore(
                            label: 'Compulsion urge',
                            value: measurements.valueOrNull?.lastOrNull
                                    ?.compulsionUrge ??
                                session.startingUrge,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _recordMeasurement,
                icon: const Icon(Icons.edit_note),
                label: const Text('Record how I feel'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push('/urge'),
                icon: const Icon(Icons.touch_app_outlined),
                label: const Text('I feel an urge'),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: session.endedAt == null ? _endSession : null,
                child: const Text('End exposure'),
              ),
              const SizedBox(height: 20),
              Text(
                'Measurements are optional. You can focus on the practice without recording every change.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SessionScore extends StatelessWidget {
  const _SessionScore({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(label),
          Text('$value / 10', style: Theme.of(context).textTheme.titleLarge),
        ],
      );
}

class _SessionEndValues {
  const _SessionEndValues({
    required this.anxiety,
    required this.urge,
    required this.responseResult,
    required this.difficulty,
    required this.reflection,
  });

  final int anxiety;
  final int urge;
  final String responseResult;
  final int difficulty;
  final String? reflection;
}

class _EndSessionDialog extends StatefulWidget {
  const _EndSessionDialog();

  @override
  State<_EndSessionDialog> createState() => _EndSessionDialogState();
}

class _EndSessionDialogState extends State<_EndSessionDialog> {
  int _anxiety = 5;
  int _urge = 5;
  int _difficulty = 5;
  String _responseResult = 'No';
  final _reflection = TextEditingController();

  @override
  void dispose() {
    _reflection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('End exposure'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingSlider(
                label: 'Anxiety now',
                value: _anxiety,
                onChanged: (value) => setState(() => _anxiety = value),
              ),
              RatingSlider(
                label: 'Compulsion urge now',
                value: _urge,
                onChanged: (value) => setState(() => _urge = value),
              ),
              DropdownButtonFormField<String>(
                value: _responseResult,
                decoration: const InputDecoration(
                  labelText: 'Did you perform the compulsion?',
                ),
                items: const ['No', 'Partially', 'Yes']
                    .map((result) => DropdownMenuItem(
                          value: result,
                          child: Text(result),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _responseResult = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              RatingSlider(
                label: 'How difficult was it?',
                value: _difficulty,
                onChanged: (value) => setState(() => _difficulty = value),
              ),
              TextField(
                controller: _reflection,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'What did you notice? (optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue practicing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              _SessionEndValues(
                anxiety: _anxiety,
                urge: _urge,
                responseResult: _responseResult,
                difficulty: _difficulty,
                reflection: _reflection.text,
              ),
            ),
            child: const Text('Save exposure'),
          ),
        ],
      );
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60);
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
