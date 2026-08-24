import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_routine_active/core/app_store.dart';
import 'package:my_routine_active/core/code_workspace.dart';
import 'package:my_routine_active/core/local_code_runner.dart';
import 'package:my_routine_active/core/sync_entity.dart';

void main() {
  group('Catálogo da IDE acadêmica', () {
    test('oferece as principais linguagens do curso', () {
      final ids = CodeLanguageCatalog.all.map((item) => item.id).toSet();

      expect(
        ids,
        containsAll(<String>{
          'dart',
          'python',
          'java',
          'javascript',
          'typescript',
          'c',
          'cpp',
          'csharp',
          'kotlin',
          'php',
          'sql',
          'web',
        }),
      );
    });

    test('detecta a linguagem pela extensão do arquivo', () {
      expect(CodeLanguageCatalog.forFileName('main.py').id, 'python');
      expect(CodeLanguageCatalog.forFileName('App.java').id, 'java');
      expect(CodeLanguageCatalog.forFileName('site.html').id, 'web');
      expect(CodeLanguageCatalog.forFileName('consulta.sql').id, 'sql');
      expect(
        CodeLanguageCatalog.forFileName(
          'arquivo.desconhecido',
          fallbackId: 'cpp',
        ).id,
        'cpp',
      );
    });

    test('bloqueia nomes perigosos e mantém nomes comuns', () {
      expect(CodeLanguageCatalog.isValidFileName('main.dart'), isTrue);
      expect(CodeLanguageCatalog.isValidFileName('modelo_aluno.py'), isTrue);
      expect(CodeLanguageCatalog.isValidFileName('../senha.txt'), isFalse);
      expect(CodeLanguageCatalog.isValidFileName('pasta/arquivo.js'), isFalse);
      expect(CodeLanguageCatalog.isValidFileName(''), isFalse);
    });

    test('isola a pasta de execução mesmo com identificador malformado', () {
      final folder = CodeWorkspaceData.runtimeFolderName('../../fora');

      expect(folder, hasLength(32));
      expect(folder, matches(RegExp(r'^[a-f0-9]+$')));
      expect(folder, CodeWorkspaceData.runtimeFolderName('../../fora'));
      expect(folder, isNot(contains('..')));
    });

    test('todo projeto novo recebe um arquivo principal e modelo', () {
      for (final language in CodeLanguageCatalog.all) {
        expect(language.mainFile, isNotEmpty);
        expect(language.template, isNotEmpty);
        expect(language.extensions, isNotEmpty);
      }
    });
  });

  test(
    'fora do Windows a execução orienta usar o aplicativo do PC',
    () async {
      final project = SyncEntity(
        id: 'project-1',
        type: EntityTypes.codeProject,
        payload: const <String, dynamic>{
          'name': 'Teste',
          'language': 'python',
          'mainFile': 'main.py',
        },
        updatedAtMs: 1,
        deviceId: 'test-device',
        revision: 1,
      );

      final result = await const LocalCodeRunner().run(
        store: AppStore(),
        project: project,
        files: const <SyncEntity>[],
      );

      expect(result.state, CodeRunState.unsupported);
      expect(result.output, contains('aplicativo do Windows'));
    },
    skip: Platform.isWindows,
  );
}
