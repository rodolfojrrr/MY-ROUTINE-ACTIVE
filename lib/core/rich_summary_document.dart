import 'package:flutter/material.dart';

const String summaryEmbedPlaceholder = '\uFFFC';

typedef SummaryEmbedBuilder = Widget Function(SummaryEmbed embed);

@immutable
class SummaryEmbed {
  const SummaryEmbed({
    required this.id,
    required this.type,
    this.widthFactor = 1,
    this.height = 260,
    this.alignment = 'center',
    this.name = '',
    this.base64 = '',
    this.caption = '',
    this.language = 'dart',
    this.code = '',
  });

  static const imageType = 'image';
  static const codeType = 'code';

  final String id;
  final String type;
  final double widthFactor;
  final double height;
  final String alignment;
  final String name;
  final String base64;
  final String caption;
  final String language;
  final String code;

  bool get isImage => type == imageType;
  bool get isCode => type == codeType;

  String get fallbackText => isCode
      ? code
      : caption.trim().isNotEmpty
          ? caption.trim()
          : '[Imagem: ${name.isEmpty ? 'sem nome' : name}]';

  SummaryEmbed copyWith({
    double? widthFactor,
    double? height,
    String? alignment,
    String? name,
    String? base64,
    String? caption,
    String? language,
    String? code,
  }) {
    return SummaryEmbed(
      id: id,
      type: type,
      widthFactor: (widthFactor ?? this.widthFactor).clamp(.3, 1).toDouble(),
      height: (height ?? this.height).clamp(110, 560).toDouble(),
      alignment: alignment ?? this.alignment,
      name: name ?? this.name,
      base64: base64 ?? this.base64,
      caption: caption ?? this.caption,
      language: language ?? this.language,
      code: code ?? this.code,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type,
        'widthFactor': widthFactor,
        'height': height,
        'alignment': alignment,
        if (name.isNotEmpty) 'name': name,
        if (base64.isNotEmpty) 'base64': base64,
        if (caption.isNotEmpty) 'caption': caption,
        if (language.isNotEmpty) 'language': language,
        if (code.isNotEmpty) 'code': code,
      };

  factory SummaryEmbed.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String? ?? codeType;
    final rawAlignment = json['alignment'] as String? ?? 'center';
    return SummaryEmbed(
      id: json['id'] as String? ??
          'embed-${DateTime.now().microsecondsSinceEpoch}',
      type: rawType == imageType ? imageType : codeType,
      widthFactor: (json['widthFactor'] as num? ?? 1).toDouble().clamp(.3, 1),
      height: (json['height'] as num? ?? 260).toDouble().clamp(110, 560),
      alignment:
          const <String>{'left', 'center', 'right'}.contains(rawAlignment)
              ? rawAlignment
              : 'center',
      name: json['name'] as String? ?? '',
      base64: json['base64'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      language: json['language'] as String? ?? 'dart',
      code: json['code'] as String? ?? '',
    );
  }
}

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
    this.embeds = const [],
    this.textAlignment = 'left',
    this.lineHeight = 1.55,
  });

  final String text;
  final List<SummaryStyleSpan> spans;
  final List<SummaryEmbed> embeds;
  final String textAlignment;
  final double lineHeight;

  String get plainText {
    if (!text.contains(summaryEmbedPlaceholder)) return text;
    final buffer = StringBuffer();
    var embedIndex = 0;
    for (final rune in text.runes) {
      final value = String.fromCharCode(rune);
      if (value != summaryEmbedPlaceholder) {
        buffer.write(value);
        continue;
      }
      if (embedIndex < embeds.length) {
        buffer.write(embeds[embedIndex++].fallbackText);
      }
    }
    return buffer.toString();
  }

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
          .map(
            (item) => SummaryStyleSpan.fromJson(item.cast<String, dynamic>()),
          )
          .where((span) => span.start >= 0 && span.end <= text.length)
          .where((span) => span.end > span.start)
          .toList(growable: false);
      final embeds = (json['embeds'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => SummaryEmbed.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false);
      final rawAlignment = json['textAlignment'] as String? ?? 'left';
      final alignment = const <String>{
        'left',
        'center',
        'right',
        'justify',
      }.contains(rawAlignment)
          ? rawAlignment
          : 'left';
      final lineHeight = (json['lineHeight'] as num? ?? 1.55).toDouble().clamp(
            1.15,
            2.0,
          );
      return RichSummaryDocument(
        text: text,
        spans: spans,
        embeds: embeds,
        textAlignment: alignment,
        lineHeight: lineHeight,
      );
    } catch (_) {
      return RichSummaryDocument(text: legacyText);
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'version': 3,
        'text': text,
        'spans': spans.map((span) => span.toJson()).toList(growable: false),
        'embeds': embeds.map((embed) => embed.toJson()).toList(growable: false),
        'textAlignment': textAlignment,
        'lineHeight': lineHeight,
      };

  List<RichSummarySegment> get segments => segmentsBetween(0, text.length);

  List<RichSummarySegment> segmentsBetween(int rawStart, int rawEnd) {
    final rangeStart = rawStart.clamp(0, text.length).toInt();
    final rangeEnd = rawEnd.clamp(rangeStart, text.length).toInt();
    if (rangeStart == rangeEnd) return const <RichSummarySegment>[];
    final styles = List<SummaryTextStyle>.filled(
      rangeEnd - rangeStart,
      const SummaryTextStyle(),
    );
    for (final span in spans) {
      final start = span.start.clamp(rangeStart, rangeEnd).toInt();
      final end = span.end.clamp(start, rangeEnd).toInt();
      for (var index = start; index < end; index++) {
        styles[index - rangeStart] = span.style;
      }
    }
    final result = <RichSummarySegment>[];
    var start = rangeStart;
    var style = styles.first;
    for (var index = rangeStart + 1; index <= rangeEnd; index++) {
      if (index == rangeEnd || styles[index - rangeStart] != style) {
        result.add(
          RichSummarySegment(text: text.substring(start, index), style: style),
        );
        if (index < rangeEnd) {
          start = index;
          style = styles[index - rangeStart];
        }
      }
    }
    return result;
  }

  TextSpan toTextSpan({
    required TextStyle baseStyle,
    required Color accentColor,
    SummaryEmbedBuilder? embedBuilder,
  }) {
    final children = <InlineSpan>[];
    var cursor = 0;
    var embedIndex = 0;
    for (var index = 0; index < text.length; index++) {
      if (text[index] != summaryEmbedPlaceholder) continue;
      children.addAll(_textSpansBetween(cursor, index, baseStyle, accentColor));
      if (embedIndex < embeds.length) {
        final embed = embeds[embedIndex++];
        if (embedBuilder == null) {
          children.add(TextSpan(text: embed.fallbackText));
        } else {
          children.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: embedBuilder(embed),
            ),
          );
        }
      }
      cursor = index + 1;
    }
    children.addAll(
      _textSpansBetween(cursor, text.length, baseStyle, accentColor),
    );
    return TextSpan(style: baseStyle, children: children);
  }

  List<TextSpan> _textSpansBetween(
    int start,
    int end,
    TextStyle baseStyle,
    Color accentColor,
  ) {
    return segmentsBetween(start, end)
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
        .toList(growable: false);
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
        _embeds = List<SummaryEmbed>.from(document.embeds),
        _textAlignment = document.textAlignment,
        _lineHeight = document.lineHeight,
        _previousText = document.text,
        super(text: document.text) {
    addListener(_synchronizeStyles);
  }

  List<SummaryTextStyle> _styles;
  List<SummaryEmbed> _embeds;
  String _textAlignment;
  double _lineHeight;
  String _previousText;
  bool _synchronizing = false;
  SummaryTextStyle _typingStyle = const SummaryTextStyle();
  TextSelection _previousSelection = const TextSelection.collapsed(offset: -1);
  SummaryEmbedBuilder? _embedBuilder;
  final List<_RemovedSummaryEmbed> _removedEmbeds = <_RemovedSummaryEmbed>[];

  SummaryTextStyle get activeStyle {
    if (_styles.isEmpty) return _typingStyle;
    final selectionIndex = selection.isValid ? selection.baseOffset : 0;
    final index = selectionIndex.clamp(0, _styles.length - 1).toInt();
    return _styles[index];
  }

  String get textAlignment => _textAlignment;
  double get lineHeight => _lineHeight;
  List<SummaryEmbed> get embeds => List<SummaryEmbed>.unmodifiable(_embeds);
  String get plainText => document.plainText;

  void setEmbedBuilder(SummaryEmbedBuilder? builder) {
    _embedBuilder = builder;
  }

  TextAlign get flutterTextAlign => switch (_textAlignment) {
        'center' => TextAlign.center,
        'right' => TextAlign.right,
        'justify' => TextAlign.justify,
        _ => TextAlign.left,
      };

  RichSummaryDocument get document => RichSummaryDocument(
        text: text,
        spans: _spansFromStyles(_styles),
        embeds: List<SummaryEmbed>.unmodifiable(_embeds),
        textAlignment: _textAlignment,
        lineHeight: _lineHeight,
      );

  void loadDocument(RichSummaryDocument document) {
    _synchronizing = true;
    _styles = _stylesFromDocument(document);
    _embeds = List<SummaryEmbed>.from(document.embeds);
    _textAlignment = document.textAlignment;
    _lineHeight = document.lineHeight;
    _previousText = document.text;
    _removedEmbeds.clear();
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
    return TextRange(start: before + 1, end: after < 0 ? text.length : after);
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
      final clean =
          line.replaceFirst(bulletPattern, '').replaceFirst(numberPattern, '');
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

  void insertEmbed(SummaryEmbed embed) {
    final rawOffset = selection.isValid ? selection.extentOffset : text.length;
    final offset = rawOffset.clamp(0, text.length).toInt();
    final before = offset > 0 && text[offset - 1] != '\n' ? '\n' : '';
    final after = offset < text.length && text[offset] != '\n' ? '\n' : '';
    final inserted = '$before$summaryEmbedPlaceholder$after';
    final embedIndex = _placeholderCount(text.substring(0, offset));
    _embeds.insert(embedIndex.clamp(0, _embeds.length), embed);
    _replaceRangeDirectly(offset, offset, inserted);
  }

  void updateEmbed(SummaryEmbed embed) {
    final index = _embeds.indexWhere((item) => item.id == embed.id);
    if (index < 0) return;
    _embeds[index] = embed;
    notifyListeners();
  }

  void removeEmbed(String id) {
    final embedIndex = _embeds.indexWhere((item) => item.id == id);
    if (embedIndex < 0) return;
    final offset = _placeholderOffset(text, embedIndex);
    final removed = _embeds.removeAt(embedIndex);
    _removedEmbeds.add(
      _RemovedSummaryEmbed(index: embedIndex, embed: removed),
    );
    if (offset < 0) {
      notifyListeners();
      return;
    }
    var start = offset;
    var end = offset + 1;
    if (start > 0 &&
        end < text.length &&
        text[start - 1] == '\n' &&
        text[end] == '\n') {
      start--;
    } else if (end < text.length && text[end] == '\n') {
      end++;
    } else if (start > 0 && text[start - 1] == '\n') {
      start--;
    }
    _replaceRangeDirectly(start, end, '');
  }

  void _replaceRangeDirectly(int start, int end, String replacement) {
    _synchronizing = true;
    final nextText = text.replaceRange(start, end, replacement);
    final nextStyles = <SummaryTextStyle>[
      ..._styles.take(start),
      ...List<SummaryTextStyle>.filled(
        replacement.length,
        const SummaryTextStyle(),
      ),
      ..._styles.skip(end),
    ];
    _styles = nextStyles;
    _previousText = nextText;
    value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
    _previousSelection = selection;
    _synchronizing = false;
    notifyListeners();
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
      embedBuilder: _embedBuilder,
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
    final removedEnd = oldText.length - suffix;
    if (removedEnd > prefix) {
      final removed = oldText.substring(prefix, removedEnd);
      final removedEmbeds = _placeholderCount(removed);
      if (removedEmbeds > 0) {
        final firstEmbed = _placeholderCount(oldText.substring(0, prefix));
        final lastEmbed = (firstEmbed + removedEmbeds).clamp(
          firstEmbed,
          _embeds.length,
        );
        if (firstEmbed < lastEmbed) {
          final removedItems = _embeds.sublist(firstEmbed, lastEmbed);
          for (var index = 0; index < removedItems.length; index++) {
            _removedEmbeds.add(
              _RemovedSummaryEmbed(
                index: firstEmbed + index,
                embed: removedItems[index],
              ),
            );
          }
          _embeds.removeRange(firstEmbed, lastEmbed);
        }
      }
    }
    final expectedEmbeds = _placeholderCount(newText);
    var restorationIndex = _placeholderCount(newText.substring(0, prefix));
    while (_embeds.length < expectedEmbeds) {
      final historyIndex = _removedEmbeds.lastIndexWhere(
        (item) => item.index == restorationIndex,
      );
      final restored = historyIndex < 0
          ? SummaryEmbed(
              id: 'recovered-${DateTime.now().microsecondsSinceEpoch}',
              type: SummaryEmbed.codeType,
              code:
                  'Elemento recuperado. Edite esta caixa para completar o conteúdo.',
            )
          : _removedEmbeds.removeAt(historyIndex).embed;
      _embeds.insert(restorationIndex.clamp(0, _embeds.length), restored);
      restorationIndex++;
    }
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

  static int _placeholderCount(String value) =>
      summaryEmbedPlaceholder.allMatches(value).length;

  static int _placeholderOffset(String value, int wantedIndex) {
    var current = 0;
    for (var index = 0; index < value.length; index++) {
      if (value[index] != summaryEmbedPlaceholder) continue;
      if (current == wantedIndex) return index;
      current++;
    }
    return -1;
  }

  @override
  void dispose() {
    removeListener(_synchronizeStyles);
    super.dispose();
  }
}

class _RemovedSummaryEmbed {
  const _RemovedSummaryEmbed({required this.index, required this.embed});

  final int index;
  final SummaryEmbed embed;
}
