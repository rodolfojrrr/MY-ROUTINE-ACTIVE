'use client';

/* eslint-disable @next/next/no-img-element */

import {
  ArrowDownLeft,
  ArrowLeft,
  ArrowRightLeft,
  ArrowUpRight,
  BarChart3,
  Bell,
  Building2,
  CalendarDays,
  Camera,
  Check,
  CheckCircle2,
  ChevronLeft,
  ChevronRight,
  CircleDollarSign,
  CreditCard,
  Download,
  Edit3,
  FileText,
  Landmark,
  ListChecks,
  MoreHorizontal,
  PiggyBank,
  Plus,
  ReceiptText,
  Search,
  ShieldCheck,
  Target,
  Trash2,
  TrendingDown,
  TrendingUp,
  Upload,
  WalletCards,
  X,
  type LucideIcon,
} from 'lucide-react';
import {
  useMemo,
  useState,
  type Dispatch,
  type FormEvent,
  type SetStateAction,
} from 'react';
import {
  uid,
  type Account,
  type AccountTransaction,
  type AppState,
  type CardPurchase,
  type FinanceCard,
  type FinanceDebt,
  type RecurringExpense,
  type RecurringIncome,
  type StudyAttachment,
} from '../lib/app-data';
import {
  cardInstallments,
  dateInMonth,
  debtInstallments,
  financeMonthKey,
  monthFromKey,
  shiftMonthKey,
  type GeneratedInstallment,
} from '../lib/finance-utils';

type FinanceTab = 'overview' | 'incomes' | 'expenses' | 'accounts' | 'cards' | 'more';
type FinanceEditorKind = 'recurringIncome' | 'income' | 'recurringExpense' | 'expense' | 'account' | 'transaction' | 'transfer' | 'card' | 'purchase' | 'debt' | 'budget' | 'investment' | 'category' | 'receipt';
type FinanceEditor = { kind: FinanceEditorKind; id?: string; cardId?: string; defaults?: Record<string, string | number> };

type FinanceModuleProps = {
  state: AppState;
  setState: Dispatch<SetStateAction<AppState>>;
  openHome: () => void;
  notify: (message: string) => void;
};

type Obligation = {
  id: string;
  source: 'expense' | 'recurring' | 'card' | 'debt';
  sourceId: string;
  description: string;
  category: string;
  amount: number;
  dueDate: string;
  paid: boolean;
  typeLabel: string;
  installment?: GeneratedInstallment;
};

const money = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });
const dateFormatter = new Intl.DateTimeFormat('pt-BR', { day: '2-digit', month: 'short', year: 'numeric' });
const monthFormatter = new Intl.DateTimeFormat('pt-BR', { month: 'long', year: 'numeric' });

const financeTabs: { id: FinanceTab; label: string; icon: LucideIcon }[] = [
  { id: 'overview', label: 'Visão geral', icon: BarChart3 },
  { id: 'incomes', label: 'Rendas', icon: Plus },
  { id: 'expenses', label: 'Despesas', icon: TrendingDown },
  { id: 'accounts', label: 'Contas', icon: Landmark },
  { id: 'cards', label: 'Cartões', icon: CreditCard },
  { id: 'more', label: 'Mais', icon: MoreHorizontal },
];

function localDateKey(date = new Date()) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return year + '-' + month + '-' + day;
}

function formatDate(value: string) {
  return value ? dateFormatter.format(new Date(value + 'T12:00:00')) : 'Sem data';
}

function monthTitle(value: string) {
  return monthFormatter.format(monthFromKey(value));
}

function updateFinance(setState: Dispatch<SetStateAction<AppState>>, updater: (finance: AppState['finance']) => AppState['finance']) {
  setState(current => ({ ...current, finance: updater(current.finance) }));
}

function applyAccountTransaction(accounts: Account[], transaction: AccountTransaction, direction: 1 | -1) {
  return accounts.map(account => {
    if (transaction.kind === 'income' && account.id === transaction.accountId) return { ...account, balance: account.balance + transaction.amount * direction };
    if (transaction.kind === 'expense' && account.id === transaction.accountId) return { ...account, balance: account.balance - transaction.amount * direction };
    if (transaction.kind === 'transfer' && account.id === transaction.accountId) return { ...account, balance: account.balance - transaction.amount * direction };
    if (transaction.kind === 'transfer' && account.id === transaction.destinationAccountId) return { ...account, balance: account.balance + transaction.amount * direction };
    return account;
  });
}

function activeInMonth(item: { active: boolean; startMonth: string; endMonth: string }, month: string) {
  return item.active && (!item.startMonth || item.startMonth <= month) && (!item.endMonth || item.endMonth >= month);
}

function daysUntil(value: string) {
  const due = new Date(value + 'T12:00:00').getTime();
  const today = new Date(localDateKey() + 'T12:00:00').getTime();
  return Math.ceil((due - today) / 86400000);
}

function installmentLabel(installment: GeneratedInstallment) {
  return installment.index + '/' + installment.count;
}

function safePercent(value: number, total: number) {
  return total > 0 ? Math.min(100, Math.max(0, Math.round(value / total * 100))) : 0;
}

function categoryColor(state: AppState, name: string) {
  return state.finance.categories.find(item => item.name === name)?.color ?? '#64748b';
}

