import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_routine_active/core/app_store.dart';
import 'package:my_routine_active/core/backup_service.dart';
import 'package:my_routine_active/core/local_database.dart';
import 'package:my_routine_active/core/sync_entity.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('migração v1 para v3 preserva todos os registros acadêmicos', () async {
    sqfliteFfiInit();
    final temporary = await Directory.systemTemp.createTemp('mra-upgrade-');
    final path = p.join(temporary.path, 'legacy.db');
    final oldDatabase = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (database, _) async {
          await database.execute('''
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
          await database.execute('''
            CREATE TABLE settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
          await database.execute('''
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
        },
      ),
    );
    const legacy = SyncEntity(
      id: 'resumo-antigo',
      type: 'study_note',
      payload: <String, dynamic>{
        'title': 'Resumo preservado',
        'body': 'Conteúdo importante',
      },
      updatedAtMs: 10,
      deviceId: 'legacy-device',
      revision: 1,
    );
    await oldDatabase.insert('entities', legacy.toMap());
    await oldDatabase.close();

    final upgraded = await LocalDatabase.openPathForTesting(path);
    final records = await upgraded.getAllEntities();
    expect(records, hasLength(1));
    expect(records.single.id, legacy.id);
    expect(records.single.payload, legacy.payload);
    expect(await upgraded.listAccounts(), isEmpty);

    await upgraded.close();
    await temporary.delete(recursive: true);
  });

  test('migração v2 fragmenta registros grandes sem perder dados', () async {
    sqfliteFfiInit();
    final temporary = await Directory.systemTemp.createTemp('mra-large-');
    final path = p.join(temporary.path, 'large-legacy.db');
    final oldDatabase = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (database, _) async {
          await database.execute('''
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
          await database.execute('''
            CREATE TABLE settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
          await database.execute('''
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
          await database.execute('''
            CREATE TABLE local_accounts (
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
        },
      ),
    );
    final block = List<String>.filled(100, '0123456789').join();
    final largeText = List<String>.filled(3 * 1024, block).join();
    final entity = SyncEntity(
      id: 'resumo-com-imagem-grande',
      type: 'study_note',
      payload: <String, dynamic>{
        'title': 'Resumo preservado',
        'imageBase64': largeText,
      },
      updatedAtMs: 20,
      deviceId: 'celular-antigo',
      revision: 2,
    );
    await oldDatabase.insert('entities', entity.toMap());
    await oldDatabase.insert('settings', <String, Object?>{
      'key': 'summary_draft:new',
      'value': largeText,
    });
    await oldDatabase.close();

    final upgraded = await LocalDatabase.openPathForTesting(path);
    final sqlite = await upgraded.database;
    final storedRows = await sqlite.query(
      'entities',
      columns: const <String>['payload'],
    );
    expect(storedRows.single['payload'], '__MRA_LARGE_VALUE_V1__');
    final chunkCount = Sqflite.firstIntValue(
      await sqlite.rawQuery(
        "SELECT COUNT(*) FROM large_value_chunks WHERE owner_kind = 'entity'",
      ),
    );
    expect(chunkCount, greaterThan(1));

    final records = await upgraded.getAllEntities();
    expect(records.single.payload, entity.payload);
    expect(await upgraded.readSetting('summary_draft:new'), largeText);

    await upgraded.close();
    await temporary.delete(recursive: true);
  });

  test('novas gravações grandes continuam legíveis e sincronizáveis', () async {
    final database = await LocalDatabase.createInMemoryForTesting();
    final block = List<String>.filled(100, 'dados-grandes-').join();
    final largeText = List<String>.filled(512, block).join();
    final local = SyncEntity(
      id: 'asset-grande',
      type: 'content_asset',
      payload: <String, dynamic>{
        'name': 'material.pdf',
        'base64': largeText,
      },
      updatedAtMs: 30,
      deviceId: 'celular',
      revision: 1,
    );
    final remote = SyncEntity(
      id: local.id,
      type: local.type,
      payload: <String, dynamic>{
        ...local.payload,
        'name': 'material-atualizado.pdf',
      },
      updatedAtMs: 31,
      deviceId: 'notebook',
      revision: 2,
    );

    await database.upsert(local);
    await database.writeSetting('rascunho-grande', largeText);
    await database.addConflict(
      local: local,
      remote: remote,
      winnerDeviceId: remote.deviceId,
    );

    final records = await database.getAllEntities();
    expect(records.single.payload, local.payload);
    expect(await database.readSetting('rascunho-grande'), largeText);
    final conflicts = await database.unresolvedConflicts();
    expect(conflicts, hasLength(1));
    expect(conflicts.single['local_json'], local.toMap()['payload']);
    expect(conflicts.single['remote_json'], remote.toMap()['payload']);

    final store = AppStore(database: database);
    await store.initialize();
    final backup = BackupService.decodeBundle(await store.exportBundle());
    expect(backup.entities.single.payload, local.payload);
    store.dispose();

    await database.close();
  });
}
