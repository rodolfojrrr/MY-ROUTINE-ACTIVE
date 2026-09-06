import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'backup_service.dart';
import 'local_database.dart';
import 'local_account.dart';
import 'sync_entity.dart';

class EntityTypes {
  static const semester = 'semester';
  static const subject = 'subject';
  static const studyContent = 'study_content';
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
  static const dailyStudyGoal = 'daily_study_goal';
  static const weeklyStudyPlan = 'weekly_study_plan';
  static const kanbanTask = 'kanban_task';
  static const studyQuestion = 'study_question';
  static const mockExam = 'mock_exam';
  static const codeProject = 'code_project';
  static const codeFile = 'code_file';
  static const codeRun = 'code_run';
  static const contentAsset = 'content_asset';
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
  late final LocalAccountService _accountService =
      LocalAccountService(database: _database);
  final List<SyncEntity> _entities = <SyncEntity>[];

  bool _ready = false;
  String _deviceId = '';
  int _conflictCount = 0;
  LocalAccount? _activeAccount;

  bool get ready => _ready;
  String get deviceId => _deviceId;
  int get conflictCount => _conflictCount;
  LocalAccount? get activeAccount => _activeAccount;
  bool get isAuthenticated => _activeAccount != null;

  Future<void> initialize() async {
    await _database.prepareLargeValuesForReading();
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
        .where(
          (item) =>
              item.type == type &&
              !item.isDeleted &&
              _belongsToActiveAccount(item),
        )
        .toList(growable: false);
    result.sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));
    return result;
  }

  SyncEntity? byId(String id) {
    for (final entity in _entities) {
      if (entity.id == id &&
          !entity.isDeleted &&
          _belongsToActiveAccount(entity)) {
        return entity;
      }
    }
    return null;
  }

  List<SyncEntity> deletedRecords() {
    final result = _entities
        .where(
          (item) =>
              item.isDeleted &&
              item.payload['purged'] != true &&
              _belongsToActiveAccount(item),
        )
        .toList(growable: false);
    result.sort(
      (a, b) => (b.deletedAtMs ?? 0).compareTo(a.deletedAtMs ?? 0),
    );
    return result;
  }

  Future<SyncEntity> save(
    String type,
    Map<String, dynamic> payload, {
    String? id,
  }) async {
    final existing = id == null ? null : _findAny(id);
    if (existing != null && !_belongsToActiveAccount(existing)) {
      throw const FormatException(
        'Este registro pertence a outra conta local.',
      );
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final ownedPayload = Map<String, dynamic>.from(payload);
    if (_activeAccount != null) {
      ownedPayload['ownerId'] = _activeAccount!.id;
    }
    final entity = SyncEntity(
      id: id ?? _uuid.v4(),
      type: type,
      payload: ownedPayload,
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
    if (existing == null || !_belongsToActiveAccount(existing)) return;
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

  Future<void> restore(String id) async {
    final existing = _findAny(id);
    if (existing == null ||
        !existing.isDeleted ||
        !_belongsToActiveAccount(existing)) {
      return;
    }
    final restored = SyncEntity(
      id: existing.id,
      type: existing.type,
      payload: existing.payload,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      deviceId: _deviceId,
      revision: existing.revision + 1,
    );
    await _database.upsert(restored);
    _replaceInMemory(restored);
    notifyListeners();
  }

  /// Removes all recoverable user content while keeping a minimal tombstone.
  ///
  /// The tombstone is intentionally retained so that a later Wi-Fi merge does
  /// not resurrect a record that was permanently removed on another device.
  Future<void> purge(String id) async {
    final existing = _findAny(id);
    if (existing == null ||
        !existing.isDeleted ||
        existing.payload['purged'] == true ||
        !_belongsToActiveAccount(existing)) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final ownerId = existing.payload['ownerId']?.toString();
    final tombstone = SyncEntity(
      id: existing.id,
      type: existing.type,
      payload: <String, dynamic>{
        if (ownerId != null && ownerId.isNotEmpty) 'ownerId': ownerId,
        'purged': true,
      },
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

    for (final originalRemote in incoming) {
      final remote = _normalizeIncomingOwner(originalRemote);
      if (remote == null) {
        ignored++;
        continue;
      }
      final local = _findAny(remote.id);
      if (local != null && !_belongsToActiveAccount(local)) {
        ignored++;
        continue;
      }
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

  bool _belongsToActiveAccount(SyncEntity entity) {
    final activeId = _activeAccount?.id;
    if (activeId == null) return true;
    final ownerId = entity.payload['ownerId'] as String?;
    return ownerId == activeId;
  }

  SyncEntity? _normalizeIncomingOwner(SyncEntity entity) {
    final activeId = _activeAccount?.id;
    if (activeId == null) return entity;
    final ownerId = entity.payload['ownerId'] as String? ?? '';
    if (ownerId.isNotEmpty && ownerId != activeId) return null;
    if (ownerId == activeId) return entity;
    return SyncEntity(
      id: entity.id,
      type: entity.type,
      payload: <String, dynamic>{...entity.payload, 'ownerId': activeId},
      updatedAtMs: entity.updatedAtMs,
      deletedAtMs: entity.deletedAtMs,
      deviceId: entity.deviceId,
      revision: entity.revision,
    );
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
    final visible = all.where(_belongsToActiveAccount).toList(growable: false);
    return BackupService.createBundle(
      entities: visible,
      deviceId: _deviceId,
      ownerId: _activeAccount?.id,
      ownerName: _activeAccount?.displayName,
    );
  }

  Future<MergeResult> importBundle(List<int> bytes) async {
    await BackupService.createAutomaticSnapshot(
      await exportBundle(),
      reason: 'antes-da-importacao',
    );
    final bundle = BackupService.decodeBundle(bytes);
    final activeId = _activeAccount?.id;
    if (activeId != null &&
        bundle.ownerId != null &&
        bundle.ownerId!.isNotEmpty &&
        bundle.ownerId != activeId) {
      throw const FormatException(
        'Este backup pertence a outra conta local. Entre na conta correta antes de importar.',
      );
    }
    return mergeRemote(bundle.entities);
  }

  Future<String?> readPreference(String key) => _database.readSetting(key);

  Future<void> writePreference(String key, String value) async {
    await _database.writeSetting(key, value);
    notifyListeners();
  }

  Future<String?> readUserPreference(String key) =>
      _database.readSetting(_userPreferenceKey(key));

  Future<void> writeUserPreference(
    String key,
    String value, {
    bool notify = false,
  }) async {
    await _database.writeSetting(_userPreferenceKey(key), value);
    if (notify) notifyListeners();
  }

  String _userPreferenceKey(String key) =>
      'user:${_activeAccount?.id ?? 'legacy'}:$key';

  Future<List<LocalAccount>> listAccounts() => _accountService.listAccounts();

  Future<CreatedLocalAccount> createAccount({
    required String username,
    required String displayName,
    required String email,
    required String password,
    required String securityQuestion,
    required String securityAnswer,
    String? legacyPin,
  }) async {
    final existingAccounts = await listAccounts();
    if (existingAccounts.isEmpty && await hasPin()) {
      if (legacyPin == null || !await verifyPin(legacyPin)) {
        throw const FormatException(
          'Informe o PIN da versão anterior para proteger os dados existentes.',
        );
      }
    }
    final created = await _accountService.createAccount(
      username: username,
      displayName: displayName,
      email: email,
      password: password,
      securityQuestion: securityQuestion,
      securityAnswer: securityAnswer,
    );
    _activeAccount = created.account;
    if (existingAccounts.isEmpty) {
      await _claimLegacyData(created.account.id);
      await clearPin();
    }
    notifyListeners();
    return created;
  }

  Future<LocalAccount?> authenticate(String identifier, String password) async {
    final account = await _accountService.authenticate(identifier, password);
    if (account != null) {
      _activeAccount = account;
      notifyListeners();
    }
    return account;
  }

  Future<PasswordResetResult> resetPassword({
    required String identifier,
    required String securityAnswerOrRecoveryCode,
    required String newPassword,
  }) =>
      _accountService.resetPassword(
        identifier: identifier,
        securityAnswerOrRecoveryCode: securityAnswerOrRecoveryCode,
        newPassword: newPassword,
      );

  Future<String?> recoveryQuestion(String identifier) =>
      _accountService.recoveryQuestion(identifier);

  void logout() {
    _activeAccount = null;
    notifyListeners();
  }

  Future<void> _claimLegacyData(String ownerId) async {
    final legacy = _entities
        .where((item) => (item.payload['ownerId'] as String? ?? '').isEmpty)
        .toList(growable: false);
    if (legacy.isEmpty) return;
    await BackupService.createAutomaticSnapshot(
      BackupService.createBundle(entities: legacy, deviceId: _deviceId),
      reason: 'antes-da-migracao-de-conta',
    );
    final now = DateTime.now().millisecondsSinceEpoch;
    final claimed = legacy
        .map(
          (item) => SyncEntity(
            id: item.id,
            type: item.type,
            payload: <String, dynamic>{...item.payload, 'ownerId': ownerId},
            updatedAtMs: now,
            deletedAtMs: item.deletedAtMs,
            deviceId: _deviceId,
            revision: item.revision + 1,
          ),
        )
        .toList(growable: false);
    await _database.upsertMany(claimed);
    for (final item in claimed) {
      _replaceInMemory(item);
    }
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
