import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app_storage_paths.dart';
import 'sync_entity.dart';
import 'local_account.dart';

class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();
  static const int _databaseVersion = 3;
  static const int _largeValueThreshold = 128 * 1024;
  static const int _largeValueChunkSize = 64 * 1024;
  static const String _largeValueMarker = '__MRA_LARGE_VALUE_V1__';
  Database? _database;
  bool _largeValuesPrepared = false;

  static Future<LocalDatabase> createInMemoryForTesting() async {
    sqfliteFfiInit();
    final instance = LocalDatabase._();
    instance._database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: instance._onCreate,
        onUpgrade: instance._onUpgrade,
        onConfigure: instance._onConfigure,
        onOpen: instance._onOpen,
      ),
    );
    return instance;
  }

  static Future<LocalDatabase> openPathForTesting(String path) async {
    sqfliteFfiInit();
    final instance = LocalDatabase._();
    instance._database = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: instance._onCreate,
        onUpgrade: instance._onUpgrade,
        onConfigure: instance._onConfigure,
        onOpen: instance._onOpen,
      ),
    );
    return instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dataDir = await AppStoragePaths.dataDirectory();
    await dataDir.create(recursive: true);
    final dbPath = p.join(dataDir.path, AppStoragePaths.databaseFileName);

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      _database = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: _databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onConfigure: _onConfigure,
          onOpen: _onOpen,
        ),
      );
    } else {
      _database = await openDatabase(
        dbPath,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
        onOpen: _onOpen,
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
    await _createAccountsTable(db);
    await _createLargeValueChunksTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _createAccountsTable(db);
    if (oldVersion < 3) {
      await _createLargeValueChunksTable(db);
      await _migrateLegacyLargeValues(db);
    }
  }

  Future<void> _onOpen(Database db) async {
    await _createLargeValueChunksTable(db);
    await db.transaction(_migrateLegacyLargeValues);
    _largeValuesPrepared = true;
  }

  Future<void> prepareLargeValuesForReading() async {
    if (_largeValuesPrepared) return;
    final db = await database;
    if (_largeValuesPrepared) return;
    await db.transaction(_migrateLegacyLargeValues);
    _largeValuesPrepared = true;
  }

  Future<void> _createAccountsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_accounts (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        username_normalized TEXT NOT NULL UNIQUE,
        display_name TEXT NOT NULL,
        email TEXT NOT NULL DEFAULT '',
        email_normalized TEXT NOT NULL DEFAULT '',
        password_salt TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        recovery_salt TEXT NOT NULL,
        recovery_hash TEXT NOT NULL,
        security_question TEXT NOT NULL,
        answer_salt TEXT NOT NULL,
        answer_hash TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_local_accounts_email '
      "ON local_accounts(email_normalized) WHERE email_normalized <> ''",
    );
  }

  Future<void> _createLargeValueChunksTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS large_value_chunks (
        owner_kind TEXT NOT NULL,
        owner_id TEXT NOT NULL,
        field_name TEXT NOT NULL,
        chunk_index INTEGER NOT NULL,
        chunk_data BLOB NOT NULL,
        PRIMARY KEY (owner_kind, owner_id, field_name, chunk_index)
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_large_value_owner
      ON large_value_chunks(owner_kind, owner_id, field_name)
    ''');
  }

  Future<void> _migrateLegacyLargeValues(DatabaseExecutor db) async {
    final entities = await db.rawQuery(
      '''
      SELECT id
      FROM entities
      WHERE length(CAST(payload AS BLOB)) > ?
    ''',
      <Object?>[_largeValueThreshold],
    );
    for (final row in entities) {
      final id = row['id'] as String;
      await _moveColumnToChunks(
        db,
        table: 'entities',
        idColumn: 'id',
        rowId: id,
        ownerKind: 'entity',
        ownerId: id,
        fieldName: 'payload',
      );
    }

    final settings = await db.rawQuery(
      '''
      SELECT key
      FROM settings
      WHERE length(CAST(value AS BLOB)) > ?
    ''',
      <Object?>[_largeValueThreshold],
    );
    for (final row in settings) {
      final key = row['key'] as String;
      await _moveColumnToChunks(
        db,
        table: 'settings',
        idColumn: 'key',
        rowId: key,
        ownerKind: 'setting',
        ownerId: key,
        fieldName: 'value',
      );
    }

    final conflicts = await db.rawQuery(
      '''
      SELECT id,
             length(CAST(local_json AS BLOB)) AS local_size,
             length(CAST(remote_json AS BLOB)) AS remote_size
      FROM sync_conflicts
      WHERE length(CAST(local_json AS BLOB)) > ?
         OR length(CAST(remote_json AS BLOB)) > ?
    ''',
      <Object?>[_largeValueThreshold, _largeValueThreshold],
    );
    for (final row in conflicts) {
      final numericId = (row['id'] as num).toInt();
      final ownerId = '$numericId';
      if ((row['local_size'] as num? ?? 0).toInt() > _largeValueThreshold) {
        await _moveColumnToChunks(
          db,
          table: 'sync_conflicts',
          idColumn: 'id',
          rowId: numericId,
          ownerKind: 'conflict',
          ownerId: ownerId,
          fieldName: 'local_json',
        );
      }
      if ((row['remote_size'] as num? ?? 0).toInt() > _largeValueThreshold) {
        await _moveColumnToChunks(
          db,
          table: 'sync_conflicts',
          idColumn: 'id',
          rowId: numericId,
          ownerKind: 'conflict',
          ownerId: ownerId,
          fieldName: 'remote_json',
        );
      }
    }
  }

  Future<void> _moveColumnToChunks(
    DatabaseExecutor db, {
    required String table,
    required String idColumn,
    required Object rowId,
    required String ownerKind,
    required String ownerId,
    required String fieldName,
  }) async {
    final sizeRows = await db.rawQuery(
      'SELECT length(CAST($fieldName AS BLOB)) AS byte_length '
      'FROM $table WHERE $idColumn = ?',
      <Object?>[rowId],
    );
    if (sizeRows.isEmpty) return;
    final byteLength = (sizeRows.first['byte_length'] as num? ?? 0).toInt();
    if (byteLength <= _largeValueThreshold) return;

    await _deleteLargeValueChunks(
      db,
      ownerKind: ownerKind,
      ownerId: ownerId,
      fieldName: fieldName,
    );
    final batch = db.batch();
    var index = 0;
    for (var offset = 0; offset < byteLength; offset += _largeValueChunkSize) {
      batch.rawInsert(
        '''
        INSERT INTO large_value_chunks (
          owner_kind, owner_id, field_name, chunk_index, chunk_data
        )
        SELECT ?, ?, ?, ?, substr(CAST($fieldName AS BLOB), ?, ?)
        FROM $table
        WHERE $idColumn = ?
      ''',
        <Object?>[
          ownerKind,
          ownerId,
          fieldName,
          index,
          offset + 1,
          _largeValueChunkSize,
          rowId,
        ],
      );
      index++;
    }
    await batch.commit(noResult: true);
    final changed = await db.update(
      table,
      <String, Object?>{fieldName: _largeValueMarker},
      where: '$idColumn = ?',
      whereArgs: <Object?>[rowId],
    );
    if (changed != 1) {
      throw StateError('Não foi possível proteger um registro grande.');
    }
  }

  Future<void> _deleteLargeValueChunks(
    DatabaseExecutor db, {
    required String ownerKind,
    required String ownerId,
    required String fieldName,
  }) async {
    await db.delete(
      'large_value_chunks',
      where: 'owner_kind = ? AND owner_id = ? AND field_name = ?',
      whereArgs: <Object?>[ownerKind, ownerId, fieldName],
    );
  }

  Future<String> _readLargeValue(
    DatabaseExecutor db, {
    required String ownerKind,
    required String ownerId,
    required String fieldName,
  }) async {
    final rows = await db.query(
      'large_value_chunks',
      columns: const <String>['chunk_data'],
      where: 'owner_kind = ? AND owner_id = ? AND field_name = ?',
      whereArgs: <Object?>[ownerKind, ownerId, fieldName],
      orderBy: 'chunk_index ASC',
    );
    if (rows.isEmpty) {
      throw StateError(
        'As partes de um registro grande não foram encontradas.',
      );
    }
    final bytes = BytesBuilder(copy: false);
    for (final row in rows) {
      final chunk = row['chunk_data'];
      if (chunk is Uint8List) {
        bytes.add(chunk);
      } else if (chunk is List<int>) {
        bytes.add(chunk);
      } else {
        throw StateError('Uma parte do registro grande está inválida.');
      }
    }
    return utf8.decode(bytes.takeBytes());
  }

  Future<List<SyncEntity>> getAllEntities({bool includeDeleted = true}) async {
    final db = await database;
    final rows = await db.query(
      'entities',
      where: includeDeleted ? null : 'deleted_at IS NULL',
      orderBy: 'updated_at DESC',
    );
    final result = <SyncEntity>[];
    for (final source in rows) {
      final row = Map<String, Object?>.from(source);
      if (row['payload'] == _largeValueMarker) {
        final id = row['id'] as String;
        row['payload'] = await _readLargeValue(
          db,
          ownerKind: 'entity',
          ownerId: id,
          fieldName: 'payload',
        );
      }
      result.add(SyncEntity.fromMap(row));
    }
    return result;
  }

  Future<void> upsert(SyncEntity entity) async {
    final db = await database;
    await db.transaction((txn) => _upsertEntity(txn, entity));
  }

  Future<void> upsertMany(List<SyncEntity> entities) async {
    if (entities.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      for (final entity in entities) {
        await _upsertEntity(txn, entity);
      }
    });
  }

  Future<void> _upsertEntity(DatabaseExecutor db, SyncEntity entity) async {
    await db.insert(
      'entities',
      entity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _deleteLargeValueChunks(
      db,
      ownerKind: 'entity',
      ownerId: entity.id,
      fieldName: 'payload',
    );
    await _moveColumnToChunks(
      db,
      table: 'entities',
      idColumn: 'id',
      rowId: entity.id,
      ownerKind: 'entity',
      ownerId: entity.id,
      fieldName: 'payload',
    );
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
    if (rows.isEmpty) return null;
    final value = rows.first['value'] as String;
    if (value != _largeValueMarker) return value;
    return _readLargeValue(
      db,
      ownerKind: 'setting',
      ownerId: key,
      fieldName: 'value',
    );
  }

  Future<void> writeSetting(String key, String value) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('settings', <String, Object?>{
        'key': key,
        'value': value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await _deleteLargeValueChunks(
        txn,
        ownerKind: 'setting',
        ownerId: key,
        fieldName: 'value',
      );
      await _moveColumnToChunks(
        txn,
        table: 'settings',
        idColumn: 'key',
        rowId: key,
        ownerKind: 'setting',
        ownerId: key,
        fieldName: 'value',
      );
    });
  }

  Future<List<LocalAccount>> listAccounts() async {
    final db = await database;
    final rows = await db.query('local_accounts', orderBy: 'display_name');
    return rows.map(LocalAccount.fromMap).toList(growable: false);
  }

  Future<Map<String, Object?>?> findAccountByIdentifier(
    String identifier, {
    bool includeId = false,
  }) async {
    final db = await database;
    final rows = await db.query(
      'local_accounts',
      where: includeId
          ? 'id = ? OR username_normalized = ? OR email_normalized = ?'
          : 'username_normalized = ? OR email_normalized = ?',
      whereArgs: includeId
          ? <Object?>[identifier, identifier, identifier]
          : <Object?>[identifier, identifier],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> insertAccount(Map<String, Object?> row) async {
    final db = await database;
    await db.insert('local_accounts', row);
  }

  Future<void> updateAccountCredentials({
    required String id,
    required String passwordSalt,
    required String passwordHash,
    required String recoverySalt,
    required String recoveryHash,
  }) async {
    final db = await database;
    await db.update(
      'local_accounts',
      <String, Object?>{
        'password_salt': passwordSalt,
        'password_hash': passwordHash,
        'recovery_salt': recoverySalt,
        'recovery_hash': recoveryHash,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> addConflict({
    required SyncEntity local,
    required SyncEntity remote,
    required String winnerDeviceId,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      final id = await txn.insert('sync_conflicts', <String, Object?>{
        'entity_id': local.id,
        'local_json': local.toMap()['payload'],
        'remote_json': remote.toMap()['payload'],
        'winner_device_id': winnerDeviceId,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'resolved': 0,
      });
      final ownerId = '$id';
      for (final fieldName in const <String>['local_json', 'remote_json']) {
        await _moveColumnToChunks(
          txn,
          table: 'sync_conflicts',
          idColumn: 'id',
          rowId: id,
          ownerKind: 'conflict',
          ownerId: ownerId,
          fieldName: fieldName,
        );
      }
    });
  }

  Future<List<Map<String, Object?>>> unresolvedConflicts() async {
    final db = await database;
    final rows = await db.query(
      'sync_conflicts',
      where: 'resolved = 0',
      orderBy: 'created_at DESC',
    );
    final result = <Map<String, Object?>>[];
    for (final source in rows) {
      final row = Map<String, Object?>.from(source);
      final ownerId = '${row['id']}';
      for (final fieldName in const <String>['local_json', 'remote_json']) {
        if (row[fieldName] == _largeValueMarker) {
          row[fieldName] = await _readLargeValue(
            db,
            ownerKind: 'conflict',
            ownerId: ownerId,
            fieldName: fieldName,
          );
        }
      }
      result.add(row);
    }
    return result;
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
    _largeValuesPrepared = false;
  }
}
