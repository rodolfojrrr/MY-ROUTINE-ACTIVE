import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_routine_active/core/app_store.dart';
import 'package:my_routine_active/core/local_database.dart';
import 'package:my_routine_active/core/study_timer_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cronômetro volta pausado depois de fechar ou ocultar o app', () async {
    final database = await LocalDatabase.createInMemoryForTesting();
    final store = AppStore(database: database);
    await store.initialize();
    final first = StudyTimerController(store);
    await first.initializeForActiveAccount();
    await first.start(title: 'Revisar algoritmos', plannedMinutes: 45);

    first.didChangeAppLifecycleState(AppLifecycleState.paused);
    await Future<void>.delayed(Duration.zero);
    expect(first.status, StudyTimerStatus.paused);

    final restored = StudyTimerController(store);
    await restored.initializeForActiveAccount();
    expect(restored.status, StudyTimerStatus.paused);
    expect(restored.title, 'Revisar algoritmos');
    expect(restored.plannedMinutes, 45);

    first.dispose();
    restored.dispose();
    store.dispose();
    await database.close();
  });
}
