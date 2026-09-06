import 'package:flutter_test/flutter_test.dart';
import 'package:my_routine_active/core/academic_pdf_service.dart';
import 'package:my_routine_active/core/app_store.dart';
import 'package:my_routine_active/core/rich_summary_document.dart';
import 'package:my_routine_active/core/sync_entity.dart';

void main() {
  test('PDF aceita imagem no texto e ignora imagem fixada do aplicativo',
      () async {
    const document = RichSummaryDocument(
      text: 'Introdução\n\uFFFC\nExemplo\n\uFFFC\nConclusão',
      embeds: <SummaryEmbed>[
        SummaryEmbed(
          id: 'image-1',
          type: SummaryEmbed.imageType,
          name: 'pixel.png',
          caption: 'Imagem dentro do texto',
          base64:
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
          widthFactor: .5,
          height: 140,
        ),
        SummaryEmbed(
          id: 'code-1',
          type: SummaryEmbed.codeType,
          language: 'sql',
          code: 'SELECT nome FROM alunos WHERE ativo = 1;',
          widthFactor: .8,
          height: 180,
        ),
      ],
    );
    const summary = SyncEntity(
      id: 'summary-1',
      type: 'study_note',
      payload: <String, dynamic>{
        'title': 'Banco de dados',
        'body': 'Introdução Exemplo Conclusão',
        'richText': <String, dynamic>{
          'version': 3,
          'text': 'Introdução\n\uFFFC\nExemplo\n\uFFFC\nConclusão',
          'spans': <dynamic>[],
          'embeds': <dynamic>[
            <String, dynamic>{
              'id': 'image-1',
              'type': 'image',
              'name': 'pixel.png',
              'caption': 'Imagem dentro do texto',
              'base64':
                  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
              'widthFactor': .5,
              'height': 140,
              'alignment': 'center',
            },
            <String, dynamic>{
              'id': 'code-1',
              'type': 'code',
              'language': 'sql',
              'code': 'SELECT nome FROM alunos WHERE ativo = 1;',
              'widthFactor': .8,
              'height': 180,
              'alignment': 'left',
            },
          ],
          'textAlignment': 'left',
          'lineHeight': 1.55,
        },
        'images': <dynamic>[
          <String, dynamic>{
            'name': 'imagem-fixada-somente-no-app.jpg',
            'base64': 'conteudo-invalido-que-nao-deve-ser-lido-pelo-pdf',
          },
        ],
      },
      updatedAtMs: 1,
      deviceId: 'teste',
      revision: 1,
    );

    expect(document.embeds, hasLength(2));
    final bytes = await AcademicPdfService.buildSummaryBytes(
      store: AppStore(),
      summary: summary,
    );

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
