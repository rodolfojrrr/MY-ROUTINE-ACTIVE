import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/file_transfer_service.dart';
import '../core/sync_entity.dart';
import '../widgets/premium_widgets.dart';
import 'studies_extra_tabs.dart';

class StudiesScreen extends StatelessWidget {
  const StudiesScreen({required this.store, super.key});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 8,
      child: AnimatedBuilder(
        animation: store,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            title: const Text('Estudos'),
            bottom: const TabBar(
              isScrollable: true,
              tabs: <Widget>[
                Tab(icon: Icon(Icons.today_outlined), text: 'Hoje'),
                Tab(icon: Icon(Icons.calendar_view_week), text: 'Horário'),
                Tab(icon: Icon(Icons.menu_book), text: 'Matérias'),
                Tab(icon: Icon(Icons.event_available), text: 'Provas'),
                Tab(icon: Icon(Icons.edit_note), text: 'Anotações'),
                Tab(icon: Icon(Icons.style), text: 'Flashcards'),
                Tab(icon: Icon(Icons.quiz_outlined), text: 'Questões'),
                Tab(icon: Icon(Icons.timer_outlined), text: 'Foco'),
              ],
            ),
          ),
          body: PremiumBackground(
            child: TabBarView(
              children: <Widget>[
                StudyTodayTab(store: store),
                _ScheduleTab(store: store),
                _SubjectsTab(store: store),
                _ExamsTab(store: store),
                _NotesTab(store: store),
                _FlashcardsTab(store: store),
                QuestionBankTab(store: store),
                StudyFocusTab(store: store),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

String _subjectName(AppStore store, String? id) {
  if (id == null) return 'Sem matéria';
  return store.byId(id)?.payload['name'] as String? ?? 'Matéria removida';
}

String _reviewDate(String? value) {
  final date = DateTime.tryParse(value ?? '');
  return date == null ? 'agora' : DateFormat('dd/MM HH:mm').format(date);
}

class _SubjectsTab extends StatelessWidget {
  const _SubjectsTab({required this.store});

  final AppStore store;

  Future<void> _deleteSubject(SyncEntity subject) async {
    const linkedTypes = <String>[
      EntityTypes.classSession,
      EntityTypes.exam,
      EntityTypes.studyNote,
      EntityTypes.flashcard,
      EntityTypes.studyQuestion,
      EntityTypes.studySession,
    ];
    for (final type in linkedTypes) {
      final linked = store
          .records(type)
          .where((item) => item.payload['subjectId'] == subject.id)
          .toList();
      for (final item in linked) {
        await store.remove(item.id);
      }
    }
    await store.remove(subject.id);
  }

  Future<void> _edit(BuildContext context, [SyncEntity? entity]) async {
    final name = TextEditingController(text: entity?.payload['name'] as String?);
    final professor =
        TextEditingController(text: entity?.payload['professor'] as String?);
    final room = TextEditingController(text: entity?.payload['room'] as String?);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(entity == null ? 'Nova matéria' : 'Editar matéria'),
        content: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nome da matéria'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: professor,
                decoration: const InputDecoration(labelText: 'Professor(a)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: room,
                decoration: const InputDecoration(labelText: 'Sala / laboratório'),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isNotEmpty) Navigator.pop(dialogContext, true);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (saved == true) {
      await store.save(
        EntityTypes.subject,
        <String, dynamic>{
          'name': name.text.trim(),
          'professor': professor.text.trim(),
          'room': room.text.trim(),
        },
        id: entity?.id,
      );
    }
    name.dispose();
    professor.dispose();
    room.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = store.records(EntityTypes.subject);
    return _TabBody(
      children: <Widget>[
        const PageIntro(
          eyebrow: 'Organização acadêmica',
          title: 'Matérias',
          subtitle:
              'Cadastre as disciplinas de Sistemas de Informação e centralize tudo que pertence a cada uma.',
          color: AppColors.purple,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => _edit(context),
          icon: const Icon(Icons.add),
          label: const Text('Nova matéria'),
        ),
        const SizedBox(height: 20),
        if (subjects.isEmpty)
          const EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'Nenhuma matéria cadastrada',
            message: 'Adicione sua primeira disciplina para montar o horário.',
          )
        else
          ...subjects.map(
            (subject) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumCard(
                borderColor: AppColors.purple.withValues(alpha: .4),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.code, color: AppColors.purple),
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
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            <String>[
                              subject.payload['professor'] as String? ?? '',
                              subject.payload['room'] as String? ?? '',
                            ].where((item) => item.isNotEmpty).join(' • '),
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Editar',
                      onPressed: () => _edit(context, subject),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    ConfirmDeleteButton(
                      onDelete: () => _deleteSubject(subject),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ScheduleTab extends StatelessWidget {
  const _ScheduleTab({required this.store});

  final AppStore store;
  static const days = <int, String>{
    1: 'Segunda',
    2: 'Terça',
    3: 'Quarta',
    4: 'Quinta',
    5: 'Sexta',
    6: 'Sábado',
  };

  Future<void> _edit(BuildContext context, [SyncEntity? entity]) async {
    final subjects = store.records(EntityTypes.subject);
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre uma matéria primeiro.')),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => _ClassDialog(store: store, entity: entity),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessions = store.records(EntityTypes.classSession);
    sessions.sort((a, b) {
      final day = (a.payload['weekday'] as num? ?? 1)
          .compareTo(b.payload['weekday'] as num? ?? 1);
      if (day != 0) return day;
      return (a.payload['start'] as String? ?? '')
          .compareTo(b.payload['start'] as String? ?? '');
    });
    return _TabBody(
      children: <Widget>[
        const PageIntro(
          eyebrow: 'Faculdade à noite',
          title: 'Horário semanal',
          subtitle:
              'Os períodos 18:30–20:10 e 20:30–22:00 já aparecem como sugestões ao adicionar uma aula.',
          color: AppColors.purple,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => _edit(context),
          icon: const Icon(Icons.add),
          label: const Text('Adicionar aula'),
        ),
        const SizedBox(height: 20),
        if (sessions.isEmpty)
          const EmptyState(
            icon: Icons.calendar_view_week_outlined,
            title: 'Seu horário está vazio',
            message: 'Cadastre as matérias e distribua as aulas durante a semana.',
          )
        else
          ...days.entries.map((day) {
            final items = sessions
                .where((item) => item.payload['weekday'] == day.key)
                .toList();
            if (items.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      day.value,
                      style: const TextStyle(
                        color: AppColors.purple,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...items.map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.schedule,
                          color: AppColors.purple,
                        ),
                        title: Text(
                          _subjectName(store, item.payload['subjectId'] as String?),
                        ),
                        subtitle: Text(
                          '${item.payload['start']} – ${item.payload['end']}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              onPressed: () => _edit(context, item),
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

class _ClassDialog extends StatefulWidget {
  const _ClassDialog({required this.store, this.entity});

  final AppStore store;
  final SyncEntity? entity;

  @override
  State<_ClassDialog> createState() => _ClassDialogState();
}

class _ClassDialogState extends State<_ClassDialog> {
  late String subjectId;
  late int weekday;
  late int slot;
  late TextEditingController start;
  late TextEditingController end;

  @override
  void initState() {
    super.initState();
    final subjects = widget.store.records(EntityTypes.subject);
    final existingSubjectId = widget.entity?.payload['subjectId'] as String?;
    subjectId = subjects.any((item) => item.id == existingSubjectId)
        ? existingSubjectId!
        : subjects.first.id;
    weekday = (widget.entity?.payload['weekday'] as num?)?.toInt() ?? 1;
    final existingStart = widget.entity?.payload['start'] as String? ?? '18:30';
    slot = existingStart == '20:30' ? 2 : 1;
    start = TextEditingController(text: existingStart);
    end = TextEditingController(
      text: widget.entity?.payload['end'] as String? ?? '20:10',
    );
  }

  @override
  void dispose() {
    start.dispose();
    end.dispose();
    super.dispose();
  }

  void setSlot(int value) {
    setState(() {
      slot = value;
      start.text = value == 1 ? '18:30' : '20:30';
      end.text = value == 1 ? '20:10' : '22:00';
    });
  }

  @override
  Widget build(BuildContext context) {
    final subjects = widget.store.records(EntityTypes.subject);
    return AlertDialog(
      title: Text(widget.entity == null ? 'Adicionar aula' : 'Editar aula'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<String>(
                initialValue: subjectId,
                decoration: const InputDecoration(labelText: 'Matéria'),
                items: subjects
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(item.payload['name'] as String? ?? ''),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => subjectId = value!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: weekday,
                decoration: const InputDecoration(labelText: 'Dia da semana'),
                items: _ScheduleTab.days.entries
                    .map(
                      (day) => DropdownMenuItem<int>(
                        value: day.key,
                        child: Text(day.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => weekday = value!),
              ),
              const SizedBox(height: 12),
              SegmentedButton<int>(
                segments: const <ButtonSegment<int>>[
                  ButtonSegment<int>(value: 1, label: Text('18:30–20:10')),
                  ButtonSegment<int>(value: 2, label: Text('20:30–22:00')),
                ],
                selected: <int>{slot},
                onSelectionChanged: (value) => setSlot(value.first),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: start,
                      decoration: const InputDecoration(labelText: 'Início'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: end,
                      decoration: const InputDecoration(labelText: 'Fim'),
                    ),
                  ),
                ],
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
            await widget.store.save(
              EntityTypes.classSession,
              <String, dynamic>{
                'subjectId': subjectId,
                'weekday': weekday,
                'start': start.text.trim(),
                'end': end.text.trim(),
              },
              id: widget.entity?.id,
            );
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _ExamsTab extends StatelessWidget {
  const _ExamsTab({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final exams = store.records(EntityTypes.exam)
      ..sort((a, b) => (a.payload['date'] as String? ?? '')
          .compareTo(b.payload['date'] as String? ?? ''));
    return _TabBody(
      children: <Widget>[
        const PageIntro(
          eyebrow: 'Avaliações',
          title: 'Provas e trabalhos',
          subtitle: 'Registre datas, conteúdos e observações de cada matéria.',
          color: AppColors.purple,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => _ExamDialog(store: store),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nova avaliação'),
        ),
        const SizedBox(height: 20),
        if (exams.isEmpty)
          const EmptyState(
            icon: Icons.event_available_outlined,
            title: 'Nenhuma avaliação',
            message: 'Adicione provas e trabalhos para não perder os prazos.',
          )
        else
          ...exams.map(
            (exam) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.assignment_outlined,
                    color: AppColors.purple,
                  ),
                  title: Text(exam.payload['title'] as String? ?? ''),
                  subtitle: Text(
                    '${_subjectName(store, exam.payload['subjectId'] as String?)} • ${_formatIsoDate(exam.payload['date'] as String?)}\n${exam.payload['notes'] ?? ''}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => _ExamDialog(
                            store: store,
                            entity: exam,
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      ConfirmDeleteButton(
                        onDelete: () => store.remove(exam.id),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ExamDialog extends StatefulWidget {
  const _ExamDialog({required this.store, this.entity});

  final AppStore store;
  final SyncEntity? entity;

  @override
  State<_ExamDialog> createState() => _ExamDialogState();
}

class _ExamDialogState extends State<_ExamDialog> {
  late final TextEditingController title;
  late final TextEditingController notes;
  late String? subjectId;
  late DateTime date;

  @override
  void initState() {
    super.initState();
    final subjects = widget.store.records(EntityTypes.subject);
    title = TextEditingController(text: widget.entity?.payload['title'] as String?);
    notes = TextEditingController(text: widget.entity?.payload['notes'] as String?);
    final existingSubjectId = widget.entity?.payload['subjectId'] as String?;
    subjectId = subjects.any((item) => item.id == existingSubjectId)
        ? existingSubjectId
        : (subjects.isEmpty ? null : subjects.first.id);
    date = DateTime.tryParse(widget.entity?.payload['date'] as String? ?? '') ??
        DateTime.now();
  }

  @override
  void dispose() {
    title.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = widget.store.records(EntityTypes.subject);
    return AlertDialog(
      title: Text(widget.entity == null ? 'Nova avaliação' : 'Editar avaliação'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: subjectId,
                decoration: const InputDecoration(labelText: 'Matéria'),
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
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: const BorderSide(color: AppColors.border),
                ),
                title: Text(DateFormat('dd/MM/yyyy').format(date)),
                leading: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await pickAppDate(context, date);
                  if (picked != null) setState(() => date = picked);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notes,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Conteúdo / observações',
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
            if (title.text.trim().isEmpty) return;
            await widget.store.save(
              EntityTypes.exam,
              <String, dynamic>{
                'title': title.text.trim(),
                'subjectId': subjectId,
                'date': DateFormat('yyyy-MM-dd').format(date),
                'notes': notes.text.trim(),
              },
              id: widget.entity?.id,
            );
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final notes = store.records(EntityTypes.studyNote);
    return _TabBody(
      children: <Widget>[
        const PageIntro(
          eyebrow: 'Conhecimento',
          title: 'Anotações por matéria',
          subtitle:
              'Escreva livremente e anexe uma imagem. Ela entra no backup e na sincronização Wi‑Fi.',
          color: AppColors.purple,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => _NoteDialog(store: store),
          ),
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Nova anotação'),
        ),
        const SizedBox(height: 20),
        if (notes.isEmpty)
          const EmptyState(
            icon: Icons.edit_note,
            title: 'Nenhuma anotação',
            message: 'Crie notas de aula, códigos, diagramas ou resumos.',
          )
        else
          ...notes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                note.payload['title'] as String? ?? '',
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                _subjectName(
                                  store,
                                  note.payload['subjectId'] as String?,
                                ),
                                style: const TextStyle(
                                  color: AppColors.purple,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => _NoteDialog(
                              store: store,
                              entity: note,
                            ),
                          ),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        ConfirmDeleteButton(
                          onDelete: () => store.remove(note.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      note.payload['body'] as String? ?? '',
                      style: const TextStyle(height: 1.5),
                    ),
                    if ((note.payload['imageBase64'] as String? ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(
                            base64Decode(note.payload['imageBase64'] as String),
                            height: 240,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(
                              height: 80,
                              child: Center(child: Text('Imagem indisponível')),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.store, this.entity});

  final AppStore store;
  final SyncEntity? entity;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final TextEditingController title;
  late final TextEditingController body;
  late String? subjectId;
  String imageBase64 = '';
  String imageName = '';

  @override
  void initState() {
    super.initState();
    final subjects = widget.store.records(EntityTypes.subject);
    title = TextEditingController(text: widget.entity?.payload['title'] as String?);
    body = TextEditingController(text: widget.entity?.payload['body'] as String?);
    final existingSubjectId = widget.entity?.payload['subjectId'] as String?;
    subjectId = subjects.any((item) => item.id == existingSubjectId)
        ? existingSubjectId
        : (subjects.isEmpty ? null : subjects.first.id);
    imageBase64 = widget.entity?.payload['imageBase64'] as String? ?? '';
    imageName = widget.entity?.payload['imageName'] as String? ?? '';
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picked = await FileTransferService.pickImagePayload();
    if (picked == null) return;
    setState(() {
      imageName = picked['imageName'] as String;
      imageBase64 = base64Encode(picked['imageBytes'] as Uint8List);
    });
  }

  @override
  Widget build(BuildContext context) {
    final subjects = widget.store.records(EntityTypes.subject);
    return AlertDialog(
      title: Text(widget.entity == null ? 'Nova anotação' : 'Editar anotação'),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: subjectId,
                decoration: const InputDecoration(labelText: 'Matéria'),
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
              TextField(
                controller: body,
                minLines: 5,
                maxLines: 12,
                decoration: const InputDecoration(labelText: 'Anotação'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.image_outlined),
                label: Text(imageName.isEmpty ? 'Anexar imagem' : imageName),
              ),
              if (imageBase64.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() {
                    imageBase64 = '';
                    imageName = '';
                  }),
                  icon: const Icon(Icons.close),
                  label: const Text('Remover imagem'),
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
            if (title.text.trim().isEmpty) return;
            await widget.store.save(
              EntityTypes.studyNote,
              <String, dynamic>{
                'title': title.text.trim(),
                'body': body.text.trim(),
                'subjectId': subjectId,
                'imageName': imageName,
                'imageBase64': imageBase64,
              },
              id: widget.entity?.id,
            );
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _FlashcardsTab extends StatelessWidget {
  const _FlashcardsTab({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final cards = store.records(EntityTypes.flashcard);
    return _TabBody(
      children: <Widget>[
        const PageIntro(
          eyebrow: 'Memorização ativa',
          title: 'Flashcards',
          subtitle: 'Crie perguntas e respostas rápidas ligadas às suas matérias.',
          color: AppColors.purple,
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ElevatedButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => _FlashcardDialog(store: store),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Novo flashcard'),
            ),
            FilledButton.tonalIcon(
              onPressed: cards.isEmpty
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => FlashcardReviewScreen(store: store),
                        ),
                      ),
              icon: const Icon(Icons.psychology_alt_outlined),
              label: const Text('Revisar agora'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (cards.isEmpty)
          const EmptyState(
            icon: Icons.style_outlined,
            title: 'Nenhum flashcard',
            message: 'Transforme os pontos importantes em perguntas curtas.',
          )
        else
          ...cards.map(
            (card) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 18),
                collapsedBackgroundColor: AppColors.surface,
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: AppColors.border),
                ),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: AppColors.border),
                ),
                title: Text(card.payload['front'] as String? ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _subjectName(store, card.payload['subjectId'] as String?),
                      style: const TextStyle(color: AppColors.purple),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Acertos: ${card.payload['correctCount'] ?? 0} • '
                      'Erros: ${card.payload['wrongCount'] ?? 0} • '
                      'Próxima: ${_reviewDate(card.payload['nextReviewAt'] as String?)}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      tooltip: 'Editar',
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => _FlashcardDialog(
                          store: store,
                          entity: card,
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    ConfirmDeleteButton(
                      onDelete: () => store.remove(card.id),
                    ),
                  ],
                ),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        card.payload['back'] as String? ?? '',
                        style: const TextStyle(fontSize: 17, height: 1.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FlashcardDialog extends StatefulWidget {
  const _FlashcardDialog({required this.store, this.entity});

  final AppStore store;
  final SyncEntity? entity;

  @override
  State<_FlashcardDialog> createState() => _FlashcardDialogState();
}

class _FlashcardDialogState extends State<_FlashcardDialog> {
  late final TextEditingController front;
  late final TextEditingController back;
  String? subjectId;

  @override
  void initState() {
    super.initState();
    final subjects = widget.store.records(EntityTypes.subject);
    front = TextEditingController(
      text: widget.entity?.payload['front'] as String?,
    );
    back = TextEditingController(
      text: widget.entity?.payload['back'] as String?,
    );
    final existingSubjectId = widget.entity?.payload['subjectId'] as String?;
    subjectId = subjects.any((item) => item.id == existingSubjectId)
        ? existingSubjectId
        : (subjects.isEmpty ? null : subjects.first.id);
  }

  @override
  void dispose() {
    front.dispose();
    back.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = widget.store.records(EntityTypes.subject);
    return AlertDialog(
      title: Text(widget.entity == null ? 'Novo flashcard' : 'Editar flashcard'),
      content: SizedBox(
        width: 470,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DropdownButtonFormField<String>(
              initialValue: subjectId,
              decoration: const InputDecoration(labelText: 'Matéria'),
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
            TextField(
              controller: front,
              decoration: const InputDecoration(labelText: 'Pergunta / frente'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: back,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Resposta / verso'),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            if (front.text.trim().isEmpty) return;
            final previous = widget.entity?.payload ?? <String, dynamic>{};
            await widget.store.save(
              EntityTypes.flashcard,
              <String, dynamic>{
                ...previous,
                'subjectId': subjectId,
                'front': front.text.trim(),
                'back': back.text.trim(),
                'nextReviewAt': previous['nextReviewAt'] ?? DateTime.now().toIso8601String(),
                'intervalDays': previous['intervalDays'] ?? 0,
                'streak': previous['streak'] ?? 0,
                'correctCount': previous['correctCount'] ?? 0,
                'wrongCount': previous['wrongCount'] ?? 0,
              },
              id: widget.entity?.id,
            );
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

String _formatIsoDate(String? value) {
  final parsed = DateTime.tryParse(value ?? '');
  return parsed == null ? 'Sem data' : DateFormat('dd/MM/yyyy').format(parsed);
}
