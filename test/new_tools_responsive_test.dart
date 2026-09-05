import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_routine_active/core/app_store.dart';
import 'package:my_routine_active/core/app_theme.dart';
import 'package:my_routine_active/core/study_timer_controller.dart';
import 'package:my_routine_active/core/sync_entity.dart';
import 'package:my_routine_active/screens/daily_goals_screen.dart';
import 'package:my_routine_active/screens/academic_courses_screen.dart';
import 'package:my_routine_active/screens/academic_dashboard_screen.dart';
import 'package:my_routine_active/screens/academic_summaries_screen.dart';
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
      AcademicSummariesScreen(store: store),
      AcademicCoursesScreen(store: store),
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

  testWidgets('cadeira com quatro áreas permanece responsiva no celular',
      (tester) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = _DetailedResponsiveStore();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: AcademicSubjectDetailScreen(
          store: store,
          subjectId: 'subject-1',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Conteúdos'), findsOneWidget);
    expect(find.text('Flashcards'), findsOneWidget);
    expect(find.text('Provas e notas'), findsOneWidget);
    expect(find.text('Simulados'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Modelo relacional'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir ambiente deste conteúdo'));
    await tester.pumpAndSettle();

    expect(find.text('Modelo relacional'), findsWidgets);
    expect(find.text('Resumos'), findsWidgets);
    expect(find.text('Provas e notas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('atalho de resumos no PDF sempre oferece navegação de volta',
      (tester) async {
    final store = _ResponsiveStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: PdfToolsScreen(store: store)),
      ),
    );

    await tester.tap(find.text('Abrir resumos'));
    await tester.pumpAndSettle();
    expect(find.text('Resumos e PDFs'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Ferramentas PDF'), findsOneWidget);
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

class _DetailedResponsiveStore extends _ResponsiveStore {
  final List<SyncEntity> entities = const <SyncEntity>[
    SyncEntity(
      id: 'semester-1',
      type: EntityTypes.semester,
      payload: <String, dynamic>{
        'name': '2026.2 — 4º semestre',
        'kind': 'semester',
        'status': 'current',
        'year': 2026,
        'term': 2,
      },
      updatedAtMs: 1,
      deviceId: 'test',
      revision: 1,
    ),
    SyncEntity(
      id: 'subject-1',
      type: EntityTypes.subject,
      payload: <String, dynamic>{
        'name': 'Banco de Dados',
        'semesterId': 'semester-1',
      },
      updatedAtMs: 1,
      deviceId: 'test',
      revision: 1,
    ),
    SyncEntity(
      id: 'content-1',
      type: EntityTypes.studyContent,
      payload: <String, dynamic>{
        'title': 'Modelo relacional',
        'subjectId': 'subject-1',
        'order': 1,
      },
      updatedAtMs: 1,
      deviceId: 'test',
      revision: 1,
    ),
  ];

  @override
  List<SyncEntity> records(String type) =>
      entities.where((item) => item.type == type).toList();

  @override
  SyncEntity? byId(String id) {
    for (final entity in entities) {
      if (entity.id == id) return entity;
    }
    return null;
  }
}
