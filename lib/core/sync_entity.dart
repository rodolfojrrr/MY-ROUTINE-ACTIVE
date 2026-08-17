import 'dart:convert';

class SyncEntity {
  const SyncEntity({
    required this.id,
    required this.type,
    required this.payload,
    required this.updatedAtMs,
    required this.deviceId,
    required this.revision,
    this.deletedAtMs,
  });

  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final int updatedAtMs;
  final int? deletedAtMs;
  final String deviceId;
  final int revision;

  bool get isDeleted => deletedAtMs != null;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'entity_type': type,
        'payload': jsonEncode(payload),
        'updated_at': updatedAtMs,
        'deleted_at': deletedAtMs,
        'device_id': deviceId,
        'revision': revision,
      };

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type,
        'payload': payload,
        'updatedAtMs': updatedAtMs,
        'deletedAtMs': deletedAtMs,
        'deviceId': deviceId,
        'revision': revision,
      };

  factory SyncEntity.fromMap(Map<String, Object?> map) {
    final rawPayload = map['payload'];
    return SyncEntity(
      id: map['id']! as String,
      type: map['entity_type']! as String,
      payload: rawPayload is String
          ? (jsonDecode(rawPayload) as Map).cast<String, dynamic>()
          : (rawPayload as Map).cast<String, dynamic>(),
      updatedAtMs: (map['updated_at']! as num).toInt(),
      deletedAtMs: (map['deleted_at'] as num?)?.toInt(),
      deviceId: map['device_id']! as String,
      revision: (map['revision']! as num).toInt(),
    );
  }

  factory SyncEntity.fromJson(Map<String, dynamic> json) => SyncEntity(
        id: json['id'] as String,
        type: json['type'] as String,
        payload: (json['payload'] as Map).cast<String, dynamic>(),
        updatedAtMs: (json['updatedAtMs'] as num).toInt(),
        deletedAtMs: (json['deletedAtMs'] as num?)?.toInt(),
        deviceId: json['deviceId'] as String,
        revision: (json['revision'] as num).toInt(),
      );

  bool contentEquals(SyncEntity other) =>
      type == other.type &&
      deletedAtMs == other.deletedAtMs &&
      jsonEncode(payload) == jsonEncode(other.payload);
}

class MergeResult {
  const MergeResult({
    required this.inserted,
    required this.updated,
    required this.ignored,
    required this.conflicts,
  });

  final int inserted;
  final int updated;
  final int ignored;
  final int conflicts;

  int get changed => inserted + updated;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'inserted': inserted,
        'updated': updated,
        'ignored': ignored,
        'conflicts': conflicts,
      };
}

