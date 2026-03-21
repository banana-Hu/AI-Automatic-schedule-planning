import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DbEvent {
  DbEvent({
    this.id,
    required this.title,
    required this.startTimeIso,
    required this.durationMinutes,
    this.notes,
  });

  final int? id;
  final String title;
  final String startTimeIso; // ISO8601 string
  final int durationMinutes;
  final String? notes;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'start_time': startTimeIso,
      'duration_minutes': durationMinutes,
      'notes': notes,
    };
  }

  static DbEvent fromMap(Map<String, Object?> map) {
    return DbEvent(
      id: map['id'] as int?,
      title: map['title'] as String,
      startTimeIso: map['start_time'] as String,
      durationMinutes: map['duration_minutes'] as int,
      notes: map['notes'] as String?,
    );
  }
}

class DbHelper {
  static const _dbName = 'minimal_ai_schedule.db';
  static const _dbVersion = 1;

  static final DbHelper instance = DbHelper._();
  DbHelper._();

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    final opened = await _open();
    _db = opened;
    return opened;
  }

  Future<Database> _open() async {
    final dbDir = await getDatabasesPath();
    final dbPath = p.join(dbDir, _dbName);
    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  start_time TEXT NOT NULL,
  duration_minutes INTEGER NOT NULL,
  notes TEXT
);
''');
        await db.execute(
          'CREATE INDEX idx_events_start_time ON events(start_time);',
        );
      },
    );
  }

  Future<int> insertEvent(DbEvent event) async {
    final db = await database;
    return db.insert('events', event.toMap());
  }

  Future<int> updateEvent(DbEvent event) async {
    final db = await database;
    if (event.id == null) {
      throw ArgumentError('event.id is required for update');
    }
    return db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(int id) async {
    final db = await database;
    return db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<DbEvent>> getAllEvents() async {
    final db = await database;
    final rows = await db.query('events', orderBy: 'start_time ASC');
    return rows.map(DbEvent.fromMap).toList();
  }

  Future<DbEvent?> getEventById(int id) async {
    final db = await database;
    final rows = await db.query('events', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return DbEvent.fromMap(rows.first);
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    await db?.close();
  }
}

