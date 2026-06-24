import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:strola_health/data/datasources/local_database.dart';
import 'package:strola_health/domain/entities/workout_session.dart';

class SessionRepository {
  Future<void> saveSession(WorkoutSession session) async {
    final db = await LocalDatabase.instance;
    await db.insert(
      'workout_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Upsert today's cumulative step total for the calendar heat-map
    final dateKey = _dateKey(session.startTime);
    final existing = await db.query(
      'daily_steps',
      where: 'date = ?',
      whereArgs: [dateKey],
    );
    if (existing.isEmpty) {
      await db.insert('daily_steps', {'date': dateKey, 'steps': session.steps});
    } else {
      await db.rawUpdate(
        'UPDATE daily_steps SET steps = steps + ? WHERE date = ?',
        [session.steps, dateKey],
      );
    }
  }

  Future<List<WorkoutSession>> getSessions({int limit = 50}) async {
    final db = await LocalDatabase.instance;
    final rows = await db.query(
      'workout_sessions',
      orderBy: 'start_time DESC',
      limit: limit,
    );
    return rows.map(WorkoutSession.fromMap).toList();
  }

  Future<List<WorkoutSession>> getSessionsForDate(DateTime date) async {
    final db = await LocalDatabase.instance;
    final start = DateTime(
      date.year,
      date.month,
      date.day,
    ).millisecondsSinceEpoch;
    final end = DateTime(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
    ).millisecondsSinceEpoch;
    final rows = await db.query(
      'workout_sessions',
      where: 'start_time BETWEEN ? AND ?',
      whereArgs: [start, end],
      orderBy: 'start_time DESC',
    );
    return rows.map(WorkoutSession.fromMap).toList();
  }

  /// Returns date → total steps for the last [days] days (calendar heat-map)
  Future<Map<DateTime, int>> getRecentDailySteps({int days = 30}) async {
    final db = await LocalDatabase.instance;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final rows = await db.query(
      'daily_steps',
      where: 'date >= ?',
      whereArgs: [_dateKey(cutoff)],
    );
    return {
      for (final r in rows) _parseDate(r['date'] as String): r['steps'] as int,
    };
  }

  Future<int> getTodaySteps() async {
    final db = await LocalDatabase.instance;
    final rows = await db.query(
      'daily_steps',
      where: 'date = ?',
      whereArgs: [_dateKey(DateTime.now())],
    );
    if (rows.isEmpty) return 0;
    return rows.first['steps'] as int;
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _parseDate(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}

final sessionRepositoryProvider = Provider<SessionRepository>(
  (_) => SessionRepository(),
);
