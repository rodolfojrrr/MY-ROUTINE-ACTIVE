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
}
