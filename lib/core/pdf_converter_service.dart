import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'academic_data.dart';
import 'file_transfer_service.dart';

class PdfConversionResult {
  const PdfConversionResult({
    required this.savedPath,
    required this.sourceName,
    required this.method,
  });

  final String? savedPath;
  final String sourceName;
  final String method;
}

class PdfConverterService {
  static const textExtensions = <String>{
    'txt',
    'md',
    'csv',
    'tsv',
    'json',
    'xml',
    'yaml',
    'yml',
    'log',
    'dart',
    'py',
    'java',
    'kt',
    'kts',
    'js',
    'ts',
    'jsx',
    'tsx',
    'c',
    'h',
    'cpp',
    'hpp',
    'cs',
    'php',
    'sql',
    'html',
    'htm',
    'css',
    'ini',
    'conf',
  };

  static const imageExtensions = <String>{'jpg', 'jpeg', 'png'};
  static const modernOfficeExtensions = <String>{'docx', 'xlsx', 'pptx'};
  static const officeExtensions = <String>{
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'odt',
    'ods',
    'odp',
    'rtf',
  };

  static Future<PdfConversionResult?> pickAndConvert() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'Escolher arquivo para converter em PDF',
      type: FileType.any,
      allowMultiple: false,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final file = picked.files.single;
    final extension =
        p.extension(file.name).replaceFirst('.', '').toLowerCase();
    if (file.size > 60 * 1024 * 1024) {
      throw const FileSystemException('O arquivo deve ter no máximo 60 MB.');
    }

    if (Platform.isWindows && officeExtensions.contains(extension)) {
      final converted = await _convertOfficeOnWindows(file, extension);
      if (converted != null) return converted;
    }

