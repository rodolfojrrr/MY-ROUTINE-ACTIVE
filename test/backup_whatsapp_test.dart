import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_routine_active/core/backup_service.dart';
import 'package:my_routine_active/core/file_transfer_service.dart';
import 'package:my_routine_active/core/sync_entity.dart';

void main() {
  test('aceita .mra normal e pacote com segunda camada gzip', () {
    final bytes = BackupService.createBundle(
      entities: const <SyncEntity>[],
      deviceId: 'teste',
    );

    expect(FileTransferService.normalizeBackupBytes(bytes), bytes);
    expect(FileTransferService.normalizeBackupBytes(gzip.encode(bytes)), bytes);
  });
}
