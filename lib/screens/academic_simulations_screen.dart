import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/academic_data.dart';
import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/sync_entity.dart';
import '../widgets/premium_widgets.dart';
import 'academic_shared.dart';

class AcademicSimulationsScreen extends StatefulWidget {
  const AcademicSimulationsScreen({
    required this.store,
    this.initialSubjectId,
    this.initialContentId,
    super.key,
  });

  final AppStore store;
  final String? initialSubjectId;
  final String? initialContentId;

  @override
  State<AcademicSimulationsScreen> createState() =>
      _AcademicSimulationsScreenState();
}

class _AcademicSimulationsScreenState extends State<AcademicSimulationsScreen> {
  final search = TextEditingController();
  String? subjectId;
  String? contentId;

  @override
  void initState() {
    super.initState();
    subjectId = widget.initialSubjectId;
    contentId = widget.initialContentId;
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void _newQuestion() {
    final academicSubjectIds = AcademicData.academicSubjects(widget.store)
        .map((item) => item.id)
        .toSet();
    final hasAcademicContent = widget.store
        .records(EntityTypes.studyContent)
        .any((item) => academicSubjectIds.contains(item.payload['subjectId']));
    if (!hasAcademicContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cadastre uma matéria e pelo menos um conteúdo primeiro.',
          ),
        ),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => AcademicQuestionEditorDialog(
        store: widget.store,
        initialSubjectId: subjectId,
        initialContentId: contentId,
      ),
    );
  }

  Future<void> _startMock() async {
    final academicSubjectIds = AcademicData.academicSubjects(widget.store)
        .map((item) => item.id)
        .toSet();
    final hasAcademicQuestions = widget.store
        .records(EntityTypes.studyQuestion)
        .any((item) => academicSubjectIds.contains(item.payload['subjectId']));
    if (!hasAcademicQuestions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre questões antes do simulado.')),
      );
      return;
    }
    final config = await showDialog<AcademicMockConfiguration>(
      context: context,
      builder: (_) => AcademicMockSetupDialog(
        store: widget.store,
        initialSubjectId: subjectId,
        initialContentId: contentId,
      ),
    );
    if (!mounted || config == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AcademicMockRunnerScreen(
          store: widget.store,
          configuration: config,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjects = AcademicData.academicSubjects(widget.store)
      ..sort(
        (a, b) => (a.payload['name'] as String? ?? '').compareTo(
          b.payload['name'] as String? ?? '',
        ),
      );
    final academicSubjectIds = subjects.map((item) => item.id).toSet();
    final contents = AcademicData.contentsForSubject(widget.store, subjectId);
    final term = search.text.trim().toLowerCase();
    final questions = widget.store.records(EntityTypes.studyQuestion).where((
      item,
    ) {
      if (!academicSubjectIds.contains(item.payload['subjectId'])) return false;
      if (subjectId != null && item.payload['subjectId'] != subjectId) {
        return false;
      }
      if (contentId != null && item.payload['contentId'] != contentId) {
        return false;
      }
      if (term.isEmpty) return true;
      return <String>[
        item.payload['question'] as String? ?? '',
        item.payload['explanation'] as String? ?? '',
        AcademicData.subjectName(
          widget.store,
          item.payload['subjectId'] as String?,
        ),
        AcademicData.contentName(
          widget.store,
          item.payload['contentId'] as String?,
        ),
      ].join(' ').toLowerCase().contains(term);
    }).toList();
    final mocks = widget.store.records(EntityTypes.mockExam).where((item) {
      final linkedSubject = item.payload['subjectId'];
      if (subjectId != null) return linkedSubject == subjectId;
      return linkedSubject == null ||
          academicSubjectIds.contains(linkedSubject);
    }).toList();
    final totalAttempts = questions.fold<int>(
      0,
      (sum, item) => sum + (item.payload['attempts'] as num? ?? 0).toInt(),
    );
    final totalCorrect = questions.fold<int>(
      0,
      (sum, item) => sum + (item.payload['correct'] as num? ?? 0).toInt(),
    );

    return AcademicPageBody(
      children: <Widget>[
        PageIntro(
          eyebrow: 'Prática direcionada',
          title: 'Questões e simulados',
          subtitle:
              'Monte o banco por matéria e conteúdo, escolha o escopo da prova, defina o tempo e acompanhe os acertos sem misturar os assuntos.',
          color: AppColors.primary,
        ),
        const SizedBox(height: 18),
        ResponsiveGrid(
          minItemWidth: 230,
          children: <Widget>[
            MetricCard(
              label: 'Questões cadastradas',
              value: '${questions.length}',
              icon: Icons.quiz_outlined,
              color: AppColors.primary,
            ),
            MetricCard(
              label: 'Simulados realizados',
              value: '${mocks.length}',
              icon: Icons.fact_check_outlined,
              color: AppColors.blue,
            ),
            MetricCard(
              label: 'Aproveitamento geral',
              value: totalAttempts == 0
                  ? '—'
                  : '${(totalCorrect * 100 / totalAttempts).round()}%',
              icon: Icons.insights_outlined,
              color: AppColors.green,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ElevatedButton.icon(
              onPressed: _startMock,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Montar simulado'),
            ),
            OutlinedButton.icon(
              onPressed: _newQuestion,
              icon: const Icon(Icons.add),
              label: const Text('Nova questão'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const AcademicSectionTitle(
          title: 'Banco de questões',
          subtitle: 'Filtre o conteúdo que deseja revisar ou editar.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            SizedBox(
              width: 300,
              child: TextField(
                controller: search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Buscar questão',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            SizedBox(
              width: 250,
              child: DropdownButtonFormField<String?>(
                isExpanded: true,
                key: ValueKey<String?>('simulation-subject-$subjectId'),
                initialValue:
                    academicSubjectIds.contains(subjectId) ? subjectId : null,
                decoration: const InputDecoration(labelText: 'Matéria'),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'Todas as matérias',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ...subjects.map(
                    (item) => DropdownMenuItem<String?>(
                      value: item.id,
                      child: Text(
                        item.payload['name'] as String? ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() {
                  subjectId = value;
                  contentId = null;
                }),
              ),
            ),
            SizedBox(
              width: 270,
              child: DropdownButtonFormField<String?>(
                isExpanded: true,
                key: ValueKey<String?>('simulation-content-$subjectId'),
                initialValue: contents.any((item) => item.id == contentId)
                    ? contentId
                    : null,
                decoration: const InputDecoration(labelText: 'Conteúdo'),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'Todos os conteúdos',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ...contents.map(
                    (item) => DropdownMenuItem<String?>(
                      value: item.id,
                      child: Text(
                        item.payload['title'] as String? ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => contentId = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (questions.isEmpty)
          const EmptyState(
            icon: Icons.quiz_outlined,
            title: 'Nenhuma questão encontrada',
            message:
                'Cadastre perguntas objetivas vinculadas a uma matéria e a um conteúdo.',
          )
        else
          ...questions.map(
            (question) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: _QuestionCard(store: widget.store, question: question),
            ),
          ),
        if (mocks.isNotEmpty) ...<Widget>[
          const SizedBox(height: 18),
          const AcademicSectionTitle(
            title: 'Histórico de simulados',
            subtitle: 'Resultados mais recentes salvos neste aparelho.',
          ),
          const SizedBox(height: 12),
          PremiumCard(
            child: Column(
              children: mocks.take(12).map((mock) {
                final date = DateTime.tryParse(
                  mock.payload['date'] as String? ?? '',
                );
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.green.withValues(alpha: .14),
                    foregroundColor: AppColors.green,
                    child: Text(
                      '${(mock.payload['scorePercent'] as num? ?? 0).round()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  title: Text(
                    '${mock.payload['correct'] ?? 0}/${mock.payload['questionCount'] ?? 0} acertos',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${AcademicData.subjectName(widget.store, mock.payload['subjectId'] as String?)} • '
                    '${date == null ? 'sem data' : DateFormat('dd/MM/yyyy HH:mm').format(date)}',
                  ),
                  trailing: ConfirmDeleteButton(
                    onDelete: () => widget.store.remove(mock.id),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.store, required this.question});

  final AppStore store;
  final SyncEntity question;

  @override
  Widget build(BuildContext context) {
    final attempts = (question.payload['attempts'] as num? ?? 0).toInt();
    final correct = (question.payload['correct'] as num? ?? 0).toInt();
    return PremiumCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.quiz_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  question.payload['question'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: <Widget>[
                    AcademicBadge(
                      label: AcademicData.subjectName(
                        store,
                        question.payload['subjectId'] as String?,
                      ),
                    ),
                    AcademicBadge(
                      label: AcademicData.contentName(
                        store,
                        question.payload['contentId'] as String?,
                      ),
                      color: AppColors.blue,
                    ),
                    AcademicBadge(
                      label: attempts == 0
                          ? 'Ainda não respondida'
                          : '$correct/$attempts acertos',
                      color: attempts == 0 ? AppColors.orange : AppColors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Editar questão',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) =>
                  AcademicQuestionEditorDialog(store: store, entity: question),
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
          ConfirmDeleteButton(onDelete: () => store.remove(question.id)),
        ],
      ),
    );
  }
}

class AcademicQuestionEditorDialog extends StatefulWidget {
  const AcademicQuestionEditorDialog({
    required this.store,
    this.entity,
    this.initialSubjectId,
    this.initialContentId,
    super.key,
  });

  final AppStore store;
  final SyncEntity? entity;
  final String? initialSubjectId;
  final String? initialContentId;

  @override
  State<AcademicQuestionEditorDialog> createState() =>
      _AcademicQuestionEditorDialogState();
}

class _AcademicQuestionEditorDialogState
    extends State<AcademicQuestionEditorDialog> {
  late final TextEditingController question;
  late final List<TextEditingController> options;
  late final TextEditingController explanation;
  String? subjectId;
  String? contentId;
  int correctIndex = 0;
  String difficulty = 'medium';

  @override
  void initState() {
    super.initState();
    final subjects = AcademicData.academicSubjects(widget.store);
    final preferredSubject = widget.entity?.payload['subjectId'] as String? ??
        widget.initialSubjectId;
    subjectId = subjects.any((item) => item.id == preferredSubject)
        ? preferredSubject
        : (subjects.isEmpty ? null : subjects.first.id);
    final contents = AcademicData.contentsForSubject(widget.store, subjectId);
    final preferredContent = widget.entity?.payload['contentId'] as String? ??
        widget.initialContentId;
    contentId = contents.any((item) => item.id == preferredContent)
        ? preferredContent
        : (contents.isEmpty ? null : contents.first.id);
    question = TextEditingController(
      text: widget.entity?.payload['question'] as String? ?? '',
    );
    final existingOptions = (widget.entity?.payload['options'] as List?)
            ?.map((item) => item.toString())
            .toList() ??
        <String>[];
    options = List<TextEditingController>.generate(
      4,
      (index) => TextEditingController(
        text: index < existingOptions.length ? existingOptions[index] : '',
      ),
    );
    explanation = TextEditingController(
      text: widget.entity?.payload['explanation'] as String? ?? '',
    );
    correctIndex =
        (widget.entity?.payload['correctIndex'] as num? ?? 0).toInt();
    difficulty = widget.entity?.payload['difficulty'] as String? ?? 'medium';
  }

  @override
  void dispose() {
    question.dispose();
    explanation.dispose();
    for (final option in options) {
      option.dispose();
    }
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
    final contents = AcademicData.contentsForSubject(widget.store, subjectId);
    return AlertDialog(
      title: Text(widget.entity == null ? 'Nova questão' : 'Editar questão'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
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
                        final available = AcademicData.contentsForSubject(
                          widget.store,
                          value,
                        );
                        contentId =
                            available.isEmpty ? null : available.first.id;
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: contentId,
                      decoration: const InputDecoration(labelText: 'Conteúdo'),
                      items: contents
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item.id,
                              child: Text(
                                item.payload['title'] as String? ?? '',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => contentId = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: question,
                autofocus: true,
                minLines: 3,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Enunciado',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              RadioGroup<int>(
                groupValue: correctIndex,
                onChanged: (value) => setState(() => correctIndex = value ?? 0),
                child: Column(
                  children: List<Widget>.generate(
                    options.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: <Widget>[
                          Radio<int>(value: index),
                          Expanded(
                            child: TextField(
                              controller: options[index],
                              decoration: InputDecoration(
                                labelText:
                                    'Alternativa ${String.fromCharCode(65 + index)}',
                                suffixIcon: correctIndex == index
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: AppColors.green,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              TextField(
                controller: explanation,
                minLines: 2,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Explicação da resposta',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: difficulty,
                decoration: const InputDecoration(labelText: 'Dificuldade'),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'easy', child: Text('Fácil')),
                  DropdownMenuItem(value: 'medium', child: Text('Média')),
                  DropdownMenuItem(value: 'hard', child: Text('Difícil')),
                ],
                onChanged: (value) =>
                    setState(() => difficulty = value ?? difficulty),
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
                contentId == null ||
                question.text.trim().isEmpty ||
                options.any((item) => item.text.trim().isEmpty)) {
              return;
            }
            final previous = widget.entity?.payload ?? <String, dynamic>{};
            await widget.store.save(
              EntityTypes.studyQuestion,
              <String, dynamic>{
                ...previous,
                'subjectId': subjectId,
                'contentId': contentId,
                'question': question.text.trim(),
                'options': options.map((item) => item.text.trim()).toList(),
                'correctIndex': correctIndex,
                'explanation': explanation.text.trim(),
                'difficulty': difficulty,
                'attempts': previous['attempts'] ?? 0,
                'correct': previous['correct'] ?? 0,
              },
              id: widget.entity?.id,
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Salvar questão'),
        ),
      ],
    );
  }
}

class AcademicMockConfiguration {
  const AcademicMockConfiguration({
    required this.subjectId,
    required this.contentId,
    required this.questionCount,
    required this.durationMinutes,
  });

  final String? subjectId;
  final String? contentId;
  final int questionCount;
  final int durationMinutes;
}

class AcademicMockSetupDialog extends StatefulWidget {
  const AcademicMockSetupDialog({
    required this.store,
    this.initialSubjectId,
    this.initialContentId,
    super.key,
  });

  final AppStore store;
  final String? initialSubjectId;
  final String? initialContentId;

  @override
  State<AcademicMockSetupDialog> createState() =>
      _AcademicMockSetupDialogState();
}

class _AcademicMockSetupDialogState extends State<AcademicMockSetupDialog> {
  String? subjectId;
  String? contentId;
  int questionCount = 10;
  int durationMinutes = 30;

  @override
  void initState() {
    super.initState();
    subjectId = widget.initialSubjectId;
    contentId = widget.initialContentId;
  }

  List<SyncEntity> get available {
    final academicSubjectIds = AcademicData.academicSubjects(widget.store)
        .map((item) => item.id)
        .toSet();
    return widget.store.records(EntityTypes.studyQuestion).where((item) {
      if (!academicSubjectIds.contains(item.payload['subjectId'])) return false;
      if (subjectId != null && item.payload['subjectId'] != subjectId) {
        return false;
      }
      if (contentId != null && item.payload['contentId'] != contentId) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = AcademicData.academicSubjects(widget.store)
      ..sort(
        (a, b) => (a.payload['name'] as String? ?? '').compareTo(
          b.payload['name'] as String? ?? '',
        ),
      );
    final contents = AcademicData.contentsForSubject(widget.store, subjectId);
    final count = available.length;
    return AlertDialog(
      title: const Text('Montar simulado'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Escolha o escopo. As questões serão embaralhadas e o resultado ficará salvo no histórico.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String?>(
              key: ValueKey<String?>('mock-subject-$subjectId'),
              initialValue: subjects.any((item) => item.id == subjectId)
                  ? subjectId
                  : null,
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
              onChanged: (value) => setState(() {
                subjectId = value;
                contentId = null;
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              key: ValueKey<String?>('mock-content-$subjectId'),
              initialValue: contents.any((item) => item.id == contentId)
                  ? contentId
                  : null,
              decoration: const InputDecoration(labelText: 'Conteúdo'),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Todos os conteúdos da seleção'),
                ),
                ...contents.map(
                  (item) => DropdownMenuItem<String?>(
                    value: item.id,
                    child: Text(item.payload['title'] as String? ?? ''),
                  ),
                ),
              ],
              onChanged: subjectId == null
                  ? null
                  : (value) => setState(() => contentId = value),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: questionCount,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade máxima',
                    ),
                    items: const <DropdownMenuItem<int>>[
                      DropdownMenuItem(value: 5, child: Text('5 questões')),
                      DropdownMenuItem(value: 10, child: Text('10 questões')),
                      DropdownMenuItem(value: 20, child: Text('20 questões')),
                      DropdownMenuItem(
                        value: 50,
                        child: Text('Até 50 questões'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => questionCount = value ?? 10),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: durationMinutes,
                    decoration: const InputDecoration(labelText: 'Tempo'),
                    items: const <DropdownMenuItem<int>>[
                      DropdownMenuItem(value: 0, child: Text('Sem limite')),
                      DropdownMenuItem(value: 15, child: Text('15 minutos')),
                      DropdownMenuItem(value: 30, child: Text('30 minutos')),
                      DropdownMenuItem(value: 60, child: Text('60 minutos')),
                      DropdownMenuItem(value: 90, child: Text('90 minutos')),
                    ],
                    onChanged: (value) =>
                        setState(() => durationMinutes = value ?? 30),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: (count == 0 ? AppColors.red : AppColors.green)
                    .withValues(alpha: .1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (count == 0 ? AppColors.red : AppColors.green)
                      .withValues(alpha: .35),
                ),
              ),
              child: Text(
                count == 0
                    ? 'Nenhuma questão disponível para esse filtro.'
                    : '$count questão(ões) disponível(is). O simulado usará ${min(count, questionCount)}.',
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: count == 0
              ? null
              : () => Navigator.pop(
                    context,
                    AcademicMockConfiguration(
                      subjectId: subjectId,
                      contentId: contentId,
                      questionCount: min(count, questionCount),
                      durationMinutes: durationMinutes,
                    ),
                  ),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Começar'),
        ),
      ],
    );
  }
}

class AcademicMockRunnerScreen extends StatefulWidget {
  const AcademicMockRunnerScreen({
    required this.store,
    required this.configuration,
    super.key,
  });

  final AppStore store;
  final AcademicMockConfiguration configuration;

  @override
  State<AcademicMockRunnerScreen> createState() =>
      _AcademicMockRunnerScreenState();
}

class _AcademicMockRunnerScreenState extends State<AcademicMockRunnerScreen> {
  late final List<SyncEntity> questions;
  final answers = <String, int>{};
  Timer? timer;
  int currentIndex = 0;
  int remainingSeconds = 0;
  int elapsedSeconds = 0;
  bool finished = false;
  bool submitting = false;
  int score = 0;

  @override
  void initState() {
    super.initState();
    final config = widget.configuration;
    final available = widget.store.records(EntityTypes.studyQuestion).where((
      item,
    ) {
      if (config.subjectId != null &&
          item.payload['subjectId'] != config.subjectId) {
        return false;
      }
      if (config.contentId != null &&
          item.payload['contentId'] != config.contentId) {
        return false;
      }
      return true;
    }).toList()
      ..shuffle(Random());
    questions = available.take(config.questionCount).toList();
    remainingSeconds = config.durationMinutes * 60;
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || finished || submitting) return;
      setState(() {
        elapsedSeconds++;
        if (widget.configuration.durationMinutes > 0) {
          remainingSeconds--;
          if (remainingSeconds <= 0) {
            remainingSeconds = 0;
            _finish(force: true);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _requestFinish() async {
    final unanswered = questions.length - answers.length;
    if (unanswered > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Finalizar simulado?'),
          content: Text(
            '$unanswered questão(ões) ainda não foram respondidas.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Continuar respondendo'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Finalizar assim mesmo'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await _finish();
  }

  Future<void> _finish({bool force = false}) async {
    if (finished || submitting) return;
    submitting = true;
    timer?.cancel();
    var correctCount = 0;
    final breakdown = <String, Map<String, int>>{};
    for (final question in questions) {
      final selected = answers[question.id];
      final expected = (question.payload['correctIndex'] as num? ?? 0).toInt();
      final isCorrect = selected == expected;
      if (isCorrect) correctCount++;
      final subjectId = question.payload['subjectId'] as String? ?? '';
      final stats = breakdown.putIfAbsent(
        subjectId,
        () => <String, int>{'questions': 0, 'correct': 0},
      );
      stats['questions'] = (stats['questions'] ?? 0) + 1;
      if (isCorrect) stats['correct'] = (stats['correct'] ?? 0) + 1;
      await widget.store.save(
          EntityTypes.studyQuestion,
          <String, dynamic>{
            ...question.payload,
            'attempts': (question.payload['attempts'] as num? ?? 0).toInt() + 1,
            'correct': (question.payload['correct'] as num? ?? 0).toInt() +
                (isCorrect ? 1 : 0),
          },
          id: question.id);
    }
    await widget.store.save(EntityTypes.mockExam, <String, dynamic>{
      'date': DateTime.now().toIso8601String(),
      'questionCount': questions.length,
      'correct': correctCount,
      'scorePercent':
          questions.isEmpty ? 0 : correctCount * 100 / questions.length,
      'subjectId': widget.configuration.subjectId,
      'contentId': widget.configuration.contentId,
      'durationMinutes': widget.configuration.durationMinutes,
      'elapsedSeconds': elapsedSeconds,
      'finishedByTime': force,
      'questionIds': questions.map((item) => item.id).toList(),
      'answers': answers,
      'breakdown': breakdown.entries
          .map(
            (entry) => <String, dynamic>{
              'subjectId': entry.key,
              ...entry.value,
            },
          )
          .toList(),
    });
    if (!mounted) return;
    setState(() {
      finished = true;
      submitting = false;
      score = correctCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (finished) return _result(context);
    final question = questions[currentIndex];
    final options = (question.payload['options'] as List?)
            ?.map((item) => item.toString())
            .toList() ??
        <String>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulado em andamento'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: AcademicBadge(
                label: widget.configuration.durationMinutes == 0
                    ? _clock(elapsedSeconds)
                    : _clock(remainingSeconds),
                color: remainingSeconds <= 300 &&
                        widget.configuration.durationMinutes > 0
                    ? AppColors.red
                    : AppColors.primary,
                icon: Icons.timer_outlined,
              ),
            ),
          ),
        ],
      ),
      body: PremiumBackground(
        child: Column(
          children: <Widget>[
            LinearProgressIndicator(
              value: (currentIndex + 1) / questions.length,
              minHeight: 4,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                children: <Widget>[
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: <Widget>[
                              AcademicBadge(
                                label:
                                    'Questão ${currentIndex + 1} de ${questions.length}',
                              ),
                              AcademicBadge(
                                label: AcademicData.subjectName(
                                  widget.store,
                                  question.payload['subjectId'] as String?,
                                ),
                                color: AppColors.blue,
                              ),
                              AcademicBadge(
                                label: AcademicData.contentName(
                                  widget.store,
                                  question.payload['contentId'] as String?,
                                ),
                                color: AppColors.green,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          PremiumCard(
                            borderColor: AppColors.primary,
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  question.payload['question'] as String? ?? '',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    height: 1.4,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                RadioGroup<int>(
                                  groupValue: answers[question.id],
                                  onChanged: (value) => setState(() {
                                    if (value != null) {
                                      answers[question.id] = value;
                                    }
                                  }),
                                  child: Column(
                                    children: options
                                        .asMap()
                                        .entries
                                        .map(
                                          (entry) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: RadioListTile<int>(
                                              value: entry.key,
                                              title: Text(
                                                '${String.fromCharCode(65 + entry.key)}. ${entry.value}',
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  14,
                                                ),
                                                side: const BorderSide(
                                                  color: AppColors.border,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _QuestionNavigator(
                            count: questions.length,
                            current: currentIndex,
                            answered: questions
                                .map((item) => answers.containsKey(item.id))
                                .toList(),
                            onSelect: (index) =>
                                setState(() => currentIndex = index),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: <Widget>[
                              OutlinedButton.icon(
                                onPressed: currentIndex == 0
                                    ? null
                                    : () => setState(() => currentIndex--),
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Anterior'),
                              ),
                              const Spacer(),
                              if (currentIndex < questions.length - 1)
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      setState(() => currentIndex++),
                                  icon: const Icon(Icons.arrow_forward),
                                  label: const Text('Próxima'),
                                )
                              else
                                ElevatedButton.icon(
                                  onPressed: submitting ? null : _requestFinish,
                                  icon: const Icon(Icons.fact_check_outlined),
                                  label: const Text('Finalizar'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _result(BuildContext context) {
    final percent = questions.isEmpty ? 0 : (score * 100 / questions.length);
    return Scaffold(
      appBar: AppBar(title: const Text('Resultado do simulado')),
      body: PremiumBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    PremiumCard(
                      borderColor:
                          percent >= 70 ? AppColors.green : AppColors.orange,
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: <Widget>[
                          Icon(
                            percent >= 70
                                ? Icons.emoji_events_outlined
                                : Icons.insights_outlined,
                            color: percent >= 70
                                ? AppColors.green
                                : AppColors.orange,
                            size: 54,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${percent.round()}%',
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '$score de ${questions.length} questões corretas • ${_clock(elapsedSeconds)}',
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const AcademicSectionTitle(
                      title: 'Correção comentada',
                      subtitle: 'Revise cada resposta antes de sair.',
                    ),
                    const SizedBox(height: 12),
                    ...questions.asMap().entries.map((entry) {
                      final question = entry.value;
                      final options = (question.payload['options'] as List?)
                              ?.map((item) => item.toString())
                              .toList() ??
                          <String>[];
                      final selected = answers[question.id];
                      final expected =
                          (question.payload['correctIndex'] as num? ?? 0)
                              .toInt();
                      final correct = selected == expected;
                      final selectedText = selected == null ||
                              selected < 0 ||
                              selected >= options.length
                          ? 'Não respondida'
                          : options[selected];
                      final expectedText =
                          expected >= 0 && expected < options.length
                              ? options[expected]
                              : 'Alternativa indisponível';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PremiumCard(
                          borderColor:
                              correct ? AppColors.green : AppColors.red,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Icon(
                                    correct
                                        ? Icons.check_circle_outline
                                        : Icons.cancel_outlined,
                                    color: correct
                                        ? AppColors.green
                                        : AppColors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Questão ${entry.key + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 9),
                              Text(
                                question.payload['question'] as String? ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Sua resposta: $selectedText'),
                              Text('Resposta correta: $expectedText'),
                              if ((question.payload['explanation'] as String? ??
                                      '')
                                  .isNotEmpty) ...<Widget>[
                                const SizedBox(height: 8),
                                Text(
                                  question.payload['explanation'] as String,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.done),
                      label: const Text('Concluir revisão'),
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
}

class _QuestionNavigator extends StatelessWidget {
  const _QuestionNavigator({
    required this.count,
    required this.current,
    required this.answered,
    required this.onSelect,
  });

  final int count;
  final int current;
  final List<bool> answered;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: List<Widget>.generate(count, (index) {
        final selected = current == index;
        final complete = answered[index];
        return InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () => onSelect(index),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary
                  : complete
                      ? AppColors.green.withValues(alpha: .18)
                      : AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : complete
                        ? AppColors.green
                        : AppColors.border,
              ),
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: selected
                    ? Colors.white
                    : complete
                        ? AppColors.green
                        : AppColors.textMuted,
              ),
            ),
          ),
        );
      }),
    );
  }
}

String _clock(int seconds) {
  final safe = max(0, seconds);
  final minutes = safe ~/ 60;
  final rest = safe % 60;
  return '${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
}
