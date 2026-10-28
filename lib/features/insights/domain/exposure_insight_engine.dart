import '../../check_in/domain/daily_check_in.dart';
import '../../exposure/domain/exposure_models.dart';

class ExposureInsightEngine {
  const ExposureInsightEngine();

  double? averageAnxiety(List<DailyCheckIn> checkIns) =>
      _average(checkIns.map((entry) => entry.anxiety));

  double? averageCompulsionUrge(List<DailyCheckIn> checkIns) =>
      _average(checkIns.map((entry) => entry.compulsionUrge));

  Duration totalPracticeTime(List<ExposureSession> sessions) {
    final completed = sessions.where((session) => session.endedAt != null);
    return completed.fold(
      Duration.zero,
      (total, session) => total + session.duration,
    );
  }

  int responsesPrevented(List<ExposureSession> sessions) => sessions
      .where((session) => session.responseResult == 'No')
      .length;

  List<DailyCheckIn> filterCheckInsByDateRange(
    List<DailyCheckIn> checkIns,
    DateTimeRange? range,
  ) {
    if (range == null) {
      return checkIns;
    }
    final start = _startOfDay(range.start);
    final end = _endOfDay(range.end);
    return checkIns.where((entry) {
      final created = entry.createdAt;
      return !created.isBefore(start) && !created.isAfter(end);
    }).toList();
  }

  List<ExposureSession> filterSessionsByDateRange(
    List<ExposureSession> sessions,
    DateTimeRange? range,
  ) {
    if (range == null) {
      return sessions;
    }
    final start = _startOfDay(range.start);
    final end = _endOfDay(range.end);
    return sessions.where((session) {
      final started = session.startedAt;
      return !started.isBefore(start) && !started.isAfter(end);
    }).toList();
  }

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999, 999);

  double? _average(Iterable<int> values) {
    final list = values.toList();
    if (list.isEmpty) return null;
    return list.reduce((a, b) => a + b) / list.length;
  }
}

class DateTimeRange {
  const DateTimeRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}
