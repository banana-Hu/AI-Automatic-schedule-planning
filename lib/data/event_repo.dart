import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/event.dart';

class EventRepo {
  EventRepo() {
    _init();
  }

  Database? _db;

  Future<void> _init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'ai_schedule.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            start_at INTEGER NOT NULL,
            duration_min INTEGER NOT NULL,
            title TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            source_text TEXT,
            llm_raw TEXT
          );
        ''');
        await db.execute('CREATE INDEX idx_events_start_at ON events(start_at);');
      },
    );
  }

  Future<Database> get db async {
    if (_db == null) {
      await _init();
    }
    return _db!;
  }

  Future<int> insert(Event e) async {
    final database = await db;
    return database.insert('events', e.toMap());
  }

  Future<List<Event>> listAll() async {
    final database = await db;
    final rows = await database.query('events', orderBy: 'start_at ASC');
    return rows.map((m) => Event.fromMap(m)).toList();
  }

  Future<List<Event>> listInRange(int startMs, int endMs) async {
    final database = await db;
    final rows = await database.query(
      'events',
      where: 'start_at >= ? AND start_at < ?',
      whereArgs: [startMs, endMs],
      orderBy: 'start_at ASC',
    );
    return rows.map((m) => Event.fromMap(m)).toList();
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
