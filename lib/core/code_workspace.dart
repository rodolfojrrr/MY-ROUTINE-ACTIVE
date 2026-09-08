import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_store.dart';
import 'sync_entity.dart';

class CodeLanguageDefinition {
  const CodeLanguageDefinition({
    required this.id,
    required this.label,
    required this.mainFile,
    required this.extensions,
    required this.template,
    required this.runtimeLabel,
  });

  final String id;
  final String label;
  final String mainFile;
  final List<String> extensions;
  final String template;
  final String runtimeLabel;
}

class CodeLanguageCatalog {
  static const dart = CodeLanguageDefinition(
    id: 'dart',
    label: 'Dart',
    mainFile: 'main.dart',
    extensions: <String>['dart'],
    runtimeLabel: 'Dart SDK',
    template: '''void main() {
  print('Olá, Studium SI!');
}
''',
  );

  static const python = CodeLanguageDefinition(
    id: 'python',
    label: 'Python',
    mainFile: 'main.py',
    extensions: <String>['py'],
    runtimeLabel: 'Python 3',
    template: '''def main():
    print("Olá, Studium SI!")


if __name__ == "__main__":
    main()
''',
  );

  static const java = CodeLanguageDefinition(
    id: 'java',
    label: 'Java',
    mainFile: 'Main.java',
    extensions: <String>['java'],
    runtimeLabel: 'JDK',
    template: '''public class Main {
    public static void main(String[] args) {
        System.out.println("Olá, Studium SI!");
    }
}
''',
  );

  static const javascript = CodeLanguageDefinition(
    id: 'javascript',
    label: 'JavaScript',
    mainFile: 'main.js',
    extensions: <String>['js', 'mjs', 'cjs'],
    runtimeLabel: 'Node.js',
    template: '''function main() {
  console.log('Olá, Studium SI!');
}

main();
''',
  );

  static const typescript = CodeLanguageDefinition(
    id: 'typescript',
    label: 'TypeScript',
    mainFile: 'main.ts',
    extensions: <String>['ts', 'tsx'],
    runtimeLabel: 'Node.js + TypeScript',
    template: '''function saudacao(nome: string): string {
  return 'Olá, ' + nome + '!';
}

console.log(saudacao('Studium SI'));
''',
  );

  static const c = CodeLanguageDefinition(
    id: 'c',
    label: 'C',
    mainFile: 'main.c',
    extensions: <String>['c', 'h'],
    runtimeLabel: 'GCC',
    template: '''#include <stdio.h>

int main(void) {
    printf("Olá, Studium SI!\\n");
    return 0;
}
''',
  );

  static const cpp = CodeLanguageDefinition(
    id: 'cpp',
    label: 'C++',
    mainFile: 'main.cpp',
    extensions: <String>['cpp', 'cc', 'cxx', 'hpp', 'h'],
    runtimeLabel: 'G++',
    template: '''#include <iostream>

int main() {
    std::cout << "Olá, Studium SI!" << std::endl;
    return 0;
}
''',
  );

  static const csharp = CodeLanguageDefinition(
    id: 'csharp',
    label: 'C#',
    mainFile: 'Program.cs',
    extensions: <String>['cs'],
    runtimeLabel: '.NET SDK',
    template: '''using System;

class Program
{
    static void Main()
    {
        Console.WriteLine("Olá, Studium SI!");
    }
}
''',
  );

  static const kotlin = CodeLanguageDefinition(
    id: 'kotlin',
    label: 'Kotlin',
    mainFile: 'Main.kt',
    extensions: <String>['kt', 'kts'],
    runtimeLabel: 'Kotlin/JDK',
    template: '''fun main() {
    println("Olá, Studium SI!")
}
''',
  );

  static const php = CodeLanguageDefinition(
    id: 'php',
    label: 'PHP',
    mainFile: 'main.php',
    extensions: <String>['php'],
    runtimeLabel: 'PHP',
    template: '''<?php

echo "Olá, Studium SI!\\n";
''',
  );

  static const sql = CodeLanguageDefinition(
    id: 'sql',
    label: 'SQL',
    mainFile: 'consulta.sql',
    extensions: <String>['sql'],
    runtimeLabel: 'SQLite CLI',
    template: '''CREATE TABLE alunos (
  id INTEGER PRIMARY KEY,
  nome TEXT NOT NULL
);

INSERT INTO alunos (nome) VALUES ('Rodolfo');
SELECT * FROM alunos;
''',
  );

