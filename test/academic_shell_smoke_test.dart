import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_routine_active/core/app_store.dart';
import 'package:my_routine_active/core/app_theme.dart';
import 'package:my_routine_active/core/wifi_sync_service.dart';
import 'package:my_routine_active/screens/academic_shell_screen.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets('menu acadêmico funciona em largura de celular', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = AppStore();
    final wifi = WifiSyncService(store);
    addTearDown(wifi.dispose);
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: AcademicShellScreen(store: store, wifi: wifi),
      ),
    );
    await tester.pump();

    expect(find.text('Visão acadêmica'), findsOneWidget);
    expect(find.text('Horário de aulas'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Smart Routine SI'), findsOneWidget);
    expect(find.text('Metas e foco'), findsOneWidget);
    expect(find.text('Resumos'), findsOneWidget);
    expect(find.text('Kanban'), findsOneWidget);
    expect(find.text('Simulados'), findsOneWidget);
    expect(find.text('Organização'), findsOneWidget);
  });

  testWidgets('menu acadêmico permanece visível no desktop', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = AppStore();
    final wifi = WifiSyncService(store);
    addTearDown(wifi.dispose);
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: AcademicShellScreen(store: store, wifi: wifi),
      ),
    );
    await tester.pump();

    expect(find.text('Smart Routine SI'), findsOneWidget);
    expect(find.text('Menu principal'), findsOneWidget);
    expect(find.text('Sincronização Wi‑Fi'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);
  });
}
