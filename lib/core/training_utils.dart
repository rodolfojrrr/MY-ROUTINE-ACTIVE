class TrainingUtils {
  static double setVolume({required num load, required num reps}) =>
      load.toDouble() * reps.toDouble();

  static double snapshotVolume(List<dynamic> snapshots) {
    var total = 0.0;
    for (final raw in snapshots) {
      if (raw is! Map) continue;
      final load = raw['load'];
      final reps = raw['reps'];
      if (load is num && reps is num) total += setVolume(load: load, reps: reps);
    }
    return total;
  }

  static double maxLoadForExercise(
    List<Map<String, dynamic>> snapshots,
    String exerciseName,
  ) {
    var best = 0.0;
    for (final item in snapshots) {
      if ((item['exerciseName'] as String? ?? '') != exerciseName) continue;
      final load = (item['load'] as num? ?? 0).toDouble();
      if (load > best) best = load;
    }
    return best;
  }
}
