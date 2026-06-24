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
      version: 2,
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
            calories_burned INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE daily_steps (
            date TEXT PRIMARY KEY,
            steps INTEGER NOT NULL
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
      },
    );
  }
}
