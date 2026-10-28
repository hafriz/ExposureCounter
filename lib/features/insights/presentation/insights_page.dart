import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../check_in/domain/daily_check_in.dart';
import '../domain/exposure_insight_engine.dart';

class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkIns = ref.watch(checkInsProvider);
    final sessions = ref.watch(sessionsProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Recorded patterns', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'These summaries describe records on this device and are not clinical interpretations.',
        ),
        const SizedBox(height: 16),
        checkIns.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, stack) => const Text('Check-in insights are unavailable.'),
          data: (items) {
            final engine = const ExposureInsightEngine();
            final anxiety = engine.averageAnxiety(items);
            final urge = engine.averageCompulsionUrge(items);
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
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _AnxietyChart(items: items.take(14).toList().reversed.toList()),
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
            final engine = const ExposureInsightEngine();
            final completed = items.where((entry) => entry.endedAt != null);
            final prevented = engine.responsesPrevented(items);
            final minutes = engine.totalPracticeTime(items).inMinutes;
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
