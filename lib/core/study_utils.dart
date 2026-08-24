class StudyReviewResult {
  const StudyReviewResult({
    required this.intervalDays,
    required this.nextReview,
    required this.streak,
  });

  final int intervalDays;
  final DateTime nextReview;
  final int streak;
}

class StudyUtils {
  static StudyReviewResult nextReview({
    required String rating,
    required int currentIntervalDays,
    required int currentStreak,
    DateTime? now,
  }) {
    final base = now ?? DateTime.now();
    final normalized = rating.toLowerCase();
    int days;
    int streak;

    switch (normalized) {
      case 'again':
        days = 0;
        streak = 0;
        break;
      case 'hard':
        days = currentIntervalDays <= 1
            ? 1
            : (currentIntervalDays * 1.35).round().clamp(1, 3650).toInt();
        streak = currentStreak + 1;
        break;
      case 'easy':
        days = currentIntervalDays <= 1
            ? 4
            : (currentIntervalDays * 2.5).round().clamp(1, 3650).toInt();
        streak = currentStreak + 1;
        break;
      default:
        days = currentIntervalDays <= 0
            ? 1
            : currentIntervalDays == 1
                ? 3
                : (currentIntervalDays * 1.8).round().clamp(1, 3650).toInt();
        streak = currentStreak + 1;
        break;
    }

    final next = normalized == 'again'
        ? base.add(const Duration(minutes: 10))
        : base.add(Duration(days: days));
    return StudyReviewResult(
      intervalDays: days,
      nextReview: next,
      streak: streak,
    );
  }

  static bool isDue(Map<String, dynamic> payload, {DateTime? now}) {
    final next = DateTime.tryParse(payload['nextReviewAt'] as String? ?? '');
    return next == null || !next.isAfter(now ?? DateTime.now());
  }
}
