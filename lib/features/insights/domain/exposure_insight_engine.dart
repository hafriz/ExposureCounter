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

  double? _average(Iterable<int> values) {
    final list = values.toList();
    if (list.isEmpty) return null;
    return list.reduce((a, b) => a + b) / list.length;
  }
}
