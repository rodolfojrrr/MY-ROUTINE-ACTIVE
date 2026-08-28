import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'local_database.dart';

class LocalAccount {
  const LocalAccount({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    required this.securityQuestion,
    required this.createdAtMs,
    required this.updatedAtMs,
  });

  final String id;
  final String username;
  final String displayName;
  final String email;
  final String securityQuestion;
  final int createdAtMs;
  final int updatedAtMs;

  factory LocalAccount.fromMap(Map<String, Object?> map) => LocalAccount(
        id: map['id']! as String,
        username: map['username']! as String,
        displayName: map['display_name']! as String,
        email: map['email'] as String? ?? '',
        securityQuestion: map['security_question']! as String,
        createdAtMs: (map['created_at']! as num).toInt(),
        updatedAtMs: (map['updated_at']! as num).toInt(),
      );
}

class CreatedLocalAccount {
  const CreatedLocalAccount({
    required this.account,
    required this.recoveryCode,
  });

  final LocalAccount account;
  final String recoveryCode;
}

class PasswordResetResult {
  const PasswordResetResult({
    required this.account,
    required this.newRecoveryCode,
  });

  final LocalAccount account;
  final String newRecoveryCode;
}

class LocalAccountService {
  LocalAccountService({LocalDatabase? database})
      : _database = database ?? LocalDatabase.instance;

  final LocalDatabase _database;
  final Random _random = Random.secure();

  Future<List<LocalAccount>> listAccounts() => _database.listAccounts();

