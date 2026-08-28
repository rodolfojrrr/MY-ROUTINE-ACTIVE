import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_routine_active/core/app_store.dart';
import 'package:my_routine_active/core/backup_service.dart';
import 'package:my_routine_active/core/local_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalDatabase database;
  late AppStore store;
  late Directory snapshotRoot;

  setUp(() async {
    database = await LocalDatabase.createInMemoryForTesting();
    snapshotRoot = await Directory.systemTemp.createTemp('smart-routine-test-');
    BackupService.snapshotRootOverrideForTesting = snapshotRoot;
    store = AppStore(database: database);
    await store.initialize();
  });

  tearDown(() async {
    store.dispose();
    await database.close();
    BackupService.snapshotRootOverrideForTesting = null;
    await snapshotRoot.delete(recursive: true);
  });

  test('primeira conta assume dados legados sem apagar registros', () async {
    final legacy = await store.save(
      EntityTypes.subject,
      <String, dynamic>{'name': 'Algoritmos'},
    );
    await store.setPin('2468');

    expect(
      () => store.createAccount(
        username: 'rodolfo',
        displayName: 'Rodolfo Junior',
        email: '',
        password: 'senha-segura',
        securityQuestion: 'Qual meu primeiro curso?',
        securityAnswer: 'Sistemas',
        legacyPin: '0000',
      ),
      throwsFormatException,
    );
    expect(store.records(EntityTypes.subject).single.id, legacy.id);

    final created = await store.createAccount(
      username: 'rodolfo',
      displayName: 'Rodolfo Junior',
      email: '',
      password: 'senha-segura',
      securityQuestion: 'Qual meu primeiro curso?',
      securityAnswer: 'Sistemas',
      legacyPin: '2468',
    );

    final migrated = store.records(EntityTypes.subject).single;
    expect(migrated.id, legacy.id);
    expect(migrated.payload['name'], 'Algoritmos');
    expect(migrated.payload['ownerId'], created.account.id);

    final backup = BackupService.decodeBundle(await store.exportBundle());
    expect(backup.ownerId, created.account.id);
    expect(backup.entities.single.id, legacy.id);
  });

  test('contas locais isolam dados e permitem recuperação de senha', () async {
    await store.createAccount(
      username: 'aluno-a',
      displayName: 'Aluno A',
      email: 'a@local.test',
      password: 'senha-a',
      securityQuestion: 'Cor favorita?',
      securityAnswer: 'Azul',
    );
    await store.save(
      EntityTypes.subject,
      <String, dynamic>{'name': 'Banco de Dados'},
    );

    await store.createAccount(
      username: 'aluno-b',
      displayName: 'Aluno B',
      email: '',
      password: 'senha-b',
      securityQuestion: 'Cidade natal?',
      securityAnswer: 'Recife',
    );
    final secondSubject = await store.save(
      EntityTypes.subject,
      <String, dynamic>{'name': 'Redes'},
    );
    expect(
      store.records(EntityTypes.subject).map((item) => item.payload['name']),
      <Object?>['Redes'],
    );
    await store.remove(secondSubject.id);
    expect(store.records(EntityTypes.subject), isEmpty);
    expect(store.deletedRecords().single.id, secondSubject.id);
    await store.restore(secondSubject.id);
    expect(store.records(EntityTypes.subject).single.payload['name'], 'Redes');

    store.logout();
    expect(await store.authenticate('aluno-a', 'senha-a'), isNotNull);
    expect(
      store.records(EntityTypes.subject).map((item) => item.payload['name']),
      <Object?>['Banco de Dados'],
    );
    expect(await store.recoveryQuestion('a@local.test'), 'Cor favorita?');

    final reset = await store.resetPassword(
      identifier: 'aluno-a',
      securityAnswerOrRecoveryCode: 'azul',
      newPassword: 'senha-a-nova',
    );
    expect(reset.newRecoveryCode, startsWith('SR-'));
    store.logout();
    expect(await store.authenticate('aluno-a', 'senha-a'), isNull);
    expect(await store.authenticate('aluno-a', 'senha-a-nova'), isNotNull);
  });
}
