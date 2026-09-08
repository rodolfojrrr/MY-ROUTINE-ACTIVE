import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_store.dart';
import 'code_workspace.dart';
import 'sync_entity.dart';

enum CodeRunState { success, failed, runtimeMissing, unsupported }

class CodeRunResult {
  const CodeRunResult({
    required this.state,
    required this.output,
    required this.command,
    required this.elapsed,
    this.exitCode,
  });

  final CodeRunState state;
  final String output;
  final String command;
  final Duration elapsed;
  final int? exitCode;

  bool get succeeded => state == CodeRunState.success;
}

class CodeRuntimeStatus {
  const CodeRuntimeStatus({
    required this.language,
    required this.available,
    required this.detail,
  });

  final CodeLanguageDefinition language;
  final bool available;
  final String detail;
}

class LocalCodeRunner {
  const LocalCodeRunner();

  bool get canRunOnThisDevice => Platform.isWindows;

  Future<List<CodeRuntimeStatus>> inspectRuntimes() async {
    final statuses = <CodeRuntimeStatus>[];
    for (final language in CodeLanguageCatalog.all) {
      if (language.id == 'json') {
        statuses.add(
          CodeRuntimeStatus(
            language: language,
            available: false,
            detail: 'Formato de dados: não possui execução.',
          ),
        );
        continue;
      }
      if (language.id == 'web') {
        statuses.add(
          CodeRuntimeStatus(
            language: language,
            available: Platform.isWindows,
            detail: Platform.isWindows
                ? 'Pré-visualização pelo navegador padrão.'
                : 'A pré-visualização é aberta no PC.',
          ),
        );
        continue;
      }
      if (!Platform.isWindows) {
        statuses.add(
          CodeRuntimeStatus(
            language: language,
            available: false,
            detail: 'Edite e sincronize aqui; execute no aplicativo do PC.',
          ),
        );
        continue;
      }
      final commands = _requiredCommands(language.id);
      final missing = <String>[];
      for (final alternatives in commands) {
        if (await _resolveExecutable(alternatives) == null) {
          missing.add(alternatives.join(' / '));
        }
      }
      statuses.add(
        CodeRuntimeStatus(
          language: language,
          available: missing.isEmpty,
          detail: missing.isEmpty
              ? '${language.runtimeLabel} encontrado.'
              : 'Instale: ${missing.join(' e ')}.',
        ),
      );
    }
    return statuses;
  }

