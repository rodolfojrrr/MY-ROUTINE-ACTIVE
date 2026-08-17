import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/sync_entity.dart';
import '../widgets/premium_widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({required this.store, super.key});

  final AppStore store;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final controller = TextEditingController();
  String query = '';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = query.trim().length < 2 ? <SyncEntity>[] : _search(query);
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar no aplicativo')),
      body: PremiumBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextField(
                      controller: controller,
                      autofocus: true,
                      onChanged: (value) => setState(() => query = value),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Buscar matéria, treino, nota, gasto, cartão...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (query.trim().length < 2)
                      const EmptyState(
                        icon: Icons.search,
                        title: 'Busca geral',
                        message: 'Digite pelo menos dois caracteres. A busca acontece somente no banco local deste aparelho.',
                      )
                    else if (results.isEmpty)
                      const EmptyState(
                        icon: Icons.search_off,
                        title: 'Nada encontrado',
                        message: 'Tente outro termo.',
                      )
                    else
                      ...results.take(100).map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PremiumCard(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(_icon(item.type), color: _color(item.type)),
                              title: Text(_title(item)),
                              subtitle: Text(_label(item.type)),
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

  List<SyncEntity> _search(String value) {
    final normalized = value.toLowerCase().trim();
    const types = <String>[
      EntityTypes.subject,
      EntityTypes.classSession,
      EntityTypes.exam,
      EntityTypes.studyNote,
      EntityTypes.flashcard,
      EntityTypes.studyQuestion,
      EntityTypes.mockExam,
      EntityTypes.workoutPlan,
      EntityTypes.exercise,
      EntityTypes.workoutSession,
      EntityTypes.bodyMetric,
      EntityTypes.cardioSession,
      EntityTypes.income,
      EntityTypes.expense,
      EntityTypes.card,
      EntityTypes.debt,
      EntityTypes.loan,
      EntityTypes.financeAccount,
      EntityTypes.financeTransfer,
      EntityTypes.financeCategory,
      EntityTypes.budget,
      EntityTypes.financeGoal,
      EntityTypes.cardPayment,
      EntityTypes.reminder,
    ];
    final result = <SyncEntity>[];
    for (final type in types) {
      for (final item in widget.store.records(type)) {
        final haystack = jsonEncode(item.payload).toLowerCase();
        if (haystack.contains(normalized)) result.add(item);
      }
    }
    return result;
  }

  String _title(SyncEntity item) {
    for (final key in const <String>['title', 'name', 'description', 'front', 'question', 'planName', 'bank', 'creditor']) {
      final value = item.payload[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return _label(item.type);
  }

  String _label(String type) {
    const labels = <String, String>{
      EntityTypes.subject: 'Matéria',
      EntityTypes.classSession: 'Aula',
      EntityTypes.exam: 'Avaliação',
      EntityTypes.studyNote: 'Anotação',
      EntityTypes.flashcard: 'Flashcard',
      EntityTypes.studyQuestion: 'Questão',
      EntityTypes.mockExam: 'Simulado',
      EntityTypes.workoutPlan: 'Ficha de treino',
      EntityTypes.exercise: 'Exercício',
      EntityTypes.workoutSession: 'Treino concluído',
      EntityTypes.bodyMetric: 'Medida corporal',
      EntityTypes.cardioSession: 'Cardio',
      EntityTypes.income: 'Receita',
      EntityTypes.expense: 'Despesa',
      EntityTypes.card: 'Cartão',
      EntityTypes.debt: 'Dívida / compra',
      EntityTypes.loan: 'Empréstimo',
      EntityTypes.financeAccount: 'Conta',
      EntityTypes.financeTransfer: 'Transferência',
      EntityTypes.financeCategory: 'Categoria financeira',
      EntityTypes.budget: 'Orçamento',
      EntityTypes.financeGoal: 'Meta financeira',
      EntityTypes.cardPayment: 'Pagamento de fatura',
      EntityTypes.reminder: 'Lembrete',
    };
    return labels[type] ?? type;
  }

  IconData _icon(String type) {
    if (<String>[EntityTypes.subject, EntityTypes.classSession, EntityTypes.exam, EntityTypes.studyNote, EntityTypes.flashcard, EntityTypes.studyQuestion, EntityTypes.mockExam].contains(type)) {
      return Icons.school_outlined;
    }
    if (<String>[EntityTypes.workoutPlan, EntityTypes.exercise, EntityTypes.workoutSession, EntityTypes.bodyMetric, EntityTypes.cardioSession].contains(type)) {
      return Icons.fitness_center;
    }
    if (type == EntityTypes.reminder) return Icons.notifications_outlined;
    return Icons.account_balance_wallet_outlined;
  }

  Color _color(String type) {
    if (<String>[EntityTypes.subject, EntityTypes.classSession, EntityTypes.exam, EntityTypes.studyNote, EntityTypes.flashcard, EntityTypes.studyQuestion, EntityTypes.mockExam].contains(type)) {
      return AppColors.purple;
    }
    if (<String>[EntityTypes.workoutPlan, EntityTypes.exercise, EntityTypes.workoutSession, EntityTypes.bodyMetric, EntityTypes.cardioSession].contains(type)) {
      return AppColors.orange;
    }
    return AppColors.green;
  }
}
