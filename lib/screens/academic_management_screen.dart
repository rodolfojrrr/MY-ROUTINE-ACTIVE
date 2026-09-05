import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/academic_data.dart';
import '../core/academic_folder_style.dart';
import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/file_transfer_service.dart';
import '../core/sync_entity.dart';
import '../widgets/premium_widgets.dart';
import 'academic_shared.dart';

Future<void> showAcademicSemesterEditor(
  BuildContext context,
  AppStore store, {
  SyncEntity? entity,
}) =>
    showDialog<void>(
      context: context,
      builder: (_) => _SemesterDialog(store: store, entity: entity),
    );

Future<void> showAcademicSubjectEditor(
  BuildContext context,
  AppStore store, {
  SyncEntity? entity,
  String? initialSemesterId,
}) =>
    showDialog<void>(
      context: context,
      builder: (_) => _SubjectDialog(
        store: store,
        entity: entity,
        initialSemesterId: initialSemesterId,
      ),
    );

Future<void> showAcademicContentEditor(
  BuildContext context,
  AppStore store, {
  SyncEntity? entity,
  String? initialSubjectId,
}) =>
    showDialog<void>(
      context: context,
      builder: (_) => _ContentDialog(
        store: store,
        entity: entity,
        initialSubjectId: initialSubjectId,
      ),
    );

Future<void> showAcademicScheduleEditor(
  BuildContext context,
  AppStore store, {
  SyncEntity? entity,
  String? initialSubjectId,
}) =>
    showDialog<void>(
      context: context,
      builder: (_) => _ScheduleDialog(
        store: store,
        entity: entity,
        initialSubjectId: initialSubjectId,
      ),
    );

