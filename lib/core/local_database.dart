import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'sync_entity.dart';

class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final support = await getApplicationSupportDirectory();
    final dataDir = Directory(p.join(support.path, 'MyRoutineActive'));
    await dataDir.create(recursive: true);
    final dbPath = p.join(dataDir.path, 'my_routine_active.db');

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      _database = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _onCreate,
          onConfigure: _onConfigure,
        ),
      );
    } else {
      _database = await openDatabase(
        dbPath,
        version: 1,
        onCreate: _onCreate,
        onConfigure: _onConfigure,
      );
    }
    return _database!;
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    await db.rawQuery('PRAGMA journal_mode = WAL');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE entities (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        payload TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        device_id TEXT NOT NULL,
        revision INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_entities_type ON entities(entity_type, deleted_at)',
    );
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE sync_conflicts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_id TEXT NOT NULL,
        local_json TEXT NOT NULL,
        remote_json TEXT NOT NULL,
        winner_device_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        resolved INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<List<SyncEntity>> getAllEntities({bool includeDeleted = true}) async {
    final db = await database;
    final rows = await db.query(
      'entities',
      where: includeDeleted ? null : 'deleted_at IS NULL',
      orderBy: 'updated_at DESC',
    );
    return rows.map(SyncEntity.fromMap).toList(growable: false);
  }

  Future<void> upsert(SyncEntity entity) async {
    final db = await database;
    await db.insert(
      'entities',
      entity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertMany(List<SyncEntity> entities) async {
    if (entities.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final entity in entities) {
        batch.insert(
          'entities',
          entity.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<String?> readSetting(String key) async {
    final db = await database;
    final rows = await db.query(
      'settings',
      columns: const <String>['value'],
      where: 'key = ?',
      whereArgs: <Object?>[key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> writeSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      <String, Object?>{'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> addConflict({
    required SyncEntity local,
    required SyncEntity remote,
    required String winnerDeviceId,
  }) async {
    final db = await database;
    await db.insert('sync_conflicts', <String, Object?>{
      'entity_id': local.id,
      'local_json': local.toMap()['payload'],
      'remote_json': remote.toMap()['payload'],
      'winner_device_id': winnerDeviceId,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'resolved': 0,
    });
  }

  Future<List<Map<String, Object?>>> unresolvedConflicts() async {
    final db = await database;
    return db.query(
      'sync_conflicts',
      where: 'resolved = 0',
      orderBy: 'created_at DESC',
    );
  }

  Future<void> resolveConflict(int id) async {
    final db = await database;
    await db.update(
      'sync_conflicts',
      <String, Object?>{'resolved': 1},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<int> unresolvedConflictCount() async {
    final db = await database;
    final value = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM sync_conflicts WHERE resolved = 0',
      ),
    );
    return value ?? 0;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

