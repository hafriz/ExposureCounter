import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../check_in/domain/daily_check_in.dart';
import '../domain/exposure_insight_engine.dart' as insight_domain;

class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  insight_domain.DateTimeRange? _selectedRange;
  final _dateFormat = DateFormat.yMd();

  String _rangeLabel() {
    if (_selectedRange == null) {
      return 'All time';
    }
    final start = _dateFormat.format(_selectedRange!.start);
    final end = _dateFormat.format(_selectedRange!.end);
    if (start == end) {
      return start;
    }
    return '$start – $end';
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final firstDate = DateTime(2000);
    final lastDate = DateTime(now.year, now.month, now.day);
    final initialRange = _selectedRange ??
        insight_domain.DateTimeRange(
          start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30)),
          end: lastDate,
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: pickedDateRange(initialRange),
      helpText: 'Select date range',
      cancelText: 'Cancel',
      confirmText: 'Apply',
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _selectedRange = insight_domain.DateTimeRange(
        start: picked.start,
        end: picked.end,
      );
    });
  }

  DateTimeRange pickedDateRange(insight_domain.DateTimeRange range) {
    return DateTimeRange(start: range.start, end: range.end);
  }

  void _clearRange() {
    setState(() {
      _selectedRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final checkIns = ref.watch(checkInsProvider);
    final sessions = ref.watch(sessionsProvider);
    final engine = insight_domain.ExposureInsightEngine();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Recorded patterns', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'These summaries describe records on this device and are not clinical interpretations.',
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date range',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(_rangeLabel()),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickRange,
                  icon: const Icon(Icons.date_range_outlined),
                  label: const Text('Filter'),
                ),
                if (_selectedRange != null)
                  TextButton(
                    onPressed: _clearRange,
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        checkIns.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, stack) => const Text('Check-in insights are unavailable.'),
          data: (items) {
            final filtered = engine.filterCheckInsByDateRange(items, _selectedRange);
            final anxiety = engine.averageAnxiety(filtered);
            final urge = engine.averageCompulsionUrge(filtered);
            return Column(
              children: [
                _MetricCard(
                  title: 'Average recorded anxiety',
                  value: anxiety == null ? '—' : '${anxiety.toStringAsFixed(1)} / 10',
                ),
                _MetricCard(
                  title: 'Average recorded compulsion urge',
                  value: urge == null ? '—' : '${urge.toStringAsFixed(1)} / 10',
                ),
                if (filtered.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _AnxietyChart(items: filtered.take(14).toList().reversed.toList()),
                ] else if (_selectedRange != null) ...[
                  const SizedBox(height: 8),
                  const Text('No check-ins in the selected date range.'),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        sessions.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, stack) => const Text('Exposure insights are unavailable.'),
          data: (items) {
            final filtered = engine.filterSessionsByDateRange(items, _selectedRange);
            final completed = filtered.where((entry) => entry.endedAt != null);
            final prevented = engine.responsesPrevented(filtered);
            final minutes = engine.totalPracticeTime(filtered).inMinutes;
            return Column(
              children: [
                _MetricCard(
                  title: 'Exposure sessions completed',
                  value: '${completed.length}',
                ),
                _MetricCard(
                  title: 'Total exposure practice time',
                  value: '$minutes min',
                ),
                _MetricCard(
                  title: 'Responses prevented',
                  value: '$prevented',
                ),
                if (filtered.isEmpty && _selectedRange != null) ...[
                  const SizedBox(height: 8),
                  const Text('No exposure sessions in the selected date range.'),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          title: Text(title),
          trailing: Text(
            value,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      );
}

class _AnxietyChart extends StatelessWidget {
  const _AnxietyChart({required this.items});

  final List<DailyCheckIn> items;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recent recorded anxiety', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              SizedBox(
                height: 190,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 10,
                    gridData: const FlGridData(show: true),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval:
                              items.length > 4 ? (items.length / 3).ceilToDouble() : 1.0,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= items.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat.Md().format(items[index].createdAt),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: false,
                        color: Theme.of(context).colorScheme.primary,
                        dotData: const FlDotData(show: true),
                        spots: [
                          for (var index = 0; index < items.length; index++)
                            FlSpot(index.toDouble(), items[index].anxiety.toDouble()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text('Each point is a saved check-in, not continuous monitoring.'),
            ],
          ),
        ),
      );
}
