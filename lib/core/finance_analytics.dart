import 'app_store.dart';
import 'finance_utils.dart';
import 'sync_entity.dart';

class FinanceAnalytics {
  static bool inMonth(String? isoDate, DateTime month) {
    final date = DateTime.tryParse(isoDate ?? '');
    return date != null && date.year == month.year && date.month == month.month;
  }

  static double accountBalance(AppStore store, SyncEntity account) {
    var value = (account.payload['initialBalance'] as num? ?? 0).toDouble();
    for (final income in store.records(EntityTypes.income)) {
      if (income.payload['accountId'] == account.id) {
        value += (income.payload['amount'] as num? ?? 0).toDouble();
      }
    }
    for (final expense in store.records(EntityTypes.expense)) {
      if (expense.payload['accountId'] == account.id) {
        value -= (expense.payload['amount'] as num? ?? 0).toDouble();
      }
    }
    for (final transfer in store.records(EntityTypes.financeTransfer)) {
      final amount = (transfer.payload['amount'] as num? ?? 0).toDouble();
      if (transfer.payload['fromAccountId'] == account.id) value -= amount;
      if (transfer.payload['toAccountId'] == account.id) value += amount;
    }
    for (final payment in store.records(EntityTypes.cardPayment)) {
      if (payment.payload['accountId'] == account.id) {
        value -= (payment.payload['amount'] as num? ?? 0).toDouble();
      }
    }
    return value;
  }

  static double invoiceForMonth(AppStore store, String cardId, DateTime month) {
    var total = 0.0;
    for (final debt in store.records(EntityTypes.debt)) {
      if (debt.payload['cardId'] != cardId || debt.payload['status'] == 'Quitada') {
        continue;
      }
      final purchase = DateTime.tryParse(debt.payload['purchaseDate'] as String? ?? '');
      if (purchase == null) continue;
      final installments = (debt.payload['installments'] as num? ?? 1).toInt();
      final current = FinanceUtils.installmentNumber(
        purchaseDate: purchase,
        month: month,
      );
      if (current >= 1 && current <= installments) {
        total += FinanceUtils.installmentValue(
          (debt.payload['total'] as num? ?? 0).toDouble(),
          installments,
        );
      }
    }
    return total;
  }

  static double paymentsForMonth(AppStore store, String cardId, DateTime month) {
    final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    return store.records(EntityTypes.cardPayment).fold<double>(0, (sum, item) {
      if (item.payload['cardId'] != cardId || item.payload['monthKey'] != key) {
        return sum;
      }
      return sum + (item.payload['amount'] as num? ?? 0).toDouble();
    });
  }
}
