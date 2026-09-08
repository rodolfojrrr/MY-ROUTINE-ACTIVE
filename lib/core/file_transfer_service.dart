import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import 'app_store.dart';
import 'backup_service.dart';
import 'sync_entity.dart';

class FileTransferService {
  static Future<String?> exportBackup(AppStore store) async {
    final bytes = await store.exportBundle();
    final stamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    return FilePicker.platform.saveFile(
      dialogTitle: 'Salvar backup do Studium SI',
      fileName: 'smart-routine-si_$stamp.mra',
      type: FileType.custom,
      allowedExtensions: const <String>['mra'],
      bytes: Uint8List.fromList(bytes),
    );
  }

  static Future<MergeResult?> importBackup(AppStore store) async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'Importar backup do Studium SI',
      type: FileType.custom,
      allowedExtensions: const <String>['mra', 'gz'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final file = picked.files.single;
    final bytes = file.bytes ??
        (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null) throw const FileSystemException('Arquivo sem dados.');
    final normalized = normalizeBackupBytes(bytes);
    return store.importBundle(normalized);
  }

  static List<int> normalizeBackupBytes(List<int> bytes) {
    try {
      BackupService.decodeBundle(bytes);
      return bytes;
    } catch (originalError) {
      try {
        final unwrapped = gzip.decode(bytes);
        BackupService.decodeBundle(unwrapped);
        return unwrapped;
      } catch (_) {
        throw FormatException(
          'Este arquivo não é um backup .mra válido. Se ele veio pelo WhatsApp, pode usar tanto .mra quanto .mra.gz. Detalhe: $originalError',
        );
      }
    }
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
    return <String, dynamic>{'imageName': file.name, 'imageBytes': bytes};
  }

  static Future<List<Map<String, dynamic>>> pickImagePayloads() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'Selecionar imagens do resumo',
      type: FileType.custom,
      allowedExtensions: const <String>['jpg', 'jpeg', 'png'],
      allowMultiple: true,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return <Map<String, dynamic>>[];
    if (picked.files.length > 8) {
      throw const FileSystemException('Selecione no máximo 8 imagens por vez.');
    }
    final result = <Map<String, dynamic>>[];
    var totalBytes = 0;
    for (final file in picked.files) {
      final bytes = file.bytes ??
          (file.path == null ? null : await File(file.path!).readAsBytes());
      if (bytes == null) continue;
      if (bytes.length > 8 * 1024 * 1024) {
        throw FileSystemException(
          'A imagem ${file.name} ultrapassa o limite de 8 MB.',
        );
      }
      totalBytes += bytes.length;
      if (totalBytes > 24 * 1024 * 1024) {
        throw const FileSystemException(
          'As imagens selecionadas ultrapassam o limite total de 24 MB.',
        );
      }
      result.add(<String, dynamic>{
        'imageName': file.name,
        'imageBytes': bytes,
      });
    }
    return result;
  }

  static Future<List<Map<String, dynamic>>> pickAttachmentPayloads() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'Selecionar anexos do resumo',
      type: FileType.any,
      allowMultiple: true,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return <Map<String, dynamic>>[];
    if (picked.files.length > 10) {
      throw const FileSystemException('Selecione no máximo 10 anexos por vez.');
    }
    final result = <Map<String, dynamic>>[];
    var totalBytes = 0;
    for (final file in picked.files) {
      final bytes = file.bytes ??
          (file.path == null ? null : await File(file.path!).readAsBytes());
      if (bytes == null) continue;
      if (bytes.length > 20 * 1024 * 1024) {
        throw FileSystemException(
          'O arquivo ${file.name} ultrapassa o limite de 20 MB.',
        );
      }
      totalBytes += bytes.length;
      if (totalBytes > 48 * 1024 * 1024) {
        throw const FileSystemException(
          'Os anexos selecionados ultrapassam o limite total de 48 MB.',
        );
      }
      result.add(<String, dynamic>{
        'name': file.name,
        'extension': file.extension ?? _extensionFromName(file.name),
        'sizeBytes': bytes.length,
        'base64': base64Encode(bytes),
      });
    }
    return result;
  }

  static Future<String?> saveAttachment(Map<String, dynamic> attachment) {
    final name = attachment['name'] as String? ?? 'anexo';
    final encoded = attachment['base64'] as String? ?? '';
    if (encoded.isEmpty) {
      throw const FileSystemException('O anexo não possui dados.');
    }
    final extension =
        (attachment['extension'] as String? ?? _extensionFromName(name))
            .replaceAll('.', '')
            .toLowerCase();
    return saveBytes(
      bytes: base64Decode(encoded),
      fileName: name,
      dialogTitle: 'Salvar anexo do resumo',
      extension: extension.isEmpty ? 'bin' : extension,
    );
  }

  static Future<String?> saveBytes({
    required Uint8List bytes,
    required String fileName,
    required String dialogTitle,
    required String extension,
  }) {
    return FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: <String>[extension],
      bytes: bytes,
    );
  }

  static String _extensionFromName(String name) {
    final separator = name.lastIndexOf('.');
    if (separator < 0 || separator == name.length - 1) return '';
    return name.substring(separator + 1).toLowerCase();
  }
}