class AcademicManagementScreen extends StatelessWidget {
  const AcademicManagementScreen({required this.store, super.key});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: PremiumBackground(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: PageIntro(
                    eyebrow: 'Sua graduação',
                    title: 'Área acadêmica',
                    subtitle:
                        'Organize a faculdade na ordem: semestre, cadeira, conteúdo e horário. Cursos livres agora ficam em uma área própria.',
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const TabBar(
              isScrollable: true,
              tabs: <Widget>[
                Tab(icon: Icon(Icons.layers_outlined), text: 'Semestres'),
                Tab(icon: Icon(Icons.menu_book_outlined), text: 'Cadeiras'),
                Tab(icon: Icon(Icons.account_tree_outlined), text: 'Conteúdos'),
                Tab(icon: Icon(Icons.calendar_view_week), text: 'Horários'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  _SemestersTab(store: store),
                  _SubjectsTab(store: store),
                  _ContentsTab(store: store),
                  _SchedulesTab(store: store),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementList extends StatelessWidget {
  const _ManagementList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

class _SemestersTab extends StatelessWidget {
  const _SemestersTab({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final semesters = AcademicData.sortedSemesters(store);
    return _ManagementList(
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => _SemesterDialog(store: store),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Novo semestre'),
          ),
        ),
        const SizedBox(height: 16),
        if (semesters.isEmpty)
          const EmptyState(
            icon: Icons.layers_outlined,
            title: 'Nenhum semestre cadastrado',
            message:
                'Comece pelo semestre atual da faculdade. Cursos livres ficam no menu Cursos.',
          )
        else
          ...semesters.map((semester) {
            final subjects = AcademicData.subjectsForSemester(
              store,
              semester.id,
            );
            final status = semester.payload['status'] as String? ?? 'current';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumCard(
                borderColor:
                    status == 'current' ? AppColors.primary : AppColors.border,
                child: Row(
                  children: <Widget>[
                    _EntityIcon(
                      icon: Icons.layers_outlined,
                      color: status == 'current'
                          ? AppColors.primary
                          : AppColors.blue,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            semester.payload['name'] as String? ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Semestre acadêmico • ${semester.payload['year'] ?? ''}.${semester.payload['term'] ?? ''} • ${subjects.length} cadeira(s)',
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 7),
                          AcademicBadge(
                            label: _semesterStatusLabel(status),
                            color: _semesterStatusColor(status),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Editar semestre',
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) =>
                            _SemesterDialog(store: store, entity: semester),
                      ),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    ConfirmDeleteButton(
                      onDelete: () =>
                          AcademicData.deleteSemester(store, semester),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _SubjectsTab extends StatelessWidget {
  const _SubjectsTab({required this.store});

  final AppStore store;

  void _create(BuildContext context) {
    if (AcademicData.sortedSemesters(store).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre um semestre primeiro.')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => _SubjectDialog(store: store),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjects = AcademicData.academicSubjects(store)
      ..sort((a, b) {
        final semester = AcademicData.semesterName(
          store,
          a.payload['semesterId'] as String?,
        ).compareTo(
          AcademicData.semesterName(
            store,
            b.payload['semesterId'] as String?,
          ),
        );
        if (semester != 0) return semester;
        final orderA = (a.payload['order'] as num? ?? 999).toInt();
        final orderB = (b.payload['order'] as num? ?? 999).toInt();
        return orderA.compareTo(orderB);
      });
    return _ManagementList(
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            onPressed: () => _create(context),
            icon: const Icon(Icons.add),
            label: const Text('Nova cadeira'),
          ),
        ),
        const SizedBox(height: 16),
        if (subjects.isEmpty)
          const EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'Nenhuma cadeira cadastrada',
            message:
                'Depois de criar o semestre, adicione as cadeiras cursadas nele.',
          )
        else
          ...subjects.map((subject) {
            final contents = AcademicData.contentsForSubject(store, subject.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumCard(
                child: Row(
                  children: <Widget>[
                    _EntityIcon(
                      icon: Icons.code_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            subject.payload['name'] as String? ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            <String>[
                              subject.payload['code'] as String? ?? '',
                              subject.payload['professor'] as String? ?? '',
                              '${contents.length} conteúdo(s)',
                            ].where((item) => item.isNotEmpty).join(' • '),
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 7),
                          AcademicBadge(
                            label: AcademicData.semesterName(
                              store,
                              subject.payload['semesterId'] as String?,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Editar cadeira',
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) =>
                            _SubjectDialog(store: store, entity: subject),
                      ),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    ConfirmDeleteButton(
                      onDelete: () =>
                          AcademicData.deleteSubject(store, subject),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _ContentsTab extends StatelessWidget {
  const _ContentsTab({required this.store});

  final AppStore store;

  void _create(BuildContext context) {
    if (AcademicData.academicSubjects(store).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre uma cadeira primeiro.')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => _ContentDialog(store: store),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjects = AcademicData.academicSubjects(store)
      ..sort(
        (a, b) => (a.payload['name'] as String? ?? '').compareTo(
          b.payload['name'] as String? ?? '',
        ),
      );
    return _ManagementList(
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            onPressed: () => _create(context),
            icon: const Icon(Icons.add),
            label: const Text('Novo conteúdo'),
          ),
        ),
        const SizedBox(height: 16),
        if (subjects.isEmpty)
          const EmptyState(
            icon: Icons.account_tree_outlined,
            title: 'Nenhuma cadeira disponível',
            message: 'Cadastre uma cadeira antes de organizar seus conteúdos.',
          )
        else
          ...subjects.map((subject) {
            final contents = AcademicData.contentsForSubject(store, subject.id);
            if (contents.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.menu_book, color: AppColors.primary),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            subject.payload['name'] as String? ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        AcademicBadge(
                          label: AcademicData.semesterName(
                            store,
                            subject.payload['semesterId'] as String?,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...contents.map(
                      (content) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(
                            alpha: .14,
                          ),
                          foregroundColor: AppColors.primary,
                          child: content.payload['completed'] == true
                              ? const Icon(Icons.check, size: 18)
                              : Text('${content.payload['order'] ?? '•'}'),
                        ),
                        title: Text(
                          content.payload['title'] as String? ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          content.payload['description'] as String? ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (content.payload['completed'] == true)
                              const Padding(
                                padding: EdgeInsets.only(right: 5),
                                child: AcademicBadge(
                                  label: 'Concluído',
                                  color: AppColors.green,
                                ),
                              ),
                            IconButton(
                              tooltip: 'Editar conteúdo',
                              onPressed: () => showDialog<void>(
                                context: context,
                                builder: (_) => _ContentDialog(
                                  store: store,
                                  entity: content,
                                ),
                              ),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            ConfirmDeleteButton(
                              onDelete: () =>
                                  AcademicData.deleteContent(store, content),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        if (subjects.isNotEmpty &&
            subjects.every(
              (subject) =>
                  AcademicData.contentsForSubject(store, subject.id).isEmpty,
            ))
          const EmptyState(
            icon: Icons.account_tree_outlined,
            title: 'Nenhum conteúdo cadastrado',
            message:
                'Divida cada cadeira por unidades, capítulos ou assuntos do plano de ensino.',
          ),
      ],
    );
  }
}

class _SchedulesTab extends StatelessWidget {
  const _SchedulesTab({required this.store});

  final AppStore store;

  void _create(BuildContext context) {
    if (AcademicData.academicSubjects(store).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre uma cadeira primeiro.')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => _ScheduleDialog(store: store),
    );
  }

  @override
  Widget build(BuildContext context) {
    final academicSubjectIds =
        AcademicData.academicSubjects(store).map((item) => item.id).toSet();
    final sessions = store
        .records(EntityTypes.classSession)
        .where(
          (item) => academicSubjectIds.contains(item.payload['subjectId']),
        )
        .toList()
      ..sort((a, b) {
        final day = (a.payload['weekday'] as num? ?? 1).compareTo(
          b.payload['weekday'] as num? ?? 1,
        );
        if (day != 0) return day;
        return (a.payload['start'] as String? ?? '').compareTo(
          b.payload['start'] as String? ?? '',
        );
      });
    return _ManagementList(
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            onPressed: () => _create(context),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar aula'),
          ),
        ),
        const SizedBox(height: 16),
        if (sessions.isEmpty)
          const EmptyState(
            icon: Icons.calendar_view_week,
            title: 'Horário semanal vazio',
            message:
                'Adicione aulas nos períodos 18:30–20:10 e 20:30–22:00 ou informe outro horário.',
          )
        else
          ...AcademicData.weekdayLong.entries.map((day) {
            final items = sessions
                .where((item) => item.payload['weekday'] == day.key)
                .toList();
            if (items.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      day.value,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...items.map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.schedule,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          AcademicData.subjectName(
                            store,
                            item.payload['subjectId'] as String?,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${item.payload['start']}–${item.payload['end']}'
                          '${(item.payload['room'] as String? ?? '').isEmpty ? '' : ' • ${item.payload['room']}'}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              tooltip: 'Editar aula',
                              onPressed: () => showDialog<void>(
                                context: context,
                                builder: (_) =>
                                    _ScheduleDialog(store: store, entity: item),
                              ),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            ConfirmDeleteButton(
                              onDelete: () => store.remove(item.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _SemesterDialog extends StatefulWidget {
  const _SemesterDialog({required this.store, this.entity});

  final AppStore store;
  final SyncEntity? entity;

  @override
  State<_SemesterDialog> createState() => _SemesterDialogState();
}

class _SemesterDialogState extends State<_SemesterDialog> {
  late final TextEditingController name;
  late final TextEditingController year;
  late final TextEditingController term;
  late String status;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    name = TextEditingController(
      text: widget.entity?.payload['name'] as String? ?? '',
    );
    year = TextEditingController(
      text: '${widget.entity?.payload['year'] ?? now.year}',
    );
    term = TextEditingController(
      text: '${widget.entity?.payload['term'] ?? (now.month <= 6 ? 1 : 2)}',
    );
    status = widget.entity?.payload['status'] as String? ?? 'current';
  }

  @override
  void dispose() {
    name.dispose();
    year.dispose();
    term.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.entity == null ? 'Novo semestre' : 'Editar semestre'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nome do semestre',
                  hintText: '2026.2 — 4º semestre',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: year,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Ano'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: term,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Período do ano',
                        hintText: '1 ou 2',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Situação'),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(
                    value: 'current',
                    child: Text('Em andamento'),
                  ),
                  DropdownMenuItem(
                    value: 'completed',
                    child: Text('Concluído'),
                  ),
                  DropdownMenuItem(value: 'planned', child: Text('Planejado')),
                ],
                onChanged: (value) => setState(() => status = value ?? status),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            final parsedYear = int.tryParse(year.text.trim());
            final parsedTerm = int.tryParse(term.text.trim());
            if (name.text.trim().isEmpty ||
                parsedYear == null ||
                parsedTerm == null) {
              return;
            }
            if (status == 'current') {
              for (final item in widget.store.records(EntityTypes.semester)) {
                if (item.id == widget.entity?.id ||
                    item.payload['status'] != 'current' ||
                    (item.payload['kind'] as String? ?? 'semester') !=
                        'semester') {
                  continue;
                }
                await widget.store.save(
                    EntityTypes.semester,
                    <String, dynamic>{
                      ...item.payload,
                      'status': 'completed',
                    },
                    id: item.id);
              }
            }
            await widget.store.save(
                EntityTypes.semester,
                <String, dynamic>{
                  ...?widget.entity?.payload,
                  'name': name.text.trim(),
                  'year': parsedYear,
                  'term': parsedTerm,
                  'status': status,
                  'kind': 'semester',
                },
                id: widget.entity?.id);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _SubjectDialog extends StatefulWidget {
  const _SubjectDialog({
    required this.store,
    this.entity,
    this.initialSemesterId,
  });

  final AppStore store;
  final SyncEntity? entity;
  final String? initialSemesterId;

  @override
  State<_SubjectDialog> createState() => _SubjectDialogState();
}

class _SubjectDialogState extends State<_SubjectDialog> {
  late final TextEditingController name;
  late final TextEditingController code;
  late final TextEditingController professor;
  late final TextEditingController room;
  late final TextEditingController workload;
  late final TextEditingController order;
  String? semesterId;
  late int folderColor;
  late String folderIcon;
  late String coverImageBase64;
  late String coverImageName;
  bool pickingCover = false;

  @override
  void initState() {
    super.initState();
    final semesters = AcademicData.sortedSemesters(widget.store);
    name = TextEditingController(
      text: widget.entity?.payload['name'] as String? ?? '',
    );
    code = TextEditingController(
      text: widget.entity?.payload['code'] as String? ?? '',
    );
    professor = TextEditingController(
      text: widget.entity?.payload['professor'] as String? ?? '',
    );
    room = TextEditingController(
      text: widget.entity?.payload['room'] as String? ?? '',
    );
    workload = TextEditingController(
      text: '${widget.entity?.payload['workload'] ?? ''}',
    );
    order = TextEditingController(
      text: '${widget.entity?.payload['order'] ?? semesters.length + 1}',
    );
    final existing = widget.entity?.payload['semesterId'] as String? ??
        widget.initialSemesterId;
    semesterId = semesters.any((item) => item.id == existing)
        ? existing
        : (semesters.isEmpty ? null : semesters.first.id);
    folderColor = (widget.entity?.payload['folderColor'] as num?)?.toInt() ??
        AcademicFolderStyle.colors.first.toARGB32();
    folderIcon = widget.entity?.payload['folderIcon'] as String? ?? 'code';
    coverImageBase64 =
        widget.entity?.payload['coverImageBase64'] as String? ?? '';
    coverImageName = widget.entity?.payload['coverImageName'] as String? ?? '';
  }

  Future<void> _pickCover() async {
    if (pickingCover) return;
    setState(() => pickingCover = true);
    try {
      final picked = await FileTransferService.pickImagePayload();
      final bytes = picked?['imageBytes'];
      if (picked != null && bytes is List<int> && mounted) {
        setState(() {
          coverImageBase64 = base64Encode(bytes);
          coverImageName = picked['imageName'] as String? ?? 'capa.jpg';
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível usar a imagem: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => pickingCover = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    code.dispose();
    professor.dispose();
    room.dispose();
    workload.dispose();
    order.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semesters = AcademicData.sortedSemesters(widget.store);
    return AlertDialog(
      title: Text(widget.entity == null ? 'Nova matéria' : 'Editar matéria'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<String>(
                initialValue: semesterId,
                decoration: const InputDecoration(
                  labelText: 'Semestre da faculdade',
                ),
                items: semesters
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(item.payload['name'] as String? ?? ''),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => semesterId = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nome da matéria'),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: code,
                      decoration: const InputDecoration(
                        labelText: 'Código da disciplina',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: workload,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Carga horária (h)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: professor,
                decoration: const InputDecoration(labelText: 'Professor(a)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: room,
                      decoration: const InputDecoration(
                        labelText: 'Sala / laboratório',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: order,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Ordem'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'APARÊNCIA DA PASTA',
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: AcademicFolderStyle.colors.map((color) {
                    final selected = color.toARGB32() == folderColor;
                    return Tooltip(
                      message: 'Cor da pasta',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(13),
                        onTap: () =>
                            setState(() => folderColor = color.toARGB32()),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: selected ? Colors.white : Colors.white24,
                              width: selected ? 3 : 1,
                            ),
                          ),
                          child: selected
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AcademicFolderStyle.icons.map((option) {
                    return ChoiceChip(
                      selected: folderIcon == option.id,
                      onSelected: (_) => setState(() => folderIcon = option.id),
                      avatar: Icon(option.icon, size: 18),
                      label: Text(option.label),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: pickingCover ? null : _pickCover,
                      icon: pickingCover
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(
                        coverImageBase64.isEmpty
                            ? 'Adicionar imagem de fundo'
                            : 'Trocar imagem de fundo',
                      ),
                    ),
                  ),
                  if (coverImageBase64.isNotEmpty) ...<Widget>[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Remover imagem de fundo',
                      onPressed: () => setState(() {
                        coverImageBase64 = '';
                        coverImageName = '';
                      }),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ],
              ),
              if (coverImageName.isNotEmpty) ...<Widget>[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    coverImageName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            if (name.text.trim().isEmpty || semesterId == null) return;
            await widget.store.save(
                EntityTypes.subject,
                <String, dynamic>{
                  ...?widget.entity?.payload,
                  'semesterId': semesterId,
                  'name': name.text.trim(),
                  'code': code.text.trim(),
                  'professor': professor.text.trim(),
                  'room': room.text.trim(),
                  'workload': int.tryParse(workload.text.trim()) ?? 0,
                  'order': int.tryParse(order.text.trim()) ?? 999,
                  'folderColor': folderColor,
                  'folderIcon': folderIcon,
                  'coverImageBase64': coverImageBase64,
                  'coverImageName': coverImageName,
                },
                id: widget.entity?.id);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _ContentDialog extends StatefulWidget {
  const _ContentDialog({
    required this.store,
    this.entity,
    this.initialSubjectId,
  });

  final AppStore store;
  final SyncEntity? entity;
  final String? initialSubjectId;

  @override
  State<_ContentDialog> createState() => _ContentDialogState();
}

class _ContentDialogState extends State<_ContentDialog> {
  late final TextEditingController title;
  late final TextEditingController description;
  late final TextEditingController order;
  String? subjectId;
  late bool completed;

  @override
  void initState() {
    super.initState();
    final subjects = AcademicData.academicSubjects(widget.store);
    title = TextEditingController(
      text: widget.entity?.payload['title'] as String? ?? '',
    );
    description = TextEditingController(
      text: widget.entity?.payload['description'] as String? ?? '',
    );
    order = TextEditingController(
      text: '${widget.entity?.payload['order'] ?? 1}',
    );
    final existing = widget.entity?.payload['subjectId'] as String? ??
        widget.initialSubjectId;
    subjectId = subjects.any((item) => item.id == existing)
        ? existing
        : (subjects.isEmpty ? null : subjects.first.id);
    completed = widget.entity?.payload['completed'] == true;
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    order.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = AcademicData.academicSubjects(widget.store)
      ..sort(
        (a, b) => (a.payload['name'] as String? ?? '').compareTo(
          b.payload['name'] as String? ?? '',
        ),
      );
    return AlertDialog(
      title: Text(widget.entity == null ? 'Novo conteúdo' : 'Editar conteúdo'),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<String>(
                initialValue: subjectId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Matéria'),
                items: subjects
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(
                          '${AcademicData.semesterName(widget.store, item.payload['semesterId'] as String?)} • ${item.payload['name']}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => subjectId = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: title,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Título do conteúdo',
                  hintText: 'Unidade 1 — Lógica proposicional',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Conteúdo concluído'),
                subtitle: const Text(
                  'Marque quando todo o assunto tiver sido estudado.',
                ),
                value: completed,
                onChanged: (value) => setState(() => completed = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                minLines: 3,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Descrição / tópicos previstos',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: order,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ordem dentro da cadeira',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            if (title.text.trim().isEmpty || subjectId == null) return;
            await widget.store.save(
                EntityTypes.studyContent,
                <String, dynamic>{
                  ...?widget.entity?.payload,
                  'subjectId': subjectId,
                  'title': title.text.trim(),
                  'description': description.text.trim(),
                  'order': int.tryParse(order.text.trim()) ?? 999,
                  'completed': completed,
                },
                id: widget.entity?.id);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _ScheduleDialog extends StatefulWidget {
  const _ScheduleDialog({
    required this.store,
    this.entity,
    this.initialSubjectId,
  });

  final AppStore store;
  final SyncEntity? entity;
  final String? initialSubjectId;

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  late final TextEditingController start;
  late final TextEditingController end;
  late final TextEditingController room;
  late final TextEditingController notes;
  String? subjectId;
  int weekday = 1;

  @override
  void initState() {
    super.initState();
    final subjects = AcademicData.academicSubjects(widget.store);
    final existing = widget.entity?.payload['subjectId'] as String? ??
        widget.initialSubjectId;
    subjectId = subjects.any((item) => item.id == existing)
        ? existing
        : (subjects.isEmpty ? null : subjects.first.id);
    weekday = (widget.entity?.payload['weekday'] as num? ?? 1).toInt();
    start = TextEditingController(
      text: widget.entity?.payload['start'] as String? ?? '18:30',
    );
    end = TextEditingController(
      text: widget.entity?.payload['end'] as String? ?? '20:10',
    );
    room = TextEditingController(
      text: widget.entity?.payload['room'] as String? ?? '',
    );
    notes = TextEditingController(
      text: widget.entity?.payload['notes'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    start.dispose();
    end.dispose();
    room.dispose();
    notes.dispose();
    super.dispose();
  }

  void _slot(String from, String to) {
    setState(() {
      start.text = from;
      end.text = to;
    });
  }

  @override
  Widget build(BuildContext context) {
    final subjects = AcademicData.academicSubjects(widget.store)
      ..sort(
        (a, b) => (a.payload['name'] as String? ?? '').compareTo(
          b.payload['name'] as String? ?? '',
        ),
      );
    return AlertDialog(
      title: Text(widget.entity == null ? 'Adicionar aula' : 'Editar aula'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DropdownButtonFormField<String>(
                initialValue: subjectId,
                decoration: const InputDecoration(labelText: 'Cadeira'),
                items: subjects
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(item.payload['name'] as String? ?? ''),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => subjectId = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: weekday,
                decoration: const InputDecoration(labelText: 'Dia da semana'),
                items: AcademicData.weekdayLong.entries
                    .map(
                      (entry) => DropdownMenuItem<int>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => weekday = value ?? 1),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ActionChip(
                    label: const Text('18:30–20:10'),
                    onPressed: () => _slot('18:30', '20:10'),
                  ),
                  ActionChip(
                    label: const Text('20:30–22:00'),
                    onPressed: () => _slot('20:30', '22:00'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: start,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: 'Início',
                        hintText: '18:30',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: end,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: 'Fim',
                        hintText: '20:10',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: room,
                decoration: const InputDecoration(
                  labelText: 'Sala / laboratório nesta aula',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notes,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Observação'),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            if (subjectId == null ||
                !_validTime(start.text) ||
                !_validTime(end.text)) {
              return;
            }
            await widget.store.save(
                EntityTypes.classSession,
                <String, dynamic>{
                  ...?widget.entity?.payload,
                  'subjectId': subjectId,
                  'weekday': weekday,
                  'start': start.text.trim(),
                  'end': end.text.trim(),
                  'room': room.text.trim(),
                  'notes': notes.text.trim(),
                },
                id: widget.entity?.id);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  bool _validTime(String value) {
    return RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(value.trim());
  }
}

class _EntityIcon extends StatelessWidget {
  const _EntityIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: color),
    );
  }
}

String _semesterStatusLabel(String status) {
  return switch (status) {
    'completed' => 'Concluído',
    'planned' => 'Planejado',
    _ => 'Em andamento',
  };
}

Color _semesterStatusColor(String status) {
  return switch (status) {
    'completed' => AppColors.green,
    'planned' => AppColors.blue,
    _ => AppColors.primary,
  };
}
