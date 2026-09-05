import 'package:flutter_test/flutter_test.dart';
import 'package:my_routine_active/core/backup_service.dart';
import 'package:my_routine_active/core/sync_entity.dart';

void main() {
  test('backup .mra preserva entidades, metadados e imagens em base64', () {
    const entity = SyncEntity(
      id: 'a1',
      type: 'study_note',
      payload: <String, dynamic>{
        'title': 'Arquitetura de software',
        'imageBase64': 'AQIDBA==',
      },
      updatedAtMs: 123456,
      deviceId: 'pc-1',
      revision: 3,
    );

    final bytes = BackupService.createBundle(
      entities: const <SyncEntity>[entity],
      deviceId: 'pc-1',
    );
    final decoded = BackupService.decodeBundle(bytes);

    expect(decoded.deviceId, 'pc-1');
    expect(decoded.entities, hasLength(1));
    expect(decoded.entities.single.id, 'a1');
    expect(decoded.entities.single.payload['imageBase64'], 'AQIDBA==');
    expect(decoded.entities.single.revision, 3);
  });

  test('backup corrompido é rejeitado', () {
    expect(
      () => BackupService.decodeBundle(<int>[1, 2, 3, 4]),
      throwsA(isA<FormatException>()),
    );
  });

  test('backup preserva anexos e imagens da pasta de conteúdo', () {
    const attachment = SyncEntity(
      id: 'asset-1',
      type: 'content_asset',
      payload: <String, dynamic>{
        'subjectId': 'subject-1',
        'contentId': 'content-1',
        'kind': 'attachment',
        'name': 'modelo-relacional.pdf',
        'extension': 'pdf',
        'size': 4,
        'base64': 'JVBERg==',
      },
      updatedAtMs: 987654,
      deviceId: 'celular-1',
      revision: 1,
    );

    final bytes = BackupService.createBundle(
      entities: const <SyncEntity>[attachment],
      deviceId: 'celular-1',
    );
    final decoded = BackupService.decodeBundle(bytes);

    expect(decoded.entities.single.type, 'content_asset');
    expect(decoded.entities.single.payload['contentId'], 'content-1');
    expect(decoded.entities.single.payload['name'], 'modelo-relacional.pdf');
    expect(decoded.entities.single.payload['base64'], 'JVBERg==');
  });
}
