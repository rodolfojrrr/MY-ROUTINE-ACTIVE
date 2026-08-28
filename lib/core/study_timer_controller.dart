import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'app_store.dart';

enum StudyTimerStatus { idle, running, paused }

class StudyTimerController extends ChangeNotifier with WidgetsBindingObserver {
  StudyTimerController(this.store);

  final AppStore store;
  Timer? _ticker;
  StudyTimerStatus status = StudyTimerStatus.idle;
  String title = '';
  String? subjectId;
  String? contentId;
  String? goalId;
  int plannedMinutes = 25;
  int elapsedSeconds = 0;
  bool _observing = false;
  bool _disposed = false;

  bool get isActive => status != StudyTimerStatus.idle;
  bool get isRunning => status == StudyTimerStatus.running;
  double get progress => plannedMinutes <= 0
      ? 0
      : (elapsedSeconds / (plannedMinutes * 60)).clamp(0, 1).toDouble();

  String get formattedElapsed {
    final hours = elapsedSeconds ~/ 3600;
    final minutes = (elapsedSeconds % 3600) ~/ 60;
    final seconds = elapsedSeconds % 60;
    return <int>[hours, minutes, seconds]
        .map((item) => item.toString().padLeft(2, '0'))
        .join(':');
  }

  Future<void> initializeForActiveAccount() async {
    _ticker?.cancel();
    _ticker = null;
    status = StudyTimerStatus.idle;
    title = '';
    subjectId = null;
    contentId = null;
    goalId = null;
    plannedMinutes = 25;
    elapsedSeconds = 0;
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    final raw = await store.readUserPreference('study_timer_state');
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = (jsonDecode(raw) as Map).cast<String, dynamic>();
        final savedStatus = map['status'] as String? ?? 'idle';
        status = savedStatus == 'idle'
            ? StudyTimerStatus.idle
            : StudyTimerStatus.paused;
        title = map['title'] as String? ?? '';
        subjectId = map['subjectId'] as String?;
        contentId = map['contentId'] as String?;
        goalId = map['goalId'] as String?;
        plannedMinutes = (map['plannedMinutes'] as num? ?? 25)
            .toInt()
            .clamp(1, 1440)
            .toInt();
        elapsedSeconds = (map['elapsedSeconds'] as num? ?? 0)
            .toInt()
            .clamp(0, 604800)
            .toInt();
      } catch (_) {
        await _persist();
      }
    }
    _notify();
  }

  Future<void> start({
    required String title,
    String? subjectId,
    String? contentId,
    String? goalId,
    int plannedMinutes = 25,
  }) async {
    _ticker?.cancel();
    this.title = title.trim().isEmpty ? 'Sessão livre de estudo' : title.trim();
    this.subjectId = subjectId;
    this.contentId = contentId;
    this.goalId = goalId;
    this.plannedMinutes = plannedMinutes.clamp(1, 1440).toInt();
    elapsedSeconds = 0;
    status = StudyTimerStatus.running;
    await _persist();
    _startTicker();
    _notify();
  }

  Future<void> pause() async {
    if (status != StudyTimerStatus.running) return;
    _ticker?.cancel();
    _ticker = null;
    status = StudyTimerStatus.paused;
    await _persist();
    _notify();
  }

  Future<void> resume() async {
    if (status != StudyTimerStatus.paused) return;
    status = StudyTimerStatus.running;
    await _persist();
    _startTicker();
    _notify();
  }

  Future<int> complete() async {
    if (!isActive) return 0;
    _ticker?.cancel();
    _ticker = null;
    final minutes = elapsedSeconds == 0 ? 0 : (elapsedSeconds / 60).ceil();
    if (minutes > 0) {
      await store.save(EntityTypes.studySession, <String, dynamic>{
        'subjectId': subjectId,
        'contentId': contentId,
        'minutes': minutes,
        'seconds': elapsedSeconds,
        'date': DateTime.now().toIso8601String(),
        'mode': 'Foco',
        'title': title,
        'goalId': goalId,
      });
    }
    if (goalId != null) {
      final goal = store.byId(goalId!);
      if (goal != null && goal.type == EntityTypes.dailyStudyGoal) {
        await store.save(
          EntityTypes.dailyStudyGoal,
          <String, dynamic>{
            ...goal.payload,
            'completed': true,
            'completedAt': DateTime.now().millisecondsSinceEpoch,
          },
          id: goal.id,
        );
      }
    }
    await _reset();
    return minutes;
  }

  Future<void> discard() => _reset();

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds++;
      if (elapsedSeconds % 5 == 0) unawaited(_persist());
      _notify();
    });
  }

  Future<void> _reset() async {
    _ticker?.cancel();
    _ticker = null;
    status = StudyTimerStatus.idle;
    title = '';
    subjectId = null;
    contentId = null;
    goalId = null;
    plannedMinutes = 25;
    elapsedSeconds = 0;
    await _persist();
    _notify();
  }

  Future<void> _persist() => store.writeUserPreference(
        'study_timer_state',
        jsonEncode(<String, dynamic>{
          'status': status.name,
          'title': title,
          'subjectId': subjectId,
          'contentId': contentId,
          'goalId': goalId,
          'plannedMinutes': plannedMinutes,
          'elapsedSeconds': elapsedSeconds,
          'savedAt': DateTime.now().toIso8601String(),
        }),
      );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (status == StudyTimerStatus.running &&
        state != AppLifecycleState.resumed) {
      unawaited(pause());
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    if (_observing) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
