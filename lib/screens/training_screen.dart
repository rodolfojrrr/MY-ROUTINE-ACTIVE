import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/sync_entity.dart';
import '../core/training_utils.dart';
import '../widgets/premium_widgets.dart';
import 'training_extra_tabs.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({required this.store, super.key});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: AnimatedBuilder(
        animation: store,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            title: const Text('Treinos'),
            bottom: const TabBar(
              isScrollable: true,
              tabs: <Widget>[
                Tab(icon: Icon(Icons.fitness_center), text: 'Fichas'),
                Tab(icon: Icon(Icons.menu_book_outlined), text: 'Biblioteca'),
                Tab(icon: Icon(Icons.insights), text: 'Evolução'),
                Tab(icon: Icon(Icons.monitor_weight_outlined), text: 'Corpo'),
                Tab(icon: Icon(Icons.water_drop_outlined), text: 'Hábitos'),
                Tab(icon: Icon(Icons.history), text: 'Histórico'),
              ],
            ),
          ),
          body: PremiumBackground(
            child: TabBarView(
              children: <Widget>[
                _PlansTab(store: store),
                ExerciseLibraryTab(store: store),
                TrainingProgressTab(store: store),
                BodyTrackingTab(store: store),
                WellnessTab(store: store),
                _WorkoutHistoryTab(store: store),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlansTab extends StatelessWidget {
  const _PlansTab({required this.store});

  final AppStore store;

  Future<void> _editPlan(BuildContext context, [SyncEntity? plan]) async {
    final name = TextEditingController(text: plan?.payload['name'] as String?);
    final focus = TextEditingController(text: plan?.payload['focus'] as String?);
    final day = TextEditingController(text: plan?.payload['day'] as String?);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(plan == null ? 'Nova ficha' : 'Editar ficha'),
        content: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nome (ex.: Treino A)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: focus,
                decoration: const InputDecoration(
                  labelText: 'Foco (ex.: Peito e tríceps)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: day,
                decoration: const InputDecoration(
                  labelText: 'Dia sugerido',
                ),
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
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (saved == true && name.text.trim().isNotEmpty) {
      await store.save(
        EntityTypes.workoutPlan,
        <String, dynamic>{
          'name': name.text.trim(),
          'focus': focus.text.trim(),
          'day': day.text.trim(),
        },
        id: plan?.id,
      );
    }
    name.dispose();
    focus.dispose();
    day.dispose();
  }

  Future<void> _deletePlan(SyncEntity plan) async {
    final exercises = store
        .records(EntityTypes.exercise)
        .where((item) => item.payload['planId'] == plan.id)
        .toList();
    for (final exercise in exercises) {
      final sets = store
          .records(EntityTypes.exerciseSet)
          .where((item) => item.payload['exerciseId'] == exercise.id)
          .toList();
      for (final set in sets) {
        await store.remove(set.id);
      }
      await store.remove(exercise.id);
    }
    await store.remove(plan.id);
  }

  @override
  Widget build(BuildContext context) {
    final plans = store.records(EntityTypes.workoutPlan);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const PageIntro(
                eyebrow: 'Evolução mensurável',
                title: 'Suas fichas de treino',
                subtitle:
                    'Cada série tem repetições, carga e tipo próprios. Cronometre exercícios e descansos separadamente.',
                color: AppColors.orange,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _editPlan(context),
                icon: const Icon(Icons.add),
                label: const Text('Nova ficha'),
              ),
              const SizedBox(height: 20),
              if (plans.isEmpty)
                const EmptyState(
                  icon: Icons.fitness_center,
                  title: 'Nenhuma ficha de treino',
                  message: 'Crie uma ficha e adicione os exercícios com suas séries.',
                )
              else
                ...plans.map((plan) {
                  final exercises = store
                      .records(EntityTypes.exercise)
                      .where((item) => item.payload['planId'] == plan.id)
                      .toList();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: PremiumCard(
                      borderColor: AppColors.orange.withValues(alpha: .45),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.orange.withValues(alpha: .16),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Icon(
                                  Icons.fitness_center,
                                  color: AppColors.orange,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      plan.payload['name'] as String? ?? '',
                                      style: const TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      <String>[
                                        plan.payload['focus'] as String? ?? '',
                                        plan.payload['day'] as String? ?? '',
                                      ].where((item) => item.isNotEmpty).join(' • '),
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Editar ficha',
                                onPressed: () => _editPlan(context, plan),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              ConfirmDeleteButton(
                                onDelete: () => _deletePlan(plan),
                              ),
                            ],
                          ),
                          const Divider(height: 28),
                          if (exercises.isEmpty)
                            const Text(
                              'Nenhum exercício nesta ficha.',
                              style: TextStyle(color: AppColors.textMuted),
                            )
                          else
                            ...exercises.map(
                              (exercise) => _ExerciseSummary(
                                store: store,
                                exercise: exercise,
                                onEdit: () => showDialog<void>(
                                  context: context,
                                  builder: (_) => _ExerciseDialog(
                                    store: store,
                                    planId: plan.id,
                                    entity: exercise,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: <Widget>[
                              OutlinedButton.icon(
                                onPressed: () => showDialog<void>(
                                  context: context,
                                  builder: (_) => _ExerciseDialog(
                                    store: store,
                                    planId: plan.id,
                                  ),
                                ),
                                icon: const Icon(Icons.add),
                                label: const Text('Exercício'),
                              ),
                              ElevatedButton.icon(
                                onPressed: exercises.isEmpty
                                    ? null
                                    : () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) => WorkoutSessionScreen(
                                              store: store,
                                              plan: plan,
                                            ),
                                          ),
                                        ),
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Iniciar treino'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseSummary extends StatelessWidget {
  const _ExerciseSummary({
    required this.store,
    required this.exercise,
    required this.onEdit,
  });

  final AppStore store;
  final SyncEntity exercise;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final sets = store
        .records(EntityTypes.exerciseSet)
        .where((item) => item.payload['exerciseId'] == exercise.id)
        .toList()
      ..sort((a, b) => (a.payload['position'] as num? ?? 0)
          .compareTo(b.payload['position'] as num? ?? 0));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  exercise.payload['name'] as String? ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  exercise.payload['group'] as String? ?? 'Geral',
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sets.map((set) {
                    final type = set.payload['type'] as String? ?? 'Normal';
                    return '$type: ${set.payload['reps']} reps × ${set.payload['load']} kg';
                  }).join('  •  '),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.tune)),
          ConfirmDeleteButton(
            onDelete: () async {
              for (final set in sets) {
                await store.remove(set.id);
              }
              await store.remove(exercise.id);
            },
          ),
        ],
      ),
    );
  }
}

class _SetDraft {
  _SetDraft({
    this.id,
    this.type = 'Normal',
    String reps = '10',
    String load = '0',
  })  : reps = TextEditingController(text: reps),
        load = TextEditingController(text: load);

  final String? id;
  String type;
  final TextEditingController reps;
  final TextEditingController load;

  void dispose() {
    reps.dispose();
    load.dispose();
  }
}

class _ExerciseDialog extends StatefulWidget {
  const _ExerciseDialog({
    required this.store,
    required this.planId,
    this.entity,
  });

  final AppStore store;
  final String planId;
  final SyncEntity? entity;

  @override
  State<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<_ExerciseDialog> {
  late final TextEditingController name;
  late final TextEditingController notes;
  late final TextEditingController rest;
  String group = 'Geral';
  final drafts = <_SetDraft>[];

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.entity?.payload['name'] as String?);
    notes = TextEditingController(text: widget.entity?.payload['notes'] as String?);
    rest = TextEditingController(
      text: (widget.entity?.payload['restSeconds'] as num? ?? 90).toString(),
    );
    group = widget.entity?.payload['group'] as String? ?? 'Geral';
    if (widget.entity != null) {
      final existing = widget.store
          .records(EntityTypes.exerciseSet)
          .where((item) => item.payload['exerciseId'] == widget.entity!.id)
          .toList()
        ..sort((a, b) => (a.payload['position'] as num? ?? 0)
            .compareTo(b.payload['position'] as num? ?? 0));
      for (final item in existing) {
        drafts.add(
          _SetDraft(
            id: item.id,
            type: item.payload['type'] as String? ?? 'Normal',
            reps: (item.payload['reps'] as num? ?? 10).toString(),
            load: (item.payload['load'] as num? ?? 0).toString(),
          ),
        );
      }
    }
    if (drafts.isEmpty) {
      drafts.addAll(<_SetDraft>[
        _SetDraft(type: 'Aquecimento', reps: '15'),
        _SetDraft(type: 'Normal', reps: '10'),
        _SetDraft(type: 'Falha', reps: '8'),
      ]);
    }
  }

  @override
  void dispose() {
    name.dispose();
    notes.dispose();
    rest.dispose();
    for (final draft in drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty) return;
    final exercise = await widget.store.save(
      EntityTypes.exercise,
      <String, dynamic>{
        'planId': widget.planId,
        'name': name.text.trim(),
        'notes': notes.text.trim(),
        'group': group,
        'restSeconds': int.tryParse(rest.text) ?? 90,
      },
      id: widget.entity?.id,
    );
    final original = widget.entity == null
        ? <SyncEntity>[]
        : widget.store
            .records(EntityTypes.exerciseSet)
            .where((item) => item.payload['exerciseId'] == widget.entity!.id)
            .toList();
    final retainedIds = drafts.map((item) => item.id).whereType<String>().toSet();
    for (final item in original) {
      if (!retainedIds.contains(item.id)) await widget.store.remove(item.id);
    }
    for (var index = 0; index < drafts.length; index++) {
      final draft = drafts[index];
      await widget.store.save(
        EntityTypes.exerciseSet,
        <String, dynamic>{
          'exerciseId': exercise.id,
          'position': index + 1,
          'type': draft.type,
          'reps': int.tryParse(draft.reps.text) ?? 0,
          'load': double.tryParse(draft.load.text.replaceAll(',', '.')) ?? 0,
        },
        id: draft.id,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.entity == null ? 'Novo exercício' : 'Editar exercício'),
      content: SizedBox(
        width: 650,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Exercício'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: group,
                decoration: const InputDecoration(labelText: 'Grupo muscular'),
                items: const <String>[
                  'Geral',
                  'Peito',
                  'Costas',
                  'Ombros',
                  'Bíceps',
                  'Tríceps',
                  'Quadríceps',
                  'Posterior',
                  'Glúteos',
                  'Panturrilhas',
                  'Abdômen',
                  'Cardio',
                ].map((item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
                onChanged: (value) => setState(() => group = value ?? group),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: rest,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Descanso (segundos)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: notes,
                      decoration: const InputDecoration(labelText: 'Observações'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Séries individuais',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                ),
              ),
              const SizedBox(height: 8),
              ...List<Widget>.generate(drafts.length, (index) {
                final draft = drafts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 36,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          initialValue: draft.type,
                          decoration: const InputDecoration(labelText: 'Tipo'),
                          items: const <String>[
                            'Aquecimento',
                            'Normal',
                            'Falha',
                            'Drop-set',
                          ]
                              .map(
                                (type) => DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => draft.type = value!,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: draft.reps,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Reps'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: draft.load,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(labelText: 'Kg'),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remover série',
                        onPressed: drafts.length == 1
                            ? null
                            : () => setState(() {
                                  final removed = drafts.removeAt(index);
                                  removed.dispose();
                                }),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                    ],
                  ),
                );
              }),
              OutlinedButton.icon(
                onPressed: () => setState(() => drafts.add(_SetDraft())),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar série'),
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
        FilledButton(onPressed: save, child: const Text('Salvar exercício')),
      ],
    );
  }
}

class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({required this.store, required this.plan, super.key});

  final AppStore store;
  final SyncEntity plan;

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  Timer? ticker;
  String? runningExerciseId;
  int restRemaining = 0;
  int totalRestSeconds = 0;
  final exerciseSeconds = <String, int>{};
  final completedSets = <String>{};

  List<SyncEntity> get exercises => widget.store
      .records(EntityTypes.exercise)
      .where((item) => item.payload['planId'] == widget.plan.id)
      .toList();

  @override
  void initState() {
    super.initState();
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (runningExerciseId != null) {
          exerciseSeconds.update(
            runningExerciseId!,
            (value) => value + 1,
            ifAbsent: () => 1,
          );
        }
        if (restRemaining > 0) {
          restRemaining--;
          totalRestSeconds++;
        }
      });
    });
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  void toggleExercise(String id) {
    setState(() {
      restRemaining = 0;
      runningExerciseId = runningExerciseId == id ? null : id;
    });
  }

  void toggleSet(SyncEntity set, int restSeconds) {
    setState(() {
      if (!completedSets.add(set.id)) {
        completedSets.remove(set.id);
      } else {
        runningExerciseId = null;
        restRemaining = restSeconds;
      }
    });
  }

  Future<void> finish() async {
    runningExerciseId = null;
    final exerciseTotal =
        exerciseSeconds.values.fold<int>(0, (sum, value) => sum + value);
    final snapshots = <Map<String, dynamic>>[];
    for (final exercise in exercises) {
      final sets = widget.store
          .records(EntityTypes.exerciseSet)
          .where((item) => item.payload['exerciseId'] == exercise.id)
          .toList();
      for (final set in sets) {
        if (!completedSets.contains(set.id)) continue;
        snapshots.add(<String, dynamic>{
          'exerciseId': exercise.id,
          'exerciseName': exercise.payload['name'],
          'group': exercise.payload['group'] as String? ?? 'Geral',
          'setId': set.id,
          'type': set.payload['type'],
          'reps': (set.payload['reps'] as num? ?? 0).toInt(),
          'load': (set.payload['load'] as num? ?? 0).toDouble(),
        });
      }
    }
    final volume = TrainingUtils.snapshotVolume(snapshots);
    await widget.store.save(EntityTypes.workoutSession, <String, dynamic>{
      'planId': widget.plan.id,
      'planName': widget.plan.payload['name'],
      'date': DateTime.now().toIso8601String(),
      'exerciseSeconds': exerciseTotal,
      'restSeconds': totalRestSeconds,
      'totalSeconds': exerciseTotal + totalRestSeconds,
      'exerciseTimes': exerciseSeconds,
      'completedSetIds': completedSets.toList(),
      'setSnapshots': snapshots,
      'volume': volume,
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final exerciseTotal =
        exerciseSeconds.values.fold<int>(0, (sum, value) => sum + value);
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(widget.plan.payload['name'] as String? ?? 'Treino'),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: finish,
                icon: const Icon(Icons.check),
                label: const Text('Finalizar'),
              ),
            ),
          ],
        ),
        body: PremiumBackground(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    children: <Widget>[
                      ResponsiveGrid(
                        minItemWidth: 220,
                        children: <Widget>[
                          MetricCard(
                            label: 'Exercícios',
                            value: _formatDuration(exerciseTotal),
                            icon: Icons.timer_outlined,
                            color: AppColors.orange,
                          ),
                          MetricCard(
                            label: 'Descanso somado',
                            value: _formatDuration(totalRestSeconds),
                            icon: Icons.hourglass_bottom,
                            color: AppColors.blue,
                          ),
                          MetricCard(
                            label: 'Tempo total',
                            value: _formatDuration(
                              exerciseTotal + totalRestSeconds,
                            ),
                            icon: Icons.av_timer,
                            color: AppColors.green,
                          ),
                        ],
                      ),
                      if (restRemaining > 0) ...<Widget>[
                        const SizedBox(height: 14),
                        PremiumCard(
                          borderColor: AppColors.blue,
                          child: Row(
                            children: <Widget>[
                              const Icon(Icons.self_improvement, color: AppColors.blue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Descanso: ${_formatDuration(restRemaining)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(() => restRemaining = 0),
                                child: const Text('Pular'),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      ...exercises.map((exercise) {
                        final sets = widget.store
                            .records(EntityTypes.exerciseSet)
                            .where(
                              (item) => item.payload['exerciseId'] == exercise.id,
                            )
                            .toList()
                          ..sort((a, b) => (a.payload['position'] as num? ?? 0)
                              .compareTo(b.payload['position'] as num? ?? 0));
                        final running = runningExerciseId == exercise.id;
                        final restSeconds =
                            (exercise.payload['restSeconds'] as num? ?? 90).toInt();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: PremiumCard(
                            borderColor: running
                                ? AppColors.orange
                                : AppColors.border,
                            child: Column(
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            exercise.payload['name'] as String? ?? '',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          Text(
                                            'Descanso programado: ${restSeconds}s',
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(exerciseSeconds[exercise.id] ?? 0),
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        fontFeatures: <FontFeature>[
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton.filled(
                                      onPressed: () => toggleExercise(exercise.id),
                                      icon: Icon(running ? Icons.pause : Icons.play_arrow),
                                    ),
                                  ],
                                ),
                                const Divider(height: 25),
                                ...sets.map(
                                  (set) => CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    value: completedSets.contains(set.id),
                                    onChanged: (_) => toggleSet(set, restSeconds),
                                    activeColor: AppColors.orange,
                                    title: Text(
                                      'Série ${set.payload['position']} • ${set.payload['type']}',
                                    ),
                                    subtitle: Text(
                                      '${set.payload['reps']} repetições • ${set.payload['load']} kg',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutHistoryTab extends StatelessWidget {
  const _WorkoutHistoryTab({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final sessions = store.records(EntityTypes.workoutSession);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const PageIntro(
                  eyebrow: 'Consistência',
                  title: 'Histórico de treinos',
                  subtitle:
                      'O total diário soma o tempo cronometrado em cada exercício e todos os descansos.',
                  color: AppColors.orange,
                ),
                const SizedBox(height: 20),
                if (sessions.isEmpty)
                  const EmptyState(
                    icon: Icons.history,
                    title: 'Nenhum treino concluído',
                    message: 'Finalize uma sessão para registrar seus tempos.',
                  )
                else
                  ...sessions.map(
                    (session) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PremiumCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.check_circle,
                            color: AppColors.green,
                          ),
                          title: Text(
                            session.payload['planName'] as String? ?? 'Treino',
                          ),
                          subtitle: Text(
                            '${_formatDateTime(session.payload['date'] as String?)}\nExercícios: ${_formatDuration((session.payload['exerciseSeconds'] as num? ?? 0).toInt())} • Descanso: ${_formatDuration((session.payload['restSeconds'] as num? ?? 0).toInt())}',
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                _formatDuration(
                                  (session.payload['totalSeconds'] as num? ?? 0)
                                      .toInt(),
                                ),
                                style: const TextStyle(
                                  color: AppColors.orange,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              ConfirmDeleteButton(
                                onDelete: () => store.remove(session.id),
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
        ),
      ],
    );
  }
}

String _formatDuration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remaining = seconds % 60;
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
}

String _formatDateTime(String? value) {
  final parsed = DateTime.tryParse(value ?? '');
  return parsed == null
      ? 'Data indisponível'
      : DateFormat('dd/MM/yyyy HH:mm').format(parsed);
}
