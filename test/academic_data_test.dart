import 'package:flutter_test/flutter_test.dart';
import 'package:my_routine_active/core/academic_data.dart';
import 'package:my_routine_active/core/sync_entity.dart';

void main() {
  test('AcademicData cria nome seguro para o PDF do resumo', () {
    expect(
      AcademicData.safeFileName('  Programação Orientada à Objetos!  '),
      'programacao-orientada-a-objetos',
    );
    expect(AcademicData.safeFileName('***'), 'resumo');
  });

  test('AcademicData preserva imagem do formato antigo de resumo', () {
    const summary = SyncEntity(
      id: 'resumo-1',
      type: 'study_note',
      payload: <String, dynamic>{
        'title': 'Banco de dados',
        'imageName': 'quadro.jpg',
        'imageBase64': 'AQIDBA==',
      },
      updatedAtMs: 1,
      deviceId: 'celular',
      revision: 1,
    );

    expect(AcademicData.summaryImages(summary), <Map<String, dynamic>>[
      <String, dynamic>{'name': 'quadro.jpg', 'base64': 'AQIDBA=='},
    ]);
    expect(AcademicData.summaryImageBytes(summary), 4);
  });
}
