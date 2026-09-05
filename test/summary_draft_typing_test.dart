import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_routine_active/core/app_store.dart';
import 'package:my_routine_active/core/app_theme.dart';
import 'package:my_routine_active/core/sync_entity.dart';
import 'package:my_routine_active/screens/academic_summaries_screen.dart';

void main() {
  testWidgets('campos continuam digitáveis e restauram rascunho',
      (tester) async {
    final store = _MemorySummaryStore();

    Future<void> pumpEditor() => tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: Scaffold(
              body: AcademicSummaryEditorDialog(store: store),
            ),
          ),
        );

    await pumpEditor();
    await tester.pump(const Duration(milliseconds: 100));
    final title = find.byKey(
      const ValueKey<String>('summary-title-field'),
    );
    final body = find.byKey(
      const ValueKey<String>('summary-body-field'),
    );
    await tester.enterText(title, 'Laços em Dart');
    await tester.enterText(body, 'for, while e do-while continuam digitáveis.');
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Laços em Dart'), findsOneWidget);
    expect(
      find.text('for, while e do-while continuam digitáveis.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpEditor();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Laços em Dart'), findsOneWidget);
    expect(
      find.text('for, while e do-while continuam digitáveis.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

  testWidgets('editor rico permanece encaixado no celular durante o autosave',
      (tester) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = _MemorySummaryStore();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: AcademicSummaryEditorDialog(store: store),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await tester.enterText(
      find.byKey(const ValueKey<String>('summary-title-field')),
      'Normalização',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('summary-body-field')),
      'Primeira, segunda e terceira forma normal.',
    );
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('EDITOR DO RESUMO'), findsOneWidget);
    expect(find.byIcon(Icons.save_outlined), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

class _MemorySummaryStore extends AppStore {
  _MemorySummaryStore();

  final Map<String, String> preferences = <String, String>{};

  final SyncEntity subject = const SyncEntity(
    id: 'subject-1',
    type: EntityTypes.subject,
    payload: <String, dynamic>{'name': 'Algoritmos'},
    updatedAtMs: 1,
    deviceId: 'test',
    revision: 1,
  );

  final SyncEntity content = const SyncEntity(
    id: 'content-1',
    type: EntityTypes.studyContent,
    payload: <String, dynamic>{
      'subjectId': 'subject-1',
      'title': 'Estruturas de repetição',
      'order': 1,
    },
    updatedAtMs: 1,
    deviceId: 'test',
    revision: 1,
  );

  @override
  List<SyncEntity> records(String type) => switch (type) {
        EntityTypes.subject => <SyncEntity>[subject],
        EntityTypes.studyContent => <SyncEntity>[content],
        _ => <SyncEntity>[],
      };

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