  static const web = CodeLanguageDefinition(
    id: 'web',
    label: 'HTML / CSS',
    mainFile: 'index.html',
    extensions: <String>['html', 'htm', 'css'],
    runtimeLabel: 'Navegador',
    template: '''<!doctype html>
<html lang="pt-BR">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Meu projeto</title>
    <style>
      body { font-family: sans-serif; padding: 2rem; background: #071b35; color: white; }
    </style>
  </head>
  <body>
    <h1>Olá, Studium SI!</h1>
  </body>
</html>
''',
  );

  static const json = CodeLanguageDefinition(
    id: 'json',
    label: 'JSON',
    mainFile: 'dados.json',
    extensions: <String>['json'],
    runtimeLabel: 'Somente edição',
    template: '''{
  "curso": "Sistemas de Informação",
  "ativo": true
}
''',
  );

  static const all = <CodeLanguageDefinition>[
    dart,
    python,
    java,
    javascript,
    typescript,
    c,
    cpp,
    csharp,
    kotlin,
    php,
    sql,
    web,
    json,
  ];

  static CodeLanguageDefinition byId(String? id) {
    return all.firstWhere(
      (language) => language.id == id,
      orElse: () => dart,
    );
  }

  static CodeLanguageDefinition forFileName(
    String fileName, {
    String? fallbackId,
  }) {
    final extension = p.extension(fileName).replaceFirst('.', '').toLowerCase();
    for (final language in all) {
      if (language.extensions.contains(extension)) return language;
    }
    return byId(fallbackId);
  }

  static bool isValidFileName(String value) {
    final name = value.trim();
    if (name.isEmpty || name.length > 120) return false;
    if (name == '.' || name == '..') return false;
    return !RegExp(r'[\\/:*?"<>|]').hasMatch(name);
  }
}

class CodeWorkspaceData {
  static String runtimeFolderName(String projectId) {
    return sha256.convert(utf8.encode(projectId)).toString().substring(0, 32);
  }

  static List<SyncEntity> sortedProjects(AppStore store) {
    final items = store.records(EntityTypes.codeProject).toList();
    items.sort(
      (a, b) => (a.payload['name'] as String? ?? '').toLowerCase().compareTo(
            (b.payload['name'] as String? ?? '').toLowerCase(),
          ),
    );
    return items;
  }

  static List<SyncEntity> filesForProject(AppStore store, String projectId) {
    final files = store
        .records(EntityTypes.codeFile)
        .where((item) => item.payload['projectId'] == projectId)
        .toList();
    files.sort((a, b) {
      final mainA = a.payload['isMain'] == true ? 0 : 1;
      final mainB = b.payload['isMain'] == true ? 0 : 1;
      if (mainA != mainB) return mainA.compareTo(mainB);
      return (a.payload['name'] as String? ?? '').toLowerCase().compareTo(
            (b.payload['name'] as String? ?? '').toLowerCase(),
          );
    });
    return files;
  }

  static Future<SyncEntity> createProject(
    AppStore store, {
    required String name,
    required CodeLanguageDefinition language,
    String description = '',
    String? semesterId,
    String? subjectId,
    String? contentId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final project = await store.save(EntityTypes.codeProject, <String, dynamic>{
      'name': name.trim(),
      'description': description.trim(),
      'language': language.id,
      'semesterId': semesterId,
      'subjectId': subjectId,
      'contentId': contentId,
      'mainFile': language.mainFile,
      'createdAt': now,
      'lastOpenedAt': now,
    });
    await store.save(EntityTypes.codeFile, <String, dynamic>{
      'projectId': project.id,
      'name': language.mainFile,
      'language': language.id,
      'content': language.template,
      'isMain': true,
      'createdAt': now,
    });
    return project;
  }

  static Future<void> deleteFile(AppStore store, SyncEntity file) async {
    await store.remove(file.id);
  }

  static Future<void> deleteProject(
    AppStore store,
    SyncEntity project,
  ) async {
    for (final file in filesForProject(store, project.id)) {
      await store.remove(file.id);
    }
    final runs = store
        .records(EntityTypes.codeRun)
        .where((item) => item.payload['projectId'] == project.id)
        .toList();
    for (final run in runs) {
      await store.remove(run.id);
    }
    await store.remove(project.id);
    final support = await getApplicationSupportDirectory();
    final directory = Directory(
      p.join(
        support.path,
        'MyRoutineActive',
        'code_workspace',
        runtimeFolderName(project.id),
      ),
    );
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