  Future<CreatedLocalAccount> createAccount({
    required String username,
    required String displayName,
    required String email,
    required String password,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    final normalizedUsername = normalizeIdentifier(username);
    final normalizedEmail = normalizeIdentifier(email);
    final cleanName = displayName.trim();
    final cleanQuestion = securityQuestion.trim();
    final cleanAnswer = normalizeAnswer(securityAnswer);

    if (normalizedUsername.length < 3) {
      throw const FormatException(
          'O usuário precisa ter pelo menos 3 caracteres.');
    }
    if (cleanName.length < 2) {
      throw const FormatException(
          'Informe o nome que aparecerá no aplicativo.');
    }
    if (password.length < 6) {
      throw const FormatException(
          'A senha precisa ter pelo menos 6 caracteres.');
    }
    if (cleanQuestion.length < 4 || cleanAnswer.length < 2) {
      throw const FormatException(
          'Defina uma pergunta e uma resposta de segurança válidas.');
    }
    if (await _database.findAccountByIdentifier(normalizedUsername) != null) {
      throw const FormatException('Este nome de usuário já está em uso.');
    }
    if (normalizedEmail.isNotEmpty &&
        await _database.findAccountByIdentifier(normalizedEmail) != null) {
      throw const FormatException(
          'Este e-mail já está ligado a uma conta local.');
    }

    final passwordSalt = _randomToken(24);
    final answerSalt = _randomToken(24);
    final recoverySalt = _randomToken(24);
    final recoveryCode = _recoveryCode();
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = sha256
        .convert(utf8.encode('smart-routine-si:$normalizedUsername'))
        .toString()
        .substring(0, 32);
    final hashes = await Future.wait<String>(<Future<String>>[
      _derive(password, passwordSalt),
      _derive(cleanAnswer, answerSalt),
      _derive(normalizeRecoveryCode(recoveryCode), recoverySalt),
    ]);
    final row = <String, Object?>{
      'id': id,
      'username': normalizedUsername,
      'username_normalized': normalizedUsername,
      'display_name': cleanName,
      'email': email.trim(),
      'email_normalized': normalizedEmail,
      'password_salt': passwordSalt,
      'password_hash': hashes[0],
      'recovery_salt': recoverySalt,
      'recovery_hash': hashes[2],
      'security_question': cleanQuestion,
      'answer_salt': answerSalt,
      'answer_hash': hashes[1],
      'created_at': now,
      'updated_at': now,
    };
    await _database.insertAccount(row);
    return CreatedLocalAccount(
      account: LocalAccount.fromMap(row),
      recoveryCode: recoveryCode,
    );
  }

  Future<LocalAccount?> authenticate(String identifier, String password) async {
    final row = await _database.findAccountByIdentifier(
      normalizeIdentifier(identifier),
    );
    if (row == null) return null;
    final actual = await _derive(password, row['password_salt']! as String);
    if (!_constantTimeEquals(actual, row['password_hash']! as String)) {
      return null;
    }
    return LocalAccount.fromMap(row);
  }

  Future<String?> recoveryQuestion(String identifier) async {
    final row = await _database.findAccountByIdentifier(
      normalizeIdentifier(identifier),
    );
    return row?['security_question'] as String?;
  }

  Future<PasswordResetResult> resetPassword({
    required String identifier,
    required String securityAnswerOrRecoveryCode,
    required String newPassword,
  }) async {
    if (newPassword.length < 6) {
      throw const FormatException(
          'A nova senha precisa ter pelo menos 6 caracteres.');
    }
    final row = await _database.findAccountByIdentifier(
      normalizeIdentifier(identifier),
    );
    if (row == null) {
      throw const FormatException('Conta local não encontrada.');
    }
    final input = securityAnswerOrRecoveryCode.trim();
    final normalizedRecovery = normalizeRecoveryCode(input);
    final looksLikeCode =
        normalizedRecovery.startsWith('SR') && normalizedRecovery.length >= 14;
    final expected = looksLikeCode
        ? row['recovery_hash']! as String
        : row['answer_hash']! as String;
    final salt = looksLikeCode
        ? row['recovery_salt']! as String
        : row['answer_salt']! as String;
    final value = looksLikeCode ? normalizedRecovery : normalizeAnswer(input);
    final actual = await _derive(value, salt);
    if (!_constantTimeEquals(actual, expected)) {
      throw const FormatException(
          'Resposta ou código de recuperação inválido.');
    }

    final passwordSalt = _randomToken(24);
    final recoverySalt = _randomToken(24);
    final newRecoveryCode = _recoveryCode();
    final hashes = await Future.wait<String>(<Future<String>>[
      _derive(newPassword, passwordSalt),
      _derive(normalizeRecoveryCode(newRecoveryCode), recoverySalt),
    ]);
    await _database.updateAccountCredentials(
      id: row['id']! as String,
      passwordSalt: passwordSalt,
      passwordHash: hashes[0],
      recoverySalt: recoverySalt,
      recoveryHash: hashes[1],
    );
    final updated = await _database.findAccountByIdentifier(
      row['id']! as String,
      includeId: true,
    );
    return PasswordResetResult(
      account: LocalAccount.fromMap(updated!),
      newRecoveryCode: newRecoveryCode,
    );
  }

  static String normalizeIdentifier(String value) => value.trim().toLowerCase();

  static String normalizeAnswer(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static String normalizeRecoveryCode(String value) =>
      value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  Future<String> _derive(String value, String salt) => compute(
        _deriveCredential,
        <String, String>{'value': value, 'salt': salt},
      );

  String _randomToken(int bytes) {
    final data = Uint8List.fromList(
      List<int>.generate(bytes, (_) => _random.nextInt(256)),
    );
    return base64UrlEncode(data).replaceAll('=', '');
  }

  String _recoveryCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final chars = List<String>.generate(
      16,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    );
    return 'SR-${chars.sublist(0, 4).join()}-${chars.sublist(4, 8).join()}-'
        '${chars.sublist(8, 12).join()}-${chars.sublist(12).join()}';
  }

  bool _constantTimeEquals(String left, String right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
    }
    return difference == 0;
  }
}

String _deriveCredential(Map<String, String> input) {
  List<int> bytes = utf8.encode('${input['salt']}:${input['value']}');
  for (var round = 0; round < 24000; round++) {
    bytes = sha256
        .convert(<int>[...bytes, round & 0xff, (round >> 8) & 0xff]).bytes;
  }
  return base64UrlEncode(bytes).replaceAll('=', '');
}
