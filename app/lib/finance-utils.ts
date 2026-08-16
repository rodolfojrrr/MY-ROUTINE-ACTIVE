import type { AppState, CardPurchase, FinanceCard, FinanceDebt } from './app-data';

export type GeneratedInstallment = {
  index: number;
  count: number;
  month: string;
  dueDate: string;
  amount: number;
  paid: boolean;
};

export type FinanceMonthObligation = {
  id: string;
  source: 'expense' | 'recurring' | 'card' | 'debt';
  sourceId: string;
  description: string;
  category: string;
  amount: number;
  dueDate: string;
  paid: boolean;
  typeLabel: string;
};

export function financeMonthKey(date = new Date()) {
  return date.getFullYear() + '-' + String(date.getMonth() + 1).padStart(2, '0');
}

export function monthFromKey(value: string) {
  const [year, month] = value.split('-').map(Number);
  return new Date(year, Math.max(0, month - 1), 1);
}

export function shiftMonthKey(value: string, amount: number) {
  const date = monthFromKey(value);
  return financeMonthKey(new Date(date.getFullYear(), date.getMonth() + amount, 1));
}

export function dateInMonth(month: string, day: number) {
  const date = monthFromKey(month);
  const lastDay = new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();
  const safeDay = Math.min(Math.max(1, Math.round(day)), lastDay);
  return date.getFullYear() + '-' + String(date.getMonth() + 1).padStart(2, '0') + '-' + String(safeDay).padStart(2, '0');
}

export function firstCardInvoiceMonth(purchaseDate: string, card: Pick<FinanceCard, 'closingDay' | 'dueDay'>) {
  const purchase = new Date(purchaseDate + 'T12:00:00');
  let closingMonth = financeMonthKey(purchase);
  if (purchase.getDate() > card.closingDay) closingMonth = shiftMonthKey(closingMonth, 1);
  return card.dueDay <= card.closingDay ? shiftMonthKey(closingMonth, 1) : closingMonth;
}

export function cardInstallments(purchase: CardPurchase, card: Pick<FinanceCard, 'closingDay' | 'dueDay'>): GeneratedInstallment[] {
  const count = Math.max(1, Math.round(purchase.installmentCount));
  const firstMonth = firstCardInvoiceMonth(purchase.purchaseDate, card);
  const totalCents = Math.round(purchase.totalAmount * 100);
  const baseCents = Math.floor(totalCents / count);
  const remainder = totalCents - baseCents * count;
  return Array.from({ length: count }, (_, index) => {
    const month = shiftMonthKey(firstMonth, index);
    const cents = baseCents + (index < remainder ? 1 : 0);
    return {
      index: index + 1,
      count,
      month,
      dueDate: dateInMonth(month, card.dueDay),
      amount: cents / 100,
      paid: purchase.paidInstallments.includes(month),
    };
  });
}

export function debtInstallments(debt: FinanceDebt): GeneratedInstallment[] {
  const count = Math.max(1, Math.round(debt.installmentCount));
  const start = new Date(debt.startDate + 'T12:00:00');
  let firstMonth = financeMonthKey(start);
  if (start.getDate() > debt.dueDay) firstMonth = shiftMonthKey(firstMonth, 1);
  const configuredCents = Math.round(debt.installmentAmount * 100);
  const totalCents = Math.round(debt.totalAmount * 100);
  return Array.from({ length: count }, (_, index) => {
    const month = shiftMonthKey(firstMonth, index);
    const cents = configuredCents || Math.floor(totalCents / count) + (index < totalCents % count ? 1 : 0);
    return {
      index: index + 1,
      count,
      month,
      dueDate: dateInMonth(month, debt.dueDay),
      amount: cents / 100,
      paid: debt.paidInstallments.includes(month),
    };
  });
}

function activeInMonth(item: { active: boolean; startMonth: string; endMonth: string }, month: string) {
  return item.active && (!item.startMonth || item.startMonth <= month) && (!item.endMonth || item.endMonth >= month);
}

export function financeMonthSnapshot(finance: AppState['finance'], month: string) {
  const recurringIncomes = finance.recurringIncomes.filter(item => activeInMonth(item, month));
  const incomes = finance.incomes.filter(item => item.date.startsWith(month));
  const obligations: FinanceMonthObligation[] = [
    ...finance.expenses.filter(item => item.dueDate.startsWith(month)).map(item => ({
      id: item.id,
      source: 'expense' as const,
      sourceId: item.id,
      description: item.description,
      category: item.category,
      amount: item.amount,
      dueDate: item.dueDate,
      paid: item.paid,
      typeLabel: item.paymentMethod || 'Avulsa',
    })),
    ...finance.recurringExpenses.filter(item => activeInMonth(item, month)).map(item => ({
      id: `recurring-${item.id}-${month}`,
      source: 'recurring' as const,
      sourceId: item.id,
      description: item.description,
      category: item.category,
      amount: item.amount,
      dueDate: dateInMonth(month, item.day),
      paid: item.paidMonths.includes(month),
      typeLabel: 'Fixa mensal',
    })),
    ...finance.cardPurchases.flatMap(purchase => {
      const card = finance.cards.find(item => item.id === purchase.cardId);
      if (!card) return [];
      return cardInstallments(purchase, card).filter(item => item.month === month).map(item => ({
        id: `card-${purchase.id}-${month}`,
        source: 'card' as const,
        sourceId: purchase.id,
        description: purchase.description,
        category: purchase.category || 'Cartão',
        amount: item.amount,
        dueDate: item.dueDate,
        paid: item.paid,
        typeLabel: `Cartão · ${item.index}/${item.count}`,
      }));
    }),
    ...finance.debts.filter(item => item.active).flatMap(debt => debtInstallments(debt).filter(item => item.month === month).map(item => ({
      id: `debt-${debt.id}-${month}`,
      source: 'debt' as const,
      sourceId: debt.id,
      description: debt.name,
      category: debt.kind,
      amount: item.amount,
      dueDate: item.dueDate,
      paid: item.paid,
      typeLabel: `${debt.kind} · ${item.index}/${item.count}`,
    }))),
  ].sort((left, right) => left.dueDate.localeCompare(right.dueDate));

  const predictedIncome = recurringIncomes.reduce((sum, item) => sum + item.amount, 0) + incomes.reduce((sum, item) => sum + item.amount, 0);
  const receivedIncome = recurringIncomes.filter(item => item.receivedMonths.includes(month)).reduce((sum, item) => sum + item.amount, 0) + incomes.filter(item => item.received).reduce((sum, item) => sum + item.amount, 0);
  const predictedExpense = obligations.reduce((sum, item) => sum + item.amount, 0);
  const paidExpense = obligations.filter(item => item.paid).reduce((sum, item) => sum + item.amount, 0);
  const pendingCount = recurringIncomes.filter(item => !item.receivedMonths.includes(month)).length + incomes.filter(item => !item.received).length + obligations.filter(item => !item.paid).length;

  return {
    recurringIncomes,
    incomes,
    obligations,
    predictedIncome,
    receivedIncome,
    predictedExpense,
    paidExpense,
    pendingCount,
  };
}
