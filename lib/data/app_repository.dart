import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../features/check_in/domain/daily_check_in.dart';
import '../features/exposure/domain/exposure_models.dart';

class AppRepository {
  AppRepository({Database? database}) : _providedDatabase = database;

  static const _uuid = Uuid();
  final Database? _providedDatabase;
  Database? _database;

  Future<Database> get _db async {
    if (_providedDatabase != null) return _providedDatabase;
    return _database ??= await _openDatabase();
  }

  Future<Database> _openDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    return openDatabase(
      path.join(directory.path, 'exposure_companion.db'),
      version: 1,
      onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE daily_check_ins (
            id TEXT PRIMARY KEY,
            created_at TEXT NOT NULL,
            anxiety INTEGER NOT NULL CHECK(anxiety BETWEEN 0 AND 10),
            compulsion_urge INTEGER NOT NULL CHECK(compulsion_urge BETWEEN 0 AND 10),
            mood TEXT NOT NULL,
            trigger_text TEXT,
            note TEXT
          )
        ''');
        await database.execute(
          'CREATE INDEX check_ins_created_at ON daily_check_ins(created_at)',
        );
        await database.execute('''
          CREATE TABLE exposure_hierarchy_items (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            trigger_text TEXT NOT NULL,
            feared_outcome TEXT NOT NULL,
            prevention_plan TEXT NOT NULL,
            expected_anxiety INTEGER NOT NULL CHECK(expected_anxiety BETWEEN 0 AND 10),
            difficulty INTEGER NOT NULL CHECK(difficulty BETWEEN 0 AND 10),
            status TEXT NOT NULL,
            sort_order INTEGER NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE exposure_sessions (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            exposure_item_id TEXT,
            started_at TEXT NOT NULL,
            ended_at TEXT,
            starting_anxiety INTEGER NOT NULL CHECK(starting_anxiety BETWEEN 0 AND 10),
            starting_urge INTEGER NOT NULL CHECK(starting_urge BETWEEN 0 AND 10),
            ending_anxiety INTEGER,
            ending_urge INTEGER,
            response_result TEXT,
            difficulty INTEGER,
            reflection TEXT,
            FOREIGN KEY(exposure_item_id) REFERENCES exposure_hierarchy_items(id)
              ON DELETE SET NULL
          )
        ''');
        await database.execute(
          'CREATE INDEX sessions_started_at ON exposure_sessions(started_at)',
        );
        await database.execute('''
          CREATE TABLE exposure_measurements (
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            recorded_at TEXT NOT NULL,
            anxiety INTEGER NOT NULL CHECK(anxiety BETWEEN 0 AND 10),
            compulsion_urge INTEGER NOT NULL CHECK(compulsion_urge BETWEEN 0 AND 10),
            note TEXT,
            FOREIGN KEY(session_id) REFERENCES exposure_sessions(id)
              ON DELETE CASCADE
          )
        ''');
        await database.execute(
          'CREATE INDEX measurements_session ON exposure_measurements(session_id, recorded_at)',
        );
        await database.execute('''
          CREATE TABLE compulsion_urges (
            id TEXT PRIMARY KEY,
            recorded_at TEXT NOT NULL,
            level INTEGER NOT NULL CHECK(level BETWEEN 0 AND 10),
            session_id TEXT,
            FOREIGN KEY(session_id) REFERENCES exposure_sessions(id)
              ON DELETE SET NULL
          )
        ''');
        await database.execute(
          'CREATE INDEX urges_recorded_at ON compulsion_urges(recorded_at)',
        );
      },
    );
  }

  Future<List<DailyCheckIn>> getCheckIns() async {
    final rows = await (await _db).query(
      'daily_check_ins',
      orderBy: 'created_at DESC',
    );
    return rows.map(DailyCheckIn.fromMap).toList();
  }

  Future<void> saveCheckIn({
    required int anxiety,
    required int compulsionUrge,
    required String mood,
    String? trigger,
    String? note,
    String? id,
  }) async {
    final database = await _db;
    final checkIn = DailyCheckIn(
      id: id ?? _uuid.v4(),
      createdAt: DateTime.now(),
      anxiety: anxiety,
      compulsionUrge: compulsionUrge,
      mood: mood,
      trigger: _nullableText(trigger),
      note: _nullableText(note),
    );
    await database.insert(
      'daily_check_ins',
      checkIn.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCheckIn(String id) async {
    await (await _db).delete(
      'daily_check_ins',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ExposureHierarchyItem>> getExposureItems() async {
    final rows = await (await _db).query(
      'exposure_hierarchy_items',
      orderBy: 'difficulty, sort_order',
    );
    return rows.map(ExposureHierarchyItem.fromMap).toList();
  }

  Future<void> saveExposureItem({
    required String title,
    required String description,
    required String trigger,
    required String fearedOutcome,
    required String responsePreventionPlan,
    required int expectedAnxiety,
    required int difficulty,
  }) async {
    final database = await _db;
    final count = Sqflite.firstIntValue(await database.rawQuery(
          'SELECT COUNT(*) FROM exposure_hierarchy_items',
        )) ??
        0;
    final item = ExposureHierarchyItem(
      id: _uuid.v4(),
      title: title.trim(),
      description: description.trim(),
      trigger: trigger.trim(),
      fearedOutcome: fearedOutcome.trim(),
      responsePreventionPlan: responsePreventionPlan.trim(),
      expectedAnxiety: expectedAnxiety,
      difficulty: difficulty,
      status: 'Planned',
      sortOrder: count,
    );
    await database.insert('exposure_hierarchy_items', item.toMap());
  }

  Future<void> updateExposureStatus(String id, String status) async {
    await (await _db).update(
      'exposure_hierarchy_items',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> reorderExposureItems(int oldIndex, int newIndex) async {
    final database = await _db;
    final items = await getExposureItems();
    if (oldIndex < 0 ||
        oldIndex >= items.length ||
        newIndex < 0 ||
        newIndex >= items.length) {
      return;
    }
    final reordered = [...items];
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);
    await database.transaction((transaction) async {
      for (var index = 0; index < reordered.length; index++) {
        await transaction.update(
          'exposure_hierarchy_items',
          {'sort_order': index},
          where: 'id = ?',
          whereArgs: [reordered[index].id],
        );
      }
    });
  }

  Future<void> deleteExposureItem(String id) async {
    await (await _db).delete(
      'exposure_hierarchy_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<ExposureSession?> getActiveSession() async {
    final rows = await (await _db).query(
      'exposure_sessions',
      where: 'ended_at IS NULL',
      orderBy: 'started_at DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : ExposureSession.fromMap(rows.first);
  }

  Future<List<ExposureSession>> getSessions() async {
    final rows = await (await _db).query(
      'exposure_sessions',
      orderBy: 'started_at DESC',
    );
    return rows.map(ExposureSession.fromMap).toList();
  }

  Future<ExposureSession> startExposure({
    required String title,
    required int anxiety,
    required int compulsionUrge,
    String? exposureItemId,
  }) async {
    final database = await _db;
    final active = await getActiveSession();
    if (active != null) {
      throw StateError('An exposure session is already active.');
    }
    final now = DateTime.now();
    final session = ExposureSession(
      id: _uuid.v4(),
      title: title,
      exposureItemId: exposureItemId,
      startedAt: now,
      startingAnxiety: anxiety,
      startingUrge: compulsionUrge,
    );
    await database.transaction((transaction) async {
      await transaction.insert('exposure_sessions', session.toMap());
      await transaction.insert(
        'exposure_measurements',
        ExposureMeasurement(
          id: _uuid.v4(),
          sessionId: session.id,
          recordedAt: now,
          anxiety: anxiety,
          compulsionUrge: compulsionUrge,
        ).toMap(),
      );
    });
    return session;
  }

  Future<List<ExposureMeasurement>> getMeasurements(String sessionId) async {
    final rows = await (await _db).query(
      'exposure_measurements',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'recorded_at',
    );
    return rows.map(ExposureMeasurement.fromMap).toList();
  }

  Future<void> recordMeasurement({
    required String sessionId,
    required int anxiety,
    required int compulsionUrge,
    String? note,
  }) async {
    final database = await _db;
    final session = await database.query(
      'exposure_sessions',
      columns: ['ended_at'],
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (session.isEmpty || session.first['ended_at'] != null) {
      throw StateError('Measurements can only be recorded during an active exposure.');
    }
    await database.insert(
      'exposure_measurements',
      ExposureMeasurement(
        id: _uuid.v4(),
        sessionId: sessionId,
        recordedAt: DateTime.now(),
        anxiety: anxiety,
        compulsionUrge: compulsionUrge,
        note: _nullableText(note),
      ).toMap(),
    );
  }

  Future<void> endExposure({
    required String sessionId,
    required int anxiety,
    required int compulsionUrge,
    required String responseResult,
    required int difficulty,
    String? reflection,
  }) async {
    final database = await _db;
    final now = DateTime.now();
    await database.transaction((transaction) async {
      final changed = await transaction.update(
        'exposure_sessions',
        {
          'ended_at': now.toIso8601String(),
          'ending_anxiety': anxiety,
          'ending_urge': compulsionUrge,
          'response_result': responseResult,
          'difficulty': difficulty,
          'reflection': _nullableText(reflection),
        },
        where: 'id = ? AND ended_at IS NULL',
        whereArgs: [sessionId],
      );
      if (changed == 0) throw StateError('This exposure session has ended.');
      await transaction.insert(
        'exposure_measurements',
        ExposureMeasurement(
          id: _uuid.v4(),
          sessionId: sessionId,
          recordedAt: now,
          anxiety: anxiety,
          compulsionUrge: compulsionUrge,
        ).toMap(),
      );
    });
  }

  Future<List<CompulsionUrge>> getUrges() async {
    final rows = await (await _db).query(
      'compulsion_urges',
      orderBy: 'recorded_at DESC',
    );
    return rows.map(CompulsionUrge.fromMap).toList();
  }

  Future<void> recordUrge(int level, {String? sessionId}) async {
    await (await _db).insert(
      'compulsion_urges',
      CompulsionUrge(
        id: _uuid.v4(),
        recordedAt: DateTime.now(),
        level: level,
        sessionId: sessionId,
      ).toMap(),
    );
  }

  Future<void> deleteAllData() async {
    final database = await _db;
    await database.transaction((transaction) async {
      await transaction.delete('compulsion_urges');
      await transaction.delete('exposure_measurements');
      await transaction.delete('exposure_sessions');
      await transaction.delete('exposure_hierarchy_items');
      await transaction.delete('daily_check_ins');
    });
  }

  Future<String> exportCsv() async {
    final checkIns = await getCheckIns();
    final sessions = await getSessions();
    final urges = await getUrges();
    final rows = <List<Object?>>[
      ['Record type', 'Recorded at', 'Title', 'Anxiety', 'Compulsion urge', 'Result', 'Reflection'],
      ...checkIns.map((entry) => [
            'Daily check-in',
            entry.createdAt.toIso8601String(),
            entry.mood,
            entry.anxiety,
            entry.compulsionUrge,
            entry.trigger ?? '',
            entry.note ?? '',
          ]),
      ...sessions.map((entry) => [
            'Exposure session',
            entry.startedAt.toIso8601String(),
            entry.title,
            entry.startingAnxiety,
            entry.startingUrge,
            entry.responseResult ?? 'In progress',
            entry.reflection ?? '',
          ]),
      ...urges.map((entry) => [
            'Compulsion urge',
            entry.recordedAt.toIso8601String(),
            '',
            '',
            entry.level,
            '',
            '',
          ]),
    ];
    return rows.map((row) => row.map(_escapeCsv).join(',')).join('\r\n');
  }

  Future<void> close() async {
    if (_providedDatabase == null) {
      await _database?.close();
      _database = null;
    }
  }

  static String? _nullableText(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String _escapeCsv(Object? value) {
    final text = '$value';
    return '"${text.replaceAll('"', '""')}"';
  }
}
