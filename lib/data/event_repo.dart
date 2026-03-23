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
            llm_raw TEXT,
            is_archived INTEGER DEFAULT 0,
            priority INTEGER DEFAULT 0,
            focus_time INTEGER
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

  Future<List<Event>> listActive() async {
    final database = await db;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final rows = await database.query(
      'events',
      where: 'is_archived = ? AND start_at >= ?',
      whereArgs: [0, startOfDay],
      orderBy: 'start_at ASC',
    );
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

  Future<int> delete(int id) async {
    final database = await db;
    return database.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> update(int id, Map<String, dynamic> updates) async {
    final database = await db;
    return database.update('events', updates, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> archiveExpired() async {
    final database = await db;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final expiredEvents = await database.query(
      'events',
      where: 'is_archived = ? AND start_at < ?',
      whereArgs: [0, startOfDay],
    );
    
    for (final row in expiredEvents) {
      final id = row['id'] as int;
      await database.update(
        'events',
        {'is_archived': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    
    return expiredEvents.length;
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}