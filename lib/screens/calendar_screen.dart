import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/finance_analytics.dart';
import '../widgets/premium_widgets.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({required this.store, super.key});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final events = _events(store);
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda geral')),
      body: PremiumBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const PageIntro(
                      eyebrow: 'Agenda integrada',
                      title: 'Tudo que vem pela frente',
                      subtitle: 'Aulas, treinos, provas, lembretes e vencimentos reunidos por data.',
                    ),
                    const SizedBox(height: 18),
                    if (events.isEmpty)
                      const EmptyState(
                        icon: Icons.calendar_month_outlined,
                        title: 'Agenda tranquila',
                        message: 'Nenhum compromisso com data foi encontrado nos próximos 60 dias.',
                      )
                    else
                      ...events.map(
                        (event) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PremiumCard(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: event.color.withValues(alpha: .14),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(event.icon, color: event.color),
                              ),
                              title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                              subtitle: Text('${DateFormat('dd/MM/yyyy HH:mm').format(event.date)} • ${event.subtitle}'),
                            ),
                          ),
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
}

List<_RoutineEvent> _events(AppStore store) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 60));
  final result = <_RoutineEvent>[];

  final classes = store.records(EntityTypes.classSession);
  final plans = store.records(EntityTypes.workoutPlan);
  for (var offset = 0; offset < 14; offset++) {
    final day = start.add(Duration(days: offset));
    for (final item in classes.where((entry) => entry.payload['weekday'] == day.weekday)) {
      final time = _timeParts(item.payload['start'] as String?);
      result.add(_RoutineEvent(
        date: DateTime(day.year, day.month, day.day, time.$1, time.$2),
        title: _subjectName(store, item.payload['subjectId'] as String?),
        subtitle: 'Aula • ${item.payload['start'] ?? ''}–${item.payload['end'] ?? ''}',
        icon: Icons.school_outlined,
        color: AppColors.purple,
      ));
    }
    for (final plan in plans) {
      if (!_matchesWorkoutDay(plan.payload['day'] as String? ?? '', day.weekday)) continue;
      result.add(_RoutineEvent(
        date: DateTime(day.year, day.month, day.day, 7),
        title: plan.payload['name'] as String? ?? 'Treino',
        subtitle: 'Treino planejado • ${plan.payload['focus'] ?? ''}',
        icon: Icons.fitness_center,
        color: AppColors.orange,
      ));
    }
  }

  for (final reminder in store.records(EntityTypes.reminder)) {
    if (reminder.payload['enabled'] == false) continue;
    final date = DateTime.tryParse(reminder.payload['dateTime'] as String? ?? '');
    if (date != null && !date.isBefore(start) && date.isBefore(end)) {
      result.add(_RoutineEvent(
        date: date,
        title: reminder.payload['title'] as String? ?? 'Lembrete',
        subtitle: reminder.payload['category'] as String? ?? 'Geral',
        icon: Icons.notifications_active_outlined,
        color: AppColors.green,
      ));
    }
  }

  for (final exam in store.records(EntityTypes.exam)) {
    final date = DateTime.tryParse(exam.payload['date'] as String? ?? '');
    if (date != null && !date.isBefore(start) && date.isBefore(end)) {
      result.add(_RoutineEvent(
        date: DateTime(date.year, date.month, date.day, 18),
        title: exam.payload['title'] as String? ?? 'Avaliação',
        subtitle: _subjectName(store, exam.payload['subjectId'] as String?),
        icon: Icons.assignment_outlined,
        color: AppColors.purple,
      ));
    }
  }

  for (var monthOffset = 0; monthOffset <= 2; monthOffset++) {
    final month = DateTime(start.year, start.month + monthOffset);
    final maxDay = DateTime(month.year, month.month + 1, 0).day;
    for (final card in store.records(EntityTypes.card)) {
      final dueDay = (card.payload['dueDay'] as num? ?? 1).toInt().clamp(1, maxDay).toInt();
      final date = DateTime(month.year, month.month, dueDay, 9);
      final invoice = FinanceAnalytics.invoiceForMonth(store, card.id, month);
      final paid = FinanceAnalytics.paymentsForMonth(store, card.id, month);
      final remaining = (invoice - paid).clamp(0.0, invoice).toDouble();
      if (remaining > 0 && !date.isBefore(start) && date.isBefore(end)) {
        result.add(_RoutineEvent(
          date: date,
          title: 'Fatura ${card.payload['bank'] ?? card.payload['name'] ?? ''}',
          subtitle: NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(remaining),
          icon: Icons.credit_card,
          color: AppColors.orange,
        ));
      }
    }
    for (final loan in store.records(EntityTypes.loan)) {
      if (loan.payload['status'] == 'Quitado') continue;
      final day = (loan.payload['dueDay'] as num? ?? 1).toInt().clamp(1, maxDay).toInt();
      final date = DateTime(month.year, month.month, day, 9);
      if (!date.isBefore(start) && date.isBefore(end)) {
        result.add(_RoutineEvent(
          date: date,
          title: 'Parcela de empréstimo',
          subtitle: loan.payload['creditor'] as String? ?? 'Empréstimo',
          icon: Icons.account_balance_outlined,
          color: AppColors.red,
        ));
      }
    }
  }

  result.sort((a, b) => a.date.compareTo(b.date));
  return result;
}

(int, int) _timeParts(String? value) {
  final parts = (value ?? '').split(':');
  final hour = parts.isEmpty ? 8 : int.tryParse(parts.first) ?? 8;
  final minute = parts.length < 2 ? 0 : int.tryParse(parts[1]) ?? 0;
  return (hour.clamp(0, 23).toInt(), minute.clamp(0, 59).toInt());
}

bool _matchesWorkoutDay(String value, int weekday) {
  final day = value.toLowerCase();
  const names = <int, List<String>>{
    1: <String>['segunda', 'seg'],
    2: <String>['terça', 'terca', 'ter'],
    3: <String>['quarta', 'qua'],
    4: <String>['quinta', 'qui'],
    5: <String>['sexta', 'sex'],
    6: <String>['sábado', 'sabado', 'sáb', 'sab'],
    7: <String>['domingo', 'dom'],
  };
  return (names[weekday] ?? <String>[]).any(day.contains);
}

String _subjectName(AppStore store, String? id) {
  if (id == null) return 'Sem matéria';
  return store.byId(id)?.payload['name'] as String? ?? 'Matéria removida';
}

class _RoutineEvent {
  const _RoutineEvent({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final DateTime date;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}
