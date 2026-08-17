import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/finance_utils.dart';
import '../core/sync_entity.dart';
import '../widgets/premium_widgets.dart';

final _money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({required this.store, super.key});

  final AppStore store;

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void changeMonth(int delta) {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            title: const Text('Finanças'),
            bottom: const TabBar(
              isScrollable: true,
              tabs: <Widget>[
                Tab(icon: Icon(Icons.dashboard_outlined), text: 'Visão geral'),
                Tab(icon: Icon(Icons.swap_vert), text: 'Lançamentos'),
                Tab(icon: Icon(Icons.credit_card), text: 'Cartões'),
                Tab(icon: Icon(Icons.receipt_long), text: 'Dívidas'),
                Tab(icon: Icon(Icons.account_balance), text: 'Empréstimos'),
              ],
            ),
          ),
          body: PremiumBackground(
            child: Column(
              children: <Widget>[
                _MonthPicker(
                  month: selectedMonth,
                  previous: () => changeMonth(-1),
                  next: () => changeMonth(1),
                ),
                Expanded(
                  child: TabBarView(
                    children: <Widget>[
                      _OverviewTab(
                        store: widget.store,
                        month: selectedMonth,
                      ),
                      _TransactionsTab(
                        store: widget.store,
                        month: selectedMonth,
                      ),
                      _CardsTab(store: widget.store),
                      _DebtsTab(store: widget.store, month: selectedMonth),
                      _LoansTab(store: widget.store, month: selectedMonth),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({
    required this.month,
    required this.previous,
    required this.next,
  });

  final DateTime month;
  final VoidCallback previous;
  final VoidCallback next;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: PremiumCard(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: <Widget>[
                IconButton(onPressed: previous, icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: Text(
                    DateFormat('MMMM \'de\' yyyy', 'pt_BR').format(month),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(onPressed: next, icon: const Icon(Icons.chevron_right)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool _inMonth(String? isoDate, DateTime month) {
  final date = DateTime.tryParse(isoDate ?? '');
  return date != null && date.year == month.year && date.month == month.month;
}

double _amount(SyncEntity item) =>
    (item.payload['amount'] as num? ?? 0).toDouble();

double _incomeForMonth(AppStore store, DateTime month) {
  return store.records(EntityTypes.income).fold<double>(0, (sum, item) {
    final recurring = item.payload['recurring'] == true;
    return sum + (recurring || _inMonth(item.payload['date'] as String?, month) ? _amount(item) : 0);
  });
}

double _expenseForMonth(AppStore store, DateTime month) {
  final direct = store.records(EntityTypes.expense).fold<double>(0, (sum, item) {
    final recurring = item.payload['recurring'] == true;
    return sum + (recurring || _inMonth(item.payload['date'] as String?, month) ? _amount(item) : 0);
  });
  final debts = store.records(EntityTypes.debt).fold<double>(0, (sum, debt) {
    final purchase = DateTime.tryParse(debt.payload['purchaseDate'] as String? ?? '');
    final installments = (debt.payload['installments'] as num? ?? 1).toInt();
    if (purchase == null || debt.payload['status'] == 'Quitada') return sum;
    final number = FinanceUtils.installmentNumber(purchaseDate: purchase, month: month);
    if (number < 1 || number > installments) return sum;
    final total = (debt.payload['total'] as num? ?? 0).toDouble();
    return sum + FinanceUtils.installmentValue(total, installments);
  });
  final loans = store.records(EntityTypes.loan).fold<double>(0, (sum, loan) {
    final start = DateTime.tryParse(loan.payload['startDate'] as String? ?? '');
    final installments = (loan.payload['installments'] as num? ?? 1).toInt();
    if (start == null || loan.payload['status'] == 'Quitado') return sum;
    final number = FinanceUtils.installmentNumber(purchaseDate: start, month: month);
    return sum +
        (number >= 1 && number <= installments
            ? (loan.payload['monthlyPayment'] as num? ?? 0).toDouble()
            : 0);
  });
  return direct + debts + loans;
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.store, required this.month});

  final AppStore store;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final income = _incomeForMonth(store, month);
    final expense = _expenseForMonth(store, month);
    final balance = income - expense;
    final salary = store
        .records(EntityTypes.income)
        .where((item) => item.payload['kind'] == 'salary')
        .cast<SyncEntity?>()
        .firstWhere((_) => true, orElse: () => null);
    final events = _calendarEvents(store, month);
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
                  eyebrow: 'Controle financeiro',
                  title: 'Visão geral',
                  subtitle:
                      'Salário, parcelas e compromissos calculados automaticamente para o mês selecionado.',
                ),
                const SizedBox(height: 20),
                ResponsiveGrid(
                  minItemWidth: 230,
                  children: <Widget>[
                    MetricCard(
                      label: 'Renda prevista',
                      value: _money.format(income),
                      icon: Icons.south_west,
                      color: AppColors.green,
                    ),
                    MetricCard(
                      label: 'Despesas previstas',
                      value: _money.format(expense),
                      icon: Icons.north_east,
                      color: AppColors.red,
                    ),
                    MetricCard(
                      label: 'Saldo previsto',
                      value: _money.format(balance),
                      icon: Icons.account_balance_wallet,
                      color: balance >= 0 ? AppColors.green : AppColors.red,
                    ),
                    MetricCard(
                      label: 'Pendências do calendário',
                      value: '${events.length}',
                      icon: Icons.notifications_active_outlined,
                      color: AppColors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PremiumCard(
                  borderColor: AppColors.green.withValues(alpha: .5),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.payments_outlined, color: AppColors.green, size: 36),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Salário mensal fixo',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              salary == null
                                  ? 'Ainda não configurado.'
                                  : '${_money.format(_amount(salary))} • todo dia ${salary.payload['fixedDay']}',
                              style: const TextStyle(color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'O dia é permanente e se repete em todos os meses, sem guardar um mês específico.',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => _SalaryDialog(store: store, salary: salary),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(salary == null ? 'Configurar' : 'Editar'),
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
                        'Calendário do mês',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
                      ),
                      const SizedBox(height: 8),
                      if (events.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Nenhum compromisso financeiro neste mês.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      else
                        ...events.map(
                          (event) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: event.color.withValues(alpha: .16),
                              child: Text(
                                event.day.toString(),
                                style: TextStyle(
                                  color: event.color,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            title: Text(event.title),
                            subtitle: Text(event.subtitle),
                            trailing: Text(
                              _money.format(event.value),
                              style: TextStyle(
                                color: event.color,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
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

class _SalaryDialog extends StatefulWidget {
  const _SalaryDialog({required this.store, this.salary});

  final AppStore store;
  final SyncEntity? salary;

  @override
  State<_SalaryDialog> createState() => _SalaryDialogState();
}

class _SalaryDialogState extends State<_SalaryDialog> {
  late final TextEditingController description;
  late final TextEditingController amount;
  late final TextEditingController day;

  @override
  void initState() {
    super.initState();
    description = TextEditingController(
      text: widget.salary?.payload['description'] as String? ?? 'Salário',
    );
    amount = TextEditingController(
      text: (widget.salary?.payload['amount'] as num?)?.toString() ?? '',
    );
    day = TextEditingController(
      text: (widget.salary?.payload['fixedDay'] as num? ?? 5).toString(),
    );
  }

  @override
  void dispose() {
    description.dispose();
    amount.dispose();
    day.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Salário fixo mensal'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor mensal'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: day,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Dia fixo do recebimento (1 a 31)',
                helperText: 'Exemplo: 5 significa todo dia 5, em qualquer mês.',
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
        FilledButton(
          onPressed: () async {
            await widget.store.save(
              EntityTypes.income,
              <String, dynamic>{
                'kind': 'salary',
                'description': description.text.trim(),
                'amount': parseMoney(amount.text),
                'recurring': true,
                'fixedDay': (int.tryParse(day.text) ?? 5).clamp(1, 31),
                'date': null,
              },
              id: widget.salary?.id,
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

class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab({required this.store, required this.month});

  final AppStore store;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final incomes = store.records(EntityTypes.income).where((item) {
      return item.payload['recurring'] == true ||
          _inMonth(item.payload['date'] as String?, month);
    }).toList();
    final expenses = store.records(EntityTypes.expense).where((item) {
      return item.payload['recurring'] == true ||
          _inMonth(item.payload['date'] as String?, month);
    }).toList();
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
                  eyebrow: 'Entradas e saídas',
                  title: 'Lançamentos',
                  subtitle: 'Cadastre rendas e despesas avulsas ou recorrentes.',
                ),
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => _TransactionDialog(
                            store: store,
                            type: EntityTypes.income,
                            initialDate: month,
                          ),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Nova renda'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => _TransactionDialog(
                            store: store,
                            type: EntityTypes.expense,
                            initialDate: month,
                          ),
                        ),
                        icon: const Icon(Icons.remove),
                        label: const Text('Nova despesa'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _TransactionSection(
                  store: store,
                  title: 'Rendas',
                  color: AppColors.green,
                  icon: Icons.south_west,
                  items: incomes,
                  type: EntityTypes.income,
                  month: month,
                ),
                const SizedBox(height: 16),
                _TransactionSection(
                  store: store,
                  title: 'Despesas',
                  color: AppColors.red,
                  icon: Icons.north_east,
                  items: expenses,
                  type: EntityTypes.expense,
                  month: month,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TransactionSection extends StatelessWidget {
  const _TransactionSection({
    required this.store,
    required this.title,
    required this.color,
    required this.icon,
    required this.items,
    required this.type,
    required this.month,
  });

  final AppStore store;
  final String title;
  final Color color;
  final IconData icon;
  final List<SyncEntity> items;
  final String type;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(color: color, fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text('Nenhum lançamento.', style: TextStyle(color: AppColors.textMuted)),
            )
          else
            ...items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(icon, color: color),
                title: Text(item.payload['description'] as String? ?? ''),
                subtitle: Text(
                  item.payload['recurring'] == true
                      ? 'Recorrente • dia ${item.payload['fixedDay'] ?? '-'}'
                      : _formatDate(item.payload['date'] as String?),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _money.format(_amount(item)),
                      style: TextStyle(color: color, fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      onPressed: item.payload['kind'] == 'salary'
                          ? () => showDialog<void>(
                                context: context,
                                builder: (_) => _SalaryDialog(store: store, salary: item),
                              )
                          : () => showDialog<void>(
                                context: context,
                                builder: (_) => _TransactionDialog(
                                  store: store,
                                  type: type,
                                  initialDate: month,
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
        ],
      ),
    );
  }
}

class _TransactionDialog extends StatefulWidget {
  const _TransactionDialog({
    required this.store,
    required this.type,
    required this.initialDate,
    this.entity,
  });

  final AppStore store;
  final String type;
  final DateTime initialDate;
  final SyncEntity? entity;

  @override
  State<_TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<_TransactionDialog> {
  late final TextEditingController description;
  late final TextEditingController amount;
  late final TextEditingController fixedDay;
  late DateTime date;
  late bool recurring;

  @override
  void initState() {
    super.initState();
    description = TextEditingController(text: widget.entity?.payload['description'] as String?);
    amount = TextEditingController(
      text: (widget.entity?.payload['amount'] as num?)?.toString() ?? '',
    );
    fixedDay = TextEditingController(
      text: (widget.entity?.payload['fixedDay'] as num? ?? 5).toString(),
    );
    date = DateTime.tryParse(widget.entity?.payload['date'] as String? ?? '') ??
        DateTime(widget.initialDate.year, widget.initialDate.month, 1);
    recurring = widget.entity?.payload['recurring'] == true;
  }

  @override
  void dispose() {
    description.dispose();
    amount.dispose();
    fixedDay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final income = widget.type == EntityTypes.income;
    return AlertDialog(
      title: Text('${widget.entity == null ? 'Nova' : 'Editar'} ${income ? 'renda' : 'despesa'}'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: description,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Valor'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: recurring,
                onChanged: (value) => setState(() => recurring = value),
                title: const Text('Repetir todos os meses'),
              ),
              if (recurring)
                TextField(
                  controller: fixedDay,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Dia fixo do mês'),
                )
              else
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  leading: const Icon(Icons.calendar_month),
                  title: Text(DateFormat('dd/MM/yyyy').format(date)),
                  onTap: () async {
                    final picked = await pickAppDate(context, date);
                    if (picked != null) setState(() => date = picked);
                  },
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
            if (description.text.trim().isEmpty) return;
            await widget.store.save(
              widget.type,
              <String, dynamic>{
                'description': description.text.trim(),
                'amount': parseMoney(amount.text),
                'recurring': recurring,
                'fixedDay': recurring
                    ? (int.tryParse(fixedDay.text) ?? 1).clamp(1, 31)
                    : null,
                'date': recurring ? null : DateFormat('yyyy-MM-dd').format(date),
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

class _CardsTab extends StatelessWidget {
  const _CardsTab({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final cards = store.records(EntityTypes.card);
    const gradients = <List<Color>>[
      <Color>[Color(0xFFB94E0B), Color(0xFF15221A)],
      <Color>[Color(0xFF74108D), Color(0xFF132230)],
      <Color>[Color(0xFF0BA8A1), Color(0xFF103121)],
      <Color>[Color(0xFF1E68D1), Color(0xFF102B25)],
    ];
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
                  eyebrow: 'Crédito organizado',
                  title: 'Cartões',
                  subtitle: 'Cadastre limites, fechamento e vencimento de cada cartão.',
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _CardDialog(store: store),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo cartão'),
                ),
                const SizedBox(height: 20),
                if (cards.isEmpty)
                  const EmptyState(
                    icon: Icons.credit_card,
                    title: 'Nenhum cartão cadastrado',
                    message: 'Adicione seus cartões para relacionar compras parceladas.',
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 760 ? 2 : 1;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.65,
                        ),
                        itemCount: cards.length,
                        itemBuilder: (context, index) {
                          final card = cards[index];
                          final colors = gradients[index % gradients.length];
                          return Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: colors),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Text(card.payload['bank'] as String? ?? ''),
                                    const Spacer(),
                                    Text(card.payload['brand'] as String? ?? ''),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  card.payload['name'] as String? ?? '',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const Spacer(),
                                const Text('Limite', style: TextStyle(color: Colors.white70)),
                                Text(
                                  _money.format((card.payload['limit'] as num? ?? 0).toDouble()),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        'Fecha dia ${card.payload['closingDay']} • vence dia ${card.payload['dueDay']}',
                                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => showDialog<void>(
                                        context: context,
                                        builder: (_) => _CardDialog(store: store, entity: card),
                                      ),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    ConfirmDeleteButton(onDelete: () => store.remove(card.id)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CardDialog extends StatefulWidget {
  const _CardDialog({required this.store, this.entity});

  final AppStore store;
  final SyncEntity? entity;

  @override
  State<_CardDialog> createState() => _CardDialogState();
}

class _CardDialogState extends State<_CardDialog> {
  late final List<TextEditingController> fields;

  @override
  void initState() {
    super.initState();
    final p = widget.entity?.payload;
    fields = <TextEditingController>[
      TextEditingController(text: p?['bank'] as String?),
      TextEditingController(text: p?['name'] as String?),
      TextEditingController(text: p?['brand'] as String? ?? 'Mastercard'),
      TextEditingController(text: (p?['limit'] as num?)?.toString() ?? ''),
      TextEditingController(text: (p?['closingDay'] as num? ?? 1).toString()),
      TextEditingController(text: (p?['dueDay'] as num? ?? 10).toString()),
    ];
  }

  @override
  void dispose() {
    for (final field in fields) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const labels = <String>['Banco', 'Nome no cartão', 'Bandeira', 'Limite', 'Dia do fechamento', 'Dia do vencimento'];
    return AlertDialog(
      title: Text(widget.entity == null ? 'Novo cartão' : 'Editar cartão'),
      content: SizedBox(
        width: 470,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(fields.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: fields[index],
                  keyboardType: index >= 3
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  decoration: InputDecoration(labelText: labels[index]),
                ),
              );
            }),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () async {
            await widget.store.save(EntityTypes.card, <String, dynamic>{
              'bank': fields[0].text.trim(),
              'name': fields[1].text.trim(),
              'brand': fields[2].text.trim(),
              'limit': parseMoney(fields[3].text),
              'closingDay': (int.tryParse(fields[4].text) ?? 1).clamp(1, 31),
              'dueDay': (int.tryParse(fields[5].text) ?? 10).clamp(1, 31),
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

class _DebtsTab extends StatelessWidget {
  const _DebtsTab({required this.store, required this.month});

  final AppStore store;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final debts = store.records(EntityTypes.debt);
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
                  eyebrow: 'Parcelas sob controle',
                  title: 'Dívidas e compras parceladas',
                  subtitle:
                      'A data da compra define automaticamente a parcela atual, as restantes e o mês em que a dívida termina.',
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _DebtDialog(store: store),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Nova dívida parcelada'),
                ),
                const SizedBox(height: 20),
                if (debts.isEmpty)
                  const EmptyState(
                    icon: Icons.receipt_long,
                    title: 'Nenhuma dívida cadastrada',
                    message: 'Compras parceladas aparecerão como compromisso fixo até a última parcela.',
                  )
                else
                  ...debts.map((debt) => _DebtCard(store: store, debt: debt, month: month)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({required this.store, required this.debt, required this.month});

  final AppStore store;
  final SyncEntity debt;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final purchase = DateTime.tryParse(debt.payload['purchaseDate'] as String? ?? '') ?? DateTime.now();
    final installments = (debt.payload['installments'] as num? ?? 1).toInt();
    final total = (debt.payload['total'] as num? ?? 0).toDouble();
    final current = FinanceUtils.installmentNumber(purchaseDate: purchase, month: month);
    final remaining = FinanceUtils.remainingInstallments(
      purchaseDate: purchase,
      installments: installments,
      month: month,
    );
    final end = FinanceUtils.installmentEndDate(
      purchaseDate: purchase,
      installments: installments,
    );
    final card = store.byId(debt.payload['cardId'] as String? ?? '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: PremiumCard(
        borderColor: AppColors.orange.withValues(alpha: .45),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    debt.payload['description'] as String? ?? '',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                Chip(label: Text(debt.payload['status'] as String? ?? 'Ativa')),
                IconButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _DebtDialog(store: store, entity: debt),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                ),
                ConfirmDeleteButton(onDelete: () => store.remove(debt.id)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 22,
              runSpacing: 8,
              children: <Widget>[
                Text('Total: ${_money.format(total)}'),
                Text('Parcela: ${_money.format(FinanceUtils.installmentValue(total, installments))}'),
                Text('Atual: ${current.clamp(0, installments)}/$installments'),
                Text('Restantes: $remaining'),
                Text('Termina: ${DateFormat('MM/yyyy').format(end)}'),
                if (card != null) Text('Cartão: ${card.payload['bank']}'),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: installments == 0
                  ? 0.0
                  : current.clamp(0, installments) / installments,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              color: AppColors.orange,
              backgroundColor: AppColors.surfaceRaised,
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtDialog extends StatefulWidget {
  const _DebtDialog({required this.store, this.entity});

  final AppStore store;
  final SyncEntity? entity;

  @override
  State<_DebtDialog> createState() => _DebtDialogState();
}

class _DebtDialogState extends State<_DebtDialog> {
  late final TextEditingController description;
  late final TextEditingController total;
  late final TextEditingController installments;
  late DateTime purchaseDate;
  String? cardId;
  String status = 'Ativa';

  @override
  void initState() {
    super.initState();
    final p = widget.entity?.payload;
    description = TextEditingController(text: p?['description'] as String?);
    total = TextEditingController(text: (p?['total'] as num?)?.toString() ?? '');
    installments = TextEditingController(text: (p?['installments'] as num? ?? 1).toString());
    purchaseDate = DateTime.tryParse(p?['purchaseDate'] as String? ?? '') ?? DateTime.now();
    cardId = p?['cardId'] as String?;
    status = p?['status'] as String? ?? 'Ativa';
  }

  @override
  void dispose() {
    description.dispose();
    total.dispose();
    installments.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.store.records(EntityTypes.card);
    return AlertDialog(
      title: Text(widget.entity == null ? 'Nova dívida parcelada' : 'Editar dívida'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(controller: description, decoration: const InputDecoration(labelText: 'Descrição')),
              const SizedBox(height: 10),
              TextField(
                controller: total,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Valor total'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: installments,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantidade de parcelas'),
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: const BorderSide(color: AppColors.border),
                ),
                leading: const Icon(Icons.calendar_month),
                title: Text('Compra: ${DateFormat('dd/MM/yyyy').format(purchaseDate)}'),
                onTap: () async {
                  final picked = await pickAppDate(context, purchaseDate);
                  if (picked != null) setState(() => purchaseDate = picked);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                initialValue: cardId,
                decoration: const InputDecoration(labelText: 'Cartão (opcional)'),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(value: null, child: Text('Sem cartão')),
                  ...cards.map(
                    (card) => DropdownMenuItem<String?>(
                      value: card.id,
                      child: Text('${card.payload['bank']} • ${card.payload['name']}'),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => cardId = value),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const <String>['Ativa', 'Pausada', 'Quitada']
                    .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) => setState(() => status = value!),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () async {
            await widget.store.save(EntityTypes.debt, <String, dynamic>{
              'description': description.text.trim(),
              'total': parseMoney(total.text),
              'purchaseDate': DateFormat('yyyy-MM-dd').format(purchaseDate),
              'installments': (int.tryParse(installments.text) ?? 1).clamp(1, 600),
              'cardId': cardId,
              'status': status,
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

class _LoansTab extends StatelessWidget {
  const _LoansTab({required this.store, required this.month});

  final AppStore store;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final loans = store.records(EntityTypes.loan);
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
                  eyebrow: 'Compromissos de longo prazo',
                  title: 'Empréstimos',
                  subtitle: 'Acompanhe credor, parcela, vencimento, prazo e status.',
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _LoanDialog(store: store),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo empréstimo'),
                ),
                const SizedBox(height: 20),
                if (loans.isEmpty)
                  const EmptyState(
                    icon: Icons.account_balance,
                    title: 'Nenhum empréstimo',
                    message: 'Cadastre somente quando precisar acompanhar um contrato.',
                  )
                else
                  ...loans.map((loan) {
                    final start = DateTime.tryParse(loan.payload['startDate'] as String? ?? '') ?? DateTime.now();
                    final count = (loan.payload['installments'] as num? ?? 1).toInt();
                    final current = FinanceUtils.installmentNumber(purchaseDate: start, month: month);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: PremiumCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.account_balance, color: AppColors.blue),
                          title: Text(
                            loan.payload['description'] as String? ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            '${loan.payload['lender']} • parcela ${current.clamp(0, count)}/$count • vence dia ${loan.payload['dueDay']}\n${loan.payload['status']}',
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                _money.format((loan.payload['monthlyPayment'] as num? ?? 0).toDouble()),
                                style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w900),
                              ),
                              IconButton(
                                onPressed: () => showDialog<void>(
                                  context: context,
                                  builder: (_) => _LoanDialog(store: store, entity: loan),
                                ),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              ConfirmDeleteButton(onDelete: () => store.remove(loan.id)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LoanDialog extends StatefulWidget {
  const _LoanDialog({required this.store, this.entity});

  final AppStore store;
  final SyncEntity? entity;

  @override
  State<_LoanDialog> createState() => _LoanDialogState();
}

class _LoanDialogState extends State<_LoanDialog> {
  late final List<TextEditingController> fields;
  late DateTime start;
  String status = 'Ativo';

  @override
  void initState() {
    super.initState();
    final p = widget.entity?.payload;
    fields = <TextEditingController>[
      TextEditingController(text: p?['description'] as String?),
      TextEditingController(text: p?['lender'] as String?),
      TextEditingController(text: (p?['total'] as num?)?.toString() ?? ''),
      TextEditingController(text: (p?['monthlyPayment'] as num?)?.toString() ?? ''),
      TextEditingController(text: (p?['installments'] as num? ?? 1).toString()),
      TextEditingController(text: (p?['dueDay'] as num? ?? 10).toString()),
    ];
    start = DateTime.tryParse(p?['startDate'] as String? ?? '') ?? DateTime.now();
    status = p?['status'] as String? ?? 'Ativo';
  }

  @override
  void dispose() {
    for (final field in fields) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const labels = <String>['Descrição', 'Banco / credor', 'Valor total', 'Valor da parcela', 'Parcelas', 'Dia do vencimento'];
    return AlertDialog(
      title: Text(widget.entity == null ? 'Novo empréstimo' : 'Editar empréstimo'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ...List<Widget>.generate(fields.length, (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: fields[index],
                      keyboardType: index >= 2
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : TextInputType.text,
                      decoration: InputDecoration(labelText: labels[index]),
                    ),
                  )),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: const BorderSide(color: AppColors.border),
                ),
                title: Text('Início: ${DateFormat('dd/MM/yyyy').format(start)}'),
                leading: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await pickAppDate(context, start);
                  if (picked != null) setState(() => start = picked);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const <String>['Ativo', 'Pausado', 'Quitado']
                    .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) => setState(() => status = value!),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () async {
            await widget.store.save(EntityTypes.loan, <String, dynamic>{
              'description': fields[0].text.trim(),
              'lender': fields[1].text.trim(),
              'total': parseMoney(fields[2].text),
              'monthlyPayment': parseMoney(fields[3].text),
              'installments': (int.tryParse(fields[4].text) ?? 1).clamp(1, 600),
              'dueDay': (int.tryParse(fields[5].text) ?? 10).clamp(1, 31),
              'startDate': DateFormat('yyyy-MM-dd').format(start),
              'status': status,
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

class _FinanceEvent {
  const _FinanceEvent({
    required this.day,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
  });

  final int day;
  final String title;
  final String subtitle;
  final double value;
  final Color color;
}

List<_FinanceEvent> _calendarEvents(AppStore store, DateTime month) {
  final events = <_FinanceEvent>[];
  for (final income in store.records(EntityTypes.income)) {
    if (income.payload['recurring'] == true || _inMonth(income.payload['date'] as String?, month)) {
      final date = DateTime.tryParse(income.payload['date'] as String? ?? '');
      events.add(_FinanceEvent(
        day: income.payload['recurring'] == true
            ? (income.payload['fixedDay'] as num? ?? 1).toInt()
            : date?.day ?? 1,
        title: income.payload['description'] as String? ?? 'Renda',
        subtitle: 'Recebimento',
        value: _amount(income),
        color: AppColors.green,
      ));
    }
  }
  for (final expense in store.records(EntityTypes.expense)) {
    if (expense.payload['recurring'] == true || _inMonth(expense.payload['date'] as String?, month)) {
      final date = DateTime.tryParse(expense.payload['date'] as String? ?? '');
      events.add(_FinanceEvent(
        day: expense.payload['recurring'] == true
            ? (expense.payload['fixedDay'] as num? ?? 1).toInt()
            : date?.day ?? 1,
        title: expense.payload['description'] as String? ?? 'Despesa',
        subtitle: 'Pagamento',
        value: _amount(expense),
        color: AppColors.red,
      ));
    }
  }
  for (final debt in store.records(EntityTypes.debt)) {
    final purchase = DateTime.tryParse(debt.payload['purchaseDate'] as String? ?? '');
    final installments = (debt.payload['installments'] as num? ?? 1).toInt();
    if (purchase == null || debt.payload['status'] == 'Quitada') continue;
    final current = FinanceUtils.installmentNumber(purchaseDate: purchase, month: month);
    if (current < 1 || current > installments) continue;
    final card = store.byId(debt.payload['cardId'] as String? ?? '');
    final day = (card?.payload['dueDay'] as num? ?? purchase.day).toInt();
    events.add(_FinanceEvent(
      day: day,
      title: debt.payload['description'] as String? ?? 'Parcela',
      subtitle: 'Parcela $current/$installments',
      value: FinanceUtils.installmentValue(
        (debt.payload['total'] as num? ?? 0).toDouble(),
        installments,
      ),
      color: AppColors.orange,
    ));
  }
  for (final loan in store.records(EntityTypes.loan)) {
    final start = DateTime.tryParse(loan.payload['startDate'] as String? ?? '');
    final installments = (loan.payload['installments'] as num? ?? 1).toInt();
    if (start == null || loan.payload['status'] == 'Quitado') continue;
    final current = FinanceUtils.installmentNumber(purchaseDate: start, month: month);
    if (current < 1 || current > installments) continue;
    events.add(_FinanceEvent(
      day: (loan.payload['dueDay'] as num? ?? 1).toInt(),
      title: loan.payload['description'] as String? ?? 'Empréstimo',
      subtitle: 'Empréstimo $current/$installments',
      value: (loan.payload['monthlyPayment'] as num? ?? 0).toDouble(),
      color: AppColors.blue,
    ));
  }
  events.sort((a, b) => a.day.compareTo(b.day));
  return events;
}

String _formatDate(String? value) {
  final date = DateTime.tryParse(value ?? '');
  return date == null ? 'Sem data' : DateFormat('dd/MM/yyyy').format(date);
}