    final bytes = await _bytes(file);
    if (bytes == null) {
      throw const FileSystemException(
          'Não foi possível ler o arquivo selecionado.');
    }
    if (extension == 'pdf') {
      return _save(
        bytes,
        sourceName: file.name,
        method: 'Cópia local do PDF original',
      );
    }
    if (imageExtensions.contains(extension)) {
      return _imageToPdf(file.name, bytes);
    }
    if (textExtensions.contains(extension)) {
      var text = utf8.decode(bytes, allowMalformed: true);
      if (extension == 'html' || extension == 'htm') {
        text = _plainXmlText(text);
      }
      return _textToPdf(file.name, text, method: 'Texto e código formatados');
    }
    if (modernOfficeExtensions.contains(extension)) {
      final text = _extractModernOfficeText(bytes, extension);
      return _textToPdf(
        file.name,
        text,
        method: 'Conteúdo textual extraído localmente do arquivo Office',
      );
    }
    throw const FormatException(
      'Este formato não possui conversor local disponível. No Windows, arquivos Office exigem Microsoft Office ou LibreOffice instalado.',
    );
  }

  static Future<PdfConversionResult> _imageToPdf(
    String sourceName,
    Uint8List bytes,
  ) async {
    final document = pw.Document(
      title: p.basenameWithoutExtension(sourceName),
      creator: 'Smart Routine SI',
    );
    final image = pw.MemoryImage(bytes);
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      ),
    );
    return _save(
      Uint8List.fromList(await document.save()),
      sourceName: sourceName,
      method: 'Imagem convertida localmente',
    );
  }

  static Future<PdfConversionResult> _textToPdf(
    String sourceName,
    String text, {
    required String method,
  }) async {
    final cleanText = text.trim().isEmpty ? 'Arquivo sem texto legível.' : text;
    final document = pw.Document(
      title: p.basenameWithoutExtension(sourceName),
      creator: 'Smart Routine SI',
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(38, 42, 38, 42),
        header: (_) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.blue400, width: .8),
            ),
          ),
          child: pw.Text(
            p.basename(sourceName),
            style: pw.TextStyle(
              color: PdfColors.blue700,
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
          ),
        ),
        build: (_) => <pw.Widget>[
          pw.SizedBox(height: 18),
          pw.Text(
            p.basenameWithoutExtension(sourceName),
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            cleanText,
            style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 3),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.grey300),
          pw.Text(
            'Gerado localmente pelo Smart Routine SI. Método: $method.',
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
          ),
        ],
      ),
    );
    return _save(
      Uint8List.fromList(await document.save()),
      sourceName: sourceName,
      method: method,
    );
  }

  static String _extractModernOfficeText(Uint8List bytes, String extension) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final files = archive.files.where((file) => file.isFile).toList();
      if (extension == 'docx') {
        final file =
            files.where((item) => item.name == 'word/document.xml').firstOrNull;
        if (file == null) {
          throw const FormatException('Documento sem conteúdo.');
        }
        return _plainXmlText(utf8.decode(file.content as List<int>));
      }
      if (extension == 'pptx') {
        final slides = files
            .where(
              (item) =>
                  RegExp(r'^ppt/slides/slide\d+\.xml$').hasMatch(item.name),
            )
            .toList()
          ..sort((a, b) => _numberIn(a.name).compareTo(_numberIn(b.name)));
        return slides
            .asMap()
            .entries
            .map(
              (entry) => 'SLIDE ${entry.key + 1}\n'
                  '${_plainXmlText(utf8.decode(entry.value.content as List<int>))}',
            )
            .join('\n\n');
      }
      final shared = files
          .where((item) => item.name == 'xl/sharedStrings.xml')
          .map((item) => _plainXmlText(utf8.decode(item.content as List<int>)))
          .join('\n');
      final sheets = files
          .where(
            (item) =>
                RegExp(r'^xl/worksheets/sheet\d+\.xml$').hasMatch(item.name),
          )
          .toList()
        ..sort((a, b) => _numberIn(a.name).compareTo(_numberIn(b.name)));
      final values = sheets
          .asMap()
          .entries
          .map(
            (entry) => 'PLANILHA ${entry.key + 1}\n'
                '${_spreadsheetValues(utf8.decode(entry.value.content as List<int>))}',
          )
          .join('\n\n');
      return <String>[shared, values]
          .where((item) => item.trim().isNotEmpty)
          .join('\n\n');
    } catch (error) {
      throw FormatException(
          'Não foi possível extrair o conteúdo do arquivo: $error');
    }
  }

  static int _numberIn(String value) =>
      int.tryParse(RegExp(r'\d+').firstMatch(value)?.group(0) ?? '') ?? 0;

  static String _spreadsheetValues(String xml) {
    final values = RegExp(r'<v>(.*?)</v>', dotAll: true)
        .allMatches(xml)
        .map((match) => match.group(1) ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
    return values.join('\t');
  }

  static String _plainXmlText(String xml) => xml
      .replaceAll(
          RegExp(r'</(?:w:p|a:p|p|div|tr)>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<(?:w:tab|br)\s*/?>', caseSensitive: false), '\t')
      .replaceAll(RegExp(r'<[^>]+>', dotAll: true), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n')
      .trim();

  static Future<PdfConversionResult?> _convertOfficeOnWindows(
    PlatformFile file,
    String extension,
  ) async {
    if (file.path == null) return null;
    final temp = await getTemporaryDirectory();
    final outputDirectory = Directory(
      p.join(temp.path,
          'smart-routine-pdf-${DateTime.now().microsecondsSinceEpoch}'),
    );
    await outputDirectory.create(recursive: true);
    try {
      final officePdf = await _tryLibreOffice(file.path!, outputDirectory.path);
      if (officePdf != null) {
        return await _save(
          await officePdf.readAsBytes(),
          sourceName: file.name,
          method: 'Conversão local pelo LibreOffice',
        );
      }
      final comPdf = await _tryMicrosoftOffice(
        file.path!,
        extension,
        outputDirectory.path,
      );
      if (comPdf != null) {
        return await _save(
          await comPdf.readAsBytes(),
          sourceName: file.name,
          method: 'Conversão local pelo Microsoft Office',
        );
      }
    } finally {
      try {
        await outputDirectory.delete(recursive: true);
      } catch (_) {}
    }
    return null;
  }

  static Future<File?> _tryLibreOffice(String input, String outputDir) async {
    final candidates = <String>[
      'soffice.exe',
      r'C:\Program Files\LibreOffice\program\soffice.exe',
      r'C:\Program Files (x86)\LibreOffice\program\soffice.exe',
    ];
    for (final executable in candidates) {
      try {
        final result = await Process.run(
          executable,
          <String>[
            '--headless',
            '--convert-to',
            'pdf',
            '--outdir',
            outputDir,
            input
          ],
        ).timeout(const Duration(minutes: 2));
        if (result.exitCode != 0) continue;
        final expected = File(
          p.join(outputDir, '${p.basenameWithoutExtension(input)}.pdf'),
        );
        if (await expected.exists()) return expected;
      } catch (_) {}
    }
    return null;
  }

  static Future<File?> _tryMicrosoftOffice(
    String input,
    String extension,
    String outputDir,
  ) async {
    if (!<String>{'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'}
        .contains(extension)) {
      return null;
    }
    final output =
        p.join(outputDir, '${p.basenameWithoutExtension(input)}.pdf');
    final escapedInput = input.replaceAll("'", "''");
    final escapedOutput = output.replaceAll("'", "''");
    final script = switch (extension) {
      'doc' ||
      'docx' =>
        '''\$app=New-Object -ComObject Word.Application;\$app.Visible=\$false;'''
            '''try{\$doc=\$app.Documents.Open('$escapedInput');\$doc.SaveAs([ref]'$escapedOutput',[ref]17);\$doc.Close()}finally{\$app.Quit()}''',
      'xls' ||
      'xlsx' =>
        '''\$app=New-Object -ComObject Excel.Application;\$app.Visible=\$false;'''
            '''try{\$book=\$app.Workbooks.Open('$escapedInput');\$book.ExportAsFixedFormat(0,'$escapedOutput');\$book.Close(\$false)}finally{\$app.Quit()}''',
      _ => '''\$app=New-Object -ComObject PowerPoint.Application;'''
          '''try{\$deck=\$app.Presentations.Open('$escapedInput',\$true,\$false,\$false);\$deck.SaveAs('$escapedOutput',32);\$deck.Close()}finally{\$app.Quit()}''',
    };
    try {
      final result = await Process.run(
        'powershell.exe',
        <String>['-NoProfile', '-NonInteractive', '-Command', script],
      ).timeout(const Duration(minutes: 2));
      final file = File(output);
      return result.exitCode == 0 && await file.exists() ? file : null;
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _bytes(PlatformFile file) async {
    if (file.bytes != null) return file.bytes;
    if (file.path == null) return null;
    return File(file.path!).readAsBytes();
  }

  static Future<PdfConversionResult> _save(
    Uint8List bytes, {
    required String sourceName,
    required String method,
  }) async {
    final fileName =
        '${AcademicData.safeFileName(p.basenameWithoutExtension(sourceName))}.pdf';
    final savedPath = await FileTransferService.saveBytes(
      bytes: bytes,
      fileName: fileName,
      dialogTitle: 'Salvar PDF convertido',
      extension: 'pdf',
    );
    return PdfConversionResult(
      savedPath: savedPath,
      sourceName: sourceName,
      method: method,
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
