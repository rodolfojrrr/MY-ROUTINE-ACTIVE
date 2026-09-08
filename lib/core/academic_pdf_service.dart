import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'academic_data.dart';
import 'app_store.dart';
import 'file_transfer_service.dart';
import 'rich_summary_document.dart';
import 'sync_entity.dart';

class AcademicPdfService {
  static Future<String?> exportSummary({
    required AppStore store,
    required SyncEntity summary,
  }) async {
    final title = summary.payload['title'] as String? ?? 'Resumo';
    final bytes = await buildSummaryBytes(store: store, summary: summary);
    return FileTransferService.saveBytes(
      bytes: bytes,
      fileName: '${AcademicData.safeFileName(title)}.pdf',
      dialogTitle: 'Salvar PDF do resumo',
      extension: 'pdf',
    );
  }

  static Future<Uint8List> buildSummaryBytes({
    required AppStore store,
    required SyncEntity summary,
  }) async {
    final title = summary.payload['title'] as String? ?? 'Resumo';
    final subject = AcademicData.subjectName(
      store,
      summary.payload['subjectId'] as String?,
    );
    final content = AcademicData.contentName(
      store,
      summary.payload['contentId'] as String?,
    );
    final semesterId = store
        .byId(summary.payload['subjectId'] as String? ?? '')
        ?.payload['semesterId'] as String?;
    final semester = AcademicData.semesterName(store, semesterId);
    final richDocument = AcademicData.summaryDocument(summary);
    final attachments = AcademicData.summaryAttachments(summary);

    final document = pw.Document(
      title: title,
      author: 'Studium SI',
      subject: '$subject • $content',
      creator: 'Studium SI',
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 46, 42, 46),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.blue400, width: 1),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: <pw.Widget>[
              pw.Text(
                'STUDIUM SI',
                style: pw.TextStyle(
                  color: PdfColors.blue700,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              pw.Text(
                DateFormat('dd/MM/yyyy').format(DateTime.now()),
                style: const pw.TextStyle(
                  color: PdfColors.grey600,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
          ),
        ),
        build: (context) => <pw.Widget>[
          pw.SizedBox(height: 22),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 25,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Wrap(
            spacing: 8,
            runSpacing: 6,
            children: <pw.Widget>[_tag(semester), _tag(subject), _tag(content)],
          ),
          pw.SizedBox(height: 22),
          if (richDocument.plainText.trim().isEmpty &&
              richDocument.embeds.isEmpty)
            pw.Text(
              'Este resumo não possui texto.',
              style: const pw.TextStyle(color: PdfColors.grey600),
            )
          else
            ..._documentWidgets(richDocument),
          if (attachments.isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 18),
            pw.Text(
              'ANEXOS DO RESUMO',
              style: pw.TextStyle(
                color: PdfColors.blue700,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            pw.SizedBox(height: 7),
            ...attachments.map(
              (item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  '• ${item['name'] as String? ?? 'Anexo'} (${_formatBytes((item['sizeBytes'] as num? ?? 0).toInt())})',
                  style: const pw.TextStyle(
                    color: PdfColors.blueGrey800,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ),
            pw.Text(
              'Os arquivos originais permanecem anexados ao resumo no Studium SI.',
              style: const pw.TextStyle(
                color: PdfColors.grey600,
                fontSize: 8.5,
              ),
            ),
          ],
          pw.SizedBox(height: 22),
          pw.Divider(color: PdfColors.grey300),
          pw.Text(
            'Gerado localmente. Nenhum dado foi enviado para a nuvem.',
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
          ),
        ],
      ),
    );

    return Uint8List.fromList(await document.save());
  }

  static pw.Widget _tag(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Text(
        text,
        style: const pw.TextStyle(color: PdfColors.blue700, fontSize: 9),
      ),
    );
  }

  static List<pw.Widget> _documentWidgets(RichSummaryDocument document) {
    final result = <pw.Widget>[];
    var cursor = 0;
    var embedIndex = 0;
    for (var index = 0; index < document.text.length; index++) {
      if (document.text[index] != summaryEmbedPlaceholder) continue;
      if (index > cursor) {
        result.add(_richText(document, cursor, index));
      }
      if (embedIndex < document.embeds.length) {
        result.add(_pdfEmbed(document.embeds[embedIndex++]));
      }
      cursor = index + 1;
    }
    if (cursor < document.text.length) {
      result.add(_richText(document, cursor, document.text.length));
    }
    return result;
  }

  static pw.Widget _richText(RichSummaryDocument document, int start, int end) {
    return pw.RichText(
      textAlign: _pdfTextAlign(document.textAlignment),
      text: pw.TextSpan(
        style: const pw.TextStyle(
          fontSize: 11.5,
          lineSpacing: 4,
          color: PdfColors.blueGrey900,
        ),
        children: document
            .segmentsBetween(start, end)
            .map(
              (segment) => pw.TextSpan(
                text: segment.text,
                style: _pdfTextStyle(segment.style),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  static pw.Widget _pdfEmbed(SummaryEmbed embed) {
    const pageBodyWidth = 511.0;
    final width = (pageBodyWidth * embed.widthFactor)
        .clamp(154.0, pageBodyWidth)
        .toDouble();
    final alignment = switch (embed.alignment) {
      'left' => pw.Alignment.centerLeft,
      'right' => pw.Alignment.centerRight,
      _ => pw.Alignment.center,
    };
    if (embed.isImage) {
      try {
        final bytes = base64Decode(embed.base64);
        final image = pw.MemoryImage(Uint8List.fromList(bytes));
        return pw.Align(
          alignment: alignment,
          child: pw.Container(
            width: width,
            margin: const pw.EdgeInsets.symmetric(vertical: 10),
            padding: const pw.EdgeInsets.all(7),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blueGrey200),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Image(
                  image,
                  height: (embed.height * .62).clamp(75, 330).toDouble(),
                  width: width - 14,
                  fit: pw.BoxFit.contain,
                ),
                if (embed.caption.isNotEmpty) ...<pw.Widget>[
                  pw.SizedBox(height: 5),
                  pw.Text(
                    embed.caption,
                    style: const pw.TextStyle(
                      color: PdfColors.blueGrey700,
                      fontSize: 8.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      } catch (_) {
        return pw.SizedBox.shrink();
      }
    }
    return pw.Align(
      alignment: alignment,
      child: pw.Container(
        width: width,
        margin: const pw.EdgeInsets.symmetric(vertical: 10),
        decoration: pw.BoxDecoration(
          color: PdfColors.blueGrey900,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
          border: pw.Border.all(color: PdfColors.blueGrey700),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: <pw.Widget>[
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey800,
                borderRadius: pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(7),
                  topRight: pw.Radius.circular(7),
                ),
              ),
              child: pw.Text(
                embed.language.toUpperCase(),
                style: pw.TextStyle(
                  color: PdfColors.blue200,
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: .8,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Text(
                _wrapCodeForPdf(embed.code, width, embed.height),
                style: pw.TextStyle(
                  color: PdfColors.grey100,
                  fontSize: 8.2,
                  lineSpacing: 2.6,
                  font: pw.Font.courier(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _wrapCodeForPdf(String code, double width, double height) {
    final maxCharacters = ((width - 20) / 4.8).floor().clamp(18, 105);
    final lines = <String>[];
    for (final sourceLine in code.split('\n')) {
      var line = sourceLine;
      if (line.isEmpty) {
        lines.add('');
        continue;
      }
      while (line.length > maxCharacters) {
        lines.add(line.substring(0, maxCharacters));
        line = '  ${line.substring(maxCharacters)}';
      }
      lines.add(line);
    }
    final maxLines = ((height * .62 - 46) / 10).floor().clamp(3, 34);
    if (lines.length <= maxLines) return lines.join('\n');
    return <String>[
      ...lines.take(maxLines - 1),
      '… restante disponível no resumo do aplicativo',
    ].join('\n');
  }

  static pw.TextStyle _pdfTextStyle(SummaryTextStyle value) {
    final decorations = <pw.TextDecoration>[
      if (value.underline) pw.TextDecoration.underline,
      if (value.strikeThrough) pw.TextDecoration.lineThrough,
    ];
    return pw.TextStyle(
      color: value.codeBlock
          ? PdfColors.blue800
          : value.accent
              ? PdfColors.blue700
              : PdfColors.blueGrey900,
      fontSize: (value.fontSize * .72).clamp(9, 22).toDouble(),
      fontWeight: value.bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontStyle: value.italic ? pw.FontStyle.italic : pw.FontStyle.normal,
      fontNormal: value.monospace || value.codeBlock ? pw.Font.courier() : null,
      fontBold:
          value.monospace || value.codeBlock ? pw.Font.courierBold() : null,
      fontItalic:
          value.monospace || value.codeBlock ? pw.Font.courierOblique() : null,
      fontBoldItalic: value.monospace || value.codeBlock
          ? pw.Font.courierBoldOblique()
          : null,
      background: value.codeBlock
          ? const pw.BoxDecoration(color: PdfColors.blueGrey50)
          : value.highlight
              ? const pw.BoxDecoration(color: PdfColors.yellow100)
              : null,
      lineSpacing: 4,
      decoration: decorations.isEmpty
          ? pw.TextDecoration.none
          : pw.TextDecoration.combine(decorations),
      decorationColor: value.accent ? PdfColors.blue700 : PdfColors.blueGrey900,
    );
  }

  static pw.TextAlign _pdfTextAlign(String value) => switch (value) {
        'center' => pw.TextAlign.center,
        'right' => pw.TextAlign.right,
        'justify' => pw.TextAlign.justify,
        _ => pw.TextAlign.left,
      };

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return 'tamanho não informado';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
