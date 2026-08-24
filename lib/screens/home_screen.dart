import 'package:flutter/material.dart';

import '../core/app_store.dart';
import '../core/wifi_sync_service.dart';
import 'academic_shell_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.store, required this.wifi, super.key});

  final AppStore store;
  final WifiSyncService wifi;

  @override
  Widget build(BuildContext context) {
    return AcademicShellScreen(store: store, wifi: wifi);
  }
}
