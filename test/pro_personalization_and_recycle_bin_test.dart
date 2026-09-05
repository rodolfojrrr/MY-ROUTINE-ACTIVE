import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_routine_active/core/app_store.dart';
import 'package:my_routine_active/core/app_theme.dart';
import 'package:my_routine_active/core/backup_service.dart';
import 'package:my_routine_active/core/local_database.dart';

void main() {
  test('tema avançado preserva todas as camadas de cor', () {
    const profile = AppVisualProfile(
      primary: Color(0xFF123456),
      primaryLight: Color(0xFF456789),
      primaryDark: Color(0xFF102030),
      secondary: Color(0xFFABCDEF),
      background: Color(0xFF020304),
      surface: Color(0xFF111213),
      surfaceRaised: Color(0xFF202122),
      border: Color(0xFF303132),
      sidebar: Color(0xFF08090A),
    );

    final restored = AppVisualProfile.fromJson(profile.toJson());
    expect(restored.primary, profile.primary);
    expect(restored.secondary, profile.secondary);
    expect(restored.background, profile.background);
    expect(restored.surface, profile.surface);
    expect(restored.surfaceRaised, profile.surfaceRaised);
    expect(restored.border, profile.border);
    expect(restored.sidebar, profile.sidebar);
  });

  test('exclusão definitiva apaga conteúdo e mantém tombstone de sync',
      () async {
    final database = await LocalDatabase.createInMemoryForTesting();
    final store = AppStore(database: database);
    addTearDown(() async {
      store.dispose();
      await database.close();
    });
    await store.initialize();
    final summary = await store.save(
      EntityTypes.studyNote,
      <String, dynamic>{
        'title': 'Resumo temporário',
        'body': 'Conteúdo que deve ser apagado',
        'coverImageBase64': 'AQID',
      },
    );

    await store.remove(summary.id);
    expect(store.deletedRecords(), hasLength(1));
    await store.purge(summary.id);
    expect(store.deletedRecords(), isEmpty);

    final bundle = BackupService.decodeBundle(await store.exportBundle());
    final tombstone = bundle.entities.singleWhere(
      (item) => item.id == summary.id,
    );
    expect(tombstone.isDeleted, isTrue);
    expect(tombstone.payload['purged'], isTrue);
    expect(tombstone.payload.containsKey('body'), isFalse);
    expect(tombstone.payload.containsKey('coverImageBase64'), isFalse);
  });
}
