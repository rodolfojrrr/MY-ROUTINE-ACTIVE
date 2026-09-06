import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_routine_active/core/app_store.dart';
import 'package:my_routine_active/core/app_theme.dart';
import 'package:my_routine_active/core/sync_entity.dart';
import 'package:my_routine_active/screens/academic_courses_screen.dart';
import 'package:my_routine_active/screens/academic_faculty_screen.dart';

void main() {
  testWidgets('curso navega por pastas de módulo conteúdo e materiais', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = _CourseStore.seeded();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: AcademicCoursesScreen(store: store)),
      ),
    );
    await tester.pumpAndSettle();

    final courseFolder = find.byKey(const Key('course-folder-course-1'));
    expect(courseFolder, findsOneWidget);
    expect(find.text('Cursando agora'), findsOneWidget);
    await tester.ensureVisible(courseFolder);
    await tester.tap(courseFolder);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('courses-add-module')), findsOneWidget);
    final moduleFolder = find.byKey(const Key('course-module-module-1'));
    await tester.ensureVisible(moduleFolder);
    await tester.tap(moduleFolder);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('course-add-content')), findsOneWidget);
    final contentFolder = find.byKey(const Key('content-folder-content-1'));
    await tester.ensureVisible(contentFolder);
    await tester.tap(contentFolder);
    await tester.pumpAndSettle();

    expect(find.text('Pastas deste conteúdo'), findsOneWidget);
    expect(find.text('Resumos'), findsOneWidget);
    expect(find.text('Códigos'), findsOneWidget);
    expect(find.text('Imagens'), findsOneWidget);
    expect(find.text('Anexos'), findsOneWidget);
    expect(find.text('Simulados'), findsOneWidget);
    expect(find.text('Flashcards'), findsOneWidget);
    expect(find.text('Provas e notas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('curso pode ser incluído no calendário semanal', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = _CourseStore.seeded();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: AcademicSchedulePage(store: store, courseId: 'course-1'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('course-add-schedule')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('schedule-source-type')), findsOneWidget);
    expect(find.byKey(const Key('schedule-course-field')), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    final sessions = store.records(EntityTypes.classSession);
    expect(sessions, hasLength(1));
    expect(sessions.single.payload['courseId'], 'course-1');
    expect(sessions.single.payload['subjectId'], isNull);
    expect(sessions.single.payload['sourceType'], 'course');
    expect(find.text('Flutter profissional'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('novo módulo aparece na pasta do curso em tempo real', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = _CourseStore.seeded();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: AcademicCourseFolderPage(
          store: store,
          courseId: 'course-1',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'tela inicial do curso');
    await tester.tap(find.byKey(const Key('courses-add-module')));
    await tester.pumpAndSettle();

    expect(find.text('Novo módulo'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Persistência local');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('course-module-created-1')), findsOneWidget);
    expect(find.text('Persistência local'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

class _CourseStore extends AppStore {
  _CourseStore(this.entities);

  factory _CourseStore.seeded() => _CourseStore(<SyncEntity>[
        const SyncEntity(
          id: 'course-1',
          type: EntityTypes.semester,
          payload: <String, dynamic>{
            'name': 'Flutter profissional',
            'kind': 'course',
            'status': 'current',
            'institution': 'Curso local',
            'folderColor': 0xFF00B894,
            'folderIcon': 'code',
          },
          updatedAtMs: 1,
          deviceId: 'test',
          revision: 1,
        ),
        const SyncEntity(
          id: 'module-1',
          type: EntityTypes.subject,
          payload: <String, dynamic>{
            'name': 'Widgets e layout',
            'semesterId': 'course-1',
            'folderColor': 0xFF2F8CFF,
            'folderIcon': 'flutter',
          },
          updatedAtMs: 1,
          deviceId: 'test',
          revision: 1,
        ),
        const SyncEntity(
          id: 'content-1',
          type: EntityTypes.studyContent,
          payload: <String, dynamic>{
            'title': 'Layout responsivo',
            'subjectId': 'module-1',
            'order': 1,
            'folderColor': 0xFF6C5CE7,
          },
          updatedAtMs: 1,
          deviceId: 'test',
          revision: 1,
        ),
      ]);

  final List<SyncEntity> entities;
  var counter = 0;

  @override
  String get deviceId => 'course-test';

  @override
  List<SyncEntity> records(String type) => entities
      .where((item) => item.type == type && !item.isDeleted)
      .toList(growable: false);

  @override
  SyncEntity? byId(String id) {
    for (final item in entities) {
      if (item.id == id && !item.isDeleted) return item;
    }
    return null;
  }

  @override
  Future<SyncEntity> save(
    String type,
    Map<String, dynamic> payload, {
    String? id,
  }) async {
    final existingIndex =
        id == null ? -1 : entities.indexWhere((item) => item.id == id);
    final previous = existingIndex < 0 ? null : entities[existingIndex];
    final entity = SyncEntity(
      id: id ?? 'created-${++counter}',
      type: type,
      payload: Map<String, dynamic>.from(payload),
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      deviceId: deviceId,
      revision: (previous?.revision ?? 0) + 1,
    );
    if (existingIndex < 0) {
      entities.add(entity);
    } else {
      entities[existingIndex] = entity;
    }
    notifyListeners();
    return entity;
  }
}
