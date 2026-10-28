import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/rating_slider.dart';

class CheckInPage extends ConsumerStatefulWidget {
  const CheckInPage({super.key});

  @override
  ConsumerState<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends ConsumerState<CheckInPage> {
  int _anxiety = 5;
  int _urge = 5;
  String _mood = 'Neutral';
  final _trigger = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _trigger.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(repositoryProvider).saveCheckIn(
            anxiety: _anxiety,
            compulsionUrge: _urge,
            mood: _mood,
            trigger: _trigger.text,
            note: _note.text,
          );
      ref.invalidate(checkInsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The check-in could not be saved.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Quick check-in')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Record what feels useful. You can leave the optional details blank.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            RatingSlider(
              label: 'Anxiety',
              value: _anxiety,
              onChanged: (value) => setState(() => _anxiety = value),
            ),
            const SizedBox(height: 16),
            RatingSlider(
              label: 'Compulsion urge',
              value: _urge,
              onChanged: (value) => setState(() => _urge = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _mood,
              decoration: const InputDecoration(labelText: 'Mood'),
              items: const [
                'Very Low',
                'Low',
                'Neutral',
                'Good',
                'Very Good',
              ]
                  .map((mood) =>
                      DropdownMenuItem(value: mood, child: Text(mood)))
                  .toList(),
              onChanged: (mood) {
                if (mood != null) setState(() => _mood = mood);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _trigger,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Trigger (optional)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Short note (optional)'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save check-in'),
            ),
          ],
        ),
      );
}
