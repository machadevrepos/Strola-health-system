import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase._();

  static Database? _db;

  static Future<Database> get instance async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'strola_health.db'),
      version: 4,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE workout_sessions (
            id TEXT PRIMARY KEY,
            start_time INTEGER NOT NULL,
            end_time INTEGER NOT NULL,
            steps INTEGER NOT NULL,
            distance_meters REAL NOT NULL,
            duration_seconds INTEGER NOT NULL,
            activity_type TEXT NOT NULL,
            route_points TEXT NOT NULL DEFAULT '',
            calories_burned INTEGER,
            custom_activity_name TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE daily_steps (
            date TEXT PRIMARY KEY,
            steps INTEGER NOT NULL,
            goal INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add calories_burned column (nullable — existing rows get NULL,
          // which gracefully falls back to the step-based formula in fromMap).
          await db.execute(
            'ALTER TABLE workout_sessions ADD COLUMN calories_burned INTEGER',
          );
        }
        if (oldVersion < 3) {
          // Snapshots the goal that was active when each day's total was
          // last written, so "days met goal" stays correct for days recorded
          // under an old goal even after the user raises it later. NULL on
          // existing rows (recorded before this column existed) — callers
          // fall back to the current goal for those.
          await db.execute('ALTER TABLE daily_steps ADD COLUMN goal INTEGER');
        }
        if (oldVersion < 4) {
          // User-entered name for an "Other" activity session (e.g. "Hiking").
          await db.execute(
            'ALTER TABLE workout_sessions ADD COLUMN custom_activity_name TEXT',
          );
        }
      },
    );
  }
}
