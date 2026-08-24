import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/academic_data.dart';
import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/sync_entity.dart';
import '../widgets/premium_widgets.dart';
import 'academic_shared.dart';

class AcademicAssessmentsScreen extends StatefulWidget {
  const AcademicAssessmentsScreen({required this.store, super.key});

  final AppStore store;

  @override
  State<AcademicAssessmentsScreen> createState() =>
      _AcademicAssessmentsScreenState();
}

class _AcademicAssessmentsScreenState extends State<AcademicAssessmentsScreen> {
  String? subjectId;
  bool showCompleted = true;

  @override
  Widget build(BuildContext context) {
    final subjects = widget.store.records(EntityTypes.subject).toList()
      ..sort(
        (a, b) => (a.payload['name'] as String? ?? '').compareTo(
          b.payload['name'] as String? ?? '',
        ),
      );
    final exams = widget.store.records(EntityTypes.exam).where((item) {
      if (subjectId != null && item.payload['subjectId'] != subjectId) {
        return false;
      }
      if (!showCompleted && item.payload['completed'] == true) return false;
      return true;
    }).toList()
      ..sort(
        (a, b) => (a.payload['date'] as String? ?? '').compareTo(
          b.payload['date'] as String? ?? '',
        ),
      );
    final now = DateTime.now();
    final upcoming = exams.where((item) {
      final date = DateTime.tryParse(item.payload['date'] as String? ?? '');
      return item.payload['completed'] != true &&
          date != null &&
          !date.isBefore(DateTime(now.year, now.month, now.day));
    }).toList();
    final completed = exams.where((item) => !upcoming.contains(item)).toList();

    return AcademicPageBody(
      children: <Widget>[
        const PageIntro(
          eyebrow: 'Calendário acadêmico',
          title: 'Provas, trabalhos e projetos',
          subtitle:
              'Registre cada avaliação por matéria e conteúdo, acompanhe datas, pesos, notas e o que já foi concluído.',
          color: AppColors.primary,
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            ElevatedButton.icon(
              onPressed: subjects.isEmpty
                  ? null
                  : () => showDialog<void>(
                        context: context,
                        builder: (_) =>
                            AcademicAssessmentEditorDialog(store: widget.store),
                      ),
              icon: const Icon(Icons.add),
              label: const Text('Nova avaliação'),
            ),
            SizedBox(
              width: 270,
              child: DropdownButtonFormField<String?>(
                initialValue: subjectId,
                decoration: const InputDecoration(labelText: 'Matéria'),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Todas as matérias'),
                  ),
                  ...subjects.map(
                    (item) => DropdownMenuItem<String?>(
                      value: item.id,
                      child: Text(item.payload['name'] as String? ?? ''),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => subjectId = value),
              ),
            ),
            FilterChip(
              selected: showCompleted,
              onSelected: (value) => setState(() => showCompleted = value),
              label: const Text('Mostrar concluídas'),
              avatar: const Icon(Icons.history, size: 17),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AcademicSectionTitle(
          title: 'Próximas avaliações',
          subtitle: '${upcoming.length} compromisso(s) pendente(s)',
        ),
        const SizedBox(height: 12),
        if (upcoming.isEmpty)
          const EmptyState(
            icon: Icons.event_available_outlined,
            title: 'Nenhuma avaliação próxima',
            message:
                'Cadastre provas, trabalhos, projetos e atividades para acompanhar aqui.',
          )
        else
          ...upcoming.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: _AssessmentCard(store: widget.store, item: item),
            ),
          ),
        if (showCompleted && completed.isNotEmpty) ...<Widget>[
          const SizedBox(height: 18),
          const AcademicSectionTitle(
            title: 'Histórico',
            subtitle: 'Avaliações concluídas ou com data passada.',
          ),
          const SizedBox(height: 12),
          ...completed.reversed.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: _AssessmentCard(store: widget.store, item: item),
            ),
          ),
        ],
      ],
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard({required this.store, required this.item});

