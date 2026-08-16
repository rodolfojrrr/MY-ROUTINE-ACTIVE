import assert from 'node:assert/strict';
import test from 'node:test';
import {
  cardInstallments,
  dateInMonth,
  debtInstallments,
  financeMonthSnapshot,
  firstCardInvoiceMonth,
} from '../app/lib/finance-utils.ts';
import type { CardPurchase, FinanceDebt } from '../app/lib/app-data.ts';

const card = { closingDay: 20, dueDay: 5 };

test('moves a card purchase to the correct invoice around the closing day', () => {
  assert.equal(firstCardInvoiceMonth('2026-01-10', card), '2026-02');
  assert.equal(firstCardInvoiceMonth('2026-01-20', card), '2026-02');
  assert.equal(firstCardInvoiceMonth('2026-01-21', card), '2026-03');
});

test('creates every card installment, preserves cents and exposes the end date', () => {
  const purchase: CardPurchase = {
    id: 'purchase-1',
    cardId: 'card-1',
    description: 'Notebook',
    category: 'Faculdade',
    totalAmount: 1000,
    purchaseDate: '2026-01-21',
    installmentCount: 12,
    paidInstallments: ['2026-03'],
    notes: '',
    attachment: null,
  };

  const schedule = cardInstallments(purchase, card);
  assert.equal(schedule.length, 12);
  assert.equal(schedule[0].month, '2026-03');
  assert.equal(schedule[0].dueDate, '2026-03-05');
  assert.equal(schedule[0].paid, true);
  assert.equal(schedule.at(-1)?.dueDate, '2027-02-05');
  assert.equal(Math.round(schedule.reduce((sum, item) => sum + item.amount, 0) * 100), 100000);
});

test('keeps recurring days valid in short months', () => {
  assert.equal(dateInMonth('2026-02', 31), '2026-02-28');
  assert.equal(dateInMonth('2028-02', 31), '2028-02-29');
});

test('generates a debt schedule until the final installment', () => {
  const debt: FinanceDebt = {
    id: 'debt-1',
    name: 'Empréstimo',
    kind: 'Empréstimo',
    creditor: 'Banco',
    totalAmount: 500,
    installmentAmount: 0,
    installmentCount: 3,
    startDate: '2026-08-18',
    dueDay: 10,
    interestRate: 0,
    accountId: '',
    paidInstallments: [],
    notes: '',
    active: true,
  };

  const schedule = debtInstallments(debt);
  assert.deepEqual(schedule.map(item => item.dueDate), ['2026-09-10', '2026-10-10', '2026-11-10']);
  assert.equal(Math.round(schedule.reduce((sum, item) => sum + item.amount, 0) * 100), 50000);
});

test('monthly snapshot includes recurring, card and debt obligations', () => {
  const finance = {
    recurringIncomes: [{ id: 'salary', description: 'Salário', amount: 2000, day: 5, category: 'Salário', accountId: '', active: true, startMonth: '', endMonth: '', receivedMonths: [] }],
    incomes: [],
    expenses: [],
    recurringExpenses: [{ id: 'internet', description: 'Internet', category: 'Moradia', amount: 100, day: 10, accountId: '', active: true, startMonth: '', endMonth: '', paidMonths: [], notes: '' }],
    accounts: [],
    accountTransactions: [],
    cards: [{ id: 'card-1', bank: 'Banco', holder: 'Usuário', brand: 'Mastercard', lastDigits: '1234', limit: 3000, closingDay: 20, dueDay: 5, color: '#000000', active: true }],
    cardPurchases: [{ id: 'purchase-1', cardId: 'card-1', description: 'Compra', category: 'Outros', totalAmount: 300, purchaseDate: '2026-07-10', installmentCount: 3, paidInstallments: [], notes: '', attachment: null }],
    debts: [{ id: 'debt-1', name: 'Empréstimo', kind: 'Empréstimo' as const, creditor: 'Banco', totalAmount: 600, installmentAmount: 200, installmentCount: 3, startDate: '2026-07-01', dueDay: 12, interestRate: 0, accountId: '', paidInstallments: [], notes: '', active: true }],
    categories: [],
    budgets: [],
    investments: [],
    planning: { needsPercent: 50, wantsPercent: 30, goalsPercent: 20 },
  };

  const snapshot = financeMonthSnapshot(finance, '2026-08');
  assert.equal(snapshot.predictedIncome, 2000);
  assert.equal(snapshot.predictedExpense, 400);
  assert.equal(snapshot.obligations.length, 3);
  assert.equal(snapshot.pendingCount, 4);
});
