import 'package:flutter/material.dart';

@immutable
class SummaryTextStyle {
  const SummaryTextStyle({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikeThrough = false,
    this.fontSize = 16,
    this.accent = false,
    this.monospace = false,
    this.highlight = false,
    this.codeBlock = false,
  });

  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikeThrough;
  final double fontSize;
  final bool accent;
  final bool monospace;
  final bool highlight;
  final bool codeBlock;

  bool get isPlain =>
      !bold &&
      !italic &&
      !underline &&
      !strikeThrough &&
      fontSize == 16 &&
      !accent &&
      !monospace &&
      !highlight &&
      !codeBlock;

  SummaryTextStyle copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikeThrough,
    double? fontSize,
    bool? accent,
    bool? monospace,
    bool? highlight,
    bool? codeBlock,
  }) {
    return SummaryTextStyle(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strikeThrough: strikeThrough ?? this.strikeThrough,
      fontSize: (fontSize ?? this.fontSize).clamp(12, 34).toDouble(),
      accent: accent ?? this.accent,
      monospace: monospace ?? this.monospace,
      highlight: highlight ?? this.highlight,
      codeBlock: codeBlock ?? this.codeBlock,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'bold': bold,
        'italic': italic,
        'underline': underline,
        'strikeThrough': strikeThrough,
        'fontSize': fontSize,
        'accent': accent,
        'monospace': monospace,
        'highlight': highlight,
        'codeBlock': codeBlock,
      };

  factory SummaryTextStyle.fromJson(Map<String, dynamic> json) {
    return SummaryTextStyle(
      bold: json['bold'] == true,
      italic: json['italic'] == true,
      underline: json['underline'] == true,
      strikeThrough: json['strikeThrough'] == true,
      fontSize:
          (json['fontSize'] as num? ?? 16).toDouble().clamp(12, 34).toDouble(),
      accent: json['accent'] == true,
      monospace: json['monospace'] == true,
      highlight: json['highlight'] == true,
      codeBlock: json['codeBlock'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SummaryTextStyle &&
      other.bold == bold &&
      other.italic == italic &&
      other.underline == underline &&
      other.strikeThrough == strikeThrough &&
      other.fontSize == fontSize &&
      other.accent == accent &&
      other.monospace == monospace &&
      other.highlight == highlight &&
      other.codeBlock == codeBlock;

  @override
  int get hashCode => Object.hash(
        bold,
        italic,
        underline,
        strikeThrough,
        fontSize,
        accent,
        monospace,
        highlight,
        codeBlock,
      );
}

@immutable
class SummaryStyleSpan {
  const SummaryStyleSpan({
    required this.start,
    required this.end,
    required this.style,
  });

  final int start;
  final int end;
  final SummaryTextStyle style;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'start': start,
        'end': end,
        'style': style.toJson(),
      };

  factory SummaryStyleSpan.fromJson(Map<String, dynamic> json) {
    return SummaryStyleSpan(
      start: (json['start'] as num? ?? 0).toInt(),
      end: (json['end'] as num? ?? 0).toInt(),
      style: SummaryTextStyle.fromJson(
        (json['style'] as Map? ?? const <String, dynamic>{})
            .cast<String, dynamic>(),
      ),
    );
  }
}

@immutable
class RichSummarySegment {
  const RichSummarySegment({required this.text, required this.style});

  final String text;
  final SummaryTextStyle style;
}

@immutable
class RichSummaryDocument {
  const RichSummaryDocument({
    required this.text,
    this.spans = const [],
    this.textAlignment = 'left',
    this.lineHeight = 1.55,
  });

  final String text;
  final List<SummaryStyleSpan> spans;
  final String textAlignment;
  final double lineHeight;

  TextAlign get flutterTextAlign => switch (textAlignment) {
        'center' => TextAlign.center,
        'right' => TextAlign.right,
        'justify' => TextAlign.justify,
        _ => TextAlign.left,
      };

  factory RichSummaryDocument.fromPayload(Map<String, dynamic> payload) {
    final legacyText = payload['body'] as String? ?? '';
    final raw = payload['richText'];
    if (raw is! Map) return RichSummaryDocument(text: legacyText);
    try {
      final json = raw.cast<String, dynamic>();
      final text = json['text'] as String? ?? legacyText;
      final spans = (json['spans'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => SummaryStyleSpan.fromJson(
                item.cast<String, dynamic>(),
              ))
          .where((span) => span.start >= 0 && span.end <= text.length)
          .where((span) => span.end > span.start)
          .toList(growable: false);
      final rawAlignment = json['textAlignment'] as String? ?? 'left';
      final alignment = const <String>{'left', 'center', 'right', 'justify'}
              .contains(rawAlignment)
          ? rawAlignment
          : 'left';
      final lineHeight =
          (json['lineHeight'] as num? ?? 1.55).toDouble().clamp(1.15, 2.0);
      return RichSummaryDocument(
        text: text,
        spans: spans,
        textAlignment: alignment,
        lineHeight: lineHeight,
      );
    } catch (_) {
      return RichSummaryDocument(text: legacyText);
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'version': 2,
        'text': text,
        'spans': spans.map((span) => span.toJson()).toList(growable: false),
        'textAlignment': textAlignment,
        'lineHeight': lineHeight,
      };

  List<RichSummarySegment> get segments {
    if (text.isEmpty) return const <RichSummarySegment>[];
    final styles = List<SummaryTextStyle>.filled(
      text.length,
      const SummaryTextStyle(),
    );
    for (final span in spans) {
      final start = span.start.clamp(0, text.length).toInt();
      final end = span.end.clamp(start, text.length).toInt();
      for (var index = start; index < end; index++) {
        styles[index] = span.style;
      }
    }
    final result = <RichSummarySegment>[];
    var start = 0;
    var style = styles.first;
    for (var index = 1; index <= text.length; index++) {
      if (index == text.length || styles[index] != style) {
        result.add(
          RichSummarySegment(text: text.substring(start, index), style: style),
        );
        if (index < text.length) {
          start = index;
          style = styles[index];
        }
      }
    }
    return result;
  }

  TextSpan toTextSpan({
    required TextStyle baseStyle,
    required Color accentColor,
  }) {
    return TextSpan(
      style: baseStyle,
      children: segments
          .map(
            (segment) => TextSpan(
              text: segment.text,
              style: textStyleFor(
                segment.style,
                baseStyle: baseStyle,
                accentColor: accentColor,
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  static TextStyle textStyleFor(
    SummaryTextStyle value, {
    required TextStyle baseStyle,
    required Color accentColor,
  }) {
    final decorations = <TextDecoration>[
      if (value.underline) TextDecoration.underline,
      if (value.strikeThrough) TextDecoration.lineThrough,
    ];
    return baseStyle.copyWith(
      fontSize: value.fontSize,
      fontWeight: value.bold ? FontWeight.w800 : FontWeight.w400,
      fontStyle: value.italic ? FontStyle.italic : FontStyle.normal,
      color: value.accent ? accentColor : baseStyle.color,
      fontFamily: value.monospace || value.codeBlock
          ? 'Consolas'
          : baseStyle.fontFamily,
      backgroundColor: value.codeBlock
          ? const Color(0xFF102A46)
          : value.highlight
              ? accentColor.withValues(alpha: .24)
              : null,
      letterSpacing: value.codeBlock ? .15 : baseStyle.letterSpacing,
      decoration: decorations.isEmpty
          ? TextDecoration.none
          : TextDecoration.combine(decorations),
      decorationColor: value.accent ? accentColor : baseStyle.color,
    );
  }
}

class RichSummaryController extends TextEditingController {
  RichSummaryController(RichSummaryDocument document)
      : _styles = _stylesFromDocument(document),
        _textAlignment = document.textAlignment,
        _lineHeight = document.lineHeight,
        _previousText = document.text,
        super(text: document.text) {
    addListener(_synchronizeStyles);
  }

  List<SummaryTextStyle> _styles;
  String _textAlignment;
  double _lineHeight;
  String _previousText;
  bool _synchronizing = false;
  SummaryTextStyle _typingStyle = const SummaryTextStyle();
  TextSelection _previousSelection = const TextSelection.collapsed(offset: -1);

  SummaryTextStyle get activeStyle {
    if (_styles.isEmpty) return _typingStyle;
    final selectionIndex = selection.isValid ? selection.baseOffset : 0;
    final index = selectionIndex.clamp(0, _styles.length - 1).toInt();
    return _styles[index];
  }

  String get textAlignment => _textAlignment;
  double get lineHeight => _lineHeight;

  TextAlign get flutterTextAlign => switch (_textAlignment) {
        'center' => TextAlign.center,
        'right' => TextAlign.right,
        'justify' => TextAlign.justify,
        _ => TextAlign.left,
      };

  RichSummaryDocument get document => RichSummaryDocument(
        text: text,
        spans: _spansFromStyles(_styles),
        textAlignment: _textAlignment,
        lineHeight: _lineHeight,
      );

  void loadDocument(RichSummaryDocument document) {
    _synchronizing = true;
    _styles = _stylesFromDocument(document);
    _textAlignment = document.textAlignment;
    _lineHeight = document.lineHeight;
    _previousText = document.text;
    value = TextEditingValue(
      text: document.text,
      selection: TextSelection.collapsed(offset: document.text.length),
    );
    _previousSelection = selection;
    _synchronizing = false;
    notifyListeners();
  }

  TextRange get selectedParagraphRange {
    if (text.isEmpty) return const TextRange(start: 0, end: 0);
    final rawStart = selection.isValid ? selection.start : text.length;
    final rawEnd = selection.isValid ? selection.end : text.length;
    final start = rawStart < 0 ? text.length : rawStart;
    final end = rawEnd < start ? start : rawEnd;
    final before = start == 0 ? -1 : text.lastIndexOf('\n', start - 1);
    final after = text.indexOf('\n', end);
    return TextRange(
      start: before + 1,
      end: after < 0 ? text.length : after,
    );
  }

  void applyToSelection(
    SummaryTextStyle Function(SummaryTextStyle current) transform, {
    bool wholeParagraphWhenCollapsed = false,
  }) {
    var start = selection.isValid ? selection.start : text.length;
    var end = selection.isValid ? selection.end : text.length;
    start = start.clamp(0, text.length).toInt();
    end = end.clamp(start, text.length).toInt();
    if (start == end && wholeParagraphWhenCollapsed) {
      final paragraph = selectedParagraphRange;
      start = paragraph.start;
      end = paragraph.end;
    }
    if (start == end) {
      _typingStyle = transform(activeStyle);
      notifyListeners();
      return;
    }
    final nextTypingStyle = transform(activeStyle);
    for (var index = start; index < end; index++) {
      _styles[index] = transform(_styles[index]);
    }
    _typingStyle = nextTypingStyle;
    notifyListeners();
  }

  void applyHeading(double fontSize, {required bool bold}) {
    applyToSelection(
      (style) => style.copyWith(fontSize: fontSize, bold: bold),
      wholeParagraphWhenCollapsed: true,
    );
  }

  void setTextAlignment(String value) {
    if (!const <String>{'left', 'center', 'right', 'justify'}.contains(value) ||
        value == _textAlignment) {
      return;
    }
    _textAlignment = value;
    notifyListeners();
  }

  void setLineHeight(double value) {
    final next = value.clamp(1.15, 2.0).toDouble();
    if (next == _lineHeight) return;
    _lineHeight = next;
    notifyListeners();
  }

  void toggleCodeBlock() {
    final enabled = !activeStyle.codeBlock;
    applyToSelection(
      (style) => style.copyWith(
        codeBlock: enabled,
        monospace: enabled,
        accent: enabled ? false : style.accent,
        fontSize: enabled && style.fontSize > 18 ? 16 : style.fontSize,
      ),
      wholeParagraphWhenCollapsed: true,
    );
  }

  void clearFormatting() {
    applyToSelection(
      (_) => const SummaryTextStyle(),
      wholeParagraphWhenCollapsed: true,
    );
  }

  void replaceParagraphsWithList({required bool numbered}) {
    final range = selectedParagraphRange;
    final source = text.substring(range.start, range.end);
    final lines = source.split('\n');
    final bulletPattern = RegExp(r'^\s*•\s+');
    final numberPattern = RegExp(r'^\s*\d+[.)]\s+');
    final pattern = numbered ? numberPattern : bulletPattern;
    final allFormatted = lines
        .where((line) => line.trim().isNotEmpty)
        .every((line) => pattern.hasMatch(line));
    var counter = 1;
    final replacement = lines.map((line) {
      if (line.trim().isEmpty) return line;
      final clean = line.replaceFirst(bulletPattern, '').replaceFirst(
            numberPattern,
            '',
          );
      if (allFormatted) return clean;
      return numbered ? '${counter++}. $clean' : '• $clean';
    }).join('\n');
    value = value.copyWith(
      text: text.replaceRange(range.start, range.end, replacement),
      selection: TextSelection(
        baseOffset: range.start,
        extentOffset: range.start + replacement.length,
      ),
      composing: TextRange.empty,
    );
  }

  void replaceParagraphsWithChecklist() {
    _toggleParagraphPrefix(
      pattern: RegExp(r'^\s*[☐☑]\s+'),
      prefixForIndex: (_) => '☐ ',
    );
  }

  void replaceParagraphsWithQuote() {
    _toggleParagraphPrefix(
      pattern: RegExp(r'^\s*>\s+'),
      prefixForIndex: (_) => '> ',
    );
  }

  void indentParagraphs({required bool outdent}) {
    final range = selectedParagraphRange;
    final source = text.substring(range.start, range.end);
    final replacement = source.split('\n').map((line) {
      if (line.isEmpty) return line;
      if (!outdent) return '    $line';
      if (line.startsWith('    ')) return line.substring(4);
      if (line.startsWith('\t')) return line.substring(1);
      return line.replaceFirst(RegExp(r'^ {1,3}'), '');
    }).join('\n');
    _replaceSelectedParagraphs(range, replacement);
  }

  void insertDivider() {
    final selectionOffset =
        selection.isValid ? selection.baseOffset : text.length;
    final offset = selectionOffset.clamp(0, text.length).toInt();
    final before = offset > 0 && text[offset - 1] != '\n' ? '\n' : '';
    final after = offset < text.length && text[offset] != '\n' ? '\n' : '';
    const divider = '────────────────────────';
    final inserted = '$before$divider\n$after';
    value = value.copyWith(
      text: text.replaceRange(offset, offset, inserted),
      selection: TextSelection.collapsed(offset: offset + inserted.length),
      composing: TextRange.empty,
    );
  }

  void selectAllText() {
    selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }

  void _toggleParagraphPrefix({
    required RegExp pattern,
    required String Function(int index) prefixForIndex,
  }) {
    final range = selectedParagraphRange;
    final lines = text.substring(range.start, range.end).split('\n');
    final nonEmpty = lines.where((line) => line.trim().isNotEmpty);
    final remove = nonEmpty.isNotEmpty && nonEmpty.every(pattern.hasMatch);
    var index = 0;
    final replacement = lines.map((line) {
      if (line.trim().isEmpty) return line;
      if (remove) return line.replaceFirst(pattern, '');
      return '${prefixForIndex(index++)}${line.replaceFirst(pattern, '')}';
    }).join('\n');
    _replaceSelectedParagraphs(range, replacement);
  }

  void _replaceSelectedParagraphs(TextRange range, String replacement) {
    value = value.copyWith(
      text: text.replaceRange(range.start, range.end, replacement),
      selection: TextSelection(
        baseOffset: range.start,
        extentOffset: range.start + replacement.length,
      ),
      composing: TextRange.empty,
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = (style ?? const TextStyle()).copyWith(
      color: Colors.white,
      fontSize: 16,
      height: _lineHeight,
      decoration: TextDecoration.none,
    );
    return document.toTextSpan(
      baseStyle: base,
      accentColor: Theme.of(context).colorScheme.primary,
    );
  }

  void _synchronizeStyles() {
    if (_synchronizing) return;
    if (text == _previousText) {
      if (selection != _previousSelection && selection.isValid) {
        if (_styles.isNotEmpty) {
          final caret = selection.baseOffset;
          final index =
              (caret <= 0 ? 0 : caret - 1).clamp(0, _styles.length - 1).toInt();
          _typingStyle = _styles[index];
        }
        _previousSelection = selection;
      }
      return;
    }
    _synchronizing = true;
    final oldText = _previousText;
    final newText = text;
    var prefix = 0;
    while (prefix < oldText.length &&
        prefix < newText.length &&
        oldText.codeUnitAt(prefix) == newText.codeUnitAt(prefix)) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < oldText.length - prefix &&
        suffix < newText.length - prefix &&
        oldText.codeUnitAt(oldText.length - suffix - 1) ==
            newText.codeUnitAt(newText.length - suffix - 1)) {
      suffix++;
    }
    final insertedLength = newText.length - prefix - suffix;
    final preservedBefore = _styles.take(prefix).toList(growable: true);
    final insertedStyle = _typingStyle;
    preservedBefore.addAll(
      List<SummaryTextStyle>.filled(insertedLength, insertedStyle),
    );
    if (suffix > 0) {
      preservedBefore.addAll(_styles.skip(oldText.length - suffix));
    }
    _styles = preservedBefore.length == newText.length
        ? preservedBefore
        : List<SummaryTextStyle>.filled(
            newText.length,
            const SummaryTextStyle(),
          );
    _previousText = newText;
    _previousSelection = selection;
    _synchronizing = false;
    notifyListeners();
  }

  static List<SummaryTextStyle> _stylesFromDocument(
    RichSummaryDocument document,
  ) {
    final styles = List<SummaryTextStyle>.filled(
      document.text.length,
      const SummaryTextStyle(),
    );
    for (final span in document.spans) {
      final start = span.start.clamp(0, document.text.length).toInt();
      final end = span.end.clamp(start, document.text.length).toInt();
      for (var index = start; index < end; index++) {
        styles[index] = span.style;
      }
    }
    return styles;
  }

  static List<SummaryStyleSpan> _spansFromStyles(
    List<SummaryTextStyle> styles,
  ) {
    if (styles.isEmpty) return const <SummaryStyleSpan>[];
    final spans = <SummaryStyleSpan>[];
    var start = 0;
    var style = styles.first;
    for (var index = 1; index <= styles.length; index++) {
      if (index == styles.length || styles[index] != style) {
        if (!style.isPlain) {
          spans.add(SummaryStyleSpan(start: start, end: index, style: style));
        }
        if (index < styles.length) {
          start = index;
          style = styles[index];
        }
      }
    }
    return spans;
  }

  @override
  void dispose() {
    removeListener(_synchronizeStyles);
    super.dispose();
  }
}
