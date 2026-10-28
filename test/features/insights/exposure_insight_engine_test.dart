import 'package:exposure_counter/features/check_in/domain/daily_check_in.dart';
import 'package:exposure_counter/features/exposure/domain/exposure_models.dart';
import 'package:exposure_counter/features/insights/domain/exposure_insight_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = ExposureInsightEngine();

  group('recorded check-in summaries', () {
    test('calculates averages from saved check-ins', () {
      final checkIns = [
        _checkIn('first', 4, 6),
        _checkIn('second', 8, 2),
      ];

      expect(engine.averageAnxiety(checkIns), 6);
      expect(engine.averageCompulsionUrge(checkIns), 4);
    });

    test('returns no average when there are no records', () {
      expect(engine.averageAnxiety([]), isNull);
      expect(engine.averageCompulsionUrge([]), isNull);
    });
  });

  group('exposure summaries', () {
    test('counts prevented responses and sums completed practice time', () {
      final sessions = [
        _session(
          id: 'completed',
          startedAt: DateTime(2026, 1, 1, 10),
          endedAt: DateTime(2026, 1, 1, 10, 25),
          responseResult: 'No',
        ),
        _session(
          id: 'active',
          startedAt: DateTime(2026, 1, 1, 11),
          responseResult: null,
        ),
      ];

      expect(engine.responsesPrevented(sessions), 1);
      expect(engine.totalPracticeTime(sessions), const Duration(minutes: 25));
    });
  });
}

DailyCheckIn _checkIn(String id, int anxiety, int urge) => DailyCheckIn(
      id: id,
      createdAt: DateTime(2026, 1, 1),
      anxiety: anxiety,
      compulsionUrge: urge,
      mood: 'Neutral',
    );

ExposureSession _session({
  required String id,
  required DateTime startedAt,
  DateTime? endedAt,
  required String? responseResult,
}) =>
    ExposureSession(
      id: id,
      title: 'Practice',
      startedAt: startedAt,
      endedAt: endedAt,
      startingAnxiety: 5,
      startingUrge: 5,
      responseResult: responseResult,
    );
