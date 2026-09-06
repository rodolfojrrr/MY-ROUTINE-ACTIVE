import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_routine_active/core/rich_summary_document.dart';

void main() {
  test('resumo antigo abre no editor rico sem perder o texto', () {
    final document = RichSummaryDocument.fromPayload(<String, dynamic>{
      'body': 'Texto criado na versão anterior.',
    });

    expect(document.text, 'Texto criado na versão anterior.');
    expect(document.spans, isEmpty);
    expect(document.toJson()['text'], document.text);
  });

  test('formatação por trecho é serializada e restaurada', () {
    final controller = RichSummaryController(
      const RichSummaryDocument(text: 'Banco de dados relacional'),
    );
    addTearDown(controller.dispose);
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 14);
    controller.applyToSelection(
      (style) => style.copyWith(bold: true, accent: true, fontSize: 23),
    );

    final restored = RichSummaryDocument.fromPayload(<String, dynamic>{
      'richText': controller.document.toJson(),
    });

    expect(restored.text, 'Banco de dados relacional');
    expect(restored.spans, hasLength(1));
    expect(restored.spans.single.start, 0);
    expect(restored.spans.single.end, 14);
    expect(restored.spans.single.style.bold, isTrue);
    expect(restored.spans.single.style.accent, isTrue);
    expect(restored.spans.single.style.fontSize, 23);
  });

  test('digitação mantém a formatação ativa no novo texto', () {
    final controller = RichSummaryController(
      const RichSummaryDocument(text: ''),
    );
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 0);
    controller.applyToSelection((style) => style.copyWith(bold: true));
    controller.value = const TextEditingValue(
      text: 'Título',
      selection: TextSelection.collapsed(offset: 6),
    );

    expect(controller.document.spans, hasLength(1));
    expect(controller.document.spans.single.style.bold, isTrue);
    expect(controller.document.spans.single.end, 6);
  });

  test('recursos profissionais são serializados sem perder compatibilidade',
      () {
    final controller = RichSummaryController(
      const RichSummaryDocument(text: 'SELECT * FROM alunos;'),
    );
    addTearDown(controller.dispose);
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 21);
    controller.applyToSelection(
      (style) => style.copyWith(highlight: true),
    );
    controller.toggleCodeBlock();
    controller.setTextAlignment('justify');
    controller.setLineHeight(1.8);

    final restored = RichSummaryDocument.fromPayload(<String, dynamic>{
      'richText': controller.document.toJson(),
    });

    expect(restored.textAlignment, 'justify');
    expect(restored.lineHeight, 1.8);
    expect(restored.spans.single.style.highlight, isTrue);
    expect(restored.spans.single.style.codeBlock, isTrue);
    expect(restored.spans.single.style.monospace, isTrue);
    expect(restored.toJson()['version'], 3);
  });

  test('listas de tarefa citações recuo e divisor preservam o texto', () {
    final controller = RichSummaryController(
      const RichSummaryDocument(text: 'Primeiro passo\nSegundo passo'),
    );
    addTearDown(controller.dispose);
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
    controller.replaceParagraphsWithChecklist();
    expect(controller.text, '☐ Primeiro passo\n☐ Segundo passo');

    controller.replaceParagraphsWithQuote();
    expect(controller.text, '> ☐ Primeiro passo\n> ☐ Segundo passo');
    controller.indentParagraphs(outdent: false);
    expect(controller.text, startsWith('    > ☐ Primeiro passo'));
    controller.indentParagraphs(outdent: true);
    controller.selection =
        TextSelection.collapsed(offset: controller.text.length);
    controller.insertDivider();
    expect(controller.text, contains('────────────────────────'));
  });

  test('imagem e código entram no documento sem quebrar texto antigo', () {
    final controller = RichSummaryController(
      const RichSummaryDocument(text: 'Introdução'),
    );
    addTearDown(controller.dispose);
    controller.selection =
        TextSelection.collapsed(offset: controller.text.length);
    controller.insertEmbed(
      const SummaryEmbed(
        id: 'codigo-1',
        type: SummaryEmbed.codeType,
        language: 'sql',
        code: 'SELECT * FROM alunos;',
        widthFactor: .8,
        height: 220,
      ),
    );

    final restored = RichSummaryDocument.fromPayload(<String, dynamic>{
      'richText': controller.document.toJson(),
    });

    expect(restored.embeds, hasLength(1));
    expect(restored.embeds.single.language, 'sql');
    expect(restored.text, contains(summaryEmbedPlaceholder));
    expect(restored.plainText, contains('SELECT * FROM alunos;'));
  });

  test('remover elemento interno também remove seu marcador invisível', () {
    final controller = RichSummaryController(
      const RichSummaryDocument(text: 'Antes\nDepois'),
    );
    addTearDown(controller.dispose);
    controller.selection = const TextSelection.collapsed(offset: 6);
    controller.insertEmbed(
      const SummaryEmbed(
        id: 'imagem-1',
        type: SummaryEmbed.imageType,
        name: 'diagrama.png',
        base64: 'AQID',
      ),
    );
    expect(controller.embeds, hasLength(1));

    controller.removeEmbed('imagem-1');

    expect(controller.embeds, isEmpty);
    expect(controller.text, isNot(contains(summaryEmbedPlaceholder)));
    expect(controller.plainText, contains('Antes'));
    expect(controller.plainText, contains('Depois'));
  });

  testWidgets('campo de texto renderiza elemento rico dentro da página',
      (tester) async {
    final controller = RichSummaryController(
      const RichSummaryDocument(
        text: 'Antes\n\uFFFC\nDepois',
        embeds: <SummaryEmbed>[
          SummaryEmbed(
            id: 'code-widget',
            type: SummaryEmbed.codeType,
            code: 'print("teste");',
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);
    controller.setEmbedBuilder(
      (embed) => SizedBox(
        key: ValueKey<String>('inline-${embed.id}'),
        width: 220,
        height: 120,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 400,
            child: TextField(
              controller: controller,
              maxLines: null,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey<String>('inline-code-widget')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('desfazer e refazer a edição preserva o elemento incorporado', () {
    const originalText = 'Antes\n\uFFFC\nDepois';
    final controller = RichSummaryController(
      const RichSummaryDocument(
        text: originalText,
        embeds: <SummaryEmbed>[
          SummaryEmbed(
            id: 'codigo-undo',
            type: SummaryEmbed.codeType,
            language: 'python',
            code: 'print("preservado")',
          ),
        ],
      ),
    );
    addTearDown(controller.dispose);

    controller.value = const TextEditingValue(
      text: 'Antes\n\nDepois',
      selection: TextSelection.collapsed(offset: 7),
    );
    expect(controller.embeds, isEmpty);

    controller.value = const TextEditingValue(
      text: originalText,
      selection: TextSelection.collapsed(offset: 7),
    );
    expect(controller.embeds.single.id, 'codigo-undo');
    expect(controller.embeds.single.code, 'print("preservado")');
  });
}
