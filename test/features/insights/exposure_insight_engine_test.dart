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

  group('date range filtering', () {
    test('returns all items when range is null (default/all-time behavior)', () {
      final checkIns = [
        _checkInAt('first', DateTime(2026, 1, 1), 4, 6),
        _checkInAt('second', DateTime(2026, 1, 15), 8, 2),
      ];
      final sessions = [
        _sessionAt(
          id: 's1',
          startedAt: DateTime(2026, 1, 5),
          endedAt: DateTime(2026, 1, 5, 10),
          responseResult: 'No',
        ),
        _sessionAt(
          id: 's2',
          startedAt: DateTime(2026, 2, 1),
          responseResult: 'Yes',
        ),
      ];

      expect(engine.filterCheckInsByDateRange(checkIns, null), checkIns);
      expect(engine.filterSessionsByDateRange(sessions, null), sessions);
    });

    test('filters check-ins and sessions inclusively by date range', () {
      final checkIns = [
        _checkInAt('early', DateTime(2025, 12, 31, 23, 59), 1, 1),
        _checkInAt('start', DateTime(2026, 1, 1, 0, 0), 4, 6),
        _checkInAt('middle', DateTime(2026, 1, 15, 12, 0), 8, 2),
        _checkInAt('end', DateTime(2026, 1, 31, 23, 59, 59, 999), 5, 3),
        _checkInAt('late', DateTime(2026, 2, 1, 0, 0), 2, 2),
      ];
      final sessions = [
        _sessionAt(
          id: 'before',
          startedAt: DateTime(2025, 12, 31, 22, 0),
          responseResult: 'No',
        ),
        _sessionAt(
          id: 'start',
          startedAt: DateTime(2026, 1, 1, 1, 0),
          endedAt: DateTime(2026, 1, 1, 1, 10),
          responseResult: 'No',
        ),
        _sessionAt(
          id: 'end',
          startedAt: DateTime(2026, 1, 31, 23, 0),
          responseResult: 'Yes',
        ),
        _sessionAt(
          id: 'after',
          startedAt: DateTime(2026, 2, 1, 1, 0),
          responseResult: 'No',
        ),
      ];
      final range = DateTimeRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31),
      );

      final filteredCheckIns = engine.filterCheckInsByDateRange(checkIns, range);
      final filteredSessions = engine.filterSessionsByDateRange(sessions, range);

      expect(filteredCheckIns.map((e) => e.id), ['start', 'middle', 'end']);
      expect(filteredSessions.map((e) => e.id), ['start', 'end']);
    });

    test('handles empty result gracefully when no records fall in range', () {
      final checkIns = [_checkInAt('x', DateTime(2026, 1, 1), 5, 5)];
      final sessions = [
        _sessionAt(id: 's', startedAt: DateTime(2026, 1, 1), responseResult: 'No'),
      ];
      final range = DateTimeRange(
        start: DateTime(2026, 2, 1),
        end: DateTime(2026, 2, 28),
      );

      expect(engine.filterCheckInsByDateRange(checkIns, range), isEmpty);
      expect(engine.filterSessionsByDateRange(sessions, range), isEmpty);
      expect(engine.averageAnxiety(engine.filterCheckInsByDateRange(checkIns, range)), isNull);
      expect(engine.responsesPrevented(engine.filterSessionsByDateRange(sessions, range)), 0);
      expect(engine.totalPracticeTime(engine.filterSessionsByDateRange(sessions, range)), Duration.zero);
    });
  });
}

DailyCheckIn _checkIn(String id, int anxiety, int urge) =>
    _checkInAt(id, DateTime(2026, 1, 1), anxiety, urge);

DailyCheckIn _checkInAt(String id, DateTime createdAt, int anxiety, int urge) =>
    DailyCheckIn(
      id: id,
      createdAt: createdAt,
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
    _sessionAt(
      id: id,
      startedAt: startedAt,
      endedAt: endedAt,
      responseResult: responseResult,
    );

ExposureSession _sessionAt({
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
