import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/sync_entity.dart';
import '../core/training_utils.dart';
import '../widgets/premium_widgets.dart';

class ExerciseLibraryTab extends StatelessWidget {
  const ExerciseLibraryTab({required this.store, super.key});

  final AppStore store;

  static const templates = <Map<String, String>>[
    <String, String>{'name': 'Supino reto', 'group': 'Peito'},
    <String, String>{'name': 'Supino inclinado', 'group': 'Peito'},
    <String, String>{'name': 'Crucifixo', 'group': 'Peito'},
    <String, String>{'name': 'Puxada frontal', 'group': 'Costas'},
    <String, String>{'name': 'Remada baixa', 'group': 'Costas'},
    <String, String>{'name': 'Remada curvada', 'group': 'Costas'},
    <String, String>{'name': 'Desenvolvimento', 'group': 'Ombros'},
    <String, String>{'name': 'Elevação lateral', 'group': 'Ombros'},
    <String, String>{'name': 'Elevação frontal', 'group': 'Ombros'},
    <String, String>{'name': 'Rosca direta', 'group': 'Bíceps'},
    <String, String>{'name': 'Rosca martelo', 'group': 'Bíceps'},
    <String, String>{'name': 'Rosca Scott', 'group': 'Bíceps'},
    <String, String>{'name': 'Tríceps pulley', 'group': 'Tríceps'},
    <String, String>{'name': 'Tríceps francês', 'group': 'Tríceps'},
    <String, String>{'name': 'Tríceps testa', 'group': 'Tríceps'},
    <String, String>{'name': 'Agachamento livre', 'group': 'Quadríceps'},
    <String, String>{'name': 'Leg press', 'group': 'Quadríceps'},
    <String, String>{'name': 'Cadeira extensora', 'group': 'Quadríceps'},
    <String, String>{'name': 'Mesa flexora', 'group': 'Posterior'},
    <String, String>{'name': 'Stiff', 'group': 'Posterior'},
    <String, String>{'name': 'Levantamento terra romeno', 'group': 'Posterior'},
    <String, String>{'name': 'Elevação pélvica', 'group': 'Glúteos'},
    <String, String>{'name': 'Abdução de quadril', 'group': 'Glúteos'},
    <String, String>{'name': 'Panturrilha em pé', 'group': 'Panturrilhas'},
    <String, String>{'name': 'Panturrilha sentado', 'group': 'Panturrilhas'},
    <String, String>{'name': 'Prancha', 'group': 'Abdômen'},
    <String, String>{'name': 'Abdominal máquina', 'group': 'Abdômen'},
  ];

