import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_routine_active/core/app_store.dart';
import 'package:my_routine_active/core/app_theme.dart';
import 'package:my_routine_active/core/study_timer_controller.dart';
import 'package:my_routine_active/core/sync_entity.dart';
import 'package:my_routine_active/screens/daily_goals_screen.dart';
import 'package:my_routine_active/screens/pdf_tools_screen.dart';
import 'package:my_routine_active/screens/recycle_bin_screen.dart';
import 'package:my_routine_active/screens/study_kanban_screen.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets('novas ferramentas encaixam em celular compacto', (tester) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = _ResponsiveStore();
    final timer = StudyTimerController(store);
    addTearDown(timer.dispose);
    addTearDown(store.dispose);

    final pages = <Widget>[
      DailyGoalsScreen(store: store, timer: timer),
      StudyKanbanScreen(store: store),
      PdfToolsScreen(store: store),
      RecycleBinScreen(store: store),
    ];
    for (final page in pages) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: page is RecycleBinScreen ? page : Scaffold(body: page),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester.takeException(),
        isNull,
        reason: '${page.runtimeType} não pode estourar a largura do celular.',
      );
    }
  });

  test('paletas alteram a cor principal sem reiniciar', () {
    addTearDown(() => AppColors.applyAccent(AppAccentPalette.blue));
    for (final palette in AppAccentPalette.values) {
      AppColors.applyAccent(palette);
      expect(AppTheme.dark().colorScheme.primary, palette.primary);
    }
  });
}

class _ResponsiveStore extends AppStore {
  final Map<String, String> preferences = <String, String>{};

  @override
  String get deviceId => 'responsive-test';

  @override
  List<SyncEntity> records(String type) => <SyncEntity>[];

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
