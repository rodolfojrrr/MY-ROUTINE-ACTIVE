import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/finance_analytics.dart';
import '../core/study_utils.dart';
import '../core/sync_entity.dart';
import '../core/wifi_sync_service.dart';
import '../widgets/premium_widgets.dart';
import 'calendar_screen.dart';
import 'finance_screen.dart';
import 'reminders_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'studies_screen.dart';
import 'training_screen.dart';
import 'wifi_sync_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.store, required this.wifi, super.key});

  final AppStore store;
  final WifiSyncService wifi;

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final now = DateTime.now();
        final subjects = store.records(EntityTypes.subject).length;
        final plans = store.records(EntityTypes.workoutPlan).length;
        final cards = store.records(EntityTypes.card).length;
        final dueFlashcards = store
            .records(EntityTypes.flashcard)
            .where((item) => StudyUtils.isDue(item.payload, now: now))
            .length;
        final todayClasses = store
            .records(EntityTypes.classSession)
            .where((item) => item.payload['weekday'] == now.weekday)
            .toList()
          ..sort((a, b) => (a.payload['start'] as String? ?? '')
              .compareTo(b.payload['start'] as String? ?? ''));
        final nextExam = _nextExam(now);
        final nextReminder = _nextReminder(now);
        final workout = _suggestedWorkout(now);
        final month = DateTime(now.year, now.month);
        final finance = _monthFinance(month);
        final todayKey = DateFormat('yyyy-MM-dd').format(now);
        final water = store.records(EntityTypes.waterLog)
            .where((item) => item.payload['date'] == todayKey)
            .fold<int>(0, (sum, item) => sum + (item.payload['ml'] as num? ?? 0).toInt());
        final studyMinutes = store.records(EntityTypes.studySession).fold<int>(0, (sum, item) {
          final date = item.payload['date'] as String? ?? '';
          return sum + (date.startsWith(todayKey) ? (item.payload['minutes'] as num? ?? 0).toInt() : 0);
        });

        return Scaffold(
          body: PremiumBackground(
            child: SafeArea(
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 18, 22, 34),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _Header(
                                onSearch: () => _open(context, SearchScreen(store: store)),
                                onCalendar: () => _open(context, CalendarScreen(store: store)),
                                onReminders: () => _open(context, RemindersScreen(store: store)),
                                onSync: () => _open(context, WifiSyncScreen(store: store, wifi: wifi)),
                                onSettings: () => _open(context, SettingsScreen(store: store, wifi: wifi)),
                              ),
                              const SizedBox(height: 32),
                              PageIntro(
                                eyebrow: DateFormat('EEEE, dd MMMM', 'pt_BR').format(now),
                                title: _greeting(now),
                                subtitle:
                                    'Aqui está o que importa hoje em estudos, treino e finanças. Tudo continua salvo somente nos seus aparelhos.',
                              ),
                              const SizedBox(height: 20),
                              ResponsiveGrid(
                                minItemWidth: 220,
                                children: <Widget>[
                                  MetricCard(
                                    label: 'Estudo hoje',
                                    value: '$studyMinutes min',
                                    caption: '$dueFlashcards flashcards para revisar',
                                    icon: Icons.school_outlined,
                                    color: AppColors.purple,
                                  ),
                                  MetricCard(
                                    label: 'Água hoje',
                                    value: '$water ml',
                                    caption: 'Meta de referência: 2.000 ml',
                                    icon: Icons.water_drop_outlined,
                                    color: AppColors.blue,
                                  ),
                                  MetricCard(
                                    label: 'Saldo previsto do mês',
                                    value: NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(finance),
                                    icon: Icons.account_balance_wallet_outlined,
                                    color: finance >= 0 ? AppColors.green : AppColors.red,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final horizontal = constraints.maxWidth >= 840;
                                  final items = <Widget>[
                                    _TodayCard(
                                      icon: Icons.schedule,
                                      color: AppColors.purple,
                                      title: 'Hoje na faculdade',
                                      primary: todayClasses.isEmpty
                                          ? 'Sem aula cadastrada hoje'
                                          : '${todayClasses.first.payload['start']} • ${_subjectName(todayClasses.first.payload['subjectId'] as String?)}',
                                      secondary: nextExam == null
                                          ? 'Nenhuma avaliação próxima'
                                          : 'Próxima: ${nextExam.payload['title']} em ${_formatDate(nextExam.payload['date'] as String?)}',
                                      action: 'Estudos',
                                      onTap: () => _open(context, StudiesScreen(store: store)),
                                    ),
                                    _TodayCard(
                                      icon: Icons.fitness_center,
                                      color: AppColors.orange,
                                      title: 'Treino sugerido',
                                      primary: workout == null
                                          ? 'Nenhuma ficha cadastrada'
                                          : workout.payload['name'] as String? ?? 'Treino',
                                      secondary: workout == null
                                          ? 'Crie sua primeira ficha de treino'
                                          : '${workout.payload['focus'] ?? ''}${(workout.payload['day'] as String? ?? '').isEmpty ? '' : ' • ${workout.payload['day']}'}',
                                      action: 'Treinar',
                                      onTap: () => _open(context, TrainingScreen(store: store)),
                                    ),
                                    _TodayCard(
                                      icon: Icons.notifications_active_outlined,
                                      color: AppColors.green,
                                      title: 'Próximo lembrete',
                                      primary: nextReminder == null
                                          ? 'Nenhum lembrete futuro'
                                          : nextReminder.payload['title'] as String? ?? 'Lembrete',
                                      secondary: nextReminder == null
                                          ? 'Crie alertas para não depender da memória'
                                          : _formatDateTime(nextReminder.payload['dateTime'] as String?),
                                      action: 'Lembretes',
                                      onTap: () => _open(context, RemindersScreen(store: store)),
                                    ),
                                  ];
                                  if (horizontal) {
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: items
                                          .map((item) => Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.only(right: 12),
                                                  child: item,
                                                ),
                                              ))
                                          .toList(),
                                    );
                                  }
                                  return Column(
                                    children: items
                                        .map((item) => Padding(
                                              padding: const EdgeInsets.only(bottom: 12),
                                              child: item,
                                            ))
                                        .toList(),
                                  );
                                },
                              ),
                              const SizedBox(height: 26),
                              const Text(
                                'Seus módulos',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 14),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final horizontal = constraints.maxWidth >= 820;
                                  final modules = <Widget>[
                                    _ModuleCard(
                                      title: 'Estudos',
                                      subtitle: 'Hoje, aulas, provas, notas, revisões, questões e Pomodoro',
                                      metric: '$subjects matérias',
                                      icon: Icons.school_outlined,
                                      colors: const <Color>[Color(0xFFA054FF), Color(0xFF5326CC)],
                                      onTap: () => _open(context, StudiesScreen(store: store)),
                                    ),
                                    _ModuleCard(
                                      title: 'Treinos',
                                      subtitle: 'Fichas, sessões, evolução de carga, corpo, cardio e hidratação',
                                      metric: '$plans fichas',
                                      icon: Icons.fitness_center,
                                      colors: const <Color>[Color(0xFFFF9A42), Color(0xFFC74731)],
                                      onTap: () => _open(context, TrainingScreen(store: store)),
                                    ),
                                    _ModuleCard(
                                      title: 'Finanças',
                                      subtitle: 'Contas, cartões, faturas, orçamento, metas e relatórios',
                                      metric: '$cards cartões',
                                      icon: Icons.account_balance_wallet_outlined,
                                      colors: const <Color>[Color(0xFF16D991), Color(0xFF087A66)],
                                      onTap: () => _open(context, FinanceScreen(store: store)),
                                    ),
                                  ];
                                  if (horizontal) {
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: modules
                                          .map((card) => Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.only(right: 14),
                                                  child: card,
                                                ),
                                              ))
                                          .toList(),
                                    );
                                  }
                                  return Column(
                                    children: modules
                                        .map((card) => Padding(
                                              padding: const EdgeInsets.only(bottom: 16),
                                              child: card,
                                            ))
                                        .toList(),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              PremiumCard(
                                child: Row(
                                  children: <Widget>[
                                    const Icon(Icons.cloud_off_outlined, color: AppColors.green, size: 34),
                                    const SizedBox(width: 16),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text('Privacidade de verdade', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                                          SizedBox(height: 4),
                                          Text(
                                            'Sem conta externa e sem nuvem. A sincronização só abre quando você escolhe usar a rede Wi‑Fi local.',
                                            style: TextStyle(color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Sincronizar',
                                      onPressed: () => _open(context, WifiSyncScreen(store: store, wifi: wifi)),
                                      icon: const Icon(Icons.arrow_forward),
                                    ),
                                  ],
                                ),
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
        );
      },
    );
  }

  SyncEntity? _nextExam(DateTime now) {
    final start = DateTime(now.year, now.month, now.day);
    final items = store.records(EntityTypes.exam).where((item) {
      final date = DateTime.tryParse(item.payload['date'] as String? ?? '');
      return date != null && !date.isBefore(start);
    }).toList()
      ..sort((a, b) => (a.payload['date'] as String? ?? '').compareTo(b.payload['date'] as String? ?? ''));
    return items.isEmpty ? null : items.first;
  }

  SyncEntity? _nextReminder(DateTime now) {
    final items = store.records(EntityTypes.reminder).where((item) {
      final date = DateTime.tryParse(item.payload['dateTime'] as String? ?? '');
      return item.payload['enabled'] != false && date != null && date.isAfter(now);
    }).toList()
      ..sort((a, b) => (a.payload['dateTime'] as String? ?? '').compareTo(b.payload['dateTime'] as String? ?? ''));
    return items.isEmpty ? null : items.first;
  }

  SyncEntity? _suggestedWorkout(DateTime now) {
    final plans = store.records(EntityTypes.workoutPlan);
    if (plans.isEmpty) return null;
    const names = <int, List<String>>{
      1: <String>['segunda', 'seg'],
      2: <String>['terça', 'terca', 'ter'],
      3: <String>['quarta', 'qua'],
      4: <String>['quinta', 'qui'],
      5: <String>['sexta', 'sex'],
      6: <String>['sábado', 'sabado', 'sáb', 'sab'],
      7: <String>['domingo', 'dom'],
    };
    for (final plan in plans) {
      final day = (plan.payload['day'] as String? ?? '').toLowerCase();
      if ((names[now.weekday] ?? <String>[]).any(day.contains)) return plan;
    }
    return plans.first;
  }

  double _monthFinance(DateTime month) {
    var income = 0.0;
    var expense = 0.0;
    for (final item in store.records(EntityTypes.income)) {
      final recurring = item.payload['recurring'] == true;
      if (recurring || FinanceAnalytics.inMonth(item.payload['date'] as String?, month)) {
        income += (item.payload['amount'] as num? ?? 0).toDouble();
      }
    }
    for (final item in store.records(EntityTypes.expense)) {
      final recurring = item.payload['recurring'] == true;
      if (recurring || FinanceAnalytics.inMonth(item.payload['date'] as String?, month)) {
        expense += (item.payload['amount'] as num? ?? 0).toDouble();
      }
    }
    for (final card in store.records(EntityTypes.card)) {
      expense += FinanceAnalytics.invoiceForMonth(store, card.id, month);
    }
    return income - expense;
  }

  String _subjectName(String? id) {
    if (id == null) return 'Matéria';
    return store.byId(id)?.payload['name'] as String? ?? 'Matéria';
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onSearch,
    required this.onCalendar,
    required this.onReminders,
    required this.onSync,
    required this.onSettings,
  });

  final VoidCallback onSearch;
  final VoidCallback onCalendar;
  final VoidCallback onReminders;
  final VoidCallback onSync;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        return Row(
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[AppColors.green, Color(0xFF0C8CA8)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.green.withValues(alpha: .25),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'My Routine Active',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Seu dia, no seu controle',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            _HeaderButton(tooltip: 'Buscar', icon: Icons.search, onPressed: onSearch),
            if (!compact) ...<Widget>[
              const SizedBox(width: 6),
              _HeaderButton(
                tooltip: 'Agenda',
                icon: Icons.calendar_month_outlined,
                onPressed: onCalendar,
              ),
              const SizedBox(width: 6),
              _HeaderButton(
                tooltip: 'Lembretes',
                icon: Icons.notifications_none,
                onPressed: onReminders,
              ),
              const SizedBox(width: 6),
              _HeaderButton(
                tooltip: 'Sincronização Wi‑Fi',
                icon: Icons.sync,
                onPressed: onSync,
              ),
              const SizedBox(width: 6),
              _HeaderButton(
                tooltip: 'Configurações',
                icon: Icons.settings_outlined,
                onPressed: onSettings,
              ),
            ] else
              PopupMenuButton<String>(
                tooltip: 'Mais opções',
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'calendar':
                      onCalendar();
                      break;
                    case 'reminders':
                      onReminders();
                      break;
                    case 'sync':
                      onSync();
                      break;
                    case 'settings':
                      onSettings();
                      break;
                  }
                },
                itemBuilder: (context) => const <PopupMenuEntry<String>>[
                  PopupMenuItem(
                    value: 'calendar',
                    child: ListTile(
                      leading: Icon(Icons.calendar_month_outlined),
                      title: Text('Agenda'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'reminders',
                    child: ListTile(
                      leading: Icon(Icons.notifications_none),
                      title: Text('Lembretes'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'sync',
                    child: ListTile(
                      leading: Icon(Icons.sync),
                      title: Text('Sincronização Wi‑Fi'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings_outlined),
                      title: Text('Configurações'),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.tooltip, required this.icon, required this.onPressed});

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(tooltip: tooltip, onPressed: onPressed, icon: Icon(icon));
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.primary,
    required this.secondary,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String primary;
  final String secondary;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      borderColor: color.withValues(alpha: .35),
      child: SizedBox(
        height: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            Text(primary, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Expanded(
              child: Text(secondary, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted)),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onTap, child: Text(action)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.metric,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String metric;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(25),
      onTap: onTap,
      child: Ink(
        height: 285,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          borderRadius: BorderRadius.circular(25),
          boxShadow: <BoxShadow>[
            BoxShadow(color: colors.first.withValues(alpha: .22), blurRadius: 30, offset: const Offset(0, 12)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .15), borderRadius: BorderRadius.circular(15)),
              child: Icon(icon, color: Colors.white, size: 29),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: .82), height: 1.35)),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Text(metric, style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                const Icon(Icons.arrow_forward_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _greeting(DateTime now) {
  if (now.hour < 12) return 'Bom dia. Sua rotina está aqui.';
  if (now.hour < 18) return 'Boa tarde. Veja o que ainda falta hoje.';
  return 'Boa noite. Feche o dia com clareza.';
}

String _formatDate(String? value) {
  final date = DateTime.tryParse(value ?? '');
  return date == null ? 'sem data' : DateFormat('dd/MM').format(date);
}

String _formatDateTime(String? value) {
  final date = DateTime.tryParse(value ?? '');
  return date == null ? 'Sem data' : DateFormat('dd/MM HH:mm').format(date);
}
