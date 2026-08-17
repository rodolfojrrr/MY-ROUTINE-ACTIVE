class FinanceUtils {
  static int installmentNumber({
    required DateTime purchaseDate,
    required DateTime month,
  }) {
    return (month.year - purchaseDate.year) * 12 +
        month.month -
        purchaseDate.month +
        1;
  }

  static int remainingInstallments({
    required DateTime purchaseDate,
    required int installments,
    required DateTime month,
  }) {
    final current = installmentNumber(
      purchaseDate: purchaseDate,
      month: month,
    );
    if (current <= 0) return installments;
    if (current > installments) return 0;
    return installments - current + 1;
  }

  static DateTime installmentEndDate({
    required DateTime purchaseDate,
    required int installments,
  }) {
    return DateTime(
      purchaseDate.year,
      purchaseDate.month + installments - 1,
      purchaseDate.day,
    );
  }

  static double installmentValue(double total, int installments) =>
      installments <= 0 ? 0 : total / installments;

  static DateTime safeDayInMonth(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day.clamp(1, lastDay).toInt());
  }
}
