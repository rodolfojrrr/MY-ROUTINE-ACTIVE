import 'package:flutter_test/flutter_test.dart';
import 'package:my_routine_active/core/study_utils.dart';

void main() {
  group('StudyUtils', () {
    final base = DateTime(2026, 8, 17, 10);

    test('erro agenda revisão rápida e zera sequência', () {
      final result = StudyUtils.nextReview(
        rating: 'again',
        currentIntervalDays: 8,
        currentStreak: 5,
        now: base,
      );

      expect(result.intervalDays, 0);
      expect(result.streak, 0);
      expect(result.nextReview, base.add(const Duration(minutes: 10)));
    });

    test('acerto aumenta o intervalo progressivamente', () {
      final result = StudyUtils.nextReview(
        rating: 'good',
        currentIntervalDays: 1,
        currentStreak: 2,
        now: base,
      );

      expect(result.intervalDays, 3);
      expect(result.streak, 3);
      expect(result.nextReview, base.add(const Duration(days: 3)));
    });

    test('muito fácil inicia com quatro dias', () {
      final result = StudyUtils.nextReview(
        rating: 'easy',
        currentIntervalDays: 0,
        currentStreak: 0,
        now: base,
      );

      expect(result.intervalDays, 4);
      expect(result.streak, 1);
    });

    test('identifica flashcard vencido', () {
      expect(
        StudyUtils.isDue(
          <String, dynamic>{'nextReviewAt': base.subtract(const Duration(minutes: 1)).toIso8601String()},
          now: base,
        ),
        isTrue,
      );
      expect(
        StudyUtils.isDue(
          <String, dynamic>{'nextReviewAt': base.add(const Duration(days: 1)).toIso8601String()},
          now: base,
        ),
        isFalse,
      );
    });
  });
}
