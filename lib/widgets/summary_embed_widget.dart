import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:re_highlight/languages/bash.dart';
import 'package:re_highlight/languages/c.dart';
import 'package:re_highlight/languages/cpp.dart';
import 'package:re_highlight/languages/csharp.dart';
import 'package:re_highlight/languages/css.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:re_highlight/languages/go.dart';
import 'package:re_highlight/languages/java.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/kotlin.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/languages/php.dart';
import 'package:re_highlight/languages/powershell.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/languages/rust.dart';
import 'package:re_highlight/languages/sql.dart';
import 'package:re_highlight/languages/swift.dart';
import 'package:re_highlight/languages/typescript.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/languages/yaml.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';

import '../core/app_theme.dart';
import '../core/rich_summary_document.dart';

class SummaryCodeLanguage {
  const SummaryCodeLanguage(this.id, this.label, this.mode);

  final String id;
  final String label;
  final Mode mode;

  static final List<SummaryCodeLanguage> all = <SummaryCodeLanguage>[
    SummaryCodeLanguage('dart', 'Dart', langDart),
    SummaryCodeLanguage('python', 'Python', langPython),
    SummaryCodeLanguage('java', 'Java', langJava),
    SummaryCodeLanguage('javascript', 'JavaScript', langJavascript),
    SummaryCodeLanguage('typescript', 'TypeScript', langTypescript),
    SummaryCodeLanguage('c', 'C', langC),
    SummaryCodeLanguage('cpp', 'C++', langCpp),
    SummaryCodeLanguage('csharp', 'C#', langCsharp),
    SummaryCodeLanguage('kotlin', 'Kotlin', langKotlin),
    SummaryCodeLanguage('php', 'PHP', langPhp),
    SummaryCodeLanguage('sql', 'SQL', langSql),
    SummaryCodeLanguage('html', 'HTML', langXml),
    SummaryCodeLanguage('css', 'CSS', langCss),
    SummaryCodeLanguage('json', 'JSON', langJson),
    SummaryCodeLanguage('bash', 'Bash / Shell', langBash),
    SummaryCodeLanguage('powershell', 'PowerShell', langPowershell),
    SummaryCodeLanguage('go', 'Go', langGo),
    SummaryCodeLanguage('rust', 'Rust', langRust),
    SummaryCodeLanguage('swift', 'Swift', langSwift),
    SummaryCodeLanguage('yaml', 'YAML', langYaml),
    SummaryCodeLanguage('markdown', 'Markdown', langMarkdown),
  ];

  static SummaryCodeLanguage byId(String id) =>
      all.firstWhere((item) => item.id == id, orElse: () => all.first);
}

class SummaryEmbedWidget extends StatelessWidget {
  const SummaryEmbedWidget({
    required this.embed,
    required this.maxWidth,
    this.editable = false,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final SummaryEmbed embed;
  final double maxWidth;
  final bool editable;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final safeMaxWidth = maxWidth.clamp(120, 760).toDouble();
    final width = (safeMaxWidth * embed.widthFactor)
        .clamp(safeMaxWidth < 220 ? safeMaxWidth : 180, safeMaxWidth)
        .toDouble();
    final alignment = switch (embed.alignment) {
      'left' => Alignment.centerLeft,
      'right' => Alignment.centerRight,
      _ => Alignment.center,
    };
    return SizedBox(
      width: safeMaxWidth,
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            width: width,
            height: embed.height,
            child: embed.isImage
                ? _InlineImage(
                    embed: embed,
                    editable: editable,
                    onEdit: onEdit,
                    onDelete: onDelete,
                  )
                : _CodeExample(
                    embed: embed,
                    editable: editable,
                    onEdit: onEdit,
                    onDelete: onDelete,
                  ),
          ),
        ),
      ),
    );
  }
}

class _InlineImage extends StatelessWidget {
  const _InlineImage({
    required this.embed,
    required this.editable,
    this.onEdit,
    this.onDelete,
  });

  final SummaryEmbed embed;
  final bool editable;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    Uint8List? bytes;
    try {
      bytes = base64Decode(embed.base64);
    } catch (_) {}
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF071524),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: .58)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: bytes == null || bytes.isEmpty
                  ? const Center(child: Icon(Icons.broken_image_outlined))
                  : Image.memory(bytes, fit: BoxFit.contain),
            ),
            if (embed.caption.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.transparent,
                        Colors.black.withValues(alpha: .88),
                      ],
                    ),
                  ),
                  child: Text(
                    embed.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            if (editable)
              Positioned(
                top: 7,
                right: 7,
                child: _EmbedActions(onEdit: onEdit, onDelete: onDelete),
              ),
          ],
        ),
      ),
    );
  }
}

class _CodeExample extends StatelessWidget {
  const _CodeExample({
    required this.embed,
    required this.editable,
    this.onEdit,
    this.onDelete,
  });

  final SummaryEmbed embed;
  final bool editable;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final language = SummaryCodeLanguage.byId(embed.language);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF07111E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: .62)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: .22),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: 38,
              padding: const EdgeInsets.only(left: 12, right: 5),
              color: const Color(0xFF10243A),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.terminal_rounded,
                    color: AppColors.primaryLight,
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      language.label.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  if (editable)
                    _EmbedActions(onEdit: onEdit, onDelete: onDelete),
                ],
              ),
            ),
            Expanded(
              child: ClipRect(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(13),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: RichText(
                      softWrap: false,
                      text: _highlight(language, embed.code),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextSpan _highlight(SummaryCodeLanguage language, String code) {
    const base = TextStyle(
      color: Color(0xFFD8E9F8),
      fontSize: 13,
      height: 1.45,
      fontFamily: 'Consolas',
      fontFamilyFallback: <String>['Cascadia Code', 'Courier New', 'monospace'],
    );
    try {
      final engine = Highlight()..registerLanguage(language.id, language.mode);
      final result = engine.highlight(code: code, language: language.id);
      final renderer = TextSpanRenderer(base, atomOneDarkTheme);
      result.render(renderer);
      return renderer.span ?? const TextSpan(text: '', style: base);
    } catch (_) {
      return TextSpan(text: code, style: base);
    }
  }
}

class _EmbedActions extends StatelessWidget {
  const _EmbedActions({this.onEdit, this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xEE071524),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.appBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            tooltip: 'Ajustar elemento',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            onPressed: onEdit,
            icon: const Icon(Icons.tune_rounded, size: 16),
          ),
          IconButton(
            tooltip: 'Remover do texto',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            onPressed: onDelete,
            icon: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppColors.red,
            ),
          ),
        ],
      ),
    );
  }
}
