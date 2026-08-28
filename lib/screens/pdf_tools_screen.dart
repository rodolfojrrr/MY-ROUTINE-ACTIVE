import 'package:flutter/material.dart';

import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/pdf_converter_service.dart';
import '../widgets/premium_widgets.dart';
import 'academic_shared.dart';
import 'academic_summaries_screen.dart';

class PdfToolsScreen extends StatefulWidget {
  const PdfToolsScreen({required this.store, super.key});

  final AppStore store;

  @override
  State<PdfToolsScreen> createState() => _PdfToolsScreenState();
}

class _PdfToolsScreenState extends State<PdfToolsScreen> {
  bool converting = false;
  PdfConversionResult? lastResult;

  Future<void> _convert() async {
    setState(() => converting = true);
    try {
      final result = await PdfConverterService.pickAndConvert();
      if (!mounted || result == null) return;
      setState(() => lastResult = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF gerado com sucesso.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error
                  .toString()
                  .replaceFirst('FormatException: ', '')
                  .replaceFirst('FileSystemException: ', ''),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => converting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AcademicPageBody(
      children: <Widget>[
        PageIntro(
          eyebrow: 'Documentos locais',
          title: 'Ferramentas PDF',
          subtitle:
              'Gere o PDF de cada resumo ou converta imagens, textos, códigos e documentos comuns sem enviar o arquivo para a internet.',
          color: AppColors.primary,
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = <Widget>[
              _PdfToolCard(
                icon: Icons.summarize_outlined,
                color: AppColors.primary,
                title: 'PDF dos seus resumos',
                description:
                    'Abra a biblioteca, escolha um resumo e use “Gerar PDF”. Texto, matéria, conteúdo e imagens entram no documento.',
                actionLabel: 'Abrir resumos',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        AcademicSummariesScreen(store: widget.store),
                  ),
                ),
              ),
              _PdfToolCard(
                icon: Icons.picture_as_pdf_outlined,
                color: AppColors.red,
                title: 'Converter arquivo para PDF',
                description:
                    'Imagens, TXT, Markdown, CSV, JSON, HTML e arquivos de código funcionam no celular e no PC. DOCX, XLSX e PPTX têm extração local de texto; no Windows, Office ou LibreOffice preservam melhor o layout.',
                actionLabel: converting ? 'Convertendo…' : 'Escolher arquivo',
                onPressed: converting ? null : _convert,
              ),
            ];
            return constraints.maxWidth >= 820
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: cards[0]),
                      const SizedBox(width: 14),
                      Expanded(child: cards[1]),
                    ],
                  )
                : Column(
                    children: <Widget>[
                      cards[0],
                      const SizedBox(height: 14),
                      cards[1],
                    ],
                  );
          },
        ),
        if (lastResult != null) ...<Widget>[
          const SizedBox(height: 16),
          PremiumCard(
            borderColor: AppColors.green,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle, color: AppColors.green),
              title: Text('Último arquivo: ${lastResult!.sourceName}'),
              subtitle: Text(lastResult!.method),
            ),
          ),
        ],
        const SizedBox(height: 18),
        const PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Compatibilidade sem promessas falsas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 9),
              Text(
                'Nenhum conversor consegue transformar literalmente todo formato existente. O app identifica formatos compatíveis, mantém tudo local e avisa quando um arquivo exige um programa instalado no Windows. O original nunca é apagado nem alterado.',
                style: TextStyle(color: AppColors.textMuted, height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PdfToolCard extends StatelessWidget {
  const _PdfToolCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      borderColor: color.withValues(alpha: .45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: AppColors.textMuted, height: 1.45),
          ),
          const SizedBox(height: 18),
          ElevatedButton(onPressed: onPressed, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
