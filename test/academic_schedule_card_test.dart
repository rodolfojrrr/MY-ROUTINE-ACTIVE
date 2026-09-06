import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_routine_active/core/sync_entity.dart';
import 'package:my_routine_active/widgets/academic_schedule_card.dart';

void main() {
  const subject = SyncEntity(
    id: 'subject-1',
    type: 'subject',
    payload: <String, dynamic>{
      'name': 'Banco de Dados I',
      'folderColor': 0xFF2F8CFF,
      'folderIcon': 'database',
      'coverImageBase64':
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    },
    updatedAtMs: 1,
    deviceId: 'teste',
    revision: 1,
  );
  const session = SyncEntity(
    id: 'session-1',
    type: 'class_session',
    payload: <String, dynamic>{
      'subjectId': 'subject-1',
      'start': '18:30',
      'end': '20:10',
      'room': 'Laboratório 04',
    },
    updatedAtMs: 1,
    deviceId: 'teste',
    revision: 1,
  );

  testWidgets('cartão de horário com capa cabe no celular', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 160,
              height: 145,
              child: AcademicScheduleCard(
                subject: subject,
                session: session,
                compact: true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Banco de Dados I'), findsOneWidget);
    expect(find.text('18:30–20:10'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
