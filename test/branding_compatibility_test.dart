import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Studium SI preserva identificadores e dados da instalação anterior',
      () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final database = File('lib/core/local_database.dart').readAsStringSync();
    final installer = File('installer/MyRoutineActive.iss').readAsStringSync();

    expect(manifest, contains('android:label="Studium SI"'));
    expect(manifest, contains('android:roundIcon="@mipmap/ic_launcher"'));
    expect(gradle, contains('applicationId = "com.rodolfo.myroutineactive"'));
    expect(database, contains("'MyRoutineActive'"));
    expect(database, contains("'my_routine_active.db'"));
    expect(installer, contains('2DDA2A48-8C38-4F7B-A006-C98D12CF79E8'));
    expect(installer, contains('#define MyAppName "Studium SI"'));
  });

  test('nova identidade possui recursos para Android e Windows', () {
    final resources = <String>[
      'assets/branding/studium_si_icon.png',
      'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
      'android/app/src/main/res/mipmap-hdpi/ic_launcher.png',
      'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png',
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png',
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
      'android/app/src/main/res/drawable-nodpi/studium_launcher_foreground.png',
      'android/app/src/main/res/drawable-nodpi/studium_launcher_monochrome.png',
      'android/app/src/main/res/mipmap-anydpi-v33/ic_launcher.xml',
      'windows/runner/resources/app_icon.ico',
    ];

    for (final path in resources) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'Recurso ausente: $path');
      expect(file.lengthSync(), greaterThan(0), reason: 'Recurso vazio: $path');
    }
  });
}