export function FinanceModule({ state, setState, openHome, notify }: FinanceModuleProps) {
  const [tab, setTab] = useState<FinanceTab>('overview');
  const [selectedMonth, setSelectedMonth] = useState(financeMonthKey());
  const [editor, setEditor] = useState<FinanceEditor | null>(null);
  const [selectedCardId, setSelectedCardId] = useState(() => state.finance.cards[0]?.id ?? '');
  const [receiptAttachment, setReceiptAttachment] = useState<StudyAttachment | null>(null);
  const [uploading, setUploading] = useState(false);
  const [search, setSearch] = useState('');
  const [expenseFilter, setExpenseFilter] = useState('all');

  const recurringIncomes = state.finance.recurringIncomes.filter(item => activeInMonth(item, selectedMonth));
  const monthIncomes = state.finance.incomes.filter(item => item.date.startsWith(selectedMonth));
  const recurringExpenses = state.finance.recurringExpenses.filter(item => activeInMonth(item, selectedMonth));
  const monthExpenses = state.finance.expenses.filter(item => item.dueDate.startsWith(selectedMonth));

  const cardObligations = useMemo(() => state.finance.cardPurchases.flatMap(purchase => {
    const card = state.finance.cards.find(item => item.id === purchase.cardId);
    if (!card) return [];
    return cardInstallments(purchase, card).filter(item => item.month === selectedMonth).map(item => ({
      id: 'card-' + purchase.id + '-' + item.month,
      source: 'card' as const,
      sourceId: purchase.id,
      description: purchase.description,
      category: purchase.category || 'Cartão',
      amount: item.amount,
      dueDate: item.dueDate,
      paid: item.paid,
      typeLabel: 'Cartão · ' + installmentLabel(item),
      installment: item,
    }));
  }), [state.finance.cardPurchases, state.finance.cards, selectedMonth]);

  const debtObligations = useMemo(() => state.finance.debts.filter(debt => debt.active).flatMap(debt => debtInstallments(debt).filter(item => item.month === selectedMonth).map(item => ({
    id: 'debt-' + debt.id + '-' + item.month,
    source: 'debt' as const,
    sourceId: debt.id,
    description: debt.name,
    category: debt.kind,
    amount: item.amount,
    dueDate: item.dueDate,
    paid: item.paid,
    typeLabel: debt.kind + ' · ' + installmentLabel(item),
    installment: item,
  }))), [state.finance.debts, selectedMonth]);

  const obligations: Obligation[] = [
    ...monthExpenses.map(item => ({ id: item.id, source: 'expense' as const, sourceId: item.id, description: item.description, category: item.category, amount: item.amount, dueDate: item.dueDate, paid: item.paid, typeLabel: item.paymentMethod || 'Avulsa' })),
    ...recurringExpenses.map(item => ({ id: 'recurring-' + item.id, source: 'recurring' as const, sourceId: item.id, description: item.description, category: item.category, amount: item.amount, dueDate: dateInMonth(selectedMonth, item.day), paid: item.paidMonths.includes(selectedMonth), typeLabel: 'Fixa mensal' })),
    ...cardObligations,
    ...debtObligations,
  ].sort((a, b) => a.dueDate.localeCompare(b.dueDate));

  const predictedIncome = recurringIncomes.reduce((sum, item) => sum + item.amount, 0) + monthIncomes.reduce((sum, item) => sum + item.amount, 0);
  const receivedIncome = recurringIncomes.filter(item => item.receivedMonths.includes(selectedMonth)).reduce((sum, item) => sum + item.amount, 0) + monthIncomes.filter(item => item.received).reduce((sum, item) => sum + item.amount, 0);
  const predictedExpense = obligations.reduce((sum, item) => sum + item.amount, 0);
  const paidExpense = obligations.filter(item => item.paid).reduce((sum, item) => sum + item.amount, 0);
  const pendingCount = recurringIncomes.filter(item => !item.receivedMonths.includes(selectedMonth)).length + monthIncomes.filter(item => !item.received).length + obligations.filter(item => !item.paid).length;
  const accountTotal = state.finance.accounts.filter(item => item.includeInTotal).reduce((sum, item) => sum + item.balance, 0);
  const selectedCard = state.finance.cards.find(item => item.id === selectedCardId) ?? state.finance.cards[0];
  const selectedCardPurchases = selectedCard ? state.finance.cardPurchases.filter(item => item.cardId === selectedCard.id) : [];
  const selectedInvoice = selectedCard ? cardObligations.filter(item => state.finance.cardPurchases.find(purchase => purchase.id === item.sourceId)?.cardId === selectedCard.id) : [];
  const selectedInvoiceTotal = selectedInvoice.reduce((sum, item) => sum + item.amount, 0);
  const categoryTotals = obligations.reduce<Record<string, number>>((result, item) => ({ ...result, [item.category]: (result[item.category] ?? 0) + item.amount }), {});

  function switchTab(next: FinanceTab) {
    setTab(next);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  function openEditor(kind: FinanceEditorKind, id?: string, cardId?: string, defaults?: Record<string, string | number>) {
    setEditor({ kind, id, cardId, defaults });
    let attachment: StudyAttachment | null = null;
    if (kind === 'income') attachment = state.finance.incomes.find(item => item.id === id)?.attachment ?? null;
    if (kind === 'expense') attachment = state.finance.expenses.find(item => item.id === id)?.attachment ?? null;
    if (kind === 'purchase') attachment = state.finance.cardPurchases.find(item => item.id === id)?.attachment ?? null;
    setReceiptAttachment(attachment);
  }

  function closeEditor() {
    setEditor(null);
    setReceiptAttachment(null);
  }

  async function uploadReceipt(file: File | undefined) {
    if (!file) return;
    setUploading(true);
    try {
      const form = new FormData();
      form.append('file', file);
      form.append('scope', 'finance');
      const response = await fetch('/api/uploads', { method: 'POST', body: form });
      const result = await response.json() as { attachment?: StudyAttachment; error?: string };
      if (!response.ok || !result.attachment) throw new Error(result.error ?? 'Falha ao enviar comprovante.');
      setReceiptAttachment(result.attachment);
      notify('Comprovante anexado. Confirme os dados do lançamento.');
    } catch (error) {
      notify(error instanceof Error ? error.message : 'Falha ao enviar comprovante.');
    } finally {
      setUploading(false);
    }
  }

  function saveEditor(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!editor) return;
    const form = new FormData(event.currentTarget);
    const text = (name: string) => String(form.get(name) ?? '').trim();
    const number = (name: string) => Number(form.get(name) ?? 0);
    if (editor.kind === 'transfer' && text('accountId') === text('destinationAccountId')) {
      notify('Escolha contas diferentes para realizar a transferência.');
      return;
    }

    updateFinance(setState, finance => {
      if (editor.kind === 'recurringIncome') {
        const previous = finance.recurringIncomes.find(item => item.id === editor.id);
        const next: RecurringIncome = {
          id: editor.id ?? uid('income-monthly'), description: text('description'), amount: number('amount'), day: Math.min(31, Math.max(1, number('day'))),
          category: text('category'), accountId: text('accountId'), active: form.get('active') === 'on',
          startMonth: text('startMonth'), endMonth: text('endMonth'), receivedMonths: previous?.receivedMonths ?? [],
        };
        return { ...finance, recurringIncomes: previous ? finance.recurringIncomes.map(item => item.id === editor.id ? next : item) : [...finance.recurringIncomes, next] };
      }
      if (editor.kind === 'income') {
        const previous = finance.incomes.find(item => item.id === editor.id);
        const next = {
          id: editor.id ?? uid('income'), description: text('description'), amount: number('amount'), date: text('date'),
          category: text('category'), accountId: text('accountId'), notes: text('notes'), attachment: receiptAttachment,
          received: previous?.received ?? false,
        };
        return { ...finance, incomes: previous ? finance.incomes.map(item => item.id === editor.id ? next : item) : [...finance.incomes, next] };
      }
      if (editor.kind === 'recurringExpense') {
        const previous = finance.recurringExpenses.find(item => item.id === editor.id);
        const next: RecurringExpense = {
          id: editor.id ?? uid('expense-monthly'), description: text('description'), category: text('category'), amount: number('amount'),
          day: Math.min(31, Math.max(1, number('day'))), accountId: text('accountId'), active: form.get('active') === 'on',
          startMonth: text('startMonth'), endMonth: text('endMonth'), paidMonths: previous?.paidMonths ?? [], notes: text('notes'),
        };
        return { ...finance, recurringExpenses: previous ? finance.recurringExpenses.map(item => item.id === editor.id ? next : item) : [...finance.recurringExpenses, next] };
      }
      if (editor.kind === 'expense' || editor.kind === 'receipt') {
        const previous = finance.expenses.find(item => item.id === editor.id);
        const next = {
          id: editor.id ?? uid('expense'), description: text('description'), category: text('category'), amount: number('amount'),
          dueDate: text('dueDate'), accountId: text('accountId'), paymentMethod: text('paymentMethod'), notes: text('notes'),
          attachment: receiptAttachment, paidAt: previous?.paidAt ?? null, paid: previous?.paid ?? false,
        };
        return { ...finance, expenses: previous ? finance.expenses.map(item => item.id === editor.id ? next : item) : [...finance.expenses, next] };
      }
      if (editor.kind === 'account') {
        const previous = finance.accounts.find(item => item.id === editor.id);
        const next: Account = {
          id: editor.id ?? uid('account'), name: text('name'), institution: text('institution'), kind: text('kind') as Account['kind'],
          balance: number('balance'), color: text('color') || '#10b981', includeInTotal: form.get('includeInTotal') === 'on',
        };
        return { ...finance, accounts: previous ? finance.accounts.map(item => item.id === editor.id ? next : item) : [...finance.accounts, next] };
      }
      if (editor.kind === 'transaction') {
        const previous = finance.accountTransactions.find(item => item.id === editor.id);
        const accountId = text('accountId');
        const amount = number('amount');
        const kind = text('kind') as 'income' | 'expense';
        const transaction: AccountTransaction = { id: editor.id ?? uid('transaction'), kind, accountId, destinationAccountId: '', description: text('description'), amount, date: text('date'), notes: text('notes') };
        const revertedAccounts = previous ? applyAccountTransaction(finance.accounts, previous, -1) : finance.accounts;
        return {
          ...finance,
          accountTransactions: previous ? finance.accountTransactions.map(item => item.id === editor.id ? transaction : item) : [transaction, ...finance.accountTransactions],
          accounts: applyAccountTransaction(revertedAccounts, transaction, 1),
        };
      }
      if (editor.kind === 'transfer') {
        const previous = finance.accountTransactions.find(item => item.id === editor.id);
        const accountId = text('accountId');
        const destinationAccountId = text('destinationAccountId');
        const amount = number('amount');
        const transaction: AccountTransaction = { id: editor.id ?? uid('transfer'), kind: 'transfer', accountId, destinationAccountId, description: text('description') || 'Transferência', amount, date: text('date'), notes: text('notes') };
        const revertedAccounts = previous ? applyAccountTransaction(finance.accounts, previous, -1) : finance.accounts;
        return {
          ...finance,
          accountTransactions: previous ? finance.accountTransactions.map(item => item.id === editor.id ? transaction : item) : [transaction, ...finance.accountTransactions],
          accounts: applyAccountTransaction(revertedAccounts, transaction, 1),
        };
      }
      if (editor.kind === 'card') {
        const previous = finance.cards.find(item => item.id === editor.id);
        const next: FinanceCard = {
          id: editor.id ?? uid('card'), bank: text('bank'), holder: text('holder'), brand: text('brand'), lastDigits: text('lastDigits').slice(-4),
          limit: number('limit'), closingDay: Math.min(31, Math.max(1, number('closingDay'))), dueDay: Math.min(31, Math.max(1, number('dueDay'))),
          color: text('color') || '#7454f6', active: form.get('active') === 'on',
        };
        return { ...finance, cards: previous ? finance.cards.map(item => item.id === editor.id ? next : item) : [...finance.cards, next] };
      }
      if (editor.kind === 'purchase') {
        const previous = finance.cardPurchases.find(item => item.id === editor.id);
        const next: CardPurchase = {
          id: editor.id ?? uid('purchase'), cardId: text('cardId'), description: text('description'), category: text('category'),
          totalAmount: number('totalAmount'), purchaseDate: text('purchaseDate'), installmentCount: Math.max(1, number('installmentCount')),
          paidInstallments: previous?.paidInstallments ?? [], notes: text('notes'), attachment: receiptAttachment,
        };
        return { ...finance, cardPurchases: previous ? finance.cardPurchases.map(item => item.id === editor.id ? next : item) : [next, ...finance.cardPurchases] };
      }
      if (editor.kind === 'debt') {
        const previous = finance.debts.find(item => item.id === editor.id);
        const next: FinanceDebt = {
          id: editor.id ?? uid('debt'), name: text('name'), kind: text('kind') as FinanceDebt['kind'], creditor: text('creditor'),
          totalAmount: number('totalAmount'), installmentAmount: number('installmentAmount'), installmentCount: Math.max(1, number('installmentCount')),
          startDate: text('startDate'), dueDay: Math.min(31, Math.max(1, number('dueDay'))), interestRate: number('interestRate'),
          accountId: text('accountId'), paidInstallments: previous?.paidInstallments ?? [], notes: text('notes'), active: form.get('active') === 'on',
        };
        return { ...finance, debts: previous ? finance.debts.map(item => item.id === editor.id ? next : item) : [next, ...finance.debts] };
      }
      if (editor.kind === 'budget') {
        const next = { id: editor.id ?? uid('budget'), category: text('category'), monthlyLimit: number('monthlyLimit'), alertPercent: number('alertPercent') || 80 };
        return { ...finance, budgets: editor.id ? finance.budgets.map(item => item.id === editor.id ? next : item) : [...finance.budgets, next] };
      }
      if (editor.kind === 'investment') {
        const next = { id: editor.id ?? uid('investment'), name: text('name'), kind: text('kind'), institution: text('institution'), currentValue: number('currentValue'), investedValue: number('investedValue'), monthlyContribution: number('monthlyContribution'), color: text('color') || '#14b8a6', updatedAt: new Date().toISOString() };
        return { ...finance, investments: editor.id ? finance.investments.map(item => item.id === editor.id ? next : item) : [...finance.investments, next] };
      }
      if (editor.kind === 'category') {
        const next = { id: editor.id ?? uid('category'), name: text('name'), kind: text('kind') as 'income' | 'expense', color: text('color') || '#64748b', bucket: text('bucket') as 'Necessidades' | 'Desejos' | 'Metas' };
        return { ...finance, categories: editor.id ? finance.categories.map(item => item.id === editor.id ? next : item) : [...finance.categories, next] };
      }
      return finance;
    });
    closeEditor();
    notify('Informação salva e sincronizada.');
  }

  function toggleRecurringIncome(item: RecurringIncome) {
    updateFinance(setState, finance => ({ ...finance, recurringIncomes: finance.recurringIncomes.map(income => income.id === item.id ? { ...income, receivedMonths: income.receivedMonths.includes(selectedMonth) ? income.receivedMonths.filter(month => month !== selectedMonth) : [...income.receivedMonths, selectedMonth] } : income) }));
  }

  function toggleIncome(id: string) {
    updateFinance(setState, finance => ({ ...finance, incomes: finance.incomes.map(item => item.id === id ? { ...item, received: !item.received } : item) }));
  }

  function toggleObligation(item: Obligation) {
    updateFinance(setState, finance => {
      if (item.source === 'expense') return { ...finance, expenses: finance.expenses.map(expense => expense.id === item.sourceId ? { ...expense, paid: !expense.paid, paidAt: expense.paid ? null : new Date().toISOString() } : expense) };
      if (item.source === 'recurring') return { ...finance, recurringExpenses: finance.recurringExpenses.map(expense => expense.id === item.sourceId ? { ...expense, paidMonths: expense.paidMonths.includes(selectedMonth) ? expense.paidMonths.filter(month => month !== selectedMonth) : [...expense.paidMonths, selectedMonth] } : expense) };
      if (item.source === 'card') return { ...finance, cardPurchases: finance.cardPurchases.map(purchase => purchase.id === item.sourceId ? { ...purchase, paidInstallments: purchase.paidInstallments.includes(selectedMonth) ? purchase.paidInstallments.filter(month => month !== selectedMonth) : [...purchase.paidInstallments, selectedMonth] } : purchase) };
      return { ...finance, debts: finance.debts.map(debt => debt.id === item.sourceId ? { ...debt, paidInstallments: debt.paidInstallments.includes(selectedMonth) ? debt.paidInstallments.filter(month => month !== selectedMonth) : [...debt.paidInstallments, selectedMonth] } : debt) };
    });
  }

  function editObligation(item: Obligation) {
    if (item.source === 'expense') openEditor('expense', item.sourceId);
    else if (item.source === 'recurring') openEditor('recurringExpense', item.sourceId);
    else if (item.source === 'card') openEditor('purchase', item.sourceId);
    else openEditor('debt', item.sourceId);
  }

  function deleteItem(kind: FinanceEditorKind, id: string) {
    if (!window.confirm('Excluir este item?')) return;
    updateFinance(setState, finance => {
      if (kind === 'recurringIncome') return { ...finance, recurringIncomes: finance.recurringIncomes.filter(item => item.id !== id) };
      if (kind === 'income') return { ...finance, incomes: finance.incomes.filter(item => item.id !== id) };
      if (kind === 'recurringExpense') return { ...finance, recurringExpenses: finance.recurringExpenses.filter(item => item.id !== id) };
      if (kind === 'expense') return { ...finance, expenses: finance.expenses.filter(item => item.id !== id) };
      if (kind === 'account') return { ...finance, accounts: finance.accounts.filter(item => item.id !== id) };
      if (kind === 'transaction' || kind === 'transfer') {
        const transaction = finance.accountTransactions.find(item => item.id === id);
        return transaction ? { ...finance, accountTransactions: finance.accountTransactions.filter(item => item.id !== id), accounts: applyAccountTransaction(finance.accounts, transaction, -1) } : finance;
      }
      if (kind === 'card') return { ...finance, cards: finance.cards.filter(item => item.id !== id), cardPurchases: finance.cardPurchases.filter(item => item.cardId !== id) };
      if (kind === 'purchase') return { ...finance, cardPurchases: finance.cardPurchases.filter(item => item.id !== id) };
      if (kind === 'debt') return { ...finance, debts: finance.debts.filter(item => item.id !== id) };
      if (kind === 'budget') return { ...finance, budgets: finance.budgets.filter(item => item.id !== id) };
      if (kind === 'investment') return { ...finance, investments: finance.investments.filter(item => item.id !== id) };
      if (kind === 'category') return { ...finance, categories: finance.categories.filter(item => item.id !== id) };
      return finance;
    });
    closeEditor();
    notify('Item excluído.');
  }

  function exportCsv() {
    const rows = [
      ['Mês', 'Tipo', 'Descrição', 'Categoria', 'Valor', 'Status'],
      ...recurringIncomes.map(item => [selectedMonth, 'Renda mensal', item.description, item.category, item.amount.toFixed(2), item.receivedMonths.includes(selectedMonth) ? 'Recebido' : 'Pendente']),
      ...monthIncomes.map(item => [selectedMonth, 'Renda avulsa', item.description, item.category, item.amount.toFixed(2), item.received ? 'Recebido' : 'Pendente']),
      ...obligations.map(item => [selectedMonth, item.typeLabel, item.description, item.category, (-item.amount).toFixed(2), item.paid ? 'Pago' : 'Pendente']),
    ];
    const csv = rows.map(row => row.map(value => '"' + String(value).replaceAll('"', '""') + '"').join(';')).join('\n');
    const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'my-routine-financas-' + selectedMonth + '.csv';
    link.click();
    URL.revokeObjectURL(url);
    notify('Planilha financeira exportada.');
  }

  function printReport() {
    const report = window.open('', '_blank', 'width=900,height=700');
    if (!report) return notify('Permita a abertura da janela para gerar o PDF.');
    const escape = (value: string) => value.replace(/[&<>"']/g, character => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;' }[character] ?? character));
    report.document.title = 'Relatório financeiro ' + selectedMonth;
    report.document.body.innerHTML = '<main style="font-family:Arial,sans-serif;max-width:850px;margin:40px auto;color:#172033"><h1>My Routine Active</h1><h2>Relatório financeiro · ' + escape(monthTitle(selectedMonth)) + '</h2><p>Renda prevista: <b>' + money.format(predictedIncome) + '</b> · Despesas previstas: <b>' + money.format(predictedExpense) + '</b> · Saldo: <b>' + money.format(predictedIncome - predictedExpense) + '</b></p><hr/><h3>Lançamentos</h3>' + obligations.map(item => '<div style="display:flex;justify-content:space-between;padding:10px 0;border-bottom:1px solid #ddd"><span>' + escape(item.description) + '<small style="display:block;color:#667">' + escape(item.typeLabel + ' · ' + formatDate(item.dueDate)) + '</small></span><b>' + money.format(item.amount) + '</b></div>').join('') + '<p style="margin-top:30px;color:#667;font-size:12px">Gerado em ' + new Date().toLocaleString('pt-BR') + '</p></main>';
    report.setTimeout(() => report.print(), 350);
  }

  const filteredObligations = obligations.filter(item => (expenseFilter === 'all' || item.source === expenseFilter) && (item.description + ' ' + item.category).toLowerCase().includes(search.toLowerCase()));

  return (
    <div className="module-view financex-view">
      <header className="financex-heading"><div><button className="back-button" onClick={openHome}><ArrowLeft size={20} /></button><span><small>Organização financeira</small><h1>Finanças</h1><p>Rendas, contas, cartões, parcelas e metas com clareza.</p></span></div><aside><button className="secondary-button" onClick={() => openEditor('receipt')}><Camera size={18} /> Ler comprovante</button><button className="finance-primary" onClick={() => openEditor('expense')}><Plus size={18} /> Novo lançamento</button></aside></header>

      <nav className="financex-tabs">{financeTabs.map(item => { const Icon = item.icon; return <button key={item.id} className={tab === item.id ? 'active' : ''} onClick={() => switchTab(item.id)}><Icon size={18} /><span>{item.label}</span></button>; })}</nav>

      {(tab === 'overview' || tab === 'incomes' || tab === 'expenses' || tab === 'cards') && <div className="financex-month"><button onClick={() => setSelectedMonth(value => shiftMonthKey(value, -1))}><ChevronLeft size={19} /></button><span><CalendarDays size={18} />{monthTitle(selectedMonth)}</span><button onClick={() => setSelectedMonth(value => shiftMonthKey(value, 1))}><ChevronRight size={19} /></button><button className="financex-alert"><Bell size={18} /><b>{pendingCount}</b></button></div>}

      {tab === 'overview' && <div className="financex-stack"><section className="financex-stats"><article><small>Renda prevista</small><strong>{money.format(predictedIncome)}</strong><em>Recebido: {money.format(receivedIncome)}</em></article><article><small>Despesas previstas</small><strong>{money.format(predictedExpense)}</strong><em>Pago: {money.format(paidExpense)}</em></article><article className="positive"><small>Saldo previsto</small><strong>{money.format(predictedIncome - predictedExpense)}</strong><em>Saldo real: {money.format(receivedIncome - paidExpense)}</em></article><article><small>Pendências</small><strong>{pendingCount}</strong><em>lançamentos no mês</em></article></section><section className="financex-panel"><div className="financex-section-head"><div><h2>Andamento do mês</h2><p>Veja claramente quanto já entrou ou foi pago e o que ainda falta.</p></div></div><div className="financex-progress-panels"><ProgressPanel kind="income" title="Recebimento das rendas" current={receivedIncome} total={predictedIncome} firstLabel="Recebido" secondLabel="A receber" /><ProgressPanel kind="expense" title="Pagamento das despesas" current={paidExpense} total={predictedExpense} firstLabel="Pago" secondLabel="A pagar" /></div></section><section className="financex-dashboard-grid"><article className="financex-panel"><div className="financex-section-head"><div><small>PRÓXIMOS VENCIMENTOS</small><h2>Calendário financeiro</h2></div><button onClick={() => switchTab('expenses')}>Ver todos <ChevronRight size={16} /></button></div><div className="financex-due-list">{obligations.filter(item => !item.paid).slice(0,6).map(item => <ObligationRow key={item.id} item={item} onToggle={() => toggleObligation(item)} onEdit={() => editObligation(item)} />)}{!obligations.some(item => !item.paid) && <FinanceEmpty icon={<CheckCircle2 size={27} />} title="Tudo em dia" text="Nenhum pagamento pendente neste mês." action="Adicionar despesa" onAction={() => openEditor('expense')} />}</div></article><article className="financex-panel"><div className="financex-section-head"><div><small>DESPESAS POR CATEGORIA</small><h2>Distribuição do mês</h2></div><BarChart3 size={20} /></div><CategoryBreakdown totals={categoryTotals} total={predictedExpense} state={state} /></article></section><section className="financex-dashboard-grid"><article className="financex-panel financex-balance-card"><div className="financex-section-head"><div><small>PATRIMÔNIO DISPONÍVEL</small><h2>Contas e carteiras</h2></div><button onClick={() => switchTab('accounts')}>Gerenciar <ChevronRight size={16} /></button></div><strong>{money.format(accountTotal)}</strong><div>{state.finance.accounts.slice(0,4).map(account => <span key={account.id}><i style={{ background: account.color }} /><small>{account.name}</small><b>{money.format(account.balance)}</b></span>)}</div></article><article className="financex-panel"><div className="financex-section-head"><div><small>PLANEJAMENTO</small><h2>Regra {state.finance.planning.needsPercent}/{state.finance.planning.wantsPercent}/{state.finance.planning.goalsPercent}</h2></div><Target size={20} /></div><PlanningBars state={state} income={predictedIncome} totals={categoryTotals} /><button className="financex-wide-link" onClick={() => switchTab('more')}>Abrir planejamento completo <ChevronRight size={16} /></button></article></section></div>}

      {tab === 'incomes' && <div className="financex-stack"><FinanceIntro eyebrow="Entradas" title="Rendas" text="Salários fixos, extras e outros recebimentos por mês." actions={<><button className="secondary-button" onClick={() => openEditor('income')}><Plus size={17} /> Renda avulsa</button><button className="finance-primary" onClick={() => openEditor('recurringIncome')}><Plus size={17} /> Renda mensal</button></>} /><section className="financex-summary-strip"><span><TrendingUp size={21} /><div><small>Previsto</small><strong>{money.format(predictedIncome)}</strong></div></span><span><CheckCircle2 size={21} /><div><small>Recebido</small><strong>{money.format(receivedIncome)}</strong></div></span><span><CircleDollarSign size={21} /><div><small>A receber</small><strong>{money.format(predictedIncome - receivedIncome)}</strong></div></span></section><section className="financex-table-card"><header><span>STATUS</span><span>DESCRIÇÃO</span><span>DATA PREVISTA</span><span>CONTA</span><span>VALOR</span><span /></header>{recurringIncomes.map(item => { const received = item.receivedMonths.includes(selectedMonth); return <div key={item.id}><button className={received ? 'paid' : ''} onClick={() => toggleRecurringIncome(item)}>{received && <Check size={15} />}</button><span><strong>{item.description}</strong><small>{item.category} · renda mensal</small></span><span>Todo dia {item.day}<small>independente do mês</small></span><span>{state.finance.accounts.find(account => account.id === item.accountId)?.name || 'Não definida'}</span><b>{money.format(item.amount)}</b><button onClick={() => openEditor('recurringIncome', item.id)}><Edit3 size={16} /></button></div>; })}{monthIncomes.map(item => <div key={item.id}><button className={item.received ? 'paid' : ''} onClick={() => toggleIncome(item.id)}>{item.received && <Check size={15} />}</button><span><strong>{item.description}</strong><small>{item.category} · avulsa</small></span><span>{formatDate(item.date)}</span><span>{state.finance.accounts.find(account => account.id === item.accountId)?.name || 'Não definida'}</span><b>{money.format(item.amount)}</b><button onClick={() => openEditor('income', item.id)}><Edit3 size={16} /></button></div>)}{!recurringIncomes.length && !monthIncomes.length && <FinanceEmpty icon={<TrendingUp size={29} />} title="Nenhuma renda neste mês" text="Cadastre seu salário fixo ou uma renda avulsa." action="Nova renda" onAction={() => openEditor('recurringIncome')} />}</section></div>}

      {tab === 'expenses' && <div className="financex-stack"><FinanceIntro eyebrow="Saídas" title="Despesas" text="Gastos fixos, avulsos, cartões, dívidas e parcelamentos em uma agenda única." actions={<><button className="secondary-button" onClick={() => openEditor('recurringExpense')}><Plus size={17} /> Despesa fixa</button><button className="finance-primary" onClick={() => openEditor('expense')}><Plus size={17} /> Nova despesa</button></>} /><div className="financex-legend"><span><i className="paid" /> Pago</span><span><i className="soon" /> Vence em até 7 dias</span><span><i className="late" /> Vencido</span></div><div className="financex-filterbar"><label><Search size={17} /><input value={search} onChange={event => setSearch(event.target.value)} placeholder="Buscar despesa..." /></label><select value={expenseFilter} onChange={event => setExpenseFilter(event.target.value)}><option value="all">Todos os tipos</option><option value="expense">Avulsas</option><option value="recurring">Fixas</option><option value="card">Cartões</option><option value="debt">Dívidas</option></select></div><section className="financex-expense-list"><header><span>STATUS</span><span>DESCRIÇÃO</span><span>VENCIMENTO</span><span>TIPO</span><span>VALOR</span><span /></header>{filteredObligations.map(item => <ObligationRow key={item.id} item={item} onToggle={() => toggleObligation(item)} onEdit={() => editObligation(item)} table />)}{!filteredObligations.length && <FinanceEmpty icon={<TrendingDown size={29} />} title="Nenhuma despesa neste filtro" text="Adicione uma conta ou altere os filtros." action="Nova despesa" onAction={() => openEditor('expense')} />}</section></div>}

      {tab === 'accounts' && <div className="financex-stack"><FinanceIntro eyebrow="Patrimônio" title="Contas e carteiras" text="Organize bancos, carteira, dinheiro e transferências." actions={<><button className="secondary-button" onClick={() => openEditor('transfer')}><ArrowRightLeft size={17} /> Transferir</button><button className="finance-primary" onClick={() => openEditor('account')}><Plus size={17} /> Nova conta</button></>} /><section className="financex-account-total"><span><WalletCards size={28} /></span><div><small>SALDO TOTAL DISPONÍVEL</small><strong>{money.format(accountTotal)}</strong><p>{state.finance.accounts.length} contas cadastradas</p></div><ShieldCheck size={24} /></section><section className="financex-account-grid">{state.finance.accounts.map(account => <article key={account.id} style={{ '--account-color': account.color } as React.CSSProperties}><i /><header><span><Landmark size={22} /></span><button onClick={() => openEditor('account', account.id)}><Edit3 size={16} /></button></header><small>{account.kind}</small><h2>{account.name}</h2><p>{account.institution}</p><strong>{money.format(account.balance)}</strong><footer><button onClick={() => openEditor('transaction', undefined, undefined, { accountId: account.id, kind: 'income' })}><ArrowDownLeft size={16} /> Entrada</button><button onClick={() => openEditor('transaction', undefined, undefined, { accountId: account.id, kind: 'expense' })}><ArrowUpRight size={16} /> Saída</button></footer></article>)}{!state.finance.accounts.length && <FinanceEmpty icon={<Landmark size={31} />} title="Nenhuma conta cadastrada" text="Adicione bancos, carteira ou dinheiro para controlar os saldos." action="Nova conta" onAction={() => openEditor('account')} />}</section><section className="financex-panel"><div className="financex-section-head"><div><small>MOVIMENTAÇÕES</small><h2>Extrato das contas</h2></div><button onClick={() => openEditor('transaction')}><Plus size={16} /> Lançar</button></div><div className="financex-account-history">{state.finance.accountTransactions.slice(0,20).map(item => <span key={item.id}><i className={item.kind}>{item.kind === 'income' ? <ArrowDownLeft size={17} /> : item.kind === 'expense' ? <ArrowUpRight size={17} /> : <ArrowRightLeft size={17} />}</i><div><strong>{item.description}</strong><small>{formatDate(item.date)} · {state.finance.accounts.find(account => account.id === item.accountId)?.name || 'Conta removida'}{item.kind === 'transfer' ? ' → ' + (state.finance.accounts.find(account => account.id === item.destinationAccountId)?.name || 'Conta removida') : ''}</small></div><b className={item.kind}>{item.kind === 'expense' ? '− ' : item.kind === 'income' ? '+ ' : ''}{money.format(item.amount)}</b></span>)}{!state.finance.accountTransactions.length && <FinanceEmpty icon={<ArrowRightLeft size={27} />} title="Sem movimentações" text="Entradas, saídas e transferências aparecerão aqui." action="Lançar movimento" onAction={() => openEditor('transaction')} />}</div></section></div>}

      {tab === 'cards' && <div className="financex-stack"><FinanceIntro eyebrow="Crédito" title="Cartões" text="Faturas e compras parceladas pelo mês correto de cobrança." actions={<><button className="secondary-button" onClick={() => openEditor('purchase', undefined, selectedCard?.id)}><Plus size={17} /> Nova compra</button><button className="finance-primary" onClick={() => openEditor('card')}><Plus size={17} /> Novo cartão</button></>} /><section className="financex-card-grid">{state.finance.cards.map(card => { const purchases = state.finance.cardPurchases.filter(item => item.cardId === card.id); const used = purchases.flatMap(item => cardInstallments(item, card)).filter(item => !item.paid).reduce((sum,item) => sum + item.amount,0); return <article key={card.id} className={selectedCard?.id === card.id ? 'selected' : ''} style={{ '--card-color': card.color } as React.CSSProperties} onClick={() => setSelectedCardId(card.id)}><div className="financex-card-rings" /><header><span>{card.bank}</span><strong>{card.brand}</strong></header><h2>{card.holder}</h2><small>Limite disponível</small><b>{money.format(Math.max(0, card.limit - used))}</b><footer><span>•••• {card.lastDigits || '0000'}</span><button onClick={event => { event.stopPropagation(); openEditor('card', card.id); }}><Edit3 size={16} /> Editar</button></footer></article>; })}{!state.finance.cards.length && <FinanceEmpty icon={<CreditCard size={31} />} title="Nenhum cartão cadastrado" text="Cadastre fechamento, vencimento e limite para calcular as faturas." action="Novo cartão" onAction={() => openEditor('card')} />}</section>{selectedCard && <section className="financex-invoice" style={{ '--card-color': selectedCard.color } as React.CSSProperties}><header><div><small>FATURA DE {monthTitle(selectedMonth).toUpperCase()}</small><h2>{selectedCard.bank} · {selectedCard.brand}</h2><p>Fecha dia {selectedCard.closingDay} · vence dia {selectedCard.dueDay}</p></div><div><small>VALOR DA FATURA</small><strong>{money.format(selectedInvoiceTotal)}</strong><em>{selectedInvoice.filter(item => !item.paid).length} pendências</em></div></header><div className="financex-invoice-purchases">{selectedInvoice.map(item => <ObligationRow key={item.id} item={item} onToggle={() => toggleObligation(item)} onEdit={() => editObligation(item)} />)}{!selectedInvoice.length && <FinanceEmpty icon={<ReceiptText size={28} />} title="Fatura sem lançamentos" text="As parcelas calculadas para este mês aparecerão aqui." action="Nova compra" onAction={() => openEditor('purchase', undefined, selectedCard.id)} />}</div><footer><button onClick={() => openEditor('purchase', undefined, selectedCard.id)}><Plus size={17} /> Adicionar compra</button></footer></section>}<section className="financex-panel"><div className="financex-section-head"><div><small>COMPRAS E PARCELAS</small><h2>Calendário de término</h2></div><CalendarDays size={20} /></div><div className="financex-purchase-list">{selectedCardPurchases.map(purchase => { const schedule = selectedCard ? cardInstallments(purchase, selectedCard) : []; const next = schedule.find(item => !item.paid); const last = schedule.at(-1); return <button key={purchase.id} onClick={() => openEditor('purchase', purchase.id)}><span style={{ background: categoryColor(state, purchase.category) }}><ReceiptText size={18} /></span><div><strong>{purchase.description}</strong><small>Comprado em {formatDate(purchase.purchaseDate)} · {purchase.installmentCount}x de {money.format(schedule[0]?.amount ?? purchase.totalAmount)}</small></div><div><small>PRÓXIMA</small><strong>{next ? installmentLabel(next) + ' · ' + formatDate(next.dueDate) : 'Quitada'}</strong></div><div><small>TERMINA</small><strong>{last ? formatDate(last.dueDate) : '—'}</strong></div><ChevronRight size={17} /></button>; })}{!selectedCardPurchases.length && <FinanceEmpty icon={<CalendarDays size={27} />} title="Sem compras neste cartão" text="Cadastre uma compra para calcular automaticamente todas as parcelas." action="Nova compra" onAction={() => openEditor('purchase', undefined, selectedCard?.id)} />}</div></section></div>}

      {tab === 'more' && <div className="financex-stack"><FinanceIntro eyebrow="Planejamento e patrimônio" title="Mais ferramentas" text="Dívidas, empréstimos, limites, investimentos, categorias e relatórios." actions={<button className="finance-primary" onClick={() => openEditor('debt')}><Plus size={17} /> Nova dívida</button>} /><section className="financex-more-grid"><article className="financex-panel"><div className="financex-section-head"><div><small>DÍVIDAS E EMPRÉSTIMOS</small><h2>Parcelas em andamento</h2></div><button onClick={() => openEditor('debt')}><Plus size={16} /></button></div><div className="financex-debt-list">{state.finance.debts.map(debt => { const schedule = debtInstallments(debt); const paid = schedule.filter(item => item.paid).length; const next = schedule.find(item => !item.paid); return <button key={debt.id} onClick={() => openEditor('debt', debt.id)}><span><Building2 size={19} /></span><div><strong>{debt.name}</strong><small>{debt.creditor} · {paid}/{schedule.length} parcelas pagas</small><i><b style={{ width: safePercent(paid, schedule.length) + '%' }} /></i></div><aside><small>Próxima</small><strong>{next ? money.format(next.amount) : 'Quitada'}</strong><em>{next ? formatDate(next.dueDate) : ''}</em></aside></button>; })}{!state.finance.debts.length && <FinanceEmpty icon={<Building2 size={28} />} title="Nenhuma dívida cadastrada" text="Empréstimos e parcelamentos externos aparecerão aqui." action="Adicionar" onAction={() => openEditor('debt')} />}</div></article><article className="financex-panel"><div className="financex-section-head"><div><small>REGRA DE DISTRIBUIÇÃO</small><h2>{state.finance.planning.needsPercent}/{state.finance.planning.wantsPercent}/{state.finance.planning.goalsPercent}</h2></div><Target size={20} /></div><PlanningEditor state={state} setState={setState} income={predictedIncome} totals={categoryTotals} /></article></section><section className="financex-more-grid"><article className="financex-panel"><div className="financex-section-head"><div><small>ORÇAMENTOS</small><h2>Limites por categoria</h2></div><button onClick={() => openEditor('budget')}><Plus size={16} /></button></div><div className="financex-budget-list">{state.finance.budgets.map(budget => { const spent = categoryTotals[budget.category] ?? 0; const percent = safePercent(spent, budget.monthlyLimit); return <button key={budget.id} onClick={() => openEditor('budget', budget.id)}><header><span>{budget.category}</span><strong>{money.format(spent)} de {money.format(budget.monthlyLimit)}</strong></header><i><b className={percent >= budget.alertPercent ? 'alert' : ''} style={{ width: percent + '%' }} /></i><small>{percent}% utilizado · alerta em {budget.alertPercent}%</small></button>; })}{!state.finance.budgets.length && <FinanceEmpty icon={<Target size={27} />} title="Sem limites configurados" text="Crie orçamentos por categoria para receber alertas." action="Novo limite" onAction={() => openEditor('budget')} />}</div></article><article className="financex-panel"><div className="financex-section-head"><div><small>INVESTIMENTOS</small><h2>Patrimônio aplicado</h2></div><button onClick={() => openEditor('investment')}><Plus size={16} /></button></div><strong className="financex-investment-total">{money.format(state.finance.investments.reduce((sum,item) => sum + item.currentValue,0))}</strong><div className="financex-investment-list">{state.finance.investments.map(item => <button key={item.id} onClick={() => openEditor('investment', item.id)}><i style={{ background: item.color }} /><div><strong>{item.name}</strong><small>{item.kind} · {item.institution}</small></div><span><b>{money.format(item.currentValue)}</b><small>aporte {money.format(item.monthlyContribution)}/mês</small></span></button>)}{!state.finance.investments.length && <FinanceEmpty icon={<PiggyBank size={27} />} title="Sem investimentos" text="Acompanhe aportes e o valor atual do patrimônio." action="Adicionar" onAction={() => openEditor('investment')} />}</div></article></section><section className="financex-tools"><button onClick={printReport}><FileText size={22} /><span><strong>Relatório PDF</strong><small>Abra a versão pronta para salvar ou imprimir.</small></span><ChevronRight size={17} /></button><button onClick={exportCsv}><Download size={22} /><span><strong>Exportar planilha</strong><small>Baixe todos os lançamentos do mês em CSV.</small></span><ChevronRight size={17} /></button><button onClick={() => openEditor('category')}><ListChecks size={22} /><span><strong>Categorias</strong><small>Personalize nomes, cores e grupos.</small></span><ChevronRight size={17} /></button></section></div>}

      {tab === 'accounts' && state.finance.accountTransactions.length > 0 && <section className="financex-panel financex-edit-transactions"><div className="financex-section-head"><div><small>EDIÇÃO DO EXTRATO</small><h2>Ajustar ou excluir movimentações</h2></div><Edit3 size={18} /></div><div>{state.finance.accountTransactions.slice(0,30).map(item => <button key={item.id} onClick={() => openEditor(item.kind === 'transfer' ? 'transfer' : 'transaction', item.id)}><i className={item.kind}>{item.kind === 'income' ? <ArrowDownLeft size={16} /> : item.kind === 'expense' ? <ArrowUpRight size={16} /> : <ArrowRightLeft size={16} />}</i><span><strong>{item.description}</strong><small>{formatDate(item.date)} · {item.kind === 'income' ? 'Entrada' : item.kind === 'expense' ? 'Saída' : 'Transferência'}</small></span><b>{money.format(item.amount)}</b><Edit3 size={15} /></button>)}</div></section>}

      {tab === 'more' && <section className="financex-panel financex-category-panel"><div className="financex-section-head"><div><small>CATEGORIAS PERSONALIZÁVEIS</small><h2>Organização dos lançamentos</h2></div><button onClick={() => openEditor('category')}><Plus size={16} /> Nova</button></div><div className="financex-category-manager">{state.finance.categories.map(item => <button key={item.id} onClick={() => openEditor('category', item.id)}><i style={{ background: item.color }} /><span><strong>{item.name}</strong><small>{item.kind === 'income' ? 'Renda' : 'Despesa'} · {item.bucket}</small></span><Edit3 size={15} /></button>)}</div></section>}

      {editor && <FinanceEditorModal editor={editor} state={state} receiptAttachment={receiptAttachment} uploading={uploading} uploadReceipt={uploadReceipt} onClose={closeEditor} onSubmit={saveEditor} onDelete={editor.id ? () => deleteItem(editor.kind, editor.id as string) : undefined} />}
    </div>
  );
}

function FinanceIntro({ eyebrow, title, text, actions }: { eyebrow: string; title: string; text: string; actions?: React.ReactNode }) {
  return <header className="financex-intro"><div><small>{eyebrow}</small><h2>{title}</h2><p>{text}</p></div>{actions && <aside>{actions}</aside>}</header>;
}

function FinanceEmpty({ icon, title, text, action, onAction }: { icon: React.ReactNode; title: string; text: string; action: string; onAction: () => void }) {
  return <div className="financex-empty"><span>{icon}</span><h2>{title}</h2><p>{text}</p><button onClick={onAction}><Plus size={16} /> {action}</button></div>;
}

function ProgressPanel({ kind, title, current, total, firstLabel, secondLabel }: { kind: 'income' | 'expense'; title: string; current: number; total: number; firstLabel: string; secondLabel: string }) {
  const percent = safePercent(current, total);
  return <article className={kind}><header><strong>{title}</strong><b>{percent}%</b></header><p>{money.format(current)} de {money.format(total)}</p><div><span style={{ width: percent + '%' }} /></div><footer><span><small>{firstLabel}</small><strong>{money.format(current)}</strong></span><span><small>{secondLabel}</small><strong>{money.format(Math.max(0, total - current))}</strong></span></footer></article>;
}

function ObligationRow({ item, onToggle, onEdit, table = false }: { item: Obligation; onToggle: () => void; onEdit: () => void; table?: boolean }) {
  const days = daysUntil(item.dueDate);
  const status = item.paid ? 'paid' : days < 0 ? 'late' : days <= 7 ? 'soon' : 'pending';
  return <div className={'financex-obligation ' + status + (table ? ' table' : '')}><button onClick={onToggle}>{item.paid && <Check size={15} />}</button><span><strong>{item.description}</strong><small>{item.category}</small></span><span>{formatDate(item.dueDate)}<small>{item.paid ? 'Pago' : days < 0 ? Math.abs(days) + ' dias em atraso' : days === 0 ? 'Vence hoje' : 'em ' + days + ' dias'}</small></span>{table && <span>{item.typeLabel}</span>}<b>{money.format(item.amount)}</b><button onClick={onEdit}><Edit3 size={16} /></button></div>;
}

function CategoryBreakdown({ totals, total, state }: { totals: Record<string, number>; total: number; state: AppState }) {
  const rows = Object.entries(totals).sort((a,b) => b[1] - a[1]);
  return <div className="financex-category-list">{rows.map(([name,value]) => <span key={name}><i style={{ background: categoryColor(state, name) }} /><div><strong>{name}</strong><small>{safePercent(value,total)}% do total</small></div><b>{money.format(value)}</b></span>)}{!rows.length && <FinanceEmpty icon={<BarChart3 size={25} />} title="Nenhuma despesa registrada" text="A distribuição aparecerá com seus lançamentos." action="Tudo certo" onAction={() => undefined} />}</div>;
}

function PlanningBars({ state, income, totals }: { state: AppState; income: number; totals: Record<string, number> }) {
  const buckets = ['Necessidades','Desejos','Metas'] as const;
  const targets = [state.finance.planning.needsPercent,state.finance.planning.wantsPercent,state.finance.planning.goalsPercent];
  return <div className="financex-planning-bars">{buckets.map((bucket,index) => { const spent = Object.entries(totals).filter(([category]) => state.finance.categories.find(item => item.name === category)?.bucket === bucket).reduce((sum,row) => sum + row[1],0); const target = income * targets[index] / 100; return <span key={bucket}><header><strong>{bucket}</strong><small>{money.format(spent)} / {money.format(target)}</small></header><i><b style={{ width: safePercent(spent,target) + '%' }} /></i></span>; })}</div>;
}

function PlanningEditor({ state, setState, income, totals }: { state: AppState; setState: Dispatch<SetStateAction<AppState>>; income: number; totals: Record<string, number> }) {
  const plan = state.finance.planning;
  function update(key: keyof typeof plan, value: number) {
    updateFinance(setState, finance => ({ ...finance, planning: { ...finance.planning, [key]: value } }));
  }
  return <div className="financex-planning-editor"><PlanningBars state={state} income={income} totals={totals} /><label>Necessidades <span>{plan.needsPercent}%</span><input type="range" min="0" max="100" value={plan.needsPercent} onChange={event => update('needsPercent', Number(event.target.value))} /></label><label>Desejos <span>{plan.wantsPercent}%</span><input type="range" min="0" max="100" value={plan.wantsPercent} onChange={event => update('wantsPercent', Number(event.target.value))} /></label><label>Metas e investimentos <span>{plan.goalsPercent}%</span><input type="range" min="0" max="100" value={plan.goalsPercent} onChange={event => update('goalsPercent', Number(event.target.value))} /></label><small className={plan.needsPercent + plan.wantsPercent + plan.goalsPercent === 100 ? 'valid' : 'invalid'}>Total: {plan.needsPercent + plan.wantsPercent + plan.goalsPercent}% {plan.needsPercent + plan.wantsPercent + plan.goalsPercent === 100 ? '✓' : '· ajuste para 100%'}</small></div>;
}

type FinanceEditorModalProps = {
  editor: FinanceEditor;
  state: AppState;
  receiptAttachment: StudyAttachment | null;
  uploading: boolean;
  uploadReceipt: (file: File | undefined) => Promise<void>;
  onClose: () => void;
  onSubmit: (event: FormEvent<HTMLFormElement>) => void;
  onDelete?: () => void;
};

function FinanceEditorModal({ editor, state, receiptAttachment, uploading, uploadReceipt, onClose, onSubmit, onDelete }: FinanceEditorModalProps) {
  const recurringIncome = state.finance.recurringIncomes.find(item => item.id === editor.id);
  const income = state.finance.incomes.find(item => item.id === editor.id);
  const recurringExpense = state.finance.recurringExpenses.find(item => item.id === editor.id);
  const expense = state.finance.expenses.find(item => item.id === editor.id);
  const account = state.finance.accounts.find(item => item.id === editor.id);
  const transaction = state.finance.accountTransactions.find(item => item.id === editor.id);
  const card = state.finance.cards.find(item => item.id === editor.id);
  const purchase = state.finance.cardPurchases.find(item => item.id === editor.id);
  const debt = state.finance.debts.find(item => item.id === editor.id);
  const budget = state.finance.budgets.find(item => item.id === editor.id);
  const investment = state.finance.investments.find(item => item.id === editor.id);
  const category = state.finance.categories.find(item => item.id === editor.id);
  const defaults = editor.defaults ?? {};
  const titles: Record<FinanceEditorKind,string> = { recurringIncome: editor.id ? 'Editar renda mensal' : 'Nova renda mensal', income: editor.id ? 'Editar renda avulsa' : 'Nova renda avulsa', recurringExpense: editor.id ? 'Editar despesa fixa' : 'Nova despesa fixa', expense: editor.id ? 'Editar despesa' : 'Nova despesa', account: editor.id ? 'Editar conta' : 'Nova conta', transaction: editor.id ? 'Editar movimentação' : 'Movimentar conta', transfer: editor.id ? 'Editar transferência' : 'Transferir entre contas', card: editor.id ? 'Editar cartão' : 'Novo cartão', purchase: editor.id ? 'Editar compra parcelada' : 'Nova compra no cartão', debt: editor.id ? 'Editar dívida' : 'Nova dívida ou empréstimo', budget: editor.id ? 'Editar orçamento' : 'Novo limite de orçamento', investment: editor.id ? 'Editar investimento' : 'Novo investimento', category: editor.id ? 'Editar categoria' : 'Nova categoria', receipt: 'Ler comprovante' };
  const expenseCategories = state.finance.categories.filter(item => item.kind === 'expense');
  const incomeCategories = state.finance.categories.filter(item => item.kind === 'income');

  return <div className="modal-backdrop financex-modal-backdrop" onMouseDown={event => event.target === event.currentTarget && onClose()}><form className="app-modal financex-modal" onSubmit={onSubmit}><header><div><span className="eyebrow">Smart Finance</span><h2>{titles[editor.kind]}</h2></div><button type="button" onClick={onClose}><X size={21} /></button></header><div className="modal-fields">
    {editor.kind === 'recurringIncome' && <><label>Descrição<input name="description" required defaultValue={recurringIncome?.description} placeholder="Ex.: Salário mensal" /></label><div className="field-row"><label>Valor mensal<input name="amount" type="number" min=".01" step=".01" required defaultValue={recurringIncome?.amount} /></label><label>Dia fixo do mês<input name="day" type="number" min="1" max="31" required defaultValue={recurringIncome?.day || 5} /></label></div><div className="field-row"><label>Categoria<CategorySelect items={incomeCategories} name="category" value={recurringIncome?.category || 'Salário'} /></label><label>Conta<AccountSelect state={state} name="accountId" value={recurringIncome?.accountId || ''} optional /></label></div><div className="field-row"><label>Começar no mês<input name="startMonth" type="month" defaultValue={recurringIncome?.startMonth} /></label><label>Terminar no mês<input name="endMonth" type="month" defaultValue={recurringIncome?.endMonth} /></label></div><label className="financex-check"><input type="checkbox" name="active" defaultChecked={recurringIncome?.active ?? true} /> Renda ativa</label><p className="field-hint">A data é recorrente: “dia 5” vale para todos os meses, sem cadastrar um mês específico.</p></>}
    {editor.kind === 'income' && <><label>Descrição<input name="description" required defaultValue={income?.description} /></label><div className="field-row"><label>Valor<input name="amount" type="number" min=".01" step=".01" required defaultValue={income?.amount} /></label><label>Data<input name="date" type="date" required defaultValue={income?.date || localDateKey()} /></label></div><div className="field-row"><label>Categoria<CategorySelect items={incomeCategories} name="category" value={income?.category || 'Renda extra'} /></label><label>Conta<AccountSelect state={state} name="accountId" value={income?.accountId || ''} optional /></label></div><label>Observações<textarea name="notes">{income?.notes}</textarea></label><ReceiptUpload attachment={receiptAttachment} uploading={uploading} upload={uploadReceipt} /></>}
    {editor.kind === 'recurringExpense' && <><label>Descrição<input name="description" required defaultValue={recurringExpense?.description} placeholder="Ex.: Internet" /></label><div className="field-row"><label>Valor mensal<input name="amount" type="number" min=".01" step=".01" required defaultValue={recurringExpense?.amount} /></label><label>Dia de vencimento<input name="day" type="number" min="1" max="31" required defaultValue={recurringExpense?.day || 10} /></label></div><div className="field-row"><label>Categoria<CategorySelect items={expenseCategories} name="category" value={recurringExpense?.category || 'Outros'} /></label><label>Conta<AccountSelect state={state} name="accountId" value={recurringExpense?.accountId || ''} optional /></label></div><div className="field-row"><label>Começar no mês<input name="startMonth" type="month" defaultValue={recurringExpense?.startMonth} /></label><label>Terminar no mês<input name="endMonth" type="month" defaultValue={recurringExpense?.endMonth} /></label></div><label>Observações<textarea name="notes">{recurringExpense?.notes}</textarea></label><label className="financex-check"><input type="checkbox" name="active" defaultChecked={recurringExpense?.active ?? true} /> Despesa ativa</label></>}
    {(editor.kind === 'expense' || editor.kind === 'receipt') && <>{editor.kind === 'receipt' && <div className="financex-scan-help"><Camera size={23} /><div><strong>Envie a foto do comprovante</strong><small>A imagem fica protegida na sua conta. Confira descrição, valor e data antes de salvar.</small></div></div>}<ReceiptUpload attachment={receiptAttachment} uploading={uploading} upload={uploadReceipt} prominent={editor.kind === 'receipt'} /><label>Descrição<input name="description" required defaultValue={expense?.description} placeholder="Ex.: Mercado" /></label><div className="field-row"><label>Valor<input name="amount" type="number" min=".01" step=".01" required defaultValue={expense?.amount} /></label><label>Vencimento<input name="dueDate" type="date" required defaultValue={expense?.dueDate || localDateKey()} /></label></div><div className="field-row"><label>Categoria<CategorySelect items={expenseCategories} name="category" value={expense?.category || 'Outros'} /></label><label>Conta<AccountSelect state={state} name="accountId" value={expense?.accountId || ''} optional /></label></div><label>Forma de pagamento<select name="paymentMethod" defaultValue={expense?.paymentMethod || 'Pix'}><option>Pix</option><option>Dinheiro</option><option>Débito</option><option>Boleto</option><option>Transferência</option><option>Outro</option></select></label><label>Observações<textarea name="notes">{expense?.notes}</textarea></label></>}
    {editor.kind === 'account' && <><div className="field-row"><label>Nome da conta<input name="name" required defaultValue={account?.name} placeholder="Ex.: Inter" /></label><label>Instituição<input name="institution" defaultValue={account?.institution} /></label></div><div className="field-row"><label>Tipo<select name="kind" defaultValue={account?.kind || 'Conta corrente'}><option>Conta corrente</option><option>Carteira</option><option>Dinheiro</option><option>Poupança</option><option>Investimento</option></select></label><label>Saldo atual<input name="balance" type="number" step=".01" defaultValue={account?.balance || 0} /></label></div><label>Cor<input name="color" type="color" defaultValue={account?.color || '#10b981'} /></label><label className="financex-check"><input type="checkbox" name="includeInTotal" defaultChecked={account?.includeInTotal ?? true} /> Incluir no saldo total</label></>}
    {editor.kind === 'transaction' && <><div className="field-row"><label>Conta<AccountSelect state={state} name="accountId" value={transaction?.accountId || String(defaults.accountId ?? '')} /></label><label>Tipo<select name="kind" defaultValue={transaction?.kind || String(defaults.kind ?? 'income')}><option value="income">Entrada</option><option value="expense">Saída</option></select></label></div><label>Descrição<input name="description" required defaultValue={transaction?.description} /></label><div className="field-row"><label>Valor<input name="amount" type="number" min=".01" step=".01" required defaultValue={transaction?.amount} /></label><label>Data<input name="date" type="date" required defaultValue={transaction?.date || localDateKey()} /></label></div><label>Observações<textarea name="notes" defaultValue={transaction?.notes} /></label></>}
    {editor.kind === 'transfer' && <><div className="field-row"><label>Conta de origem<AccountSelect state={state} name="accountId" value={transaction?.accountId || ''} /></label><label>Conta de destino<AccountSelect state={state} name="destinationAccountId" value={transaction?.destinationAccountId || ''} /></label></div><label>Descrição<input name="description" defaultValue={transaction?.description || 'Transferência'} /></label><div className="field-row"><label>Valor<input name="amount" type="number" min=".01" step=".01" required defaultValue={transaction?.amount} /></label><label>Data<input name="date" type="date" required defaultValue={transaction?.date || localDateKey()} /></label></div><label>Observações<textarea name="notes" defaultValue={transaction?.notes} /></label></>}
    {editor.kind === 'card' && <><div className="field-row"><label>Banco ou cartão<input name="bank" required defaultValue={card?.bank} placeholder="Ex.: Nubank" /></label><label>Bandeira<select name="brand" defaultValue={card?.brand || 'Mastercard'}><option>Mastercard</option><option>Visa</option><option>Elo</option><option>American Express</option><option>Hipercard</option><option>Outro</option></select></label></div><div className="field-row"><label>Nome no cartão<input name="holder" required defaultValue={card?.holder || state.profile.displayName} /></label><label>Últimos 4 dígitos<input name="lastDigits" inputMode="numeric" maxLength={4} defaultValue={card?.lastDigits} /></label></div><label>Limite<input name="limit" type="number" min="0" step=".01" required defaultValue={card?.limit} /></label><div className="field-row three"><label>Fechamento<input name="closingDay" type="number" min="1" max="31" required defaultValue={card?.closingDay || 1} /></label><label>Vencimento<input name="dueDay" type="number" min="1" max="31" required defaultValue={card?.dueDay || 10} /></label><label>Cor<input name="color" type="color" defaultValue={card?.color || '#7454f6'} /></label></div><label className="financex-check"><input type="checkbox" name="active" defaultChecked={card?.active ?? true} /> Cartão ativo</label></>}
    {editor.kind === 'purchase' && <><label>Cartão<select name="cardId" required defaultValue={purchase?.cardId || editor.cardId || ''}><option value="" disabled>Selecione o cartão</option>{state.finance.cards.map(item => <option value={item.id} key={item.id}>{item.bank} · {item.brand}</option>)}</select></label><label>Descrição<input name="description" required defaultValue={purchase?.description} /></label><div className="field-row"><label>Valor total<input name="totalAmount" type="number" min=".01" step=".01" required defaultValue={purchase?.totalAmount} /></label><label>Data da compra<input name="purchaseDate" type="date" required defaultValue={purchase?.purchaseDate || localDateKey()} /></label></div><div className="field-row"><label>Quantidade de parcelas<input name="installmentCount" type="number" min="1" max="240" required defaultValue={purchase?.installmentCount || 1} /></label><label>Categoria<CategorySelect items={expenseCategories} name="category" value={purchase?.category || 'Outros'} /></label></div><label>Observações<textarea name="notes">{purchase?.notes}</textarea></label><ReceiptUpload attachment={receiptAttachment} uploading={uploading} upload={uploadReceipt} /><p className="field-hint">A primeira fatura será calculada pela data da compra e pelo fechamento do cartão. As parcelas continuarão como dívida fixa até a última.</p></>}
    {editor.kind === 'debt' && <><div className="field-row"><label>Nome<input name="name" required defaultValue={debt?.name} placeholder="Ex.: Empréstimo pessoal" /></label><label>Tipo<select name="kind" defaultValue={debt?.kind || 'Dívida'}><option>Dívida</option><option>Empréstimo</option><option>Financiamento</option></select></label></div><label>Credor ou instituição<input name="creditor" defaultValue={debt?.creditor} /></label><div className="field-row three"><label>Valor total<input name="totalAmount" type="number" min=".01" step=".01" required defaultValue={debt?.totalAmount} /></label><label>Valor da parcela<input name="installmentAmount" type="number" min="0" step=".01" defaultValue={debt?.installmentAmount} /></label><label>Nº de parcelas<input name="installmentCount" type="number" min="1" required defaultValue={debt?.installmentCount || 1} /></label></div><div className="field-row three"><label>Data inicial<input name="startDate" type="date" required defaultValue={debt?.startDate || localDateKey()} /></label><label>Dia de vencimento<input name="dueDay" type="number" min="1" max="31" required defaultValue={debt?.dueDay || 10} /></label><label>Juros (% a.m.)<input name="interestRate" type="number" min="0" step=".01" defaultValue={debt?.interestRate || 0} /></label></div><label>Conta para pagamento<AccountSelect state={state} name="accountId" value={debt?.accountId || ''} optional /></label><label>Observações<textarea name="notes">{debt?.notes}</textarea></label><label className="financex-check"><input type="checkbox" name="active" defaultChecked={debt?.active ?? true} /> Dívida ativa</label></>}
    {editor.kind === 'budget' && <><label>Categoria<CategorySelect items={expenseCategories} name="category" value={budget?.category || ''} /></label><div className="field-row"><label>Limite mensal<input name="monthlyLimit" type="number" min=".01" step=".01" required defaultValue={budget?.monthlyLimit} /></label><label>Alertar ao atingir (%)<input name="alertPercent" type="number" min="1" max="100" defaultValue={budget?.alertPercent || 80} /></label></div></>}
    {editor.kind === 'investment' && <><div className="field-row"><label>Nome<input name="name" required defaultValue={investment?.name} placeholder="Ex.: Reserva de emergência" /></label><label>Tipo<select name="kind" defaultValue={investment?.kind || 'Renda fixa'}><option>Renda fixa</option><option>Ações</option><option>Fundo</option><option>Criptomoeda</option><option>Previdência</option><option>Outro</option></select></label></div><label>Instituição<input name="institution" defaultValue={investment?.institution} /></label><div className="field-row three"><label>Valor investido<input name="investedValue" type="number" min="0" step=".01" defaultValue={investment?.investedValue || 0} /></label><label>Valor atual<input name="currentValue" type="number" min="0" step=".01" defaultValue={investment?.currentValue || 0} /></label><label>Aporte mensal<input name="monthlyContribution" type="number" min="0" step=".01" defaultValue={investment?.monthlyContribution || 0} /></label></div><label>Cor<input name="color" type="color" defaultValue={investment?.color || '#14b8a6'} /></label></>}
    {editor.kind === 'category' && <><label>Nome<input name="name" required defaultValue={category?.name} /></label><div className="field-row"><label>Tipo<select name="kind" defaultValue={category?.kind || 'expense'}><option value="expense">Despesa</option><option value="income">Renda</option></select></label><label>Grupo do planejamento<select name="bucket" defaultValue={category?.bucket || 'Necessidades'}><option>Necessidades</option><option>Desejos</option><option>Metas</option></select></label></div><label>Cor<input name="color" type="color" defaultValue={category?.color || '#64748b'} /></label></>}
  </div><footer>{onDelete ? <button type="button" className="financex-delete" onClick={onDelete}><Trash2 size={17} /> Excluir</button> : <span />}<div><button className="cancel-button" type="button" onClick={onClose}>Cancelar</button><button className="modal-save financex-save" type="submit" disabled={uploading}><Check size={17} /> Salvar</button></div></footer></form></div>;
}

function AccountSelect({ state, name, value, optional = false }: { state: AppState; name: string; value: string; optional?: boolean }) {
  return <select name={name} required={!optional} defaultValue={value}><option value="">{optional ? 'Não definida' : 'Selecione'}</option>{state.finance.accounts.map(item => <option value={item.id} key={item.id}>{item.name}</option>)}</select>;
}

function CategorySelect({ items, name, value }: { items: AppState['finance']['categories']; name: string; value: string }) {
  return <select name={name} required defaultValue={value}><option value="" disabled>Selecione</option>{items.map(item => <option value={item.name} key={item.id}>{item.name}</option>)}</select>;
}

function ReceiptUpload({ attachment, uploading, upload, prominent = false }: { attachment: StudyAttachment | null; uploading: boolean; upload: (file: File | undefined) => Promise<void>; prominent?: boolean }) {
  return <div className={'financex-receipt-upload ' + (prominent ? 'prominent' : '')}><label className={uploading ? 'loading' : ''}>{attachment ? <><img src={attachment.url} alt="Comprovante anexado" /><span><CheckCircle2 size={17} /> {attachment.name}</span></> : <><Upload size={prominent ? 27 : 19} /><span>{uploading ? 'Enviando...' : 'Anexar comprovante'}</span></>}<input type="file" accept="image/jpeg,image/png,image/webp,image/gif" disabled={uploading} onChange={event => void upload(event.target.files?.[0])} /></label></div>;
}
