import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'academic_data.dart';
import 'app_store.dart';
import 'file_transfer_service.dart';
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
    final semesterId =
        store
                .byId(summary.payload['subjectId'] as String? ?? '')
                ?.payload['semesterId']
            as String?;
    final semester = AcademicData.semesterName(store, semesterId);
    final body = summary.payload['body'] as String? ?? '';
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
              bottom: pw.BorderSide(color: PdfColors.deepPurple400, width: 1),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: <pw.Widget>[
              pw.Text(
                'SMART ROUTINE SI',
                style: pw.TextStyle(
                  color: PdfColors.deepPurple600,
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
          if (body.trim().isEmpty)
            pw.Text(
              'Este resumo não possui texto.',
              style: const pw.TextStyle(color: PdfColors.grey600),
            )
          else
            pw.Text(
              body,
              style: const pw.TextStyle(
                fontSize: 11.5,
                lineSpacing: 4,
                color: PdfColors.blueGrey900,
              ),
            ),
          ...imageWidgets,
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
        color: PdfColors.deepPurple50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Text(
        text,
        style: const pw.TextStyle(color: PdfColors.deepPurple700, fontSize: 9),
      ),
    );
  }
}