  Future<CodeRunResult> run({
    required AppStore store,
    required SyncEntity project,
    required List<SyncEntity> files,
  }) async {
    final stopwatch = Stopwatch()..start();
    final language = CodeLanguageCatalog.byId(
      project.payload['language'] as String?,
    );
    if (!Platform.isWindows) {
      return CodeRunResult(
        state: CodeRunState.unsupported,
        output:
            'A edição funciona neste aparelho e será sincronizada por Wi‑Fi.\n'
            'Para executar ${language.label}, abra o mesmo projeto no aplicativo do Windows.',
        command: '',
        elapsed: stopwatch.elapsed,
      );
    }
    if (language.id == 'json') {
      return CodeRunResult(
        state: CodeRunState.unsupported,
        output: 'JSON é um formato de dados e não possui comando de execução.',
        command: '',
        elapsed: stopwatch.elapsed,
      );
    }

    try {
      final directory = await _writeWorkspace(project.id, files);
      final mainName =
          project.payload['mainFile'] as String? ?? language.mainFile;
      final mainPath = p.join(directory.path, mainName);
      if (!await File(mainPath).exists()) {
        return CodeRunResult(
          state: CodeRunState.failed,
          output: 'O arquivo principal “$mainName” não existe. '
              'Marque um arquivo como principal nas opções do projeto.',
          command: '',
          elapsed: stopwatch.elapsed,
          exitCode: 2,
        );
      }

      final plan = await _buildPlan(language, directory, mainName);
      if (plan.missingRuntime != null) {
        return CodeRunResult(
          state: CodeRunState.runtimeMissing,
          output: '${plan.missingRuntime}\n\n'
              'O Studium SI não baixa compiladores sozinho e continua 100% local. '
              'Depois de instalar o ambiente no Windows, use “Verificar ambientes”.',
          command: '',
          elapsed: stopwatch.elapsed,
        );
      }

      final output = StringBuffer();
      var lastExitCode = 0;
      final displayedCommands = <String>[];
      for (final step in plan.steps) {
        displayedCommands.add(step.displayCommand);
        output.writeln(r'$ ' + step.displayCommand);
        final result = await _execute(
          step,
          workingDirectory: directory.path,
          timeout: const Duration(seconds: 30),
        );
        lastExitCode = result.exitCode;
        if (result.stdout.trim().isNotEmpty) {
          output.writeln(result.stdout.trim());
        }
        if (result.stderr.trim().isNotEmpty) {
          output.writeln(result.stderr.trim());
        }
        if (lastExitCode != 0) break;
      }
      stopwatch.stop();
      final text = output.toString().trim();
      final result = CodeRunResult(
        state: lastExitCode == 0 ? CodeRunState.success : CodeRunState.failed,
        output: text.isEmpty
            ? (lastExitCode == 0
                ? 'Programa finalizado sem saída.'
                : 'A execução terminou com erro.')
            : text,
        command: displayedCommands.join(' && '),
        elapsed: stopwatch.elapsed,
        exitCode: lastExitCode,
      );
      await store.save(EntityTypes.codeRun, <String, dynamic>{
        'projectId': project.id,
        'language': language.id,
        'state': result.state.name,
        'output': result.output.length > 30000
            ? result.output.substring(0, 30000)
            : result.output,
        'command': result.command,
        'exitCode': result.exitCode,
        'elapsedMs': result.elapsed.inMilliseconds,
        'ranAt': DateTime.now().millisecondsSinceEpoch,
      });
      return result;
    } on TimeoutException {
      stopwatch.stop();
      return CodeRunResult(
        state: CodeRunState.failed,
        output: 'A execução passou de 30 segundos e foi interrompida. '
            'Verifique loops infinitos ou programas aguardando entrada.',
        command: '',
        elapsed: stopwatch.elapsed,
        exitCode: -1,
      );
    } catch (error) {
      stopwatch.stop();
      return CodeRunResult(
        state: CodeRunState.failed,
        output: 'Não foi possível iniciar a execução local.\n$error',
        command: '',
        elapsed: stopwatch.elapsed,
        exitCode: -1,
      );
    }
  }

