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
  });

  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikeThrough;
  final double fontSize;
  final bool accent;
  final bool monospace;

  bool get isPlain =>
      !bold &&
      !italic &&
      !underline &&
      !strikeThrough &&
      fontSize == 16 &&
      !accent &&
      !monospace;

  SummaryTextStyle copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikeThrough,
    double? fontSize,
    bool? accent,
    bool? monospace,
  }) {
    return SummaryTextStyle(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strikeThrough: strikeThrough ?? this.strikeThrough,
      fontSize: (fontSize ?? this.fontSize).clamp(12, 34).toDouble(),
      accent: accent ?? this.accent,
      monospace: monospace ?? this.monospace,
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
      other.monospace == monospace;

  @override
  int get hashCode => Object.hash(
        bold,
        italic,
        underline,
        strikeThrough,
        fontSize,
        accent,
        monospace,
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
  const RichSummaryDocument({required this.text, this.spans = const []});

  final String text;
  final List<SummaryStyleSpan> spans;

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
      return RichSummaryDocument(text: text, spans: spans);
    } catch (_) {
      return RichSummaryDocument(text: legacyText);
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'version': 1,
        'text': text,
        'spans': spans.map((span) => span.toJson()).toList(growable: false),
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
      fontFamily: value.monospace ? 'Consolas' : baseStyle.fontFamily,
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
        _previousText = document.text,
        super(text: document.text) {
    addListener(_synchronizeStyles);
  }

  List<SummaryTextStyle> _styles;
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

  RichSummaryDocument get document => RichSummaryDocument(
        text: text,
        spans: _spansFromStyles(_styles),
      );

  void loadDocument(RichSummaryDocument document) {
    _synchronizing = true;
    _styles = _stylesFromDocument(document);
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

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = (style ?? const TextStyle()).copyWith(
      color: Colors.white,
      fontSize: 16,
      height: 1.55,
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
