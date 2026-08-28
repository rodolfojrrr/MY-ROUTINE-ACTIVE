import 'package:flutter/material.dart';

import '../core/app_store.dart';
import '../core/app_appearance.dart';
import '../core/study_timer_controller.dart';
import '../core/wifi_sync_service.dart';
import 'academic_shell_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.store,
    required this.wifi,
    required this.appearance,
    required this.studyTimer,
    required this.onLogout,
    super.key,
  });

  final AppStore store;
  final WifiSyncService wifi;
  final AppAppearanceController appearance;
  final StudyTimerController studyTimer;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return AcademicShellScreen(
      store: store,
      wifi: wifi,
      appearance: appearance,
      studyTimer: studyTimer,
      onLogout: onLogout,
    );
  }
}
