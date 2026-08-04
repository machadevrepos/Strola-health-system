import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:strola_health/core/services/firebase_client.dart';
import 'package:strola_health/core/utils/polyline_encoder.dart';
import 'package:strola_health/data/datasources/local_database.dart';
import 'package:strola_health/domain/entities/personal_record.dart';
import 'package:strola_health/domain/entities/workout_session.dart';

class SessionRepository {
  Future<void> saveSession(WorkoutSession session, {required int goal}) async {
    final db = await LocalDatabase.instance;
    await db.insert(
      'workout_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Upsert today's cumulative step total for the calendar heat-map —
    // `goal` is snapshotted alongside it so "days met goal" stays accurate
    // for this day even if the goal changes again later.
    final dateKey = _dateKey(session.startTime);
    final existing = await db.query(
      'daily_steps',
      where: 'date = ?',
      whereArgs: [dateKey],
    );
    if (existing.isEmpty) {
      await db.insert('daily_steps', {
        'date': dateKey,
        'steps': session.steps,
        'goal': goal,
      });
    } else {
      await db.rawUpdate(
        'UPDATE daily_steps SET steps = steps + ?, goal = ? WHERE date = ?',
        [session.steps, goal, dateKey],
      );
    }
  }

  /// Best-effort backend sync — the local SQLite save (above) is already
  /// the source of truth for the on-device experience, so a sync failure
  /// (no connectivity, transient error) must never surface to the user or
  /// block the session-complete flow. `id` doubles as the server-side
  /// idempotency key (ingestWorkoutSession.ts), so a retried/duplicate call
  /// is always safe.
  Future<void> syncToBackend(WorkoutSession session) async {
    await FirebaseClient.call('ingestWorkoutSession', {
      'id': session.id,
      'startTimeMillis': session.startTime.millisecondsSinceEpoch,
      'endTimeMillis': session.endTime.millisecondsSinceEpoch,
      'steps': session.steps,
      'distanceMeters': session.distanceMeters,
      'durationSeconds': session.durationSeconds,
      'activityType': _activityTypeApiValue(session.activityType),
      if (session.customActivityName?.isNotEmpty == true)
        'customActivityName': session.customActivityName,
      if (session.routePoints.isNotEmpty)
        'routePolyline': encodePolyline(
          session.routePoints.map((p) => p.position).toList(),
        ),
      if (session.avgPaceSecPerKm != null)
        'avgPaceSecPerKm': session.avgPaceSecPerKm,
      if (session.caloriesBurned != null)
        'caloriesBurned': session.caloriesBurned,
      'source': 'strolla_app',
    });
  }

  /// `ActivityType.name` is camelCase (`outdoorWalk`); the backend's
  /// `ActivityType` union is snake_case (`outdoor_walk`) — this converts
  /// generically rather than a hand-written per-value map since the two
  /// naming schemes already line up 1:1.
  String _activityTypeApiValue(ActivityType type) => type.name.replaceAllMapped(
    RegExp('[A-Z]'),
    (m) => '_${m.group(0)!.toLowerCase()}',
  );

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

  Future<int> getTodaySteps() => getStepsForDate(DateTime.now());

  Future<int> getStepsForDate(DateTime date) async {
    final db = await LocalDatabase.instance;
    final rows = await db.query(
      'daily_steps',
      where: 'date = ?',
      whereArgs: [_dateKey(date)],
    );
    if (rows.isEmpty) return 0;
    return rows.first['steps'] as int;
  }

  /// Upserts [steps] as [date]'s running total, keeping the higher of the
  /// new and existing value (steps only ever accumulate within a day).
  /// Used to keep `daily_steps` fresh from the live step count, not just
  /// from saved workout sessions — needed for accurate streak tracking.
  ///
  /// [goal] is re-snapshotted on every call (even when steps didn't go up),
  /// so it always reflects the goal most recently in effect for this day —
  /// raising the goal tomorrow doesn't retroactively change whether today
  /// counted as met.
  Future<void> recordDailyTotal(
    DateTime date,
    int steps, {
    required int goal,
  }) async {
    final db = await LocalDatabase.instance;
    final dateKey = _dateKey(date);
    final existing = await db.query(
      'daily_steps',
      where: 'date = ?',
      whereArgs: [dateKey],
    );
    if (existing.isEmpty) {
      await db.insert('daily_steps', {
        'date': dateKey,
        'steps': steps,
        'goal': goal,
      });
    } else {
      final currentSteps = existing.first['steps'] as int;
      await db.update(
        'daily_steps',
        {'steps': steps > currentSteps ? steps : currentSteps, 'goal': goal},
        where: 'date = ?',
        whereArgs: [dateKey],
      );
    }
  }

  /// Checks [session] against this device's full local history (excluding
  /// itself, since it's already been saved by the time this is called) and
  /// returns every category it set a new best in. Bare SQL `MAX`/`ORDER BY`
  /// queries — no separate "records" table, the history itself is the
  /// source of truth.
  Future<List<PersonalRecordCategory>> checkPersonalRecords(
    WorkoutSession session,
  ) async {
    final records = <PersonalRecordCategory>[];

    final bestDuration = await _bestOf('duration_seconds', session.id);
    if (bestDuration == null || session.durationSeconds > bestDuration) {
      records.add(PersonalRecordCategory.longestDuration);
    }

    final bestDistance = await _bestOf('distance_meters', session.id);
    if (bestDistance == null || session.distanceMeters > bestDistance) {
      records.add(PersonalRecordCategory.farthestDistance);
    }

    final bestSteps = await _bestOf('steps', session.id);
    if (bestSteps == null || session.steps > bestSteps) {
      records.add(PersonalRecordCategory.mostStepsInSession);
    }

    if (session.distanceMeters > 0 &&
        session.durationSeconds > 0 &&
        await _isBestPace(session)) {
      records.add(PersonalRecordCategory.bestPace);
    }

    return records;
  }

  Future<num?> _bestOf(String column, String excludeId) async {
    final db = await LocalDatabase.instance;
    final rows = await db.query(
      'workout_sessions',
      columns: [column],
      where: 'id != ?',
      whereArgs: [excludeId],
      orderBy: '$column DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first[column] as num;
  }

  /// Pace = seconds per km, lower is better — not a simple MAX/MIN column,
  /// so this compares against every other distance-tracked session directly.
  Future<bool> _isBestPace(WorkoutSession session) async {
    final db = await LocalDatabase.instance;
    final rows = await db.query(
      'workout_sessions',
      columns: ['distance_meters', 'duration_seconds'],
      where: 'id != ? AND distance_meters > 0',
      whereArgs: [session.id],
    );
    final pace = session.durationSeconds / (session.distanceMeters / 1000);
    for (final r in rows) {
      final distanceM = (r['distance_meters'] as num).toDouble();
      final durationS = r['duration_seconds'] as int;
      final otherPace = durationS / (distanceM / 1000);
      if (otherPace <= pace) return false;
    }
    return true;
  }

  /// Each recorded day in [month] (any day within it — only year/month are
  /// used), paired with the goal that was active when that day's total was
  /// last written — not necessarily the current goal. Days recorded before
  /// the `goal` column existed fall back to [fallbackGoal], the best
  /// available guess for them.
  Future<List<({DateTime date, int steps, int goal})>> getStepsForMonthWithGoal(
    DateTime month, {
    required int fallbackGoal,
  }) async {
    final db = await LocalDatabase.instance;
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 1);
    final rows = await db.query(
      'daily_steps',
      where: 'date >= ? AND date < ?',
      whereArgs: [_dateKey(monthStart), _dateKey(monthEnd)],
    );
    return [
      for (final r in rows)
        (
          date: _parseDate(r['date'] as String),
          steps: r['steps'] as int,
          goal: (r['goal'] as int?) ?? fallbackGoal,
        ),
    ];
  }

  /// Total steps ever recorded on this device.
  Future<int> getAllTimeSteps() async {
    final db = await LocalDatabase.instance;
    final result = await db.rawQuery(
      'SELECT SUM(steps) as total FROM daily_steps',
    );
    return (result.first['total'] as int?) ?? 0;
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
