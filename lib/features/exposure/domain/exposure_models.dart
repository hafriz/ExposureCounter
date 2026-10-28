class ExposureHierarchyItem {
  const ExposureHierarchyItem({
    required this.id,
    required this.title,
    required this.description,
    required this.trigger,
    required this.fearedOutcome,
    required this.responsePreventionPlan,
    required this.expectedAnxiety,
    required this.difficulty,
    required this.status,
    required this.sortOrder,
  });

  final String id;
  final String title;
  final String description;
  final String trigger;
  final String fearedOutcome;
  final String responsePreventionPlan;
  final int expectedAnxiety;
  final int difficulty;
  final String status;
  final int sortOrder;

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'trigger_text': trigger,
        'feared_outcome': fearedOutcome,
        'prevention_plan': responsePreventionPlan,
        'expected_anxiety': expectedAnxiety,
        'difficulty': difficulty,
        'status': status,
        'sort_order': sortOrder,
      };

  factory ExposureHierarchyItem.fromMap(Map<String, Object?> map) =>
      ExposureHierarchyItem(
        id: map['id']! as String,
        title: map['title']! as String,
        description: map['description']! as String,
        trigger: map['trigger_text']! as String,
        fearedOutcome: map['feared_outcome']! as String,
        responsePreventionPlan: map['prevention_plan']! as String,
        expectedAnxiety: map['expected_anxiety']! as int,
        difficulty: map['difficulty']! as int,
        status: map['status']! as String,
        sortOrder: map['sort_order']! as int,
      );
}

class ExposureSession {
  const ExposureSession({
    required this.id,
    required this.title,
    required this.startedAt,
    required this.startingAnxiety,
    required this.startingUrge,
    this.exposureItemId,
    this.endedAt,
    this.endingAnxiety,
    this.endingUrge,
    this.responseResult,
    this.difficulty,
    this.reflection,
  });

  final String id;
  final String title;
  final DateTime startedAt;
  final int startingAnxiety;
  final int startingUrge;
  final String? exposureItemId;
  final DateTime? endedAt;
  final int? endingAnxiety;
  final int? endingUrge;
  final String? responseResult;
  final int? difficulty;
  final String? reflection;

  Duration get duration => (endedAt ?? DateTime.now()).difference(startedAt);

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'exposure_item_id': exposureItemId,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'starting_anxiety': startingAnxiety,
        'starting_urge': startingUrge,
        'ending_anxiety': endingAnxiety,
        'ending_urge': endingUrge,
        'response_result': responseResult,
        'difficulty': difficulty,
        'reflection': reflection,
      };

  factory ExposureSession.fromMap(Map<String, Object?> map) => ExposureSession(
        id: map['id']! as String,
        title: map['title']! as String,
        exposureItemId: map['exposure_item_id'] as String?,
        startedAt: DateTime.parse(map['started_at']! as String),
        endedAt: map['ended_at'] == null
            ? null
            : DateTime.parse(map['ended_at']! as String),
        startingAnxiety: map['starting_anxiety']! as int,
        startingUrge: map['starting_urge']! as int,
        endingAnxiety: map['ending_anxiety'] as int?,
        endingUrge: map['ending_urge'] as int?,
        responseResult: map['response_result'] as String?,
        difficulty: map['difficulty'] as int?,
        reflection: map['reflection'] as String?,
      );
}

class ExposureMeasurement {
  const ExposureMeasurement({
    required this.id,
    required this.sessionId,
    required this.recordedAt,
    required this.anxiety,
    required this.compulsionUrge,
    this.note,
  });

  final String id;
  final String sessionId;
  final DateTime recordedAt;
  final int anxiety;
  final int compulsionUrge;
  final String? note;

  Map<String, Object?> toMap() => {
        'id': id,
        'session_id': sessionId,
        'recorded_at': recordedAt.toIso8601String(),
        'anxiety': anxiety,
        'compulsion_urge': compulsionUrge,
        'note': note,
      };

  factory ExposureMeasurement.fromMap(Map<String, Object?> map) =>
      ExposureMeasurement(
        id: map['id']! as String,
        sessionId: map['session_id']! as String,
        recordedAt: DateTime.parse(map['recorded_at']! as String),
        anxiety: map['anxiety']! as int,
        compulsionUrge: map['compulsion_urge']! as int,
        note: map['note'] as String?,
      );
}

class CompulsionUrge {
  const CompulsionUrge({
    required this.id,
    required this.recordedAt,
    required this.level,
    this.sessionId,
  });

  final String id;
  final DateTime recordedAt;
  final int level;
  final String? sessionId;

  Map<String, Object?> toMap() => {
        'id': id,
        'recorded_at': recordedAt.toIso8601String(),
        'level': level,
        'session_id': sessionId,
      };

  factory CompulsionUrge.fromMap(Map<String, Object?> map) => CompulsionUrge(
        id: map['id']! as String,
        recordedAt: DateTime.parse(map['recorded_at']! as String),
        level: map['level']! as int,
        sessionId: map['session_id'] as String?,
      );
}

class CompulsionDelay {
  const CompulsionDelay({
    required this.id,
    required this.startedAt,
    required this.durationMinutes,
    required this.initialUrge,
    this.sessionId,
    this.endedAt,
    this.result,
  });

  final String id;
  final DateTime startedAt;
  final int durationMinutes;
  final int initialUrge;
  final String? sessionId;
  final DateTime? endedAt;
  final String? result;

  DateTime get dueAt => startedAt.add(Duration(minutes: durationMinutes));
  Duration get remaining => dueAt.difference(DateTime.now());

  Map<String, Object?> toMap() => {
        'id': id,
        'started_at': startedAt.toIso8601String(),
        'duration_minutes': durationMinutes,
        'initial_urge': initialUrge,
        'session_id': sessionId,
        'ended_at': endedAt?.toIso8601String(),
        'result': result,
      };

  factory CompulsionDelay.fromMap(Map<String, Object?> map) => CompulsionDelay(
        id: map['id']! as String,
        startedAt: DateTime.parse(map['started_at']! as String),
        durationMinutes: map['duration_minutes']! as int,
        initialUrge: map['initial_urge']! as int,
        sessionId: map['session_id'] as String?,
        endedAt: map['ended_at'] == null
            ? null
            : DateTime.parse(map['ended_at']! as String),
        result: map['result'] as String?,
      );
}
