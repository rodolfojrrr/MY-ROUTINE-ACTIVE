import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_routine_active/core/app_store.dart';
import 'package:my_routine_active/core/app_theme.dart';
import 'package:my_routine_active/core/local_account.dart';
import 'package:my_routine_active/core/sync_entity.dart';
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
    expect(find.text('Resumos'), findsWidgets);
    expect(find.text('Kanban'), findsOneWidget);
    expect(find.text('Simulados'), findsOneWidget);
    expect(find.text('Faculdade'), findsOneWidget);
    expect(find.text('Cursos'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Faculdade')).dy,
      lessThan(tester.getTopLeft(find.text('Cursos')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Cursos')).dy,
      lessThan(tester.getTopLeft(find.text('Metas e foco')).dy),
    );

    await tester.tap(find.text('Faculdade'));
    await tester.pumpAndSettle();
    expect(find.text('Sua faculdade, organizada como pastas'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('academic-sidebar-destinations')),
      const Offset(0, -350),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lixeira'), findsOneWidget);
  });

  testWidgets('menu acadêmico pode ser recolhido no desktop', (tester) async {
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
    expect(
      tester.getSize(find.byKey(const Key('desktop-sidebar-frame'))).width,
      286,
    );

    await tester.tap(find.byKey(const Key('desktop-sidebar-collapse')));
    await tester.pump();

    expect(
      tester.getSize(find.byKey(const Key('desktop-sidebar-frame'))).width,
      84,
    );
    expect(find.byKey(const Key('desktop-sidebar-expand')), findsOneWidget);
    expect(find.text('Menu principal'), findsNothing);
    expect(find.text('Horário de aulas'), findsOneWidget);

    await tester.tap(find.byKey(const Key('desktop-sidebar-expand')));
    await tester.pump();

    expect(
      tester.getSize(find.byKey(const Key('desktop-sidebar-frame'))).width,
      286,
    );
    expect(find.text('Menu principal'), findsOneWidget);
  });

  testWidgets('estado recolhido é restaurado para a conta local',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = _ShellStore()
      ..preferences['desktop_sidebar_collapsed'] = 'true';
    final wifi = WifiSyncService(store);
    addTearDown(wifi.dispose);
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: AcademicShellScreen(store: store, wifi: wifi),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const Key('desktop-sidebar-frame'))).width,
      84,
    );

    await tester.tap(find.byKey(const Key('desktop-sidebar-expand')));
    await tester.pump();

    expect(store.preferences['desktop_sidebar_collapsed'], 'false');
  });
}

class _ShellStore extends AppStore {
  final Map<String, String> preferences = <String, String>{};

  @override
  LocalAccount? get activeAccount => const LocalAccount(
        id: 'conta-teste',
        username: 'teste',
        displayName: 'Conta de teste',
        email: '',
        securityQuestion: 'Pergunta?',
        createdAtMs: 1,
        updatedAtMs: 1,
      );

  @override
  String get deviceId => 'desktop-test';

  @override
  List<SyncEntity> records(String type) => <SyncEntity>[];

  @override
  SyncEntity? byId(String id) => null;

  @override
  List<SyncEntity> deletedRecords() => <SyncEntity>[];

  @override
  Future<String?> readUserPreference(String key) async => preferences[key];

  @override
  Future<void> writeUserPreference(
    String key,
    String value, {
    bool notify = false,
  }) async {
    preferences[key] = value;
    if (notify) notifyListeners();
  }
}
