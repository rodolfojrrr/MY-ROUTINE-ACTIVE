import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Centraliza os caminhos locais para que uma troca de nome visual do
/// aplicativo nunca faça o Windows abrir outro banco por engano.
class AppStoragePaths {
  AppStoragePaths._();

  static const companyName = 'Rodolfo Junior';
  static const legacyWindowsProductName = 'Smart Routine SI';
  static const currentWindowsProductName = 'Studium SI';
  static const dataFolderName = 'MyRoutineActive';
  static const databaseFileName = 'my_routine_active.db';

  static Future<Directory> dataDirectory() async {
    if (Platform.isWindows) {
      final roamingPath = Platform.environment['APPDATA']?.trim() ?? '';
      if (roamingPath.isNotEmpty) {
        final legacyPath = windowsDataDirectoryPath(
          roamingPath,
          productName: legacyWindowsProductName,
        );
        final studiumPath = windowsDataDirectoryPath(
          roamingPath,
          productName: currentWindowsProductName,
        );
        final legacyDatabaseExists = File(p.join(legacyPath, databaseFileName))
            .existsSync();
        final studiumDatabaseExists = File(
          p.join(studiumPath, databaseFileName),
        ).existsSync();

        return Directory(
          selectWindowsDataDirectoryPath(
            legacyPath: legacyPath,
            studiumPath: studiumPath,
            legacyDatabaseExists: legacyDatabaseExists,
            studiumDatabaseExists: studiumDatabaseExists,
          ),
        );
      }
    }

    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, dataFolderName));
  }

  static String windowsDataDirectoryPath(
    String roamingPath, {
    required String productName,
  }) => p.join(roamingPath, companyName, productName, dataFolderName);

  /// O banco do nome antigo tem prioridade porque ele contém os dados das
  /// instalações existentes. O caminho Studium é usado somente quando o
  /// banco legado realmente não existe.
  static String selectWindowsDataDirectoryPath({
    required String legacyPath,
    required String studiumPath,
    required bool legacyDatabaseExists,
    required bool studiumDatabaseExists,
  }) {
    if (legacyDatabaseExists) return legacyPath;
    if (studiumDatabaseExists) return studiumPath;
    return legacyPath;
  }
}
