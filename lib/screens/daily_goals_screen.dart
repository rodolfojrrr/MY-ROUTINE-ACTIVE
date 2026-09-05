import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/academic_data.dart';
import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/study_timer_controller.dart';
import '../core/sync_entity.dart';
import '../widgets/premium_widgets.dart';
import 'academic_shared.dart';

class DailyGoalsScreen extends StatefulWidget {
  const DailyGoalsScreen({
    required this.store,
    required this.timer,
    super.key,
  });

  final AppStore store;
  final StudyTimerController timer;

  @override
  State<DailyGoalsScreen> createState() => _DailyGoalsScreenState();
}

class _DailyGoalsScreenState extends State<DailyGoalsScreen> {
  DateTime selectedDate = DateTime.now();

  String get dateKey => DateFormat('yyyy-MM-dd').format(selectedDate);

  List<SyncEntity> get goals {
    final items = widget.store
        .records(EntityTypes.dailyStudyGoal)
        .where((item) => item.payload['date'] == dateKey)
        .toList();
    items.sort(
      (a, b) => (a.payload['order'] as num? ?? 0).toInt().compareTo(
            (b.payload['order'] as num? ?? 0).toInt(),
          ),
    );
    return items;
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (value != null) setState(() => selectedDate = value);
  }

  Future<void> _toggle(SyncEntity goal) => widget.store.save(
        EntityTypes.dailyStudyGoal,
        <String, dynamic>{
          ...goal.payload,
          'completed': goal.payload['completed'] != true,
          'completedAt': goal.payload['completed'] == true
              ? null
              : DateTime.now().millisecondsSinceEpoch,
        },
        id: goal.id,
      );

  Future<void> _startGoal(SyncEntity goal) async {
    if (!await _canReplaceTimer()) return;
    await widget.timer.start(
      title: goal.payload['title'] as String? ?? 'Meta de estudo',
      subjectId: goal.payload['subjectId'] as String?,
      contentId: goal.payload['contentId'] as String?,
      goalId: goal.id,
      plannedMinutes: (goal.payload['plannedMinutes'] as num? ?? 30).toInt(),
    );
  }

