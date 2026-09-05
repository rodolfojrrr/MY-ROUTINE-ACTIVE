import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_routine_active/core/academic_data.dart';
import 'package:my_routine_active/core/app_store.dart';
import 'package:my_routine_active/core/app_theme.dart';
import 'package:my_routine_active/core/sync_entity.dart';
import 'package:my_routine_active/screens/academic_faculty_screen.dart';

void main() {
  testWidgets('faculdade navega por semestre matéria conteúdo e ferramentas',
      (tester) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = _FacultyStore.seeded();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: AcademicFacultyScreen(store: store)),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('current-semester-banner')), findsOneWidget);
    expect(find.byKey(const Key('semester-folder-semester-1')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('current-semester-banner')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('faculty-add-subject')), findsOneWidget);
    expect(find.byKey(const Key('subject-folder-subject-1')), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -420));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('subject-folder-subject-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('faculty-add-content')), findsOneWidget);
    expect(find.byKey(const Key('content-folder-content-1')), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -420));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('content-folder-content-1')));
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

  testWidgets('semestre salvo aparece imediatamente sem reabrir a tela',
      (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = _FacultyStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(body: AcademicFacultyScreen(store: store)),
      ),
    );

    await tester.tap(find.byKey(const Key('faculty-add-semester')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField).first, '2027.1 — 5º semestre');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('2027.1 — 5º semestre'), findsWidgets);
    expect(find.byKey(const Key('current-semester-banner')), findsOneWidget);
    expect(find.byKey(const Key('semester-folder-created-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('matéria e conteúdo novos aparecem na pasta aberta',
      (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = _FacultyStore(
      const <SyncEntity>[
        SyncEntity(
          id: 'semester-only',
          type: EntityTypes.semester,
          payload: <String, dynamic>{
            'name': '2027.1',
            'kind': 'semester',
            'status': 'current',
            'year': 2027,
            'term': 1,
          },
          updatedAtMs: 1,
          deviceId: 'test',
          revision: 1,
        ),
      ],
    );
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: AcademicSemesterPage(
          store: store,
          semesterId: 'semester-only',
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('faculty-add-subject')));
    await tester.pumpAndSettle();
    expect(find.text('APARÊNCIA DA PASTA'), findsOneWidget);
    await tester.enterText(
        find.byType(TextField).first, 'Redes de Computadores');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('subject-folder-created-1')), findsOneWidget);
    expect(store.byId('created-1')?.payload['folderIcon'], 'code');
    expect(store.byId('created-1')?.payload['folderColor'], isA<int>());
    expect(
      tester.takeException(),
      isNull,
      reason: 'A pasta de matéria não pode estourar a largura.',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: AcademicSubjectFolderPage(
          store: store,
          semesterId: 'semester-only',
          subjectId: 'created-1',
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('faculty-add-content')));
    await tester.pumpAndSettle();
    expect(
      tester.takeException(),
      isNull,
      reason: 'O formulário de conteúdo não pode estourar a largura.',
    );
    await tester.enterText(find.byType(TextField).first, 'Modelo OSI');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('content-folder-created-2')), findsOneWidget);
    expect(
      tester.takeException(),
      isNull,
      reason: 'A pasta de conteúdo não pode estourar a largura.',
    );
  });

  test('anexos do conteúdo acompanham a exclusão segura para a lixeira',
      () async {
    final store = _FacultyStore(
      const <SyncEntity>[
        SyncEntity(
          id: 'content-delete',
          type: EntityTypes.studyContent,
          payload: <String, dynamic>{
            'title': 'Conteúdo',
            'subjectId': 'subject-delete',
          },
          updatedAtMs: 1,
          deviceId: 'test',
          revision: 1,
        ),
        SyncEntity(
          id: 'asset-delete',
          type: EntityTypes.contentAsset,
          payload: <String, dynamic>{
            'contentId': 'content-delete',
            'subjectId': 'subject-delete',
            'kind': 'attachment',
            'name': 'aula.pdf',
            'base64': 'AQID',
          },
          updatedAtMs: 1,
          deviceId: 'test',
          revision: 1,
        ),
      ],
    );
    addTearDown(store.dispose);

    expect(
      AcademicData.assetsForContent(store, 'content-delete'),
      hasLength(1),
    );
    await AcademicData.deleteContent(
      store,
      store.byId('content-delete')!,
    );
    expect(AcademicData.assetsForContent(store, 'content-delete'), isEmpty);
    expect(store.byId('content-delete'), isNull);
  });
}

class _FacultyStore extends AppStore {
  _FacultyStore([List<SyncEntity>? initial])
      : entities = List<SyncEntity>.from(initial ?? const <SyncEntity>[]);

  factory _FacultyStore.seeded() => _FacultyStore(
        const <SyncEntity>[
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
              'folderIcon': 'database',
              'folderColor': 0xFF2F8CFF,
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
        ],
      );

  final List<SyncEntity> entities;
  var counter = 0;

  @override
  String get deviceId => 'faculty-test';

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

  @override
  Future<void> remove(String id) async {
    entities.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}
