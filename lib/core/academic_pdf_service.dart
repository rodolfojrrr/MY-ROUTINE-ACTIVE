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
    final imageWidgets = <pw.Widget>[];

    for (final item in AcademicData.summaryImages(summary)) {
      try {
        final bytes = base64Decode(item['base64'] as String);
        final provider = pw.MemoryImage(Uint8List.fromList(bytes));
        imageWidgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 14),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Image(provider, height: 300, fit: pw.BoxFit.contain),
                pw.SizedBox(height: 6),
                pw.Text(
                  item['name'] as String? ?? 'Imagem do resumo',
                  style: const pw.TextStyle(
                    color: PdfColors.grey700,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        );
      } catch (_) {}
    }

    final document = pw.Document(
      title: title,
      author: 'Smart Routine SI',
      subject: '$subject • $content',
      creator: 'Smart Routine SI',
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
                'SMART ROUTINE SI',
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
          if (richDocument.text.trim().isEmpty)
            pw.Text(
              'Este resumo não possui texto.',
              style: const pw.TextStyle(color: PdfColors.grey600),
            )
          else
            pw.RichText(
              text: pw.TextSpan(
                style: const pw.TextStyle(
                  fontSize: 11.5,
                  lineSpacing: 4,
                  color: PdfColors.blueGrey900,
                ),
                children: richDocument.segments
                    .map(
                      (segment) => pw.TextSpan(
                        text: segment.text,
                        style: _pdfTextStyle(segment.style),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ...imageWidgets,
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
              'Os arquivos originais permanecem anexados ao resumo no Smart Routine SI.',
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

    final bytes = Uint8List.fromList(await document.save());
    return FileTransferService.saveBytes(
      bytes: bytes,
      fileName: '${AcademicData.safeFileName(title)}.pdf',
      dialogTitle: 'Salvar PDF do resumo',
      extension: 'pdf',
    );
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

  static pw.TextStyle _pdfTextStyle(SummaryTextStyle value) {
    final decorations = <pw.TextDecoration>[
      if (value.underline) pw.TextDecoration.underline,
      if (value.strikeThrough) pw.TextDecoration.lineThrough,
    ];
    return pw.TextStyle(
      color: value.accent ? PdfColors.blue700 : PdfColors.blueGrey900,
      fontSize: (value.fontSize * .72).clamp(9, 22).toDouble(),
      fontWeight: value.bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontStyle: value.italic ? pw.FontStyle.italic : pw.FontStyle.normal,
      fontNormal: value.monospace ? pw.Font.courier() : null,
      fontBold: value.monospace ? pw.Font.courierBold() : null,
      fontItalic: value.monospace ? pw.Font.courierOblique() : null,
      fontBoldItalic: value.monospace ? pw.Font.courierBoldOblique() : null,
      lineSpacing: 4,
      decoration: decorations.isEmpty
          ? pw.TextDecoration.none
          : pw.TextDecoration.combine(decorations),
      decorationColor: value.accent ? PdfColors.blue700 : PdfColors.blueGrey900,
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return 'tamanho não informado';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
