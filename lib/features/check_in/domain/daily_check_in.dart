class DailyCheckIn {
  const DailyCheckIn({
    required this.id,
    required this.createdAt,
    required this.anxiety,
    required this.compulsionUrge,
    required this.mood,
    this.trigger,
    this.note,
  });

  final String id;
  final DateTime createdAt;
  final int anxiety;
  final int compulsionUrge;
  final String mood;
  final String? trigger;
  final String? note;

  Map<String, Object?> toMap() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'anxiety': anxiety,
        'compulsion_urge': compulsionUrge,
        'mood': mood,
        'trigger_text': trigger,
        'note': note,
      };

  factory DailyCheckIn.fromMap(Map<String, Object?> map) => DailyCheckIn(
        id: map['id']! as String,
        createdAt: DateTime.parse(map['created_at']! as String),
        anxiety: map['anxiety']! as int,
        compulsionUrge: map['compulsion_urge']! as int,
        mood: map['mood']! as String,
        trigger: map['trigger_text'] as String?,
        note: map['note'] as String?,
      );
}
