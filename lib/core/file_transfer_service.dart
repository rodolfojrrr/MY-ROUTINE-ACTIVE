import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import 'app_store.dart';
import 'sync_entity.dart';

class FileTransferService {
  static Future<String?> exportBackup(AppStore store) async {
    final bytes = await store.exportBundle();
    final stamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    return FilePicker.platform.saveFile(
      dialogTitle: 'Salvar backup do My Routine Active',
      fileName: 'my-routine-active_$stamp.mra',
      type: FileType.custom,
      allowedExtensions: const <String>['mra'],
      bytes: Uint8List.fromList(bytes),
    );
  }

  static Future<MergeResult?> importBackup(AppStore store) async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'Importar backup do My Routine Active',
      type: FileType.custom,
      allowedExtensions: const <String>['mra'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final file = picked.files.single;
    final bytes = file.bytes ??
        (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null) throw const FileSystemException('Arquivo sem dados.');
    return store.importBundle(bytes);
  }

  static Future<Map<String, dynamic>?> pickImagePayload() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final file = picked.files.single;
    final bytes = file.bytes ??
        (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null) return null;
    if (bytes.length > 8 * 1024 * 1024) {
      throw const FileSystemException('A imagem deve ter no máximo 8 MB.');
    }
    return <String, dynamic>{
      'imageName': file.name,
      'imageBytes': bytes,
    };
  }
}