  Future<Directory> _writeWorkspace(
    String projectId,
    List<SyncEntity> files,
  ) async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory(
      p.join(
        support.path,
        'MyRoutineActive',
        'code_workspace',
        CodeWorkspaceData.runtimeFolderName(projectId),
      ),
    );
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    await directory.create(recursive: true);
    for (final file in files) {
      final name = file.payload['name'] as String? ?? '';
      if (!CodeLanguageCatalog.isValidFileName(name)) continue;
      final contents = file.payload['content'] as String? ?? '';
      await File(p.join(directory.path, name)).writeAsString(contents);
    }
    return directory;
  }

  Future<_RunPlan> _buildPlan(
    CodeLanguageDefinition language,
    Directory directory,
    String mainName,
  ) async {
    Future<String?> command(List<String> alternatives) =>
        _resolveExecutable(alternatives);

    switch (language.id) {
      case 'dart':
        final dart = await command(const <String>['dart']);
        return dart == null
            ? const _RunPlan.missing('Dart SDK não encontrado.')
            : _RunPlan(<_CommandStep>[
                _CommandStep(dart, <String>['run', mainName]),
              ]);
      case 'python':
        final python = await command(const <String>['python', 'py']);
        return python == null
            ? const _RunPlan.missing('Python 3 não encontrado.')
            : _RunPlan(<_CommandStep>[
                _CommandStep(
                  python,
                  p.basenameWithoutExtension(python).toLowerCase() == 'py'
                      ? <String>['-3', mainName]
                      : <String>[mainName],
                ),
              ]);
      case 'javascript':
        final node = await command(const <String>['node']);
        return node == null
            ? const _RunPlan.missing('Node.js não encontrado.')
            : _RunPlan(<_CommandStep>[
                _CommandStep(node, <String>[mainName]),
              ]);
      case 'typescript':
        final tsc = await command(const <String>['tsc']);
        final node = await command(const <String>['node']);
        if (tsc == null || node == null) {
          return const _RunPlan.missing(
            'Node.js e o compilador TypeScript não foram encontrados.',
          );
        }
        final outputName = '${p.basenameWithoutExtension(mainName)}.js';
        return _RunPlan(<_CommandStep>[
          _CommandStep(tsc, <String>[
            mainName,
            '--outDir',
            'dist',
            '--target',
            'ES2020',
            '--module',
            'commonjs',
          ]),
          _CommandStep(node, <String>[p.join('dist', outputName)]),
        ]);
      case 'java':
        final javac = await command(const <String>['javac']);
        final java = await command(const <String>['java']);
        if (javac == null || java == null) {
          return const _RunPlan.missing('JDK não encontrado.');
        }
        return _RunPlan(<_CommandStep>[
          _CommandStep(javac, <String>[mainName]),
          _CommandStep(java, <String>[p.basenameWithoutExtension(mainName)]),
        ]);
      case 'kotlin':
        final kotlinc = await command(const <String>['kotlinc']);
        final java = await command(const <String>['java']);
        if (kotlinc == null || java == null) {
          return const _RunPlan.missing(
              'Kotlin Compiler e JDK não encontrados.');
        }
        final sources = await _sourceFiles(directory, const <String>{'kt'});
        return _RunPlan(<_CommandStep>[
          _CommandStep(kotlinc, <String>[
            ...sources,
            '-include-runtime',
            '-d',
            'programa.jar',
          ]),
          _CommandStep(java, const <String>['-jar', 'programa.jar']),
        ]);
      case 'c':
        final gcc = await command(const <String>['gcc']);
        final sources = await _sourceFiles(directory, const <String>{'c'});
        return gcc == null
            ? const _RunPlan.missing('GCC não encontrado.')
            : _RunPlan(<_CommandStep>[
                _CommandStep(gcc, <String>[
                  ...sources,
                  '-O2',
                  '-o',
                  'programa.exe',
                ]),
                _CommandStep(p.join(directory.path, 'programa.exe'), const []),
              ]);
      case 'cpp':
        final compiler = await command(const <String>['g++']);
        final sources = await _sourceFiles(
          directory,
          const <String>{'cpp', 'cc', 'cxx', 'c'},
        );
        return compiler == null
            ? const _RunPlan.missing('G++ não encontrado.')
            : _RunPlan(<_CommandStep>[
                _CommandStep(
                  compiler,
                  <String>[...sources, '-O2', '-o', 'programa.exe'],
                ),
                _CommandStep(p.join(directory.path, 'programa.exe'), const []),
              ]);
      case 'csharp':
        final dotnet = await command(const <String>['dotnet']);
        if (dotnet == null) {
          return const _RunPlan.missing('.NET SDK não encontrado.');
        }
        final projectFile =
            File(p.join(directory.path, 'SmartRoutineCode.csproj'));
        await projectFile.writeAsString('''<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
</Project>
''');
        return _RunPlan(<_CommandStep>[
          _CommandStep(
            dotnet,
            const <String>['run', '--project', 'SmartRoutineCode.csproj'],
          ),
        ]);
      case 'php':
        final php = await command(const <String>['php']);
        return php == null
            ? const _RunPlan.missing('PHP não encontrado.')
            : _RunPlan(<_CommandStep>[
                _CommandStep(php, <String>[mainName]),
              ]);
      case 'sql':
        final sqlite = await command(const <String>['sqlite3']);
        return sqlite == null
            ? const _RunPlan.missing('SQLite CLI não encontrado.')
            : _RunPlan(<_CommandStep>[
                _CommandStep(
                  sqlite,
                  const <String>[':memory:'],
                  stdinText: await File(p.join(directory.path, mainName))
                      .readAsString(),
                ),
              ]);
      case 'web':
        return _RunPlan(<_CommandStep>[
          _CommandStep(
            'cmd.exe',
            <String>['/c', 'start', '', p.join(directory.path, mainName)],
          ),
        ]);
      default:
        return const _RunPlan.missing('Linguagem sem executor configurado.');
    }
  }

  List<List<String>> _requiredCommands(String languageId) {
    return switch (languageId) {
      'dart' => const <List<String>>[
          <String>['dart'],
        ],
      'python' => const <List<String>>[
          <String>['python', 'py'],
        ],
      'java' => const <List<String>>[
          <String>['javac'],
          <String>['java'],
        ],
      'javascript' => const <List<String>>[
          <String>['node'],
        ],
      'typescript' => const <List<String>>[
          <String>['tsc'],
          <String>['node'],
        ],
      'c' => const <List<String>>[
          <String>['gcc'],
        ],
      'cpp' => const <List<String>>[
          <String>['g++'],
        ],
      'csharp' => const <List<String>>[
          <String>['dotnet'],
        ],
      'kotlin' => const <List<String>>[
          <String>['kotlinc'],
          <String>['java'],
        ],
      'php' => const <List<String>>[
          <String>['php'],
        ],
      'sql' => const <List<String>>[
          <String>['sqlite3'],
        ],
      _ => const <List<String>>[],
    };
  }

  Future<List<String>> _sourceFiles(
    Directory directory,
    Set<String> extensions,
  ) async {
    final names = <String>[];
    await for (final entry in directory.list(followLinks: false)) {
      if (entry is! File) continue;
      final extension =
          p.extension(entry.path).replaceFirst('.', '').toLowerCase();
      if (extensions.contains(extension)) {
        names.add(p.basename(entry.path));
      }
    }
    names.sort();
    return names;
  }

  Future<String?> _resolveExecutable(List<String> alternatives) async {
    if (!Platform.isWindows) return null;
    for (final name in alternatives) {
      try {
        final result = await Process.run(
          'where.exe',
          <String>[name],
          runInShell: false,
        ).timeout(const Duration(seconds: 3));
        if (result.exitCode == 0) {
          final lines = result.stdout
              .toString()
              .split(RegExp(r'[\r\n]+'))
              .where((line) => line.trim().isNotEmpty);
          if (lines.isNotEmpty) return lines.first.trim();
        }
      } catch (_) {}
    }
    return null;
  }

  Future<_ProcessOutput> _execute(
    _CommandStep step, {
    required String workingDirectory,
    required Duration timeout,
  }) async {
    final process = await Process.start(
      step.executable,
      step.arguments,
      workingDirectory: workingDirectory,
      runInShell: false,
    );
    if (step.stdinText != null) {
      process.stdin.write(step.stdinText);
    }
    await process.stdin.close();

    final stdoutBuffer = _LimitedOutputBuffer();
    final stderrBuffer = _LimitedOutputBuffer();
    final stdoutDone = const Utf8Decoder(allowMalformed: true)
        .bind(process.stdout)
        .forEach(stdoutBuffer.write);
    final stderrDone = const Utf8Decoder(allowMalformed: true)
        .bind(process.stderr)
        .forEach(stderrBuffer.write);
    int exitCode;
    try {
      exitCode = await process.exitCode.timeout(timeout);
    } on TimeoutException {
      await _terminateProcessTree(process);
      rethrow;
    }
    await Future.wait<void>(<Future<void>>[stdoutDone, stderrDone]);
    return _ProcessOutput(
      exitCode: exitCode,
      stdout: stdoutBuffer.toString(),
      stderr: stderrBuffer.toString(),
    );
  }

  Future<void> _terminateProcessTree(Process process) async {
    try {
      final result = await Process.run(
        'taskkill.exe',
        <String>['/PID', '${process.pid}', '/T', '/F'],
        runInShell: false,
      ).timeout(const Duration(seconds: 3));
      if (result.exitCode == 0) return;
    } catch (_) {}
    process.kill();
  }
}

