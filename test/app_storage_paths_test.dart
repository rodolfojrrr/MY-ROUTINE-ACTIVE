import 'package:flutter_test/flutter_test.dart';
import 'package:my_routine_active/core/app_storage_paths.dart';

void main() {
  test('banco legado do Windows sempre tem prioridade quando existe', () {
    final selected = AppStoragePaths.selectWindowsDataDirectoryPath(
      legacyPath:
          r'C:\Users\Rodolfo\AppData\Roaming\Rodolfo Junior\Smart Routine SI\MyRoutineActive',
      studiumPath:
          r'C:\Users\Rodolfo\AppData\Roaming\Rodolfo Junior\Studium SI\MyRoutineActive',
      legacyDatabaseExists: true,
      studiumDatabaseExists: true,
    );

    expect(selected, contains(r'Smart Routine SI\MyRoutineActive'));
  });

  test('banco Studium é aceito quando não há banco legado', () {
    final selected = AppStoragePaths.selectWindowsDataDirectoryPath(
      legacyPath: 'legado',
      studiumPath: 'studium',
      legacyDatabaseExists: false,
      studiumDatabaseExists: true,
    );

    expect(selected, 'studium');
  });

  test('instalação nova usa caminho interno estável', () {
    final selected = AppStoragePaths.selectWindowsDataDirectoryPath(
      legacyPath: 'legado',
      studiumPath: 'studium',
      legacyDatabaseExists: false,
      studiumDatabaseExists: false,
    );

    expect(selected, 'legado');
  });
}
