import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/app_store.dart';
import 'core/app_appearance.dart';
import 'core/app_theme.dart';
import 'core/notification_service.dart';
import 'core/study_timer_controller.dart';
import 'core/wifi_sync_service.dart';
import 'screens/home_screen.dart';
import 'screens/local_auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  try {
    await NotificationService.instance.initialize();
  } catch (_) {}
  runApp(const MyRoutineBootstrap());
}

class MyRoutineBootstrap extends StatefulWidget {
  const MyRoutineBootstrap({super.key});

  @override
  State<MyRoutineBootstrap> createState() => _MyRoutineBootstrapState();
}

class _MyRoutineBootstrapState extends State<MyRoutineBootstrap> {
  late final AppStore store;
  late final WifiSyncService wifi;
  late final AppAppearanceController appearance;
  late final StudyTimerController studyTimer;
  late final Future<void> initialization;

  @override
  void initState() {
    super.initState();
    store = AppStore();
    wifi = WifiSyncService(store);
    appearance = AppAppearanceController(store);
    studyTimer = StudyTimerController(store);
    initialization = _initialize();
  }

  Future<void> _initialize() async {
    await store.initialize();
  }

  Future<void> _onAuthenticated() async {
    await appearance.loadForActiveAccount();
    await studyTimer.initializeForActiveAccount();
    try {
      await NotificationService.instance.syncReminders(store);
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    if (studyTimer.isRunning) await studyTimer.pause();
    store.logout();
    appearance.reset();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    wifi.dispose();
    appearance.dispose();
    studyTimer.dispose();
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appearance,
      builder: (context, _) => MaterialApp(
        title: 'Smart Routine SI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        locale: const Locale('pt', 'BR'),
        home: FutureBuilder<void>(
          future: initialization,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _StartupError(message: snapshot.error.toString());
            }
            if (snapshot.connectionState != ConnectionState.done) {
              return const _StartupLoading();
            }
            if (!store.isAuthenticated) {
              return LocalAuthScreen(
                store: store,
                onAuthenticated: _onAuthenticated,
              );
            }
            return HomeScreen(
              store: store,
              wifi: wifi,
              appearance: appearance,
              studyTimer: studyTimer,
              onLogout: _logout,
            );
          },
        ),
      ),
    );
  }
}

class _StartupLoading extends StatelessWidget {
  const _StartupLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.school_rounded, color: AppColors.primary, size: 44),
            const SizedBox(height: 18),
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            const Text('Preparando seus dados locais…'),
          ],
        ),
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, color: AppColors.red, size: 48),
              const SizedBox(height: 14),
              const Text(
                'Não foi possível abrir o banco local.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
