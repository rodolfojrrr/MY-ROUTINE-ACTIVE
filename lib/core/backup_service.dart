import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'sync_entity.dart';

class BackupBundle {
  const BackupBundle({
    required this.entities,
    required this.deviceId,
    required this.exportedAt,
  });

  final List<SyncEntity> entities;
  final String deviceId;
  final DateTime exportedAt;
}

class BackupService {
  static const format = 'my-routine-active';
  static const version = 1;

  static List<int> createBundle({
    required List<SyncEntity> entities,
    required String deviceId,
  }) {
    final entityJson = entities.map((item) => item.toJson()).toList();
    final canonical = jsonEncode(entityJson);
    final envelope = <String, dynamic>{
      'manifest': <String, dynamic>{
        'format': format,
        'version': version,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'deviceId': deviceId,
        'entityCount': entities.length,
        'sha256': sha256.convert(utf8.encode(canonical)).toString(),
      },
      'entities': entityJson,
    };
    return gzip.encode(utf8.encode(jsonEncode(envelope)));
  }

  static BackupBundle decodeBundle(List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(gzip.decode(bytes)));
      if (decoded is! Map) throw const FormatException('Pacote inválido.');
      final map = decoded.cast<String, dynamic>();
      final manifest = (map['manifest'] as Map).cast<String, dynamic>();
      if (manifest['format'] != format || manifest['version'] != version) {
        throw const FormatException('Versão de backup incompatível.');
      }
      final rawEntities = (map['entities'] as List).cast<dynamic>();
      final canonical = jsonEncode(rawEntities);
      final actual = sha256.convert(utf8.encode(canonical)).toString();
      if (actual != manifest['sha256']) {
        throw const FormatException('Backup corrompido: checksum inválido.');
      }
      final entities = rawEntities
          .map((item) => SyncEntity.fromJson(
                (item as Map).cast<String, dynamic>(),
              ))
          .toList(growable: false);
      return BackupBundle(
        entities: entities,
        deviceId: manifest['deviceId'] as String,
        exportedAt: DateTime.parse(manifest['exportedAt'] as String),
      );
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Não foi possível ler este arquivo .mra: $error');
    }
  }

  static Future<File> createAutomaticSnapshot(
    List<int> bytes, {
    required String reason,
  }) async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory(
      p.join(support.path, 'MyRoutineActive', 'backups'),
    );
    await directory.create(recursive: true);
    final stamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File(p.join(directory.path, '$stamp-$reason.mra'));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
