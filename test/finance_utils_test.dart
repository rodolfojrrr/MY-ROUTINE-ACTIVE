import 'package:flutter_test/flutter_test.dart';
import 'package:my_routine_active/core/finance_utils.dart';

void main() {
  group('FinanceUtils', () {
    test('calcula a parcela atual a partir do mês da compra', () {
      final purchase = DateTime(2026, 1, 12);
      expect(
        FinanceUtils.installmentNumber(
          purchaseDate: purchase,
          month: DateTime(2026, 1),
        ),
        1,
      );
      expect(
        FinanceUtils.installmentNumber(
          purchaseDate: purchase,
          month: DateTime(2026, 8),
        ),
        8,
      );
    });

    test('calcula parcelas restantes e data final', () {
      final purchase = DateTime(2026, 1, 12);
      expect(
        FinanceUtils.remainingInstallments(
          purchaseDate: purchase,
          installments: 12,
          month: DateTime(2026, 8),
        ),
        5,
      );
      expect(
        FinanceUtils.installmentEndDate(
          purchaseDate: purchase,
          installments: 12,
        ),
        DateTime(2026, 12, 12),
      );
    });

    test('adapta um dia fixo ao último dia do mês', () {
      expect(FinanceUtils.safeDayInMonth(2026, 2, 31), DateTime(2026, 2, 28));
      expect(FinanceUtils.safeDayInMonth(2028, 2, 31), DateTime(2028, 2, 29));
    });
  });
}