  final AppStore store;
  final SyncEntity item;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(item.payload['date'] as String? ?? '');
    final completed = item.payload['completed'] == true;
    final grade = item.payload['grade'] as num?;
    return PremiumCard(
      borderColor: completed
          ? AppColors.green.withValues(alpha: .45)
          : AppColors.orange.withValues(alpha: .45),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: (completed ? AppColors.green : AppColors.orange)
                  .withValues(alpha: .14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: <Widget>[
                Text(
                  date == null ? '—' : DateFormat('dd').format(date),
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  date == null
                      ? ''
                      : DateFormat('MMM', 'pt_BR').format(date).toUpperCase(),
                  style: TextStyle(
                    color: completed ? AppColors.green : AppColors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.payload['title'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: <Widget>[
                    AcademicBadge(
                      label: AcademicData.subjectName(
                        store,
                        item.payload['subjectId'] as String?,
                      ),
                    ),
                    if ((item.payload['contentId'] as String? ?? '').isNotEmpty)
                      AcademicBadge(
                        label: AcademicData.contentName(
                          store,
                          item.payload['contentId'] as String?,
                        ),
                        color: AppColors.blue,
                      ),
                    AcademicBadge(
                      label: _typeLabel(item.payload['type'] as String?),
                      color: AppColors.orange,
                    ),
                    if (grade != null)
                      AcademicBadge(
                        label: 'Nota ${grade.toStringAsFixed(1)}',
                        color: AppColors.green,
                      ),
                  ],
                ),
                if ((item.payload['notes'] as String? ?? '')
                    .isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    item.payload['notes'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip:
                completed ? 'Marcar como pendente' : 'Marcar como concluída',
            onPressed: () => store.save(
                EntityTypes.exam,
                <String, dynamic>{
                  ...item.payload,
                  'completed': !completed,
                },
                id: item.id),
            icon: Icon(
              completed ? Icons.check_circle : Icons.radio_button_unchecked,
              color: completed ? AppColors.green : AppColors.textMuted,
            ),
          ),
          IconButton(
            tooltip: 'Editar',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) =>
                  AcademicAssessmentEditorDialog(store: store, entity: item),
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
          ConfirmDeleteButton(onDelete: () => store.remove(item.id)),
        ],
      ),
    );
  }
}

class AcademicAssessmentEditorDialog extends StatefulWidget {
  const AcademicAssessmentEditorDialog({
    required this.store,
    this.entity,
    this.initialSubjectId,
    super.key,
  });

  final AppStore store;
  final SyncEntity? entity;
  final String? initialSubjectId;

  @override
  State<AcademicAssessmentEditorDialog> createState() =>
      _AcademicAssessmentEditorDialogState();
}

class _AcademicAssessmentEditorDialogState
    extends State<AcademicAssessmentEditorDialog> {
  late final TextEditingController title;
  late final TextEditingController time;
  late final TextEditingController weight;
  late final TextEditingController grade;
  late final TextEditingController notes;
  String? subjectId;
  String? contentId;
  String type = 'exam';
  DateTime date = DateTime.now();
  bool completed = false;

  @override
  void initState() {
    super.initState();
    final subjects = widget.store.records(EntityTypes.subject);
    final preferred = widget.entity?.payload['subjectId'] as String? ??
        widget.initialSubjectId;
    subjectId = subjects.any((item) => item.id == preferred)
        ? preferred
        : (subjects.isEmpty ? null : subjects.first.id);
    final contents = AcademicData.contentsForSubject(widget.store, subjectId);
    final existingContent = widget.entity?.payload['contentId'] as String?;
    contentId = contents.any((item) => item.id == existingContent)
        ? existingContent
        : null;
    title = TextEditingController(
      text: widget.entity?.payload['title'] as String? ?? '',
    );
    time = TextEditingController(
      text: widget.entity?.payload['time'] as String? ?? '18:30',
    );
    weight = TextEditingController(
      text: '${widget.entity?.payload['weight'] ?? ''}',
    );
    grade = TextEditingController(
      text: '${widget.entity?.payload['grade'] ?? ''}',
    );
    notes = TextEditingController(
      text: widget.entity?.payload['notes'] as String? ?? '',
    );
    type = widget.entity?.payload['type'] as String? ?? 'exam';
    date = DateTime.tryParse(widget.entity?.payload['date'] as String? ?? '') ??
        DateTime.now();
    completed = widget.entity?.payload['completed'] == true;
  }

  @override
  void dispose() {
    title.dispose();
    time.dispose();
    weight.dispose();
    grade.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = widget.store.records(EntityTypes.subject).toList()
      ..sort(
        (a, b) => (a.payload['name'] as String? ?? '').compareTo(
          b.payload['name'] as String? ?? '',
        ),
      );
    final contents = AcademicData.contentsForSubject(widget.store, subjectId);
    return AlertDialog(
      title: Text(
        widget.entity == null ? 'Nova avaliação' : 'Editar avaliação',
      ),
      content: SizedBox(
        width: 650,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: title,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: subjectId,
                      decoration: const InputDecoration(labelText: 'Matéria'),
                      items: subjects
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item.id,
                              child: Text(
                                item.payload['name'] as String? ?? '',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() {
                        subjectId = value;
                        contentId = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: contentId,
                      decoration: const InputDecoration(labelText: 'Conteúdo'),
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Vários / geral'),
                        ),
                        ...contents.map(
                          (item) => DropdownMenuItem<String?>(
                            value: item.id,
                            child: Text(item.payload['title'] as String? ?? ''),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => contentId = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'exam', child: Text('Prova')),
                  DropdownMenuItem(
                    value: 'assignment',
                    child: Text('Trabalho'),
                  ),
                  DropdownMenuItem(value: 'project', child: Text('Projeto')),
                  DropdownMenuItem(value: 'activity', child: Text('Atividade')),
                  DropdownMenuItem(
                    value: 'presentation',
                    child: Text('Apresentação'),
                  ),
                ],
                onChanged: (value) => setState(() => type = value ?? type),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final selected = await pickAppDate(context, date);
                        if (selected != null) setState(() => date = selected);
                      },
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(DateFormat('dd/MM/yyyy').format(date)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: time,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(labelText: 'Horário'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: weight,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Peso / valor da avaliação',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: grade,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Nota obtida (opcional)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notes,
                minLines: 3,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Observações e conteúdos cobrados',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: completed,
                onChanged: (value) => setState(() => completed = value),
                title: const Text('Avaliação concluída'),
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
                EntityTypes.exam,
                <String, dynamic>{
                  'title': title.text.trim(),
                  'subjectId': subjectId,
                  'contentId': contentId,
                  'type': type,
                  'date': DateFormat('yyyy-MM-dd').format(date),
                  'time': time.text.trim(),
                  'weight': _parseNumber(weight.text),
                  'grade': grade.text.trim().isEmpty
                      ? null
                      : _parseNumber(grade.text),
                  'notes': notes.text.trim(),
                  'completed': completed,
                },
                id: widget.entity?.id);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Salvar avaliação'),
        ),
      ],
    );
  }
}

String _typeLabel(String? type) {
  return switch (type) {
    'assignment' => 'Trabalho',
    'project' => 'Projeto',
    'activity' => 'Atividade',
    'presentation' => 'Apresentação',
    _ => 'Prova',
  };
}

double _parseNumber(String value) {
  return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
}
