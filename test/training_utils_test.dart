import 'package:flutter_test/flutter_test.dart';
import 'package:my_routine_active/core/training_utils.dart';

void main() {
  group('TrainingUtils', () {
    test('calcula volume de uma série', () {
      expect(TrainingUtils.setVolume(load: 20, reps: 10), 200);
    });

    test('soma volume de snapshots válidos', () {
      final snapshots = <dynamic>[
        <String, dynamic>{'load': 20, 'reps': 10},
        <String, dynamic>{'load': 30, 'reps': 8},
        <String, dynamic>{'load': null, 'reps': 8},
      ];
      expect(TrainingUtils.snapshotVolume(snapshots), 440);
    });

    test('encontra maior carga de um exercício', () {
      final snapshots = <Map<String, dynamic>>[
        <String, dynamic>{'exerciseName': 'Supino reto', 'load': 30},
        <String, dynamic>{'exerciseName': 'Supino reto', 'load': 42.5},
        <String, dynamic>{'exerciseName': 'Remada', 'load': 60},
      ];
      expect(TrainingUtils.maxLoadForExercise(snapshots, 'Supino reto'), 42.5);
    });
  });
}
