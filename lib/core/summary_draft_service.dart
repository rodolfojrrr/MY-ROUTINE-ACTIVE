import 'dart:convert';

import 'app_store.dart';

class SummaryDraft {
  const SummaryDraft({
    required this.title,
    required this.body,
    required this.richText,
    required this.subjectId,
    required this.contentId,
    required this.images,
    required this.attachments,
    required this.savedAtMs,
    required this.sourceUpdatedAtMs,
  });

  final String title;
  final String body;
  final Map<String, dynamic> richText;
  final String? subjectId;
  final String? contentId;
  final List<Map<String, dynamic>> images;
  final List<Map<String, dynamic>> attachments;
  final int savedAtMs;
  final int sourceUpdatedAtMs;

  bool get hasContent =>
      title.trim().isNotEmpty ||
      body.trim().isNotEmpty ||
      images.isNotEmpty ||
      attachments.isNotEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'body': body,
        'richText': richText,
        'subjectId': subjectId,
        'contentId': contentId,
        'images': images,
        'attachments': attachments,
        'savedAtMs': savedAtMs,
        'sourceUpdatedAtMs': sourceUpdatedAtMs,
      };

  factory SummaryDraft.fromJson(Map<String, dynamic> json) => SummaryDraft(
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        richText: (json['richText'] as Map? ?? const <String, dynamic>{})
            .cast<String, dynamic>(),
        subjectId: json['subjectId'] as String?,
        contentId: json['contentId'] as String?,
        images: (json['images'] as List? ?? const <dynamic>[])
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList(growable: false),
        attachments: (json['attachments'] as List? ?? const <dynamic>[])
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList(growable: false),
        savedAtMs: (json['savedAtMs'] as num? ?? 0).toInt(),
        sourceUpdatedAtMs: (json['sourceUpdatedAtMs'] as num? ?? 0).toInt(),
      );
}

class SummaryDraftService {
  const SummaryDraftService(this.store);

  final AppStore store;

  Future<SummaryDraft?> load(String? summaryId) async {
    final raw = await store.readUserPreference(_key(summaryId));
    if (raw == null || raw.isEmpty) return null;
    try {
      return SummaryDraft.fromJson(
        (jsonDecode(raw) as Map).cast<String, dynamic>(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String? summaryId, SummaryDraft draft) =>
      store.writeUserPreference(_key(summaryId), jsonEncode(draft.toJson()));

  Future<void> clear(String? summaryId) =>
      store.writeUserPreference(_key(summaryId), '');

  String _key(String? summaryId) =>
      'summary_draft:${summaryId == null || summaryId.isEmpty ? 'new' : summaryId}';
}