  Future<bool> _canReplaceTimer() async {
    if (!widget.timer.isActive) return true;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Substituir sessão atual?'),
            content: const Text(
              'Existe um temporizador salvo. Se continuar, o tempo atual será descartado.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Manter atual'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Substituir'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _completeTimer() async {
    final minutes = await widget.timer.complete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          minutes == 0
              ? 'Sessão encerrada sem tempo registrado.'
              : 'Sessão concluída: $minutes minuto(s) registrados.',
        ),
      ),
    );
  }

  Future<void> _discardTimer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Descartar sessão?'),
        content: const Text('O tempo atual não será registrado.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.timer.discard();
  }

  Future<void> _freeSession() async {
    if (!await _canReplaceTimer() || !mounted) return;
    final config = await showDialog<_FreeSessionConfig>(
      context: context,
      builder: (_) => _FreeSessionDialog(store: widget.store),
    );
    if (config == null) return;
    await widget.timer.start(
      title: config.title,
      subjectId: config.subjectId,
      contentId: config.contentId,
      plannedMinutes: config.minutes,
    );
  }

  Future<void> _useWeeklyPlan(SyncEntity plan) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final existing = widget.store.records(EntityTypes.dailyStudyGoal).where(
          (item) => item.payload['date'] == today,
        );
    await widget.store.save(EntityTypes.dailyStudyGoal, <String, dynamic>{
      'date': today,
      'title': plan.payload['title'],
      'subjectId': plan.payload['subjectId'],
      'contentId': plan.payload['contentId'],
      'plannedMinutes': plan.payload['plannedMinutes'] ?? 30,
      'completed': false,
      'completedAt': null,
      'order': existing.length,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    if (!mounted) return;
    setState(() => selectedDate = DateTime.now());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Planejamento adicionado às metas de hoje.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayGoals = goals;
    final completed =
        dayGoals.where((item) => item.payload['completed'] == true).length;
    final planned = dayGoals.fold<int>(
      0,
      (sum, item) =>
          sum + (item.payload['plannedMinutes'] as num? ?? 0).toInt(),
    );
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayMinutes = widget.store
        .records(EntityTypes.studySession)
        .where(
          (item) =>
              (item.payload['date'] as String? ?? '').startsWith(todayKey),
        )
        .fold<int>(
          0,
          (sum, item) => sum + (item.payload['minutes'] as num? ?? 0).toInt(),
        );

    return AnimatedBuilder(
      animation: widget.timer,
      builder: (context, _) => AcademicPageBody(
        children: <Widget>[
          PageIntro(
            eyebrow: 'Rotina flexível',
            title: 'Metas diárias e foco',
            subtitle:
                'Planeje o dia, escolha a matéria quando quiser e use o cronograma semanal apenas como referência — nada fica amarrado.',
            color: AppColors.primary,
          ),
          const SizedBox(height: 18),
          _TimerPanel(
            store: widget.store,
            timer: widget.timer,
            onFreeSession: _freeSession,
            onComplete: _completeTimer,
            onDiscard: _discardTimer,
          ),
          const SizedBox(height: 16),
          ResponsiveGrid(
            minItemWidth: 220,
            children: <Widget>[
              MetricCard(
                label: 'Metas do dia',
                value: '$completed/${dayGoals.length}',
                caption: dayGoals.isEmpty
                    ? 'Organize do seu jeito'
                    : '${dayGoals.length - completed} restante(s)',
                icon: Icons.flag_outlined,
                color: AppColors.primary,
              ),
              MetricCard(
                label: 'Tempo planejado',
                value: '$planned min',
                caption: 'Referência, não limite',
                icon: Icons.schedule,
                color: AppColors.orange,
              ),
              MetricCard(
                label: 'Estudado hoje',
                value: '$todayMinutes min',
                caption: 'Sessões concluídas',
                icon: Icons.timer_outlined,
                color: AppColors.green,
              ),
            ],
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final heading = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Lista do dia',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat("EEEE, dd 'de' MMMM", 'pt_BR')
                        .format(selectedDate),
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              );
              final dateButton = IconButton(
                tooltip: 'Escolher data',
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month_outlined),
              );
              final addButton = ElevatedButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => _DailyGoalDialog(
                    store: widget.store,
                    date: dateKey,
                    order: dayGoals.length,
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Nova meta'),
              );
              if (constraints.maxWidth >= 570) {
                return Row(
                  children: <Widget>[
                    Expanded(child: heading),
                    dateButton,
                    const SizedBox(width: 4),
                    addButton,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(child: heading),
                      dateButton,
                    ],
                  ),
                  const SizedBox(height: 10),
                  addButton,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          if (dayGoals.isEmpty)
            const EmptyState(
              icon: Icons.flag_outlined,
              title: 'Dia livre para organizar',
              message:
                  'Crie uma meta vinculada a uma matéria ou apenas escreva o que deseja estudar.',
            )
          else
            ...dayGoals.map(
              (goal) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _GoalCard(
                  store: widget.store,
                  goal: goal,
                  onToggle: () => _toggle(goal),
                  onStart: () => _startGoal(goal),
                  onEdit: () => showDialog<void>(
                    context: context,
                    builder: (_) => _DailyGoalDialog(
                      store: widget.store,
                      date: dateKey,
                      order: dayGoals.indexOf(goal),
                      entity: goal,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 22),
          AcademicSectionTitle(
            title: 'Cronograma semanal flexível',
            subtitle:
                'Planeje uma referência para a semana e leve qualquer item para o dia atual quando fizer sentido.',
            trailing: OutlinedButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => _WeeklyPlanDialog(store: widget.store),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            ),
          ),
          const SizedBox(height: 12),
          _WeeklyBoard(
            store: widget.store,
            onUseToday: _useWeeklyPlan,
          ),
        ],
      ),
    );
  }
}

class _TimerPanel extends StatelessWidget {
  const _TimerPanel({
    required this.store,
    required this.timer,
    required this.onFreeSession,
    required this.onComplete,
    required this.onDiscard,
  });

  final AppStore store;
  final StudyTimerController timer;
  final VoidCallback onFreeSession;
  final VoidCallback onComplete;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      borderColor: timer.isActive ? AppColors.primary : AppColors.appBorder,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                timer.isActive ? timer.title : 'Pronto para focar?',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                timer.isActive
                    ? '${AcademicData.subjectName(store, timer.subjectId)} • planejado: ${timer.plannedMinutes} min'
                    : 'O cronômetro continua ao navegar. Se o app for ocultado ou fechado, a sessão fica salva e pausada.',
                style: const TextStyle(color: AppColors.textMuted),
              ),
              if (timer.isActive) ...<Widget>[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: timer.progress),
              ],
            ],
          );
          final controls = Column(
            crossAxisAlignment:
                wide ? CrossAxisAlignment.end : CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                timer.formattedElapsed,
                textAlign: wide ? TextAlign.right : TextAlign.center,
                style: const TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.w900,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: wide ? WrapAlignment.end : WrapAlignment.center,
                children: <Widget>[
                  if (!timer.isActive)
                    ElevatedButton.icon(
                      onPressed: onFreeSession,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Sessão livre'),
                    ),
                  if (timer.isRunning)
                    OutlinedButton.icon(
                      onPressed: timer.pause,
                      icon: const Icon(Icons.pause),
                      label: const Text('Pausar'),
                    ),
                  if (timer.status == StudyTimerStatus.paused)
                    ElevatedButton.icon(
                      onPressed: timer.resume,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Continuar'),
                    ),
                  if (timer.isActive)
                    FilledButton.tonalIcon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check),
                      label: const Text('Concluir'),
                    ),
                  if (timer.isActive)
                    IconButton(
                      tooltip: 'Descartar sessão',
                      onPressed: onDiscard,
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.red),
                    ),
                ],
              ),
            ],
          );
          return wide
              ? Row(
                  children: <Widget>[
                    Expanded(child: details),
                    const SizedBox(width: 24),
                    controls,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    details,
                    const SizedBox(height: 18),
                    controls,
                  ],
                );
        },
      ),
    );
  }
}

