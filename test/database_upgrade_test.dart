import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_routine_active/core/local_database.dart';
import 'package:my_routine_active/core/sync_entity.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('migração v1 para v2 preserva todos os registros acadêmicos', () async {
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
}