class _RunPlan {
  const _RunPlan(this.steps) : missingRuntime = null;

  const _RunPlan.missing(this.missingRuntime) : steps = const <_CommandStep>[];

  final List<_CommandStep> steps;
  final String? missingRuntime;
}

class _CommandStep {
  const _CommandStep(
    this.executable,
    this.arguments, {
    this.stdinText,
  });

  final String executable;
  final List<String> arguments;
  final String? stdinText;

  String get displayCommand {
    final executableName = p.basename(executable);
    final quoted = arguments.map((argument) {
      return argument.contains(' ') ? '"$argument"' : argument;
    });
    return <String>[executableName, ...quoted].join(' ');
  }
}

class _ProcessOutput {
  const _ProcessOutput({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

class _LimitedOutputBuffer {
  static const limit = 200000;
  final StringBuffer _buffer = StringBuffer();
  var _length = 0;
  var _truncated = false;

  void write(String chunk) {
    if (_truncated) return;
    final remaining = limit - _length;
    if (remaining <= 0) {
      _truncated = true;
      return;
    }
    final value =
        chunk.length > remaining ? chunk.substring(0, remaining) : chunk;
    _buffer.write(value);
    _length += value.length;
    if (value.length < chunk.length) _truncated = true;
  }

  @override
  String toString() {
    if (!_truncated) return _buffer.toString();
    return '${_buffer.toString()}\n[saída limitada a 200 KB]';
  }
}
