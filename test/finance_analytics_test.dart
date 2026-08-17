import 'package:flutter_test/flutter_test.dart';
import 'package:my_routine_active/core/finance_analytics.dart';

void main() {
  group('FinanceAnalytics', () {
    test('identifica data dentro do mês selecionado', () {
      expect(FinanceAnalytics.inMonth('2026-08-17', DateTime(2026, 8)), isTrue);
      expect(FinanceAnalytics.inMonth('2026-07-31', DateTime(2026, 8)), isFalse);
      expect(FinanceAnalytics.inMonth(null, DateTime(2026, 8)), isFalse);
    });
  });
}
