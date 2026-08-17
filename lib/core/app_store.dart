import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'backup_service.dart';
import 'local_database.dart';
import 'sync_entity.dart';

class EntityTypes {
  static const subject = 'subject';
  static const classSession = 'class_session';
  static const exam = 'exam';
  static const studyNote = 'study_note';
  static const flashcard = 'flashcard';
  static const workoutPlan = 'workout_plan';
  static const exercise = 'exercise';
  static const exerciseSet = 'exercise_set';
  static const workoutSession = 'workout_session';
  static const income = 'income';
  static const expense = 'expense';
  static const card = 'card';
  static const debt = 'debt';
  static const loan = 'loan';
  static const reminder = 'reminder';
  static const studyGoal = 'study_goal';
  static const studySession = 'study_session';
  static const studyQuestion = 'study_question';
  static const mockExam = 'mock_exam';
  static const bodyMetric = 'body_metric';
  static const cardioSession = 'cardio_session';
  static const waterLog = 'water_log';
  static const trainingGoal = 'training_goal';
  static const financeAccount = 'finance_account';
  static const financeTransfer = 'finance_transfer';
  static const financeCategory = 'finance_category';
  static const budget = 'budget';
  static const financeGoal = 'finance_goal';
  static const cardPayment = 'card_payment';
}

class AppStore extends ChangeNotifier {
  AppStore({LocalDatabase? database})
      : _database = database ?? LocalDatabase.instance;

  final LocalDatabase _database;
  final Uuid _uuid = const Uuid();
  final List<SyncEntity> _entities = <SyncEntity>[];

  bool _ready = false;
  String _deviceId = '';
  int _conflictCount = 0;

  bool get ready => _ready;
  String get deviceId => _deviceId;
  int get conflictCount => _conflictCount;

  Future<void> initialize() async {
    _deviceId = await _database.readSetting('device_id') ?? '';
    if (_deviceId.isEmpty) {
      _deviceId = _uuid.v4();
      await _database.writeSetting('device_id', _deviceId);
    }
    await reload();
    _ready = true;
    notifyListeners();
  }

  Future<void> reload() async {
    _entities
      ..clear()
      ..addAll(await _database.getAllEntities());
    _conflictCount = await _database.unresolvedConflictCount();
    notifyListeners();
  }

  List<SyncEntity> records(String type) {
    final result = _entities
        .where((item) => item.type == type && !item.isDeleted)
        .toList(growable: false);
    result.sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));
    return result;
  }

  SyncEntity? byId(String id) {
    for (final entity in _entities) {
      if (entity.id == id && !entity.isDeleted) return entity;
    }
    return null;
  }

  Future<SyncEntity> save(
    String type,
    Map<String, dynamic> payload, {
    String? id,
  }) async {
    final existing = id == null ? null : _findAny(id);
    final now = DateTime.now().millisecondsSinceEpoch;
    final entity = SyncEntity(
      id: id ?? _uuid.v4(),
      type: type,
      payload: Map<String, dynamic>.from(payload),
      updatedAtMs: now,
      deviceId: _deviceId,
      revision: (existing?.revision ?? 0) + 1,
    );
    await _database.upsert(entity);
    _replaceInMemory(entity);
    notifyListeners();
    return entity;
  }

  Future<void> remove(String id) async {
    final existing = _findAny(id);
    if (existing == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final tombstone = SyncEntity(
      id: existing.id,
      type: existing.type,
      payload: existing.payload,
      updatedAtMs: now,
      deletedAtMs: now,
      deviceId: _deviceId,
      revision: existing.revision + 1,
    );
    await _database.upsert(tombstone);
    _replaceInMemory(tombstone);
    notifyListeners();
  }

  Future<MergeResult> mergeRemote(List<SyncEntity> incoming) async {
    var inserted = 0;
    var updated = 0;
    var ignored = 0;
    var conflicts = 0;
    final winners = <SyncEntity>[];

    for (final remote in incoming) {
      final local = _findAny(remote.id);
      if (local == null) {
        inserted++;
        winners.add(remote);
        continue;
      }
      if (local.contentEquals(remote)) {
        ignored++;
        continue;
      }

      final remoteWins = _remoteWins(local, remote);
      if (local.deviceId != remote.deviceId) {
        conflicts++;
        await _database.addConflict(
          local: local,
          remote: remote,
          winnerDeviceId: remoteWins ? remote.deviceId : local.deviceId,
        );
      }
      if (remoteWins) {
        updated++;
        winners.add(remote);
      } else {
        ignored++;
      }
    }

    await _database.upsertMany(winners);
    for (final winner in winners) {
      _replaceInMemory(winner);
    }
    _conflictCount = await _database.unresolvedConflictCount();
    notifyListeners();
    return MergeResult(
      inserted: inserted,
      updated: updated,
      ignored: ignored,
      conflicts: conflicts,
    );
  }

  bool _remoteWins(SyncEntity local, SyncEntity remote) {
    if (remote.updatedAtMs != local.updatedAtMs) {
      return remote.updatedAtMs > local.updatedAtMs;
    }
    if (remote.revision != local.revision) {
      return remote.revision > local.revision;
    }
    return remote.deviceId.compareTo(local.deviceId) > 0;
  }

  SyncEntity? _findAny(String id) {
    for (final entity in _entities) {
      if (entity.id == id) return entity;
    }
    return null;
  }

  void _replaceInMemory(SyncEntity entity) {
    final index = _entities.indexWhere((item) => item.id == entity.id);
    if (index < 0) {
      _entities.add(entity);
    } else {
      _entities[index] = entity;
    }
  }

  Future<List<int>> exportBundle() async {
    final all = await _database.getAllEntities();
    return BackupService.createBundle(
      entities: all,
      deviceId: _deviceId,
    );
  }

  Future<MergeResult> importBundle(List<int> bytes) async {
    await BackupService.createAutomaticSnapshot(
      await exportBundle(),
      reason: 'antes-da-importacao',
    );
    final bundle = BackupService.decodeBundle(bytes);
    return mergeRemote(bundle.entities);
  }

  Future<String?> readPreference(String key) => _database.readSetting(key);

  Future<void> writePreference(String key, String value) async {
    await _database.writeSetting(key, value);
    notifyListeners();
  }

  Future<List<Map<String, Object?>>> unresolvedConflicts() =>
      _database.unresolvedConflicts();

  Future<void> resolveConflict(int id) async {
    await _database.resolveConflict(id);
    _conflictCount = await _database.unresolvedConflictCount();
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    final salt = _uuid.v4();
    final hash = sha256.convert(utf8.encode('$salt:$pin')).toString();
    await _database.writeSetting('pin_salt', salt);
    await _database.writeSetting('pin_hash', hash);
    notifyListeners();
  }

  Future<bool> hasPin() async =>
      (await _database.readSetting('pin_hash') ?? '').isNotEmpty;

  Future<bool> verifyPin(String pin) async {
    final salt = await _database.readSetting('pin_salt') ?? '';
    final expected = await _database.readSetting('pin_hash') ?? '';
    if (salt.isEmpty || expected.isEmpty) return true;
    final actual = sha256.convert(utf8.encode('$salt:$pin')).toString();
    return actual == expected;
  }

  Future<void> clearPin() async {
    await _database.writeSetting('pin_salt', '');
    await _database.writeSetting('pin_hash', '');
    notifyListeners();
  }
}
