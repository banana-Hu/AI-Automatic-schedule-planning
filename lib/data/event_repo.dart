import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/event.dart';

class EventRepo {
  EventRepo();

  Database? _db;
  bool _initializing = false;

  Future<void> _init() async {
    if (_initializing) return;
    _initializing = true;
    try {
      // 使用应用内部存储路径，避免存储权限问题
      final appDocDir = await getApplicationDocumentsDirectory();
      final dbPath = join(appDocDir.path, 'ai_schedule.db');
      _db = await openDatabase(
        dbPath,
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
              is_completed INTEGER DEFAULT 0,
              priority INTEGER DEFAULT 0,
              focus_time INTEGER,
              delay_count INTEGER DEFAULT 0,
              original_start_at INTEGER
            );
          ''');
          await db
              .execute('CREATE INDEX idx_events_start_at ON events(start_at);');
        },
      );
      print('Database initialized at: $dbPath');
    } catch (e) {
      print('Database initialization error: $e');
    } finally {
      _initializing = false;
    }
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
    final startOfDay =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
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
    final startOfDay =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
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