Future<bool> _confirmDailyGoalDelete(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mover meta para a lixeira?'),
        content: const Text(
          'A meta poderá ser restaurada depois pela Lixeira.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Mover para a lixeira'),
          ),
        ],
      ),
    ) ??
    false;

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.store,
    required this.goal,
    required this.onToggle,
    required this.onStart,
    required this.onEdit,
  });

  final AppStore store;
  final SyncEntity goal;
  final VoidCallback onToggle;
  final VoidCallback onStart;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final completed = goal.payload['completed'] == true;
    return PremiumCard(
      borderColor: completed ? AppColors.green : AppColors.appBorder,
      child: Row(
        children: <Widget>[
          Checkbox(value: completed, onChanged: (_) => onToggle()),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  goal.payload['title'] as String? ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: <Widget>[
                    AcademicBadge(
                      label: AcademicData.subjectName(
                        store,
                        goal.payload['subjectId'] as String?,
                      ),
                    ),
                    AcademicBadge(
                      label: '${goal.payload['plannedMinutes'] ?? 30} min',
                      color: AppColors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!completed)
            IconButton(
              tooltip: 'Iniciar foco',
              onPressed: onStart,
              icon: Icon(Icons.play_circle_fill, color: AppColors.primary),
            ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') onEdit();
              if (value == 'delete' && await _confirmDailyGoalDelete(context)) {
                await store.remove(goal.id);
              }
            },
            itemBuilder: (_) => const <PopupMenuEntry<String>>[
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'delete', child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyBoard extends StatelessWidget {
  const _WeeklyBoard({required this.store, required this.onUseToday});

  final AppStore store;
  final ValueChanged<SyncEntity> onUseToday;

  @override
  Widget build(BuildContext context) {
    final plans = store.records(EntityTypes.weeklyStudyPlan);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1060
            ? 4
            : constraints.maxWidth >= 700
                ? 2
                : 1;
        final spacing = 12.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: AcademicData.weekdayLong.entries.map((entry) {
            final dayPlans = plans
                .where((item) => item.payload['weekday'] == entry.key)
                .toList()
              ..sort(
                (a, b) => (a.payload['order'] as num? ?? 0).toInt().compareTo(
                      (b.payload['order'] as num? ?? 0).toInt(),
                    ),
              );
            return SizedBox(
              width: width,
              child: PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.value,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 9),
                    if (dayPlans.isEmpty)
                      const Text(
                        'Sem planejamento fixo.',
                        style: TextStyle(color: AppColors.textMuted),
                      )
                    else
                      ...dayPlans.map(
                        (plan) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.appSurfaceRaised,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    plan.payload['title'] as String? ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${AcademicData.subjectName(store, plan.payload['subjectId'] as String?)} • ${plan.payload['plannedMinutes'] ?? 30} min',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 4,
                                    children: <Widget>[
                                      TextButton(
                                        onPressed: () => onUseToday(plan),
                                        child: const Text('Usar hoje'),
                                      ),
                                      IconButton(
                                        tooltip: 'Editar',
                                        onPressed: () => showDialog<void>(
                                          context: context,
                                          builder: (_) => _WeeklyPlanDialog(
                                            store: store,
                                            entity: plan,
                                          ),
                                        ),
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                      ConfirmDeleteButton(
                                        onDelete: () => store.remove(plan.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _DailyGoalDialog extends StatefulWidget {
  const _DailyGoalDialog({
    required this.store,
    required this.date,
    required this.order,
    this.entity,
  });

  final AppStore store;
  final String date;
  final int order;
  final SyncEntity? entity;

  @override
  State<_DailyGoalDialog> createState() => _DailyGoalDialogState();
}

class _DailyGoalDialogState extends State<_DailyGoalDialog> {
  late final TextEditingController title;
  late final TextEditingController minutes;
  String? subjectId;
  String? contentId;

  @override
  void initState() {
    super.initState();
    title = TextEditingController(
      text: widget.entity?.payload['title'] as String? ?? '',
    );
    minutes = TextEditingController(
      text: (widget.entity?.payload['plannedMinutes'] ?? 30).toString(),
    );
    subjectId = widget.entity?.payload['subjectId'] as String?;
    contentId = widget.entity?.payload['contentId'] as String?;
  }

  @override
  void dispose() {
    title.dispose();
    minutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = widget.store.records(EntityTypes.subject);
    final contents = AcademicData.contentsForSubject(widget.store, subjectId);
    return AlertDialog(
      title: Text(widget.entity == null ? 'Nova meta diária' : 'Editar meta'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: title,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'O que você quer estudar?',
                  hintText: 'Ex.: revisar estruturas de dados',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: subjectId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Matéria (opcional)',
                ),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Meta livre'),
                  ),
                  ...subjects.map(
                    (item) => DropdownMenuItem<String?>(
                      value: item.id,
                      child: Text(
                        item.payload['name'] as String? ?? '',
                        maxLines: 1,
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: contentId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Conteúdo (opcional)',
                ),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Conteúdo geral'),
                  ),
                  ...contents.map(
                    (item) => DropdownMenuItem<String?>(
                      value: item.id,
                      child: Text(
                        item.payload['title'] as String? ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => contentId = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minutes,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tempo planejado em minutos',
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
              EntityTypes.dailyStudyGoal,
              <String, dynamic>{
                ...?widget.entity?.payload,
                'date': widget.date,
                'title': title.text.trim(),
                'subjectId': subjectId,
                'contentId': contentId,
                'plannedMinutes':
                    (int.tryParse(minutes.text) ?? 30).clamp(1, 1440).toInt(),
                'completed': widget.entity?.payload['completed'] == true,
                'completedAt': widget.entity?.payload['completedAt'],
                'order': widget.entity?.payload['order'] ?? widget.order,
                'createdAt': widget.entity?.payload['createdAt'] ??
                    DateTime.now().millisecondsSinceEpoch,
              },
              id: widget.entity?.id,
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _WeeklyPlanDialog extends StatefulWidget {
  const _WeeklyPlanDialog({required this.store, this.entity});

  final AppStore store;
  final SyncEntity? entity;

  @override
  State<_WeeklyPlanDialog> createState() => _WeeklyPlanDialogState();
}

class _WeeklyPlanDialogState extends State<_WeeklyPlanDialog> {
  late final TextEditingController title;
  late final TextEditingController minutes;
  late int weekday;
  String? subjectId;
  String? contentId;

  @override
  void initState() {
    super.initState();
    title = TextEditingController(
      text: widget.entity?.payload['title'] as String? ?? '',
    );
    minutes = TextEditingController(
      text: (widget.entity?.payload['plannedMinutes'] ?? 30).toString(),
    );
    weekday =
        (widget.entity?.payload['weekday'] as num? ?? DateTime.now().weekday)
            .toInt();
    subjectId = widget.entity?.payload['subjectId'] as String?;
    contentId = widget.entity?.payload['contentId'] as String?;
  }

  @override
  void dispose() {
    title.dispose();
    minutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = widget.store.records(EntityTypes.subject);
    final contents = AcademicData.contentsForSubject(widget.store, subjectId);
    return AlertDialog(
      title: Text(widget.entity == null ? 'Planejar a semana' : 'Editar plano'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
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
                onChanged: (value) => setState(() => weekday = value!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: title,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Atividade sugerida',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: subjectId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Matéria (opcional)',
                ),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Planejamento livre'),
                  ),
                  ...subjects.map(
                    (item) => DropdownMenuItem<String?>(
                      value: item.id,
                      child: Text(
                        item.payload['name'] as String? ?? '',
                        maxLines: 1,
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: contentId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Conteúdo (opcional)',
                ),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Conteúdo geral'),
                  ),
                  ...contents.map(
                    (item) => DropdownMenuItem<String?>(
                      value: item.id,
                      child: Text(
                        item.payload['title'] as String? ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => contentId = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minutes,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tempo sugerido em minutos',
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
            final sameDay = widget.store
                .records(EntityTypes.weeklyStudyPlan)
                .where((item) => item.payload['weekday'] == weekday);
            await widget.store.save(
              EntityTypes.weeklyStudyPlan,
              <String, dynamic>{
                ...?widget.entity?.payload,
                'weekday': weekday,
                'title': title.text.trim(),
                'subjectId': subjectId,
                'contentId': contentId,
                'plannedMinutes':
                    (int.tryParse(minutes.text) ?? 30).clamp(1, 1440).toInt(),
                'order': widget.entity?.payload['order'] ?? sameDay.length,
                'createdAt': widget.entity?.payload['createdAt'] ??
                    DateTime.now().millisecondsSinceEpoch,
              },
              id: widget.entity?.id,
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _FreeSessionConfig {
  const _FreeSessionConfig({
    required this.title,
    required this.subjectId,
    required this.contentId,
    required this.minutes,
  });

  final String title;
  final String? subjectId;
  final String? contentId;
  final int minutes;
}

class _FreeSessionDialog extends StatefulWidget {
  const _FreeSessionDialog({required this.store});

  final AppStore store;

  @override
  State<_FreeSessionDialog> createState() => _FreeSessionDialogState();
}

class _FreeSessionDialogState extends State<_FreeSessionDialog> {
  final title = TextEditingController(text: 'Sessão livre de estudo');
  final minutes = TextEditingController(text: '25');
  String? subjectId;
  String? contentId;

  @override
  void dispose() {
    title.dispose();
    minutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = widget.store.records(EntityTypes.subject);
    final contents = AcademicData.contentsForSubject(widget.store, subjectId);
    return AlertDialog(
      title: const Text('Iniciar sessão livre'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: title,
              autofocus: true,
              decoration:
                  const InputDecoration(labelText: 'Objetivo da sessão'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: subjectId,
              isExpanded: true,
              decoration:
                  const InputDecoration(labelText: 'Matéria (opcional)'),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Estudo geral'),
                ),
                ...subjects.map(
                  (item) => DropdownMenuItem<String?>(
                    value: item.id,
                    child: Text(
                      item.payload['name'] as String? ?? '',
                      maxLines: 1,
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
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: contentId,
              isExpanded: true,
              decoration:
                  const InputDecoration(labelText: 'Conteúdo (opcional)'),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Conteúdo geral'),
                ),
                ...contents.map(
                  (item) => DropdownMenuItem<String?>(
                    value: item.id,
                    child: Text(
                      item.payload['title'] as String? ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => contentId = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: minutes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tempo planejado'),
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
          onPressed: () => Navigator.pop(
            context,
            _FreeSessionConfig(
              title: title.text.trim(),
              subjectId: subjectId,
              contentId: contentId,
              minutes:
                  (int.tryParse(minutes.text) ?? 25).clamp(1, 1440).toInt(),
            ),
          ),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Iniciar'),
        ),
      ],
    );
  }
}
