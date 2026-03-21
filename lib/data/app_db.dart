import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

const _dbName = 'ai_schedule.db';
const _dbVersion = 1;

const _createEvents = '''
CREATE TABLE events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  start_at INTEGER NOT NULL,
  duration_min INTEGER NOT NULL,
  title TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  source_text TEXT,
  llm_raw TEXT
);
''';

const _indexStartAt = 'CREATE INDEX idx_events_start_at ON events(start_at);';

Future<Database> openAppDb(String basePath) async {
  final path = join(basePath, _dbName);
  return openDatabase(
    path,
    version: _dbVersion,
    onCreate: (db, version) async {
      await db.execute(_createEvents);
      await db.execute(_indexStartAt);
    },
  );
}
