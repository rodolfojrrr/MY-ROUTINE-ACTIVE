import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/finance_analytics.dart';
import '../core/finance_utils.dart';
import '../core/sync_entity.dart';
import '../widgets/premium_widgets.dart';

final _financeMoney = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class AccountsTab extends StatelessWidget {
  const AccountsTab({required this.store, super.key});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final accounts = store.records(EntityTypes.financeAccount);
    final total = accounts.fold<double>(
      0,
      (sum, item) => sum + FinanceAnalytics.accountBalance(store, item),
    );
    final transfers = store.records(EntityTypes.financeTransfer);
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
                  eyebrow: 'Patrimônio',
                  title: 'Contas e transferências',
                  subtitle: 'Acompanhe o saldo de cada conta e movimente dinheiro entre elas.',
                ),
                const SizedBox(height: 20),
                ResponsiveGrid(
                  minItemWidth: 230,
                  children: <Widget>[
                    MetricCard(
                      label: 'Saldo em contas',
                      value: _financeMoney.format(total),
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppColors.green,
                    ),
                    MetricCard(
                      label: 'Contas cadastradas',
                      value: '${accounts.length}',
                      icon: Icons.account_balance_outlined,
                      color: AppColors.blue,
                    ),
                    MetricCard(
                      label: 'Transferências',
                      value: '${transfers.length}',
                      icon: Icons.compare_arrows,
                      color: AppColors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    ElevatedButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => _AccountDialog(store: store),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Nova conta'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: accounts.length < 2
                          ? null
                          : () => showDialog<void>(
                                context: context,
                                builder: (_) => _TransferDialog(store: store),
                              ),
                      icon: const Icon(Icons.compare_arrows),
                      label: const Text('Transferir'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (accounts.isEmpty)
                  const EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Nenhuma conta cadastrada',
                    message: 'Cadastre sua conta corrente, carteira ou poupança para consolidar seu saldo.',
                  )
                else
                  ...accounts.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PremiumCard(
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.green.withValues(alpha: .14),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(Icons.account_balance_outlined, color: AppColors.green),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    item.payload['name'] as String? ?? '',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                  ),
                                  Text(
                                    '${item.payload['institution'] ?? ''} • ${item.payload['type'] ?? 'Conta'}',
                                    style: const TextStyle(color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _financeMoney.format(FinanceAnalytics.accountBalance(store, item)),
                              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                            ),
                            IconButton(
                              onPressed: () => showDialog<void>(
                                context: context,
                                builder: (_) => _AccountDialog(store: store, entity: item),
                              ),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            ConfirmDeleteButton(onDelete: () => store.remove(item.id)),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (transfers.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Últimas transferências', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 6),
                        ...transfers.take(8).map(
                          (item) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.compare_arrows, color: AppColors.purple),
                            title: Text(
                              '${_accountName(store, item.payload['fromAccountId'] as String?)} → ${_accountName(store, item.payload['toAccountId'] as String?)}',
                            ),
                            subtitle: Text(_formatDate(item.payload['date'] as String?)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  _financeMoney.format((item.payload['amount'] as num? ?? 0).toDouble()),
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                                ConfirmDeleteButton(onDelete: () => store.remove(item.id)),
                              ],
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

class FinancePlanningTab extends StatelessWidget {
  const FinancePlanningTab({required this.store, required this.month, super.key});

  final AppStore store;
  final DateTime month;

  Future<void> _deleteCategory(SyncEntity category) async {
    for (final type in <String>[EntityTypes.income, EntityTypes.expense]) {
      final linked = store
          .records(type)
          .where((item) => item.payload['categoryId'] == category.id)
          .toList();
      for (final item in linked) {
        await store.save(
          type,
          <String, dynamic>{...item.payload, 'categoryId': null},
          id: item.id,
        );
      }
    }
    final linkedBudgets = store
        .records(EntityTypes.budget)
        .where((item) => item.payload['categoryId'] == category.id)
        .toList();
    for (final item in linkedBudgets) {
      await store.remove(item.id);
    }
    final children = store
        .records(EntityTypes.financeCategory)
        .where((item) => item.payload['parentId'] == category.id)
        .toList();
    for (final child in children) {
      await store.save(
        EntityTypes.financeCategory,
        <String, dynamic>{...child.payload, 'parentId': null},
        id: child.id,
      );
    }
    await store.remove(category.id);
  }

  @override
  Widget build(BuildContext context) {
    final categories = store.records(EntityTypes.financeCategory);
    final budgets = store.records(EntityTypes.budget);
    final goals = store.records(EntityTypes.financeGoal);
    final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final monthBudgets = budgets.where((item) => item.payload['monthKey'] == monthKey).toList();

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
                  eyebrow: 'Planejamento',
                  title: 'Categorias, orçamentos e metas',
                  subtitle: 'Defina limites por categoria e acompanhe objetivos financeiros.',
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    ElevatedButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => _CategoryDialog(store: store),
                      ),
                      icon: const Icon(Icons.category_outlined),
                      label: const Text('Nova categoria'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: categories.isEmpty
                          ? null
                          : () => showDialog<void>(
                                context: context,
                                builder: (_) => _BudgetDialog(store: store, month: month),
                              ),
                      icon: const Icon(Icons.pie_chart_outline),
                      label: const Text('Novo orçamento'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => _FinanceGoalDialog(store: store),
                      ),
                      icon: const Icon(Icons.savings_outlined),
                      label: const Text('Nova meta'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Orçamentos de ${DateFormat('MMMM', 'pt_BR').format(month)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      if (monthBudgets.isEmpty)
                        const Text('Nenhum limite definido para este mês.', style: TextStyle(color: AppColors.textMuted))
                      else
                        ...monthBudgets.map((item) {
                          final categoryId = item.payload['categoryId'] as String?;
                          final limit = (item.payload['limit'] as num? ?? 0).toDouble();
                          final spent = _categorySpent(store, categoryId, month);
                          final progress = limit <= 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0).toDouble();
                          final over = spent > limit && limit > 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        _categoryName(store, categoryId),
                                        style: const TextStyle(fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    Text('${_financeMoney.format(spent)} / ${_financeMoney.format(limit)}'),
                                    ConfirmDeleteButton(onDelete: () => store.remove(item.id)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(8),
                                  color: over ? AppColors.red : AppColors.green,
                                  backgroundColor: AppColors.surfaceRaised,
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
                      const Text('Metas financeiras', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      if (goals.isEmpty)
                        const Text('Nenhuma meta criada.', style: TextStyle(color: AppColors.textMuted))
                      else
                        ...goals.map((item) {
                          final target = (item.payload['target'] as num? ?? 0).toDouble();
                          final current = (item.payload['current'] as num? ?? 0).toDouble();
                          final progress = target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0).toDouble();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.savings_outlined, color: AppColors.green),
                              title: Text(item.payload['name'] as String? ?? ''),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const SizedBox(height: 4),
                                  Text('${_financeMoney.format(current)} de ${_financeMoney.format(target)}'),
                                  const SizedBox(height: 5),
                                  LinearProgressIndicator(value: progress, minHeight: 7, borderRadius: BorderRadius.circular(7)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  IconButton(
                                    tooltip: 'Atualizar valor',
                                    onPressed: () => showDialog<void>(
                                      context: context,
                                      builder: (_) => _FinanceGoalDialog(store: store, entity: item),
                                    ),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  ConfirmDeleteButton(onDelete: () => store.remove(item.id)),
                                ],
                              ),
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
                      const Text('Categorias', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      if (categories.isEmpty)
                        const Text('Crie categorias como Alimentação, Transporte e Lazer.', style: TextStyle(color: AppColors.textMuted))
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories
                              .map(
                                (item) => InputChip(
                                  label: Text('${_categoryName(store, item.id)} • ${item.payload['type']}'),
                                  onPressed: () => showDialog<void>(
                                    context: context,
                                    builder: (_) => _CategoryDialog(store: store, entity: item),
                                  ),
                                  onDeleted: () => _deleteCategory(item),
                                ),
                              )
                              .toList(),
                        ),
                    ],
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

class FinanceReportsTab extends StatelessWidget {
  const FinanceReportsTab({required this.store, super.key});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List<DateTime>.generate(
      6,
      (index) => DateTime(now.year, now.month - 5 + index),
    );
    final expenses = months.map((month) => _expenseMonth(store, month)).toList();
    final incomes = months.map((month) => _incomeMonth(store, month)).toList();
    final accounts = store.records(EntityTypes.financeAccount);
    final cash = accounts.fold<double>(0, (sum, item) => sum + FinanceAnalytics.accountBalance(store, item));
    final outstandingDebts = store.records(EntityTypes.debt).fold<double>(0, (sum, item) {
      if (item.payload['status'] == 'Quitada') return sum;
      final total = (item.payload['total'] as num? ?? 0).toDouble();
      return sum + total;
    });
    final outstandingLoans = store.records(EntityTypes.loan).fold<double>(0, (sum, item) {
      if (item.payload['status'] == 'Quitado') return sum;
      final payment = (item.payload['monthlyPayment'] as num? ?? 0).toDouble();
      final installments = (item.payload['installments'] as num? ?? 0).toInt();
      return sum + payment * installments;
    });
    final netWorth = cash - outstandingDebts - outstandingLoans;

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
                  eyebrow: 'Relatórios',
                  title: 'Visão financeira de longo prazo',
                  subtitle: 'Compare meses, acompanhe seu patrimônio e identifique a tendência de gastos.',
                ),
                const SizedBox(height: 20),
                ResponsiveGrid(
                  minItemWidth: 230,
                  children: <Widget>[
                    MetricCard(
                      label: 'Saldo em contas',
                      value: _financeMoney.format(cash),
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppColors.green,
                    ),
                    MetricCard(
                      label: 'Dívidas cadastradas',
                      value: _financeMoney.format(outstandingDebts),
                      icon: Icons.receipt_long_outlined,
                      color: AppColors.red,
                    ),
                    MetricCard(
                      label: 'Patrimônio estimado',
                      value: _financeMoney.format(netWorth),
                      icon: Icons.insights,
                      color: netWorth >= 0 ? AppColors.green : AppColors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Receitas x despesas — 6 meses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 220,
                        child: _MonthlyFinanceChart(months: months, incomes: incomes, expenses: expenses),
                      ),
                      const SizedBox(height: 10),
                      const Row(
                        children: <Widget>[
                          Icon(Icons.square, size: 14, color: AppColors.green),
                          SizedBox(width: 5),
                          Text('Receitas'),
                          SizedBox(width: 18),
                          Icon(Icons.square, size: 14, color: AppColors.red),
                          SizedBox(width: 5),
                          Text('Despesas'),
                        ],
                      ),
                    ],
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

class _AccountDialog extends StatefulWidget {
  const _AccountDialog({required this.store, this.entity});

  final AppStore store;
  final SyncEntity? entity;

  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<_AccountDialog> {
  late final TextEditingController name;
  late final TextEditingController institution;
  late final TextEditingController initial;
  String type = 'Conta corrente';

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.entity?.payload['name'] as String? ?? '');
    institution = TextEditingController(text: widget.entity?.payload['institution'] as String? ?? '');
    initial = TextEditingController(text: widget.entity?.payload['initialBalance']?.toString() ?? '0');
    type = widget.entity?.payload['type'] as String? ?? 'Conta corrente';
  }

  @override
  void dispose() {
    name.dispose();
    institution.dispose();
    initial.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.entity == null ? 'Nova conta' : 'Editar conta'),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome da conta')),
            const SizedBox(height: 10),
            TextField(controller: institution, decoration: const InputDecoration(labelText: 'Banco / instituição')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: const <String>['Conta corrente', 'Poupança', 'Carteira', 'Investimentos', 'Outro']
                  .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: (value) => setState(() => type = value ?? type),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: initial,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Saldo inicial'),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () async {
            if (name.text.trim().isEmpty) return;
            await widget.store.save(EntityTypes.financeAccount, <String, dynamic>{
              'name': name.text.trim(),
              'institution': institution.text.trim(),
              'type': type,
              'initialBalance': parseMoney(initial.text),
            }, id: widget.entity?.id);
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _TransferDialog extends StatefulWidget {
  const _TransferDialog({required this.store});

  final AppStore store;

  @override
  State<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<_TransferDialog> {
  late String fromId;
  late String toId;
  DateTime date = DateTime.now();
  final amount = TextEditingController();
  final description = TextEditingController();

  @override
  void initState() {
    super.initState();
    final accounts = widget.store.records(EntityTypes.financeAccount);
    fromId = accounts.first.id;
    toId = accounts[1].id;
  }

  @override
  void dispose() {
    amount.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = widget.store.records(EntityTypes.financeAccount);
    return AlertDialog(
      title: const Text('Transferência entre contas'),
      content: SizedBox(
        width: 470,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DropdownButtonFormField<String>(
              initialValue: fromId,
              decoration: const InputDecoration(labelText: 'Conta de origem'),
              items: accounts.map((item) => DropdownMenuItem(value: item.id, child: Text(item.payload['name'] as String? ?? ''))).toList(),
              onChanged: (value) => setState(() => fromId = value ?? fromId),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: toId,
              decoration: const InputDecoration(labelText: 'Conta de destino'),
              items: accounts.map((item) => DropdownMenuItem(value: item.id, child: Text(item.payload['name'] as String? ?? ''))).toList(),
              onChanged: (value) => setState(() => toId = value ?? toId),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor'),
            ),
            const SizedBox(height: 10),
            TextField(controller: description, decoration: const InputDecoration(labelText: 'Descrição')),
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
            if (fromId == toId || parseMoney(amount.text) <= 0) return;
            await widget.store.save(EntityTypes.financeTransfer, <String, dynamic>{
              'fromAccountId': fromId,
              'toAccountId': toId,
              'amount': parseMoney(amount.text),
              'description': description.text.trim(),
              'date': DateFormat('yyyy-MM-dd').format(date),
            });
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: const Text('Transferir'),
        ),
      ],
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({required this.store, this.entity});

  final AppStore store;
  final SyncEntity? entity;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController name;
  String type = 'Despesa';
  String? parentId;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.entity?.payload['name'] as String? ?? '');
    type = widget.entity?.payload['type'] as String? ?? 'Despesa';
    parentId = widget.entity?.payload['parentId'] as String?;
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parents = widget.store
        .records(EntityTypes.financeCategory)
        .where((item) => item.id != widget.entity?.id && item.payload['type'] == type)
        .toList();
    final selectedParent = parents.any((item) => item.id == parentId) ? parentId : null;
    return AlertDialog(
      title: Text(widget.entity == null ? 'Nova categoria' : 'Editar categoria'),
      content: SizedBox(
        width: 430,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: const <String>['Despesa', 'Receita']
                  .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: (value) => setState(() {
                type = value ?? type;
                parentId = null;
              }),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String?>(
              initialValue: selectedParent,
              decoration: const InputDecoration(labelText: 'Categoria pai (opcional)'),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Categoria principal'),
                ),
                ...parents.map(
                  (item) => DropdownMenuItem<String?>(
                    value: item.id,
                    child: Text(item.payload['name'] as String? ?? ''),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => parentId = value),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () async {
            if (name.text.trim().isEmpty) return;
            await widget.store.save(EntityTypes.financeCategory, <String, dynamic>{
              'name': name.text.trim(),
              'type': type,
              'parentId': parentId,
            }, id: widget.entity?.id);
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({required this.store, required this.month});

  final AppStore store;
  final DateTime month;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late String categoryId;
  final limit = TextEditingController();

  @override
  void initState() {
    super.initState();
    categoryId = widget.store.records(EntityTypes.financeCategory).first.id;
  }

  @override
  void dispose() {
    limit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.store.records(EntityTypes.financeCategory)
        .where((item) => item.payload['type'] == 'Despesa')
        .toList();
    if (!categories.any((item) => item.id == categoryId) && categories.isNotEmpty) {
      categoryId = categories.first.id;
    }
    return AlertDialog(
      title: const Text('Novo orçamento mensal'),
      content: SizedBox(
        width: 430,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DropdownButtonFormField<String>(
              initialValue: categories.any((item) => item.id == categoryId) ? categoryId : null,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: categories.map((item) => DropdownMenuItem(value: item.id, child: Text(_categoryName(widget.store, item.id)))).toList(),
              onChanged: (value) => setState(() => categoryId = value ?? categoryId),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: limit,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Limite do mês'),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: categories.isEmpty
              ? null
              : () async {
                  await widget.store.save(EntityTypes.budget, <String, dynamic>{
                    'categoryId': categoryId,
                    'monthKey': '${widget.month.year}-${widget.month.month.toString().padLeft(2, '0')}',
                    'limit': parseMoney(limit.text),
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

class _FinanceGoalDialog extends StatefulWidget {
  const _FinanceGoalDialog({required this.store, this.entity});

  final AppStore store;
  final SyncEntity? entity;

  @override
  State<_FinanceGoalDialog> createState() => _FinanceGoalDialogState();
}

class _FinanceGoalDialogState extends State<_FinanceGoalDialog> {
  late final TextEditingController name;
  late final TextEditingController target;
  late final TextEditingController current;
  DateTime? dueDate;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.entity?.payload['name'] as String? ?? '');
    target = TextEditingController(text: widget.entity?.payload['target']?.toString() ?? '');
    current = TextEditingController(text: widget.entity?.payload['current']?.toString() ?? '0');
    dueDate = DateTime.tryParse(widget.entity?.payload['dueDate'] as String? ?? '');
  }

  @override
  void dispose() {
    name.dispose();
    target.dispose();
    current.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.entity == null ? 'Nova meta financeira' : 'Atualizar meta'),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Objetivo')),
            const SizedBox(height: 10),
            TextField(
              controller: target,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor alvo'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: current,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor acumulado'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Prazo opcional'),
              subtitle: Text(dueDate == null ? 'Sem prazo' : DateFormat('dd/MM/yyyy').format(dueDate!)),
              onTap: () async {
                final value = await pickAppDate(context, dueDate ?? DateTime.now());
                if (value != null && mounted) setState(() => dueDate = value);
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () async {
            if (name.text.trim().isEmpty) return;
            await widget.store.save(EntityTypes.financeGoal, <String, dynamic>{
              'name': name.text.trim(),
              'target': parseMoney(target.text),
              'current': parseMoney(current.text),
              'dueDate': dueDate?.toIso8601String(),
            }, id: widget.entity?.id);
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _MonthlyFinanceChart extends StatelessWidget {
  const _MonthlyFinanceChart({required this.months, required this.incomes, required this.expenses});

  final List<DateTime> months;
  final List<double> incomes;
  final List<double> expenses;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FinanceChartPainter(months: months, incomes: incomes, expenses: expenses),
      child: const SizedBox.expand(),
    );
  }
}

class _FinanceChartPainter extends CustomPainter {
  _FinanceChartPainter({required this.months, required this.incomes, required this.expenses});

  final List<DateTime> months;
  final List<double> incomes;
  final List<double> expenses;

  @override
  void paint(Canvas canvas, Size size) {
    var maxValue = 1.0;
    for (final value in <double>[...incomes, ...expenses]) {
      if (value > maxValue) maxValue = value;
    }
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    final groupWidth = size.width / months.length;
    final barWidth = (groupWidth * .24).clamp(6.0, 28.0);
    for (var index = 0; index < months.length; index++) {
      final center = groupWidth * index + groupWidth / 2;
      final incomeHeight = (incomes[index] / maxValue) * (size.height - 30);
      final expenseHeight = (expenses[index] / maxValue) * (size.height - 30);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(center - barWidth - 2, size.height - 24 - incomeHeight, barWidth, incomeHeight),
          const Radius.circular(4),
        ),
        Paint()..color = AppColors.green,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(center + 2, size.height - 24 - expenseHeight, barWidth, expenseHeight),
          const Radius.circular(4),
        ),
        Paint()..color = AppColors.red,
      );
      textPainter.text = TextSpan(
        text: DateFormat('MMM', 'pt_BR').format(months[index]),
        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(center - textPainter.width / 2, size.height - 18));
    }
  }

  @override
  bool shouldRepaint(covariant _FinanceChartPainter oldDelegate) =>
      oldDelegate.incomes != incomes || oldDelegate.expenses != expenses;
}

double _categorySpent(AppStore store, String? categoryId, DateTime month) {
  if (categoryId == null) return 0;
  final family = <String>{categoryId};
  var changed = true;
  while (changed) {
    changed = false;
    for (final category in store.records(EntityTypes.financeCategory)) {
      final parentId = category.payload['parentId'] as String?;
      if (parentId != null && family.contains(parentId) && family.add(category.id)) {
        changed = true;
      }
    }
  }
  return store.records(EntityTypes.expense).fold<double>(0, (sum, item) {
    if (!family.contains(item.payload['categoryId'])) return sum;
    final recurring = item.payload['recurring'] == true;
    final date = item.payload['date'] as String?;
    return sum + (recurring || FinanceAnalytics.inMonth(date, month)
        ? (item.payload['amount'] as num? ?? 0).toDouble()
        : 0);
  });
}

double _incomeMonth(AppStore store, DateTime month) {
  return store.records(EntityTypes.income).fold<double>(0, (sum, item) {
    final recurring = item.payload['recurring'] == true;
    return sum + (recurring || FinanceAnalytics.inMonth(item.payload['date'] as String?, month)
        ? (item.payload['amount'] as num? ?? 0).toDouble()
        : 0);
  });
}

double _expenseMonth(AppStore store, DateTime month) {
  final direct = store.records(EntityTypes.expense).fold<double>(0, (sum, item) {
    final recurring = item.payload['recurring'] == true;
    return sum + (recurring || FinanceAnalytics.inMonth(item.payload['date'] as String?, month)
        ? (item.payload['amount'] as num? ?? 0).toDouble()
        : 0);
  });
  final debts = store.records(EntityTypes.debt).fold<double>(0, (sum, item) {
    if (item.payload['status'] == 'Quitada') return sum;
    final purchase = DateTime.tryParse(item.payload['purchaseDate'] as String? ?? '');
    if (purchase == null) return sum;
    final installments = (item.payload['installments'] as num? ?? 1).toInt();
    final number = FinanceUtils.installmentNumber(purchaseDate: purchase, month: month);
    if (number < 1 || number > installments) return sum;
    return sum + FinanceUtils.installmentValue(
      (item.payload['total'] as num? ?? 0).toDouble(),
      installments,
    );
  });
  final loans = store.records(EntityTypes.loan).fold<double>(0, (sum, item) {
    if (item.payload['status'] == 'Quitado') return sum;
    final startDate = DateTime.tryParse(item.payload['startDate'] as String? ?? '');
    if (startDate == null) return sum;
    final installments = (item.payload['installments'] as num? ?? 1).toInt();
    final number = FinanceUtils.installmentNumber(purchaseDate: startDate, month: month);
    if (number < 1 || number > installments) return sum;
    return sum + (item.payload['monthlyPayment'] as num? ?? 0).toDouble();
  });
  return direct + debts + loans;
}

String _accountName(AppStore store, String? id) =>
    id == null ? 'Conta' : store.byId(id)?.payload['name'] as String? ?? 'Conta removida';

String _categoryName(AppStore store, String? id) {
  if (id == null) return 'Sem categoria';
  final category = store.byId(id);
  if (category == null) return 'Categoria removida';
  final name = category.payload['name'] as String? ?? 'Categoria';
  final parentId = category.payload['parentId'] as String?;
  if (parentId == null) return name;
  final parent = store.byId(parentId);
  final parentName = parent?.payload['name'] as String?;
  return parentName == null || parentName.isEmpty ? name : '$parentName › $name';
}

String _formatDate(String? value) {
  final date = DateTime.tryParse(value ?? '');
  return date == null ? 'Sem data' : DateFormat('dd/MM/yyyy').format(date);
}
