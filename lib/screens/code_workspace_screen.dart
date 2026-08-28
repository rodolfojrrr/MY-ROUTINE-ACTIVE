import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/c.dart';
import 'package:re_highlight/languages/cpp.dart';
import 'package:re_highlight/languages/csharp.dart';
import 'package:re_highlight/languages/css.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:re_highlight/languages/java.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/kotlin.dart';
import 'package:re_highlight/languages/php.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/languages/sql.dart';
import 'package:re_highlight/languages/typescript.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';

import '../core/academic_data.dart';
import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/code_workspace.dart';
import '../core/local_code_runner.dart';
import '../core/sync_entity.dart';
import '../widgets/premium_widgets.dart';
import 'academic_shared.dart';

class CodeWorkspaceScreen extends StatefulWidget {
  const CodeWorkspaceScreen({required this.store, super.key});

  final AppStore store;

  @override
  State<CodeWorkspaceScreen> createState() => _CodeWorkspaceScreenState();
}

class _CodeWorkspaceScreenState extends State<CodeWorkspaceScreen> {
  String? selectedProjectId;
  final runner = const LocalCodeRunner();

  Future<void> _createProject() async {
    final project = await showDialog<SyncEntity>(
      context: context,
      builder: (_) => _ProjectDialog(store: widget.store),
    );
    if (project != null && mounted) {
      setState(() => selectedProjectId = project.id);
    }
  }

  Future<void> _showRuntimes() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _RuntimeDialog(runner: runner),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projects = CodeWorkspaceData.sortedProjects(widget.store);
    final wide = MediaQuery.sizeOf(context).width >= 930;
    final selected = projects.where((item) => item.id == selectedProjectId);
    final active = selected.isNotEmpty
        ? selected.first
        : (projects.isEmpty ? null : projects.first);

