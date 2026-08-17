import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/app_store.dart';
import 'core/app_theme.dart';
import 'core/notification_service.dart';
import 'core/wifi_sync_service.dart';
import 'screens/home_screen.dart';
import 'screens/pin_screen.dart';

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
  late final Future<void> initialization;
  bool unlocked = false;

  @override
  void initState() {
    super.initState();
    store = AppStore();
    wifi = WifiSyncService(store);
    initialization = _initialize();
  }

  Future<void> _initialize() async {
    await store.initialize();
    try {
      await NotificationService.instance.syncReminders(store);
    } catch (_) {}
  }

  @override
  void dispose() {
    wifi.dispose();
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Routine Active',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: FutureBuilder<void>(
        future: initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _StartupError(message: snapshot.error.toString());
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const _StartupLoading();
          }
          return FutureBuilder<bool>(
            future: store.hasPin(),
            builder: (context, pinSnapshot) {
              if (pinSnapshot.connectionState != ConnectionState.done) {
                return const _StartupLoading();
              }
              if (pinSnapshot.data == true && !unlocked) {
                return PinScreen(
                  store: store,
                  onUnlocked: () => setState(() => unlocked = true),
                );
              }
              return HomeScreen(store: store, wifi: wifi);
            },
          );
        },
      ),
    );
  }
}

class _StartupLoading extends StatelessWidget {
  const _StartupLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.auto_awesome, color: AppColors.green, size: 44),
            SizedBox(height: 18),
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text('Preparando seus dados locais…'),
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