  Future<void> _addToPlan(BuildContext context, Map<String, String> template) async {
    final plans = store.records(EntityTypes.workoutPlan);
    if (plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crie uma ficha antes de usar a biblioteca.')),
      );
      return;
    }
    var planId = plans.first.id;
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Adicionar ${template['name']}'),
          content: SizedBox(
            width: 430,
            child: DropdownButtonFormField<String>(
              initialValue: planId,
              decoration: const InputDecoration(labelText: 'Ficha de destino'),
              items: plans
                  .map(
                    (plan) => DropdownMenuItem<String>(
                      value: plan.id,
                      child: Text(plan.payload['name'] as String? ?? 'Ficha'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => planId = value ?? planId),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, planId),
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    final exercise = await store.save(EntityTypes.exercise, <String, dynamic>{
      'planId': selected,
      'name': template['name'],
      'group': template['group'],
      'notes': '',
      'restSeconds': 90,
    });
    const defaults = <({String type, int reps, double load})>[
      (type: 'Aquecimento', reps: 15, load: 0),
      (type: 'Normal', reps: 10, load: 0),
      (type: 'Normal', reps: 10, load: 0),
      (type: 'Falha', reps: 8, load: 0),
    ];
    for (var index = 0; index < defaults.length; index++) {
      final item = defaults[index];
      await store.save(EntityTypes.exerciseSet, <String, dynamic>{
        'exerciseId': exercise.id,
        'position': index + 1,
        'type': item.type,
        'reps': item.reps,
        'load': item.load,
      });
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${template['name']} adicionado à ficha.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Map<String, String>>>{};
    for (final item in templates) {
      grouped.putIfAbsent(item['group'] ?? 'Geral', () => <Map<String, String>>[]).add(item);
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const PageIntro(
                  eyebrow: 'Biblioteca',
                  title: 'Exercícios prontos para suas fichas',
                  subtitle: 'Escolha um exercício, envie para uma ficha e depois ajuste séries, carga e descanso do seu jeito.',
                  color: AppColors.orange,
                ),
                const SizedBox(height: 18),
                ...grouped.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: PremiumCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(entry.key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          ...entry.value.map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.fitness_center, color: AppColors.orange),
                              title: Text(item['name'] ?? ''),
                              trailing: IconButton(
                                tooltip: 'Adicionar à ficha',
                                onPressed: () => _addToPlan(context, item),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ),
                          ),
                        ],
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

class TrainingProgressTab extends StatelessWidget {
  const TrainingProgressTab({required this.store, super.key});

  final AppStore store;

  List<Map<String, dynamic>> _snapshots() {
    final result = <Map<String, dynamic>>[];
    for (final session in store.records(EntityTypes.workoutSession)) {
      final raw = session.payload['setSnapshots'];
      if (raw is! List) continue;
      for (final item in raw) {
        if (item is Map) {
          result.add(<String, dynamic>{
            ...Map<String, dynamic>.from(item),
            'sessionDate': session.payload['date'],
          });
        }
      }
    }
    return result;
  }

  Future<void> _setWeeklyGoal(BuildContext context) async {
    final goals = store.records(EntityTypes.trainingGoal);
    final current = goals.isEmpty
        ? 4
        : (goals.first.payload['weeklySessions'] as num? ?? 4).toInt();
    final controller = TextEditingController(text: current.toString());
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Meta semanal de treinos'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Treinos por semana'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              (int.tryParse(controller.text) ?? current).clamp(1, 14).toInt(),
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    await store.save(
      EntityTypes.trainingGoal,
      <String, dynamic>{'weeklySessions': value},
      id: goals.isEmpty ? null : goals.first.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessions = store.records(EntityTypes.workoutSession);
    final snapshots = _snapshots();
    final now = DateTime.now();
    final last30 = sessions.where((item) {
      final date = DateTime.tryParse(item.payload['date'] as String? ?? '');
      return date != null && now.difference(date).inDays <= 30;
    }).toList();
    final totalVolume = last30.fold<double>(0, (sum, item) {
      final saved = item.payload['volume'];
      if (saved is num) return sum + saved.toDouble();
      final raw = item.payload['setSnapshots'];
      return sum + (raw is List ? TrainingUtils.snapshotVolume(raw) : 0);
    });
    final exerciseNames = snapshots
        .map((item) => item['exerciseName'] as String? ?? '')
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final exerciseHistories = <String, List<Map<String, dynamic>>>{};
    for (final item in snapshots) {
      final name = item['exerciseName'] as String? ?? '';
      if (name.isEmpty) continue;
      exerciseHistories.putIfAbsent(name, () => <Map<String, dynamic>>[]).add(item);
    }
    for (final history in exerciseHistories.values) {
      history.sort((a, b) => (a['sessionDate'] as String? ?? '')
          .compareTo(b['sessionDate'] as String? ?? ''));
    }
    final prs = exerciseNames.map((name) {
      final best = TrainingUtils.maxLoadForExercise(snapshots, name);
      return (name: name, load: best);
    }).where((item) => item.load > 0).toList()
      ..sort((a, b) => b.load.compareTo(a.load));
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final weekSessions = sessions.where((item) {
      final date = DateTime.tryParse(item.payload['date'] as String? ?? '');
      return date != null && !date.isBefore(weekStart);
    }).length;
    final goalRecords = store.records(EntityTypes.trainingGoal);
    final weeklyGoal = goalRecords.isEmpty
        ? 4
        : (goalRecords.first.payload['weeklySessions'] as num? ?? 4).toInt();
    final consistency = weeklyGoal <= 0
        ? 0
        : (weekSessions * 100 / weeklyGoal).clamp(0, 100).round();
    final groupVolume = <String, double>{};
    for (final item in snapshots) {
      final group = item['group'] as String? ?? 'Geral';
      final load = item['load'] as num? ?? 0;
      final reps = item['reps'] as num? ?? 0;
      groupVolume[group] = (groupVolume[group] ?? 0) +
          TrainingUtils.setVolume(load: load, reps: reps);
    }
    final groupEntries = groupVolume.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final orderedSessions = sessions.toList()
      ..sort((a, b) => (b.payload['date'] as String? ?? '')
          .compareTo(a.payload['date'] as String? ?? ''));
    double sessionVolume(SyncEntity item) {
      final saved = item.payload['volume'];
      if (saved is num) return saved.toDouble();
      final raw = item.payload['setSnapshots'];
      return raw is List ? TrainingUtils.snapshotVolume(raw) : 0.0;
    }
    final latestVolume = orderedSessions.isEmpty ? 0.0 : sessionVolume(orderedSessions.first);
    final previousVolume = orderedSessions.length < 2 ? 0.0 : sessionVolume(orderedSessions[1]);
    final volumeDelta = previousVolume <= 0
        ? null
        : ((latestVolume - previousVolume) / previousVolume) * 100;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const PageIntro(
                  eyebrow: 'Evolução real',
                  title: 'Progresso e recordes',
                  subtitle:
                      'Acompanhe frequência, volume de treino e maiores cargas registradas.',
                  color: AppColors.orange,
                ),
                const SizedBox(height: 20),
                ResponsiveGrid(
                  minItemWidth: 220,
                  children: <Widget>[
                    MetricCard(
                      label: 'Treinos em 30 dias',
                      value: '${last30.length}',
                      icon: Icons.calendar_month,
                      color: AppColors.orange,
                    ),
                    MetricCard(
                      label: 'Volume em 30 dias',
                      value: '${totalVolume.toStringAsFixed(0)} kg',
                      icon: Icons.monitor_weight_outlined,
                      color: AppColors.green,
                    ),
                    MetricCard(
                      label: 'Exercícios com PR',
                      value: '${prs.length}',
                      icon: Icons.emoji_events_outlined,
                      color: AppColors.purple,
                    ),
                    MetricCard(
                      label: 'Meta desta semana',
                      value: '$weekSessions/$weeklyGoal',
                      caption: '$consistency% da meta',
                      icon: Icons.local_fire_department_outlined,
                      color: AppColors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _setWeeklyGoal(context),
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Alterar meta semanal'),
                  ),
                ),
                const SizedBox(height: 8),
                if (orderedSessions.length >= 2) ...<Widget>[
                  PremiumCard(
                    child: Row(
                      children: <Widget>[
                        Icon(
                          volumeDelta != null && volumeDelta >= 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: volumeDelta != null && volumeDelta >= 0
                              ? AppColors.green
                              : AppColors.red,
                          size: 34,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Comparação com o treino anterior',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${latestVolume.toStringAsFixed(0)} kg vs ${previousVolume.toStringAsFixed(0)} kg'
                                '${volumeDelta == null ? '' : ' • ${volumeDelta >= 0 ? '+' : ''}${volumeDelta.toStringAsFixed(1)}%'}',
                                style: const TextStyle(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (sessions.isEmpty)
                  const EmptyState(
                    icon: Icons.insights_outlined,
                    title: 'Ainda não há evolução para analisar',
                    message: 'Finalize treinos para formar seu histórico de progressão.',
                  )
                else ...<Widget>[
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Volume dos últimos treinos',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 180,
                          child: _TrainingVolumeChart(
                            sessions: sessions.take(10).toList().reversed.toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Recordes de carga',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        if (prs.isEmpty)
                          const Text(
                            'Os próximos treinos passarão a salvar uma fotografia das séries para calcular seus recordes.',
                            style: TextStyle(color: AppColors.textMuted),
                          )
                        else
                          ...prs.take(12).map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.emoji_events_outlined,
                                color: AppColors.orange,
                              ),
                              title: Text(item.name),
                              trailing: Text(
                                '${item.load.toStringAsFixed(item.load % 1 == 0 ? 0 : 1)} kg',
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Evolução de carga por exercício',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        ...exerciseNames.take(10).map((name) {
                          final history = exerciseHistories[name] ?? <Map<String, dynamic>>[];
                          final loads = history
                              .map((item) => (item['load'] as num? ?? 0).toDouble())
                              .where((value) => value > 0)
                              .toList();
                          final latest = loads.isEmpty ? 0.0 : loads.last;
                          final previous = loads.length < 2 ? null : loads[loads.length - 2];
                          final best = loads.isEmpty ? 0.0 : loads.reduce((a, b) => a > b ? a : b);
                          final latestRaw = history.isEmpty ? null : history.last;
                          final date = DateTime.tryParse(latestRaw?['sessionDate'] as String? ?? '');
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Atual ${latest.toStringAsFixed(latest % 1 == 0 ? 0 : 1)} kg'
                                        '${previous == null ? '' : ' • anterior ${previous.toStringAsFixed(previous % 1 == 0 ? 0 : 1)} kg'}'
                                        ' • PR ${best.toStringAsFixed(best % 1 == 0 ? 0 : 1)} kg'
                                        '${date == null ? '' : ' • ${DateFormat('dd/MM').format(date)}'}',
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 150,
                                  height: 46,
                                  child: CustomPaint(
                                    painter: _MiniLoadChartPainter(loads.length <= 12 ? loads : loads.sublist(loads.length - 12)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Volume por grupo muscular',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        if (groupEntries.isEmpty)
                          const Text(
                            'Defina o grupo muscular nos exercícios para separar o volume por região.',
                            style: TextStyle(color: AppColors.textMuted),
                          )
                        else
                          ...groupEntries.take(10).map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.donut_large, color: AppColors.orange),
                              title: Text(item.key),
                              trailing: Text(
                                '${item.value.toStringAsFixed(0)} kg',
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BodyTrackingTab extends StatelessWidget {
  const BodyTrackingTab({required this.store, super.key});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final metrics = store.records(EntityTypes.bodyMetric)
      ..sort((a, b) => (b.payload['date'] as String? ?? '')
          .compareTo(a.payload['date'] as String? ?? ''));
    final latest = metrics.isEmpty ? null : metrics.first;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const PageIntro(
                  eyebrow: 'Acompanhamento corporal',
                  title: 'Peso, medidas e fotos',
                  subtitle:
                      'Registre sua evolução corporal sem enviar nenhuma imagem para a nuvem.',
                  color: AppColors.orange,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _BodyMetricDialog(store: store),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo registro corporal'),
                ),
                const SizedBox(height: 18),
                if (latest != null)
                  ResponsiveGrid(
                    minItemWidth: 210,
                    children: <Widget>[
                      MetricCard(
                        label: 'Peso atual',
                        value: '${(latest.payload['weight'] as num? ?? 0).toStringAsFixed(1)} kg',
                        icon: Icons.monitor_weight_outlined,
                        color: AppColors.orange,
                      ),
                      MetricCard(
                        label: 'Cintura',
                        value: '${(latest.payload['waist'] as num? ?? 0).toStringAsFixed(1)} cm',
                        icon: Icons.straighten,
                        color: AppColors.green,
                      ),
                      MetricCard(
                        label: 'Braço',
                        value: '${(latest.payload['arm'] as num? ?? 0).toStringAsFixed(1)} cm',
                        icon: Icons.fitness_center,
                        color: AppColors.purple,
                      ),
                    ],
                  ),
                const SizedBox(height: 18),
                if (metrics.isEmpty)
                  const EmptyState(
                    icon: Icons.monitor_weight_outlined,
                    title: 'Nenhum registro corporal',
                    message: 'Adicione seu primeiro peso e suas medidas para acompanhar a evolução.',
                  )
                else
                  ...metrics.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PremiumCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _BodyPhoto(payload: item.payload),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    _formatDate(item.payload['date'] as String?),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Peso ${(item.payload['weight'] as num? ?? 0).toStringAsFixed(1)} kg • '
                                    'Peito ${(item.payload['chest'] as num? ?? 0).toStringAsFixed(1)} cm • '
                                    'Cintura ${(item.payload['waist'] as num? ?? 0).toStringAsFixed(1)} cm • '
                                    'Braço ${(item.payload['arm'] as num? ?? 0).toStringAsFixed(1)} cm • '
                                    'Coxa ${(item.payload['thigh'] as num? ?? 0).toStringAsFixed(1)} cm',
                                    style: const TextStyle(color: AppColors.textMuted),
                                  ),
                                  if ((item.payload['notes'] as String? ?? '').isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 6),
                                    Text(item.payload['notes'] as String),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => showDialog<void>(
                                context: context,
                                builder: (_) => _BodyMetricDialog(
                                  store: store,
                                  entity: item,
                                ),
                              ),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            ConfirmDeleteButton(onDelete: () => store.remove(item.id)),
                          ],
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

class WellnessTab extends StatelessWidget {
  const WellnessTab({required this.store, super.key});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final water = store.records(EntityTypes.waterLog)
        .where((item) => item.payload['date'] == today)
        .fold<int>(0, (sum, item) => sum + (item.payload['ml'] as num? ?? 0).toInt());
    final cardio = store.records(EntityTypes.cardioSession)
      ..sort((a, b) => (b.payload['date'] as String? ?? '')
          .compareTo(a.payload['date'] as String? ?? ''));
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const PageIntro(
                  eyebrow: 'Hábitos',
                  title: 'Cardio e hidratação',
                  subtitle: 'Registre cardio e acompanhe sua água do dia de forma rápida.',
                  color: AppColors.orange,
                ),
                const SizedBox(height: 20),
                ResponsiveGrid(
                  minItemWidth: 230,
                  children: <Widget>[
                    MetricCard(
                      label: 'Água hoje',
                      value: '$water ml',
                      caption: 'Meta sugerida: 2.000 ml',
                      icon: Icons.water_drop_outlined,
                      color: AppColors.blue,
                    ),
                    MetricCard(
                      label: 'Cardios registrados',
                      value: '${cardio.length}',
                      icon: Icons.directions_run,
                      color: AppColors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    FilledButton.tonalIcon(
                      onPressed: () => _addWater(context, 250),
                      icon: const Icon(Icons.local_drink_outlined),
                      label: const Text('+250 ml'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _addWater(context, 500),
                      icon: const Icon(Icons.water_drop_outlined),
                      label: const Text('+500 ml'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => _CardioDialog(store: store),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Registrar cardio'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (cardio.isEmpty)
                  const EmptyState(
                    icon: Icons.directions_run,
                    title: 'Nenhum cardio registrado',
                    message: 'Corrida, caminhada, bicicleta e outros cardios podem ser salvos aqui.',
                  )
                else
                  ...cardio.take(20).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PremiumCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.directions_run, color: AppColors.orange),
                          title: Text(item.payload['type'] as String? ?? 'Cardio'),
                          subtitle: Text(
                            '${_formatDate(item.payload['date'] as String?)} • '
                            '${item.payload['minutes'] ?? 0} min • '
                            '${(item.payload['distanceKm'] as num? ?? 0).toStringAsFixed(1)} km',
                          ),
                          trailing: ConfirmDeleteButton(onDelete: () => store.remove(item.id)),
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

  Future<void> _addWater(BuildContext context, int ml) async {
    await store.save(EntityTypes.waterLog, <String, dynamic>{
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'ml': ml,
      'time': DateTime.now().toIso8601String(),
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('+$ml ml registrados.')),
      );
    }
  }
}

class _MiniLoadChartPainter extends CustomPainter {
  const _MiniLoadChartPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;
    final paint = Paint()
      ..color = AppColors.orange
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = size.width * index / (values.length - 1);
      final normalized = range == 0 ? .5 : (values[index] - minValue) / range;
      final y = size.height - (normalized * size.height);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniLoadChartPainter oldDelegate) =>
      oldDelegate.values != values;
}

class _TrainingVolumeChart extends StatelessWidget {
  const _TrainingVolumeChart({required this.sessions});

  final List<SyncEntity> sessions;

  @override
  Widget build(BuildContext context) {
    final values = sessions.map((item) {
      final saved = item.payload['volume'];
      if (saved is num) return saved.toDouble();
      final raw = item.payload['setSnapshots'];
      return raw is List ? TrainingUtils.snapshotVolume(raw) : 0.0;
    }).toList();
    return CustomPaint(
      painter: _BarChartPainter(values),
      child: const SizedBox.expand(),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height - 1), Offset(size.width, size.height - 1), axis);
    if (values.isEmpty) return;
    final maxValue = values.fold<double>(1, (best, value) => value > best ? value : best);
    final gap = 7.0;
    final width = ((size.width - gap * (values.length - 1)) / values.length).clamp(5.0, 80.0);
    final paint = Paint()..color = AppColors.orange;
    for (var i = 0; i < values.length; i++) {
      final height = (values[i] / maxValue) * (size.height - 12);
      final left = i * (width + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, size.height - height, width, height),
        const Radius.circular(5),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) => oldDelegate.values != values;
}

class _BodyPhoto extends StatelessWidget {
  const _BodyPhoto({required this.payload});

  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final raw = payload['photoBase64'] as String? ?? '';
    if (raw.isEmpty) {
      return Container(
        width: 72,
        height: 82,
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.person_outline, color: AppColors.textMuted),
      );
    }
    try {
      final bytes = base64Decode(raw);
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(bytes, width: 72, height: 82, fit: BoxFit.cover),
      );
    } catch (_) {
      return const SizedBox(width: 72, height: 82);
    }
  }
}

class _BodyMetricDialog extends StatefulWidget {
  const _BodyMetricDialog({required this.store, this.entity});

  final AppStore store;
  final SyncEntity? entity;

  @override
  State<_BodyMetricDialog> createState() => _BodyMetricDialogState();
}

class _BodyMetricDialogState extends State<_BodyMetricDialog> {
  late DateTime date;
  late final TextEditingController weight;
  late final TextEditingController chest;
  late final TextEditingController waist;
  late final TextEditingController arm;
  late final TextEditingController thigh;
  late final TextEditingController bodyFat;
  late final TextEditingController notes;
  String photoName = '';
  String photoBase64 = '';

  @override
  void initState() {
    super.initState();
    date = DateTime.tryParse(widget.entity?.payload['date'] as String? ?? '') ?? DateTime.now();
    weight = _controller('weight');
    chest = _controller('chest');
    waist = _controller('waist');
    arm = _controller('arm');
    thigh = _controller('thigh');
    bodyFat = _controller('bodyFat');
    notes = TextEditingController(text: widget.entity?.payload['notes'] as String? ?? '');
    photoName = widget.entity?.payload['photoName'] as String? ?? '';
    photoBase64 = widget.entity?.payload['photoBase64'] as String? ?? '';
  }

  TextEditingController _controller(String key) => TextEditingController(
        text: widget.entity?.payload[key]?.toString() ?? '',
      );

  @override
  void dispose() {
    for (final item in <TextEditingController>[weight, chest, waist, arm, thigh, bodyFat, notes]) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || !mounted) return;
    setState(() {
      photoName = file.name;
      photoBase64 = base64Encode(Uint8List.fromList(bytes));
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.entity == null ? 'Novo registro corporal' : 'Editar registro'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(date)),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final value = await pickAppDate(context, date);
                  if (value != null && mounted) setState(() => date = value);
                },
              ),
              _number(weight, 'Peso (kg)'),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(child: _number(chest, 'Peito (cm)')),
                  const SizedBox(width: 10),
                  Expanded(child: _number(waist, 'Cintura (cm)')),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(child: _number(arm, 'Braço (cm)')),
                  const SizedBox(width: 10),
                  Expanded(child: _number(thigh, 'Coxa (cm)')),
                ],
              ),
              const SizedBox(height: 10),
              _number(bodyFat, 'Gordura corporal (%)'),
              const SizedBox(height: 10),
              TextField(
                controller: notes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Observações'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(photoName.isEmpty ? 'Adicionar foto' : photoName),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () async {
            await widget.store.save(EntityTypes.bodyMetric, <String, dynamic>{
              'date': DateFormat('yyyy-MM-dd').format(date),
              'weight': _numberValue(weight),
              'chest': _numberValue(chest),
              'waist': _numberValue(waist),
              'arm': _numberValue(arm),
              'thigh': _numberValue(thigh),
              'bodyFat': _numberValue(bodyFat),
              'notes': notes.text.trim(),
              'photoName': photoName,
              'photoBase64': photoBase64,
            }, id: widget.entity?.id);
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  Widget _number(TextEditingController controller, String label) => TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      );

  double _numberValue(TextEditingController controller) =>
      double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
}

class _CardioDialog extends StatefulWidget {
  const _CardioDialog({required this.store});

  final AppStore store;

  @override
  State<_CardioDialog> createState() => _CardioDialogState();
}

class _CardioDialogState extends State<_CardioDialog> {
  DateTime date = DateTime.now();
  String type = 'Caminhada';
  final minutes = TextEditingController(text: '30');
  final distance = TextEditingController();

  @override
  void dispose() {
    minutes.dispose();
    distance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar cardio'),
      content: SizedBox(
        width: 430,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: const <String>['Caminhada', 'Corrida', 'Bicicleta', 'Elíptico', 'Escada', 'Outro']
                  .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: (value) => setState(() => type = value ?? type),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: minutes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Minutos'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: distance,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Distância (km, opcional)'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(date)),
              onTap: () async {
                final value = await pickAppDate(context, date);
                if (value != null && mounted) setState(() => date = value);
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () async {
            await widget.store.save(EntityTypes.cardioSession, <String, dynamic>{
              'type': type,
              'date': DateFormat('yyyy-MM-dd').format(date),
              'minutes': int.tryParse(minutes.text) ?? 0,
              'distanceKm': double.tryParse(distance.text.replaceAll(',', '.')) ?? 0,
            });
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

String _formatDate(String? value) {
  final date = DateTime.tryParse(value ?? '');
  return date == null ? 'Sem data' : DateFormat('dd/MM/yyyy').format(date);
}