    if (wide) {
      return PremiumBackground(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _WorkspaceHeader(
                onCreate: _createProject,
                onRuntimes: _showRuntimes,
                desktopExecution: runner.canRunOnThisDevice,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: .96),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 245,
                        child: _ProjectRail(
                          store: widget.store,
                          projects: projects,
                          selectedProjectId: active?.id,
                          onCreate: _createProject,
                          onSelect: (id) =>
                              setState(() => selectedProjectId = id),
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: active == null
                            ? _NoProject(onCreate: _createProject)
                            : _CodeProjectWorkspace(
                                key: ValueKey<String>(active.id),
                                store: widget.store,
                                projectId: active.id,
                                runner: runner,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AcademicPageBody(
      children: <Widget>[
        _WorkspaceHeader(
          onCreate: _createProject,
          onRuntimes: _showRuntimes,
          desktopExecution: runner.canRunOnThisDevice,
        ),
        const SizedBox(height: 18),
        if (projects.isEmpty)
          _NoProject(onCreate: _createProject)
        else
          ...projects.map(
            (project) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MobileProjectCard(
                store: widget.store,
                project: project,
                onOpen: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(
                        title: Text(
                          project.payload['name'] as String? ?? 'Projeto',
                        ),
                      ),
                      body: _CodeProjectWorkspace(
                        store: widget.store,
                        projectId: project.id,
                        runner: runner,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({
    required this.onCreate,
    required this.onRuntimes,
    required this.desktopExecution,
  });

  final VoidCallback onCreate;
  final VoidCallback onRuntimes;
  final bool desktopExecution;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PageIntro(
          eyebrow: 'Laboratório de desenvolvimento',
          title: 'IDE acadêmica',
          subtitle:
              'Crie projetos vinculados às suas matérias, edite arquivos com destaque de sintaxe e sincronize tudo por Wi‑Fi.',
          color: AppColors.primary,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('Novo projeto'),
            ),
            OutlinedButton.icon(
              onPressed: onRuntimes,
              icon: const Icon(Icons.memory_outlined),
              label: const Text('Verificar ambientes'),
            ),
            AcademicBadge(
              label: desktopExecution
                  ? 'Execução local disponível'
                  : 'Edição móvel + execução no PC',
              color: desktopExecution ? AppColors.green : AppColors.cyan,
              icon:
                  desktopExecution ? Icons.play_circle_outline : Icons.sync_alt,
            ),
          ],
        ),
      ],
    );
  }
}

class _ProjectRail extends StatelessWidget {
  const _ProjectRail({
    required this.store,
    required this.projects,
    required this.selectedProjectId,
    required this.onCreate,
    required this.onSelect,
  });

  final AppStore store;
  final List<SyncEntity> projects;
  final String? selectedProjectId;
  final VoidCallback onCreate;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 15, 10, 8),
          child: Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'PROJETOS',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Novo projeto',
                onPressed: onCreate,
                icon: Icon(Icons.add, color: AppColors.primary),
              ),
            ],
          ),
        ),
        Expanded(
          child: projects.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'Crie seu primeiro projeto.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  itemCount: projects.length,
                  itemBuilder: (_, index) {
                    final project = projects[index];
                    final selected = project.id == selectedProjectId;
                    final language = CodeLanguageCatalog.byId(
                      project.payload['language'] as String?,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: ListTile(
                        selected: selected,
                        selectedTileColor: AppColors.primary.withValues(
                          alpha: .14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                          side: BorderSide(
                            color: selected
                                ? AppColors.primary.withValues(alpha: .45)
                                : Colors.transparent,
                          ),
                        ),
                        leading: Icon(
                          _languageIcon(language.id),
                          color: selected
                              ? AppColors.primaryLight
                              : AppColors.textMuted,
                        ),
                        title: Text(
                          project.payload['name'] as String? ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight:
                                selected ? FontWeight.w900 : FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          language.label,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => onSelect(project.id),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MobileProjectCard extends StatelessWidget {
  const _MobileProjectCard({
    required this.store,
    required this.project,
    required this.onOpen,
  });

  final AppStore store;
  final SyncEntity project;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final language = CodeLanguageCatalog.byId(
      project.payload['language'] as String?,
    );
    final files = CodeWorkspaceData.filesForProject(store, project.id);
    final subject = AcademicData.subjectName(
      store,
      project.payload['subjectId'] as String?,
    );
    return PremiumCard(
      onTap: onOpen,
      borderColor: AppColors.primary.withValues(alpha: .35),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(_languageIcon(language.id), color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  project.payload['name'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${language.label} • ${files.length} arquivo(s)',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                if (subject != 'Sem matéria') ...<Widget>[
                  const SizedBox(height: 6),
                  AcademicBadge(
                    label: subject,
                    icon: Icons.menu_book_outlined,
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _NoProject extends StatelessWidget {
  const _NoProject({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const EmptyState(
              icon: Icons.terminal_rounded,
              title: 'Seu laboratório está pronto',
              message:
                  'Crie um projeto em Dart, Python, Java, JavaScript, TypeScript, C, C++, C#, Kotlin, PHP, SQL, HTML/CSS ou JSON.',
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('Criar primeiro projeto'),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _languageIcon(String languageId) {
  return switch (languageId) {
    'python' => Icons.data_object_rounded,
    'java' || 'kotlin' => Icons.coffee_outlined,
    'javascript' || 'typescript' => Icons.javascript_rounded,
    'sql' => Icons.storage_outlined,
    'web' => Icons.language_outlined,
    'json' => Icons.data_array_rounded,
    _ => Icons.code_rounded,
  };
}

class _ProjectDialog extends StatefulWidget {
  const _ProjectDialog({required this.store, this.project});

  final AppStore store;
  final SyncEntity? project;

  @override
  State<_ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<_ProjectDialog> {
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late String languageId;
  String? semesterId;
  String? subjectId;
  String? contentId;
  var saving = false;

  @override
  void initState() {
    super.initState();
    final payload = widget.project?.payload;
    nameController = TextEditingController(
      text: payload?['name'] as String? ?? '',
    );
    descriptionController = TextEditingController(
      text: payload?['description'] as String? ?? '',
    );
    languageId = payload?['language'] as String? ?? 'dart';
    semesterId = payload?['semesterId'] as String?;
    subjectId = payload?['subjectId'] as String?;
    contentId = payload?['contentId'] as String?;
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (nameController.text.trim().isEmpty || saving) return;
    setState(() => saving = true);
    final language = CodeLanguageCatalog.byId(languageId);
    late final SyncEntity saved;
    if (widget.project == null) {
      saved = await CodeWorkspaceData.createProject(
        widget.store,
        name: nameController.text,
        description: descriptionController.text,
        language: language,
        semesterId: semesterId,
        subjectId: subjectId,
        contentId: contentId,
      );
    } else {
      saved = await widget.store.save(
        EntityTypes.codeProject,
        <String, dynamic>{
          ...widget.project!.payload,
          'name': nameController.text.trim(),
          'description': descriptionController.text.trim(),
          'semesterId': semesterId,
          'subjectId': subjectId,
          'contentId': contentId,
        },
        id: widget.project!.id,
      );
    }
    if (mounted) Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final semesters = AcademicData.sortedSemesters(widget.store);
    final subjects = semesterId == null
        ? widget.store.records(EntityTypes.subject)
        : AcademicData.subjectsForSemester(widget.store, semesterId);
    if (subjectId != null && !subjects.any((item) => item.id == subjectId)) {
      subjectId = null;
      contentId = null;
    }
    final contents = subjectId == null
        ? const <SyncEntity>[]
        : AcademicData.contentsForSubject(widget.store, subjectId);
    if (contentId != null && !contents.any((item) => item.id == contentId)) {
      contentId = null;
    }
    return AlertDialog(
      title: Text(widget.project == null ? 'Novo projeto' : 'Editar projeto'),
      content: SizedBox(
        width: 580,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                autofocus: true,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Nome do projeto *',
                  hintText: 'Ex.: Sistema de cadastro de alunos',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: languageId,
                decoration: const InputDecoration(
                  labelText: 'Linguagem principal',
                ),
                items: CodeLanguageCatalog.all
                    .map(
                      (language) => DropdownMenuItem<String>(
                        value: language.id,
                        child: Text(language.label),
                      ),
                    )
                    .toList(),
                onChanged: widget.project == null
                    ? (value) => setState(() => languageId = value ?? 'dart')
                    : null,
              ),
              if (widget.project != null)
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'A linguagem principal é fixada na criação; cada arquivo ainda pode usar sua própria extensão.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Objetivo ou descrição',
                  hintText: 'O que este projeto pratica?',
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'VÍNCULO ACADÊMICO',
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                key: ValueKey<String?>('semester-$semesterId'),
                initialValue: semesterId,
                decoration: const InputDecoration(labelText: 'Semestre'),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    child: Text('Sem vínculo'),
                  ),
                  ...semesters.map(
                    (semester) => DropdownMenuItem<String?>(
                      value: semester.id,
                      child: Text(
                        semester.payload['name'] as String? ?? 'Semestre',
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() {
                  semesterId = value;
                  subjectId = null;
                  contentId = null;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                key: ValueKey<String?>('subject-$semesterId-$subjectId'),
                initialValue: subjectId,
                decoration: const InputDecoration(labelText: 'Matéria'),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    child: Text('Sem vínculo'),
                  ),
                  ...subjects.map(
                    (subject) => DropdownMenuItem<String?>(
                      value: subject.id,
                      child: Text(
                        subject.payload['name'] as String? ?? 'Matéria',
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() {
                  subjectId = value;
                  contentId = null;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                key: ValueKey<String?>('content-$subjectId-$contentId'),
                initialValue: contentId,
                decoration: const InputDecoration(labelText: 'Conteúdo'),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    child: Text('Conteúdo geral'),
                  ),
                  ...contents.map(
                    (content) => DropdownMenuItem<String?>(
                      value: content.id,
                      child: Text(
                        content.payload['title'] as String? ?? 'Conteúdo',
                      ),
                    ),
                  ),
                ],
                onChanged: subjectId == null
                    ? null
                    : (value) => setState(() => contentId = value),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: saving ? null : _save,
          icon: saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _RuntimeDialog extends StatefulWidget {
  const _RuntimeDialog({required this.runner});

  final LocalCodeRunner runner;

  @override
  State<_RuntimeDialog> createState() => _RuntimeDialogState();
}

class _RuntimeDialogState extends State<_RuntimeDialog> {
  late Future<List<CodeRuntimeStatus>> result;

  @override
  void initState() {
    super.initState();
    result = widget.runner.inspectRuntimes();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: <Widget>[
          Icon(Icons.memory_outlined, color: AppColors.primary),
          SizedBox(width: 10),
          Text('Ambientes de execução'),
        ],
      ),
      content: SizedBox(
        width: 660,
        height: 520,
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: .28),
                ),
              ),
              child: const Text(
                'Os compiladores não são enviados para a internet nem baixados pelo app. '
                'A IDE apenas usa os ambientes que você instalou no Windows. '
                'Execute somente códigos confiáveis: eles usam as permissões do seu usuário.',
                style: TextStyle(color: AppColors.textMuted, height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<CodeRuntimeStatus>>(
                future: result,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final statuses = snapshot.data ?? const <CodeRuntimeStatus>[];
                  return ListView.separated(
                    itemCount: statuses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final status = statuses[index];
                      return ListTile(
                        leading: Icon(
                          _languageIcon(status.language.id),
                          color: status.available
                              ? AppColors.green
                              : AppColors.textMuted,
                        ),
                        title: Text(status.language.label),
                        subtitle: Text(
                          status.detail,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                        trailing: Icon(
                          status.available
                              ? Icons.check_circle
                              : Icons.info_outline,
                          color: status.available
                              ? AppColors.green
                              : AppColors.orange,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton.icon(
          onPressed: () => setState(
            () => result = widget.runner.inspectRuntimes(),
          ),
          icon: const Icon(Icons.refresh),
          label: const Text('Verificar novamente'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

class _CodeProjectWorkspace extends StatefulWidget {
  const _CodeProjectWorkspace({
    required this.store,
    required this.projectId,
    required this.runner,
    super.key,
  });

  final AppStore store;
  final String projectId;
  final LocalCodeRunner runner;

  @override
  State<_CodeProjectWorkspace> createState() => _CodeProjectWorkspaceState();
}

class _CodeProjectWorkspaceState extends State<_CodeProjectWorkspace> {
  late CodeLineEditingController editorController;
  late CodeFindController findController;
  Timer? saveTimer;
  String? currentFileId;
  bool dirty = false;
  bool saving = false;
  bool running = false;
  bool wordWrap = false;
  bool showOutput = true;
  CodeRunResult? runResult;

  @override
  void initState() {
    super.initState();
    final files = CodeWorkspaceData.filesForProject(
      widget.store,
      widget.projectId,
    );
    final first = files.isEmpty ? null : files.first;
    currentFileId = first?.id;
    _createControllers(first?.payload['content'] as String? ?? '');
  }

  void _createControllers(String text) {
    editorController = CodeLineEditingController.fromText(text);
    findController = CodeFindController(editorController);
  }

  @override
  void dispose() {
    saveTimer?.cancel();
    if (dirty) {
      final file =
          currentFileId == null ? null : widget.store.byId(currentFileId!);
      if (file != null) {
        unawaited(
          widget.store.save(
            EntityTypes.codeFile,
            <String, dynamic>{
              ...file.payload,
              'content': editorController.text,
            },
            id: file.id,
          ),
        );
      }
    }
    findController.dispose();
    editorController.dispose();
    super.dispose();
  }

  void _changed(CodeLineEditingValue _) {
    if (!dirty) setState(() => dirty = true);
    saveTimer?.cancel();
    saveTimer = Timer(const Duration(milliseconds: 900), _saveCurrent);
  }

  Future<void> _saveCurrent() async {
    saveTimer?.cancel();
    if (!dirty || saving || currentFileId == null) return;
    final file = widget.store.byId(currentFileId!);
    if (file == null) return;
    final contents = editorController.text;
    setState(() {
      saving = true;
      dirty = false;
    });
    await widget.store.save(
      EntityTypes.codeFile,
      <String, dynamic>{
        ...file.payload,
        'content': contents,
        'lastSavedAt': DateTime.now().millisecondsSinceEpoch,
      },
      id: file.id,
    );
    if (mounted) setState(() => saving = false);
  }

  Future<void> _selectFile(SyncEntity file) async {
    if (file.id == currentFileId) return;
    await _saveCurrent();
    findController.dispose();
    editorController.dispose();
    _createControllers(file.payload['content'] as String? ?? '');
    setState(() {
      currentFileId = file.id;
      dirty = false;
      runResult = null;
    });
  }

  Future<void> _newFile() async {
    final project = widget.store.byId(widget.projectId);
    if (project == null) return;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _FileNameDialog(title: 'Novo arquivo'),
    );
    if (name == null) return;
    final files = CodeWorkspaceData.filesForProject(
      widget.store,
      widget.projectId,
    );
    if (files.any(
      (file) =>
          (file.payload['name'] as String? ?? '').toLowerCase() ==
          name.toLowerCase(),
    )) {
      _message('Já existe um arquivo com esse nome.');
      return;
    }
    final language = CodeLanguageCatalog.forFileName(
      name,
      fallbackId: project.payload['language'] as String?,
    );
    final file = await widget.store.save(
      EntityTypes.codeFile,
      <String, dynamic>{
        'projectId': widget.projectId,
        'name': name,
        'language': language.id,
        'content': '',
        'isMain': false,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      },
    );
    await _selectFile(file);
  }

  Future<void> _importFiles() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'Importar arquivos para o projeto',
      allowMultiple: true,
      withData: true,
      type: FileType.any,
    );
    if (picked == null || picked.files.isEmpty) return;
    final project = widget.store.byId(widget.projectId);
    if (project == null) return;
    final existing = CodeWorkspaceData.filesForProject(
      widget.store,
      widget.projectId,
    )
        .map((file) => (file.payload['name'] as String? ?? '').toLowerCase())
        .toSet();
    var imported = 0;
    for (final pickedFile in picked.files) {
      final name = pickedFile.name;
      if (!CodeLanguageCatalog.isValidFileName(name) ||
          existing.contains(name.toLowerCase())) {
        continue;
      }
      final bytes = pickedFile.bytes ??
          (pickedFile.path == null
              ? null
              : await File(pickedFile.path!).readAsBytes());
      if (bytes == null || bytes.length > 1024 * 1024) continue;
      final language = CodeLanguageCatalog.forFileName(
        name,
        fallbackId: project.payload['language'] as String?,
      );
      await widget.store.save(EntityTypes.codeFile, <String, dynamic>{
        'projectId': widget.projectId,
        'name': name,
        'language': language.id,
        'content': utf8.decode(bytes, allowMalformed: true),
        'isMain': false,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      existing.add(name.toLowerCase());
      imported++;
    }
    _message(
      imported == 0
          ? 'Nenhum arquivo foi importado. Evite nomes repetidos e arquivos acima de 1 MB.'
          : '$imported arquivo(s) importado(s).',
    );
  }

  Future<void> _exportCurrent() async {
    await _saveCurrent();
    final file =
        currentFileId == null ? null : widget.store.byId(currentFileId!);
    if (file == null) return;
    final name = file.payload['name'] as String? ?? 'codigo.txt';
    await FilePicker.platform.saveFile(
      dialogTitle: 'Exportar arquivo de código',
      fileName: name,
      type: FileType.any,
      bytes: Uint8List.fromList(
        utf8.encode(file.payload['content'] as String? ?? ''),
      ),
    );
  }

  Future<void> _run() async {
    if (running) return;
    await _saveCurrent();
    final project = widget.store.byId(widget.projectId);
    if (project == null) return;
    setState(() {
      running = true;
      showOutput = true;
      runResult = null;
    });
    final result = await widget.runner.run(
      store: widget.store,
      project: project,
      files: CodeWorkspaceData.filesForProject(
        widget.store,
        widget.projectId,
      ),
    );
    if (mounted) {
      setState(() {
        running = false;
        runResult = result;
      });
    }
  }

  Future<void> _editProject(SyncEntity project) async {
    await _saveCurrent();
    if (!mounted) return;
    await showDialog<SyncEntity>(
      context: context,
      builder: (_) => _ProjectDialog(store: widget.store, project: project),
    );
  }

  Future<void> _deleteProject(SyncEntity project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir projeto?'),
        content: Text(
          '“${project.payload['name'] ?? 'Projeto'}” e todos os seus arquivos serão excluídos também.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await CodeWorkspaceData.deleteProject(widget.store, project);
    if (mounted && MediaQuery.sizeOf(context).width < 930) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _fileOptions(SyncEntity file) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Renomear arquivo'),
              onTap: () => Navigator.of(context).pop('rename'),
            ),
            ListTile(
              leading: const Icon(
                Icons.play_circle_outline,
                color: AppColors.green,
              ),
              title: const Text('Definir como arquivo principal'),
              onTap: () => Navigator.of(context).pop('main'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.red),
              title: const Text(
                'Excluir arquivo',
                style: TextStyle(color: AppColors.red),
              ),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'rename') {
      final oldName = file.payload['name'] as String? ?? '';
      final name = await showDialog<String>(
        context: context,
        builder: (_) => _FileNameDialog(
          title: 'Renomear arquivo',
          initialValue: oldName,
        ),
      );
      if (name == null || name == oldName) return;
      final duplicates = CodeWorkspaceData.filesForProject(
        widget.store,
        widget.projectId,
      ).any(
        (item) =>
            item.id != file.id &&
            (item.payload['name'] as String? ?? '').toLowerCase() ==
                name.toLowerCase(),
      );
      if (duplicates) {
        _message('Já existe um arquivo com esse nome.');
        return;
      }
      final project = widget.store.byId(widget.projectId);
      final language = CodeLanguageCatalog.forFileName(
        name,
        fallbackId: project?.payload['language'] as String?,
      );
      await widget.store.save(
        EntityTypes.codeFile,
        <String, dynamic>{
          ...file.payload,
          'name': name,
          'language': language.id,
        },
        id: file.id,
      );
      if (file.payload['isMain'] == true && project != null) {
        await widget.store.save(
          EntityTypes.codeProject,
          <String, dynamic>{...project.payload, 'mainFile': name},
          id: project.id,
        );
      }
    } else if (action == 'main') {
      final project = widget.store.byId(widget.projectId);
      if (project == null) return;
      for (final item in CodeWorkspaceData.filesForProject(
        widget.store,
        widget.projectId,
      )) {
        final shouldBeMain = item.id == file.id;
        if (item.payload['isMain'] != shouldBeMain) {
          await widget.store.save(
            EntityTypes.codeFile,
            <String, dynamic>{...item.payload, 'isMain': shouldBeMain},
            id: item.id,
          );
        }
      }
      await widget.store.save(
        EntityTypes.codeProject,
        <String, dynamic>{
          ...project.payload,
          'mainFile': file.payload['name'],
        },
        id: project.id,
      );
      _message('Arquivo principal atualizado.');
    } else if (action == 'delete') {
      final files = CodeWorkspaceData.filesForProject(
        widget.store,
        widget.projectId,
      );
      if (files.length == 1) {
        _message('O projeto precisa manter pelo menos um arquivo.');
        return;
      }
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Excluir arquivo?'),
          content:
              Text('O arquivo “${file.payload['name'] ?? ''}” será excluído.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      final wasCurrent = currentFileId == file.id;
      await CodeWorkspaceData.deleteFile(widget.store, file);
      if (wasCurrent) {
        final remaining = CodeWorkspaceData.filesForProject(
          widget.store,
          widget.projectId,
        );
        if (remaining.isNotEmpty) await _selectFile(remaining.first);
      }
    }
    if (mounted) setState(() {});
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final project = widget.store.byId(widget.projectId);
        if (project == null) {
          return const Center(
            child: Text(
              'Este projeto não existe mais.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          );
        }
        final files = CodeWorkspaceData.filesForProject(
          widget.store,
          widget.projectId,
        );
        final activeFile = files.where((file) => file.id == currentFileId);
        final current = activeFile.isNotEmpty
            ? activeFile.first
            : (files.isEmpty ? null : files.first);
        if (current != null && current.id != currentFileId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && current.id != currentFileId) {
              _selectFile(current);
            }
          });
        }
        final compact = MediaQuery.sizeOf(context).width < 720;
        return Column(
          children: <Widget>[
            _ProjectToolbar(
              store: widget.store,
              project: project,
              running: running,
              onRun: _run,
              onEdit: () => _editProject(project),
              onDelete: () => _deleteProject(project),
            ),
            const Divider(height: 1),
            Expanded(
              child: compact
                  ? Column(
                      children: <Widget>[
                        SizedBox(
                          height: 58,
                          child: _HorizontalFileRail(
                            files: files,
                            currentFileId: current?.id,
                            onSelect: _selectFile,
                            onOptions: _fileOptions,
                            onNew: _newFile,
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: _buildEditor(project, current),
                        ),
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        SizedBox(
                          width: 210,
                          child: _VerticalFileRail(
                            files: files,
                            currentFileId: current?.id,
                            onSelect: _selectFile,
                            onOptions: _fileOptions,
                            onNew: _newFile,
                            onImport: _importFiles,
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: _buildEditor(project, current)),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditor(SyncEntity project, SyncEntity? file) {
    if (file == null) {
      return _NoFile(onCreate: _newFile);
    }
    final language = CodeLanguageCatalog.forFileName(
      file.payload['name'] as String? ?? '',
      fallbackId: project.payload['language'] as String?,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _EditorToolbar(
          file: file,
          controller: editorController,
          dirty: dirty,
          saving: saving,
          wordWrap: wordWrap,
          onSave: _saveCurrent,
          onFind: findController.findMode,
          onToggleWrap: () => setState(() => wordWrap = !wordWrap),
          onImport: _importFiles,
          onExport: _exportCurrent,
          onOptions: () => _fileOptions(file),
        ),
        const Divider(height: 1),
        Expanded(
          child: CodeEditor(
            controller: editorController,
            findController: findController,
            onChanged: _changed,
            wordWrap: wordWrap,
            padding: const EdgeInsets.fromLTRB(12, 14, 16, 24),
            autofocus: false,
            style: CodeEditorStyle(
              fontSize: 14,
              fontHeight: 1.45,
              fontFamily: 'Consolas',
              fontFamilyFallback: const <String>[
                'Cascadia Code',
                'Courier New',
                'monospace',
              ],
              textColor: const Color(0xFFD8E9F8),
              backgroundColor: const Color(0xFF06111F),
              cursorColor: AppColors.primaryLight,
              cursorLineColor: AppColors.primary.withValues(alpha: .08),
              selectionColor: AppColors.primary.withValues(alpha: .30),
              highlightColor: AppColors.orange.withValues(alpha: .30),
              chunkIndicatorColor: AppColors.border,
              codeTheme: CodeHighlightTheme(
                languages: <String, CodeHighlightThemeMode>{
                  language.id: CodeHighlightThemeMode(
                    mode: _highlightMode(language, file),
                  ),
                },
                theme: atomOneDarkTheme,
              ),
            ),
            indicatorBuilder:
                (context, editingController, chunkController, notifier) {
              return Row(
                children: <Widget>[
                  DefaultCodeLineNumber(
                    controller: editingController,
                    notifier: notifier,
                  ),
                  DefaultCodeChunkIndicator(
                    width: 18,
                    controller: chunkController,
                    notifier: notifier,
                  ),
                ],
              );
            },
            findBuilder: (context, controller, readOnly) => _CodeFindPanel(
              controller: controller,
              readOnly: readOnly,
            ),
            leadingDivider: Container(width: 1, color: AppColors.border),
          ),
        ),
        _OutputPanel(
          visible: showOutput,
          running: running,
          result: runResult,
          onToggle: () => setState(() => showOutput = !showOutput),
          onClear: () => setState(() => runResult = null),
        ),
      ],
    );
  }
}

class _ProjectToolbar extends StatelessWidget {
  const _ProjectToolbar({
    required this.store,
    required this.project,
    required this.running,
    required this.onRun,
    required this.onEdit,
    required this.onDelete,
  });

  final AppStore store;
  final SyncEntity project;
  final bool running;
  final VoidCallback onRun;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final language = CodeLanguageCatalog.byId(
      project.payload['language'] as String?,
    );
    final subjectId = project.payload['subjectId'] as String?;
    final subject = subjectId == null
        ? 'Projeto independente'
        : AcademicData.subjectName(store, subjectId);
    final compact = MediaQuery.sizeOf(context).width < 620;
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 10 : 16, 10, 8, 10),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  AppColors.primaryLight,
                  AppColors.primaryDark,
                ],
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(_languageIcon(language.id), color: Colors.white),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  project.payload['name'] as String? ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${language.label} • $subject',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: running ? null : onRun,
            style: FilledButton.styleFrom(
              minimumSize: Size(compact ? 48 : 112, 44),
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 17),
              backgroundColor: AppColors.green,
              foregroundColor: const Color(0xFF032219),
            ),
            icon: running
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF032219),
                    ),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: compact
                ? const SizedBox.shrink()
                : Text(running ? 'Executando' : 'Executar'),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opções do projeto',
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Editar projeto'),
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline, color: AppColors.red),
                  title: Text(
                    'Excluir projeto',
                    style: TextStyle(color: AppColors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerticalFileRail extends StatelessWidget {
  const _VerticalFileRail({
    required this.files,
    required this.currentFileId,
    required this.onSelect,
    required this.onOptions,
    required this.onNew,
    required this.onImport,
  });

  final List<SyncEntity> files;
  final String? currentFileId;
  final ValueChanged<SyncEntity> onSelect;
  final ValueChanged<SyncEntity> onOptions;
  final VoidCallback onNew;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(13, 12, 7, 7),
          child: Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'ARQUIVOS',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Importar arquivos',
                onPressed: onImport,
                icon: const Icon(Icons.file_upload_outlined, size: 20),
              ),
              IconButton(
                tooltip: 'Novo arquivo',
                onPressed: onNew,
                icon: Icon(
                  Icons.note_add_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            itemCount: files.length,
            itemBuilder: (_, index) {
              final file = files[index];
              final selected = file.id == currentFileId;
              final name = file.payload['name'] as String? ?? '';
              return ListTile(
                dense: true,
                selected: selected,
                selectedTileColor: AppColors.primary.withValues(alpha: .12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                leading: Icon(
                  file.payload['isMain'] == true
                      ? Icons.play_circle_filled
                      : Icons.description_outlined,
                  size: 19,
                  color: file.payload['isMain'] == true
                      ? AppColors.green
                      : (selected
                          ? AppColors.primaryLight
                          : AppColors.textMuted),
                ),
                title: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
                trailing: InkWell(
                  onTap: () => onOptions(file),
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(Icons.more_horiz, size: 18),
                  ),
                ),
                onTap: () => onSelect(file),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HorizontalFileRail extends StatelessWidget {
  const _HorizontalFileRail({
    required this.files,
    required this.currentFileId,
    required this.onSelect,
    required this.onOptions,
    required this.onNew,
  });

  final List<SyncEntity> files;
  final String? currentFileId;
  final ValueChanged<SyncEntity> onSelect;
  final ValueChanged<SyncEntity> onOptions;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(10, 9, 4, 8),
            scrollDirection: Axis.horizontal,
            itemCount: files.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (_, index) {
              final file = files[index];
              final selected = file.id == currentFileId;
              return Material(
                color: selected
                    ? AppColors.primary.withValues(alpha: .15)
                    : AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onSelect(file),
                  onLongPress: () => onOptions(file),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          file.payload['isMain'] == true
                              ? Icons.play_circle_filled
                              : Icons.description_outlined,
                          size: 17,
                          color: file.payload['isMain'] == true
                              ? AppColors.green
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          file.payload['name'] as String? ?? '',
                          style: TextStyle(
                            fontFamily: 'Consolas',
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        IconButton(
          tooltip: 'Novo arquivo',
          onPressed: onNew,
          icon: Icon(Icons.add, color: AppColors.primary),
        ),
      ],
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({
    required this.file,
    required this.controller,
    required this.dirty,
    required this.saving,
    required this.wordWrap,
    required this.onSave,
    required this.onFind,
    required this.onToggleWrap,
    required this.onImport,
    required this.onExport,
    required this.onOptions,
  });

  final SyncEntity file;
  final CodeLineEditingController controller;
  final bool dirty;
  final bool saving;
  final bool wordWrap;
  final VoidCallback onSave;
  final VoidCallback onFind;
  final VoidCallback onToggleWrap;
  final VoidCallback onImport;
  final VoidCallback onExport;
  final VoidCallback onOptions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: <Widget>[
          const SizedBox(width: 8),
          if (dirty)
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
              ),
            )
          else
            const Icon(Icons.check, size: 14, color: AppColors.green),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              file.payload['name'] as String? ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Consolas',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                ValueListenableBuilder<CodeLineEditingValue>(
                  valueListenable: controller,
                  builder: (_, value, __) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: Text(
                      '${controller.lineCount} ln • ${controller.text.length} car.',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Desfazer',
                  onPressed: controller.undo,
                  icon: const Icon(Icons.undo, size: 19),
                ),
                IconButton(
                  tooltip: 'Refazer',
                  onPressed: controller.redo,
                  icon: const Icon(Icons.redo, size: 19),
                ),
                IconButton(
                  tooltip: 'Buscar (Ctrl + F)',
                  onPressed: onFind,
                  icon: const Icon(Icons.search, size: 19),
                ),
                IconButton(
                  tooltip:
                      wordWrap ? 'Desativar quebra de linha' : 'Quebrar linhas',
                  onPressed: onToggleWrap,
                  color: wordWrap ? AppColors.primaryLight : null,
                  icon: const Icon(Icons.wrap_text, size: 19),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Importar ou exportar',
                  onSelected: (value) {
                    if (value == 'import') onImport();
                    if (value == 'export') onExport();
                    if (value == 'options') onOptions();
                  },
                  itemBuilder: (_) => const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'import',
                      child: Text('Importar arquivos'),
                    ),
                    PopupMenuItem<String>(
                      value: 'export',
                      child: Text('Exportar arquivo atual'),
                    ),
                    PopupMenuItem<String>(
                      value: 'options',
                      child: Text('Opções do arquivo'),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: saving ? 'Salvando…' : 'Salvar (Ctrl + S)',
                  onPressed: saving ? null : onSave,
                  color: dirty ? AppColors.primaryLight : null,
                  icon: saving
                      ? const SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined, size: 20),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutputPanel extends StatelessWidget {
  const _OutputPanel({
    required this.visible,
    required this.running,
    required this.result,
    required this.onToggle,
    required this.onClear,
  });

  final bool visible;
  final bool running;
  final CodeRunResult? result;
  final VoidCallback onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final color = switch (result?.state) {
      CodeRunState.success => AppColors.green,
      CodeRunState.failed => AppColors.red,
      CodeRunState.runtimeMissing => AppColors.orange,
      CodeRunState.unsupported => AppColors.cyan,
      null => AppColors.textMuted,
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: visible ? 190 : 39,
      decoration: const BoxDecoration(
        color: Color(0xFF050E19),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: 38,
            child: Row(
              children: <Widget>[
                const SizedBox(width: 12),
                Icon(Icons.terminal_rounded, size: 18, color: color),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'SAÍDA / TERMINAL',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (result != null)
                  Text(
                    '${result!.elapsed.inMilliseconds} ms',
                    style: TextStyle(color: color, fontSize: 11),
                  ),
                IconButton(
                  tooltip: 'Limpar saída',
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                ),
                IconButton(
                  tooltip: visible ? 'Recolher' : 'Expandir',
                  onPressed: onToggle,
                  icon: Icon(
                    visible ? Icons.expand_more : Icons.expand_less,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          if (visible)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 12),
                child: running
                    ? const Row(
                        children: <Widget>[
                          SizedBox.square(
                            dimension: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Compilando e executando localmente…'),
                        ],
                      )
                    : SingleChildScrollView(
                        child: SelectableText(
                          result?.output ??
                              'Clique em “Executar”. No celular, o código é editado e sincronizado; a execução acontece no PC.',
                          style: TextStyle(
                            color: result == null
                                ? AppColors.textMuted
                                : const Color(0xFFD5E7F6),
                            fontFamily: 'Consolas',
                            fontSize: 12.5,
                            height: 1.45,
                          ),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoFile extends StatelessWidget {
  const _NoFile({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.note_add_outlined,
            size: 46,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          const Text(
            'Nenhum arquivo neste projeto.',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Criar arquivo'),
          ),
        ],
      ),
    );
  }
}

class _CodeFindPanel extends StatelessWidget implements PreferredSizeWidget {
  const _CodeFindPanel({
    required this.controller,
    required this.readOnly,
  });

  final CodeFindController controller;
  final bool readOnly;

  @override
  Size get preferredSize => Size(
        double.infinity,
        controller.value == null ? 0 : 46,
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final value = controller.value;
        if (value == null) return const SizedBox.shrink();
        final result = value.result;
        final counter = result == null
            ? '0/0'
            : '${result.index + 1}/${result.matches.length}';
        return Container(
          height: 46,
          margin: const EdgeInsets.only(right: 10),
          alignment: Alignment.centerRight,
          child: Container(
            width: 390,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(11),
              ),
              border: Border.all(color: AppColors.border),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: .24),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: controller.findInputController,
                    focusNode: controller.findInputFocusNode,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Buscar no arquivo',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  counter,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                _FindToggle(
                  label: 'Aa',
                  selected: value.option.caseSensitive,
                  tooltip: 'Diferenciar maiúsculas',
                  onTap: controller.toggleCaseSensitive,
                ),
                _FindToggle(
                  label: '.*',
                  selected: value.option.regex,
                  tooltip: 'Expressão regular',
                  onTap: controller.toggleRegex,
                ),
                IconButton(
                  tooltip: 'Anterior',
                  onPressed: result == null ? null : controller.previousMatch,
                  icon: const Icon(Icons.keyboard_arrow_up, size: 19),
                ),
                IconButton(
                  tooltip: 'Próximo',
                  onPressed: result == null ? null : controller.nextMatch,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 19),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: controller.close,
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FindToggle extends StatelessWidget {
  const _FindToggle({
    required this.label,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.primaryLight : AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _FileNameDialog extends StatefulWidget {
  const _FileNameDialog({
    required this.title,
    this.initialValue = '',
  });

  final String title;
  final String initialValue;

  @override
  State<_FileNameDialog> createState() => _FileNameDialogState();
}

class _FileNameDialogState extends State<_FileNameDialog> {
  late final TextEditingController controller;
  String? error;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initialValue.contains('.')
          ? widget.initialValue.lastIndexOf('.')
          : widget.initialValue.length,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = controller.text.trim();
    if (!CodeLanguageCatalog.isValidFileName(value)) {
      setState(() {
        error =
            'Use um nome de arquivo válido, com extensão e sem \\ / : * ? " < > |';
      });
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 430,
        child: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: 'Nome e extensão',
            hintText: 'ex.: main.py',
            errorText: error,
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

Mode _highlightMode(
  CodeLanguageDefinition language,
  SyncEntity file,
) {
  final fileName = file.payload['name'] as String? ?? '';
  final extension = fileName.toLowerCase().split('.').last;
  return switch (language.id) {
    'dart' => langDart,
    'python' => langPython,
    'java' => langJava,
    'javascript' => langJavascript,
    'typescript' => langTypescript,
    'c' => langC,
    'cpp' => langCpp,
    'csharp' => langCsharp,
    'kotlin' => langKotlin,
    'php' => langPhp,
    'sql' => langSql,
    'web' => extension == 'css' ? langCss : langXml,
    'json' => langJson,
    _ => langDart,
  };
}
