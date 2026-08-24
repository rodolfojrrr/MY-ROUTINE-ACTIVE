import 'dart:convert';

import 'app_store.dart';
import 'sync_entity.dart';

class AcademicData {
  static const weekdayShort = <int, String>{
    1: 'Seg',
    2: 'Ter',
    3: 'Qua',
    4: 'Qui',
    5: 'Sex',
    6: 'Sáb',
    7: 'Dom',
  };

  static const weekdayLong = <int, String>{
    1: 'Segunda-feira',
    2: 'Terça-feira',
    3: 'Quarta-feira',
    4: 'Quinta-feira',
    5: 'Sexta-feira',
    6: 'Sábado',
    7: 'Domingo',
  };

  static String semesterName(AppStore store, String? id) {
    if (id == null || id.isEmpty) return 'Sem semestre';
    return store.byId(id)?.payload['name'] as String? ?? 'Semestre removido';
  }

  static String subjectName(AppStore store, String? id) {
    if (id == null || id.isEmpty) return 'Sem matéria';
    return store.byId(id)?.payload['name'] as String? ?? 'Matéria removida';
  }

  static String contentName(AppStore store, String? id) {
    if (id == null || id.isEmpty) return 'Conteúdo geral';
    return store.byId(id)?.payload['title'] as String? ?? 'Conteúdo removido';
  }

  static List<SyncEntity> sortedSemesters(AppStore store) {
    final items = store.records(EntityTypes.semester).toList();
    items.sort((a, b) {
      final statusA = a.payload['status'] == 'current' ? 1 : 0;
      final statusB = b.payload['status'] == 'current' ? 1 : 0;
      if (statusA != statusB) return statusB.compareTo(statusA);
      final yearA = (a.payload['year'] as num? ?? 0).toInt();
      final yearB = (b.payload['year'] as num? ?? 0).toInt();
      if (yearA != yearB) return yearB.compareTo(yearA);
      final termA = (a.payload['term'] as num? ?? 0).toInt();
      final termB = (b.payload['term'] as num? ?? 0).toInt();
      return termB.compareTo(termA);
    });
    return items;
  }

  static List<SyncEntity> subjectsForSemester(
    AppStore store,
    String? semesterId,
  ) {
    final items = store.records(EntityTypes.subject).where((item) {
      final value = item.payload['semesterId'] as String?;
      if (semesterId == null) return value == null || value.isEmpty;
      return value == semesterId;
    }).toList();
    items.sort((a, b) {
      final orderA = (a.payload['order'] as num? ?? 999).toInt();
      final orderB = (b.payload['order'] as num? ?? 999).toInt();
      if (orderA != orderB) return orderA.compareTo(orderB);
      return (a.payload['name'] as String? ?? '').compareTo(
        b.payload['name'] as String? ?? '',
      );
    });
    return items;
  }

  static List<SyncEntity> contentsForSubject(
    AppStore store,
    String? subjectId,
  ) {
    final items = store
        .records(EntityTypes.studyContent)
        .where((item) => item.payload['subjectId'] == subjectId)
        .toList();
    items.sort((a, b) {
      final orderA = (a.payload['order'] as num? ?? 999).toInt();
      final orderB = (b.payload['order'] as num? ?? 999).toInt();
      if (orderA != orderB) return orderA.compareTo(orderB);
      return (a.payload['title'] as String? ?? '').compareTo(
        b.payload['title'] as String? ?? '',
      );
    });
    return items;
  }

  static List<Map<String, dynamic>> summaryImages(SyncEntity summary) {
    final raw = summary.payload['images'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .where((item) => (item['base64'] as String? ?? '').isNotEmpty)
          .toList();
    }
    final legacy = summary.payload['imageBase64'] as String? ?? '';
    if (legacy.isEmpty) return <Map<String, dynamic>>[];
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'name': summary.payload['imageName'] as String? ?? 'imagem.jpg',
        'base64': legacy,
      },
    ];
  }

  static int summaryImageBytes(SyncEntity summary) {
    var total = 0;
    for (final image in summaryImages(summary)) {
      try {
        total += base64Decode(image['base64'] as String).length;
      } catch (_) {}
    }
    return total;
  }

  static String safeFileName(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[áàãâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòõôö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized.isEmpty ? 'resumo' : normalized;
  }

  static Future<void> deleteContent(AppStore store, SyncEntity content) async {
    final linkedProjects = store
        .records(EntityTypes.codeProject)
        .where((item) => item.payload['contentId'] == content.id)
        .toList();
    for (final project in linkedProjects) {
      await store.save(
        EntityTypes.codeProject,
        <String, dynamic>{...project.payload, 'contentId': null},
        id: project.id,
      );
    }
    for (final type in <String>[
      EntityTypes.studyNote,
      EntityTypes.studyQuestion,
      EntityTypes.flashcard,
    ]) {
      final linked = store
          .records(type)
          .where((item) => item.payload['contentId'] == content.id)
          .toList();
      for (final item in linked) {
        await store.remove(item.id);
      }
    }
    await store.remove(content.id);
  }

  static Future<void> deleteSubject(AppStore store, SyncEntity subject) async {
    final contents = store
        .records(EntityTypes.studyContent)
        .where((item) => item.payload['subjectId'] == subject.id)
        .toList();
    for (final content in contents) {
      await deleteContent(store, content);
    }
    final linkedProjects = store
        .records(EntityTypes.codeProject)
        .where((item) => item.payload['subjectId'] == subject.id)
        .toList();
    for (final project in linkedProjects) {
      await store.save(
        EntityTypes.codeProject,
        <String, dynamic>{
          ...project.payload,
          'subjectId': null,
          'contentId': null,
        },
        id: project.id,
      );
    }
    for (final type in <String>[
      EntityTypes.classSession,
      EntityTypes.exam,
      EntityTypes.studyNote,
      EntityTypes.flashcard,
      EntityTypes.studyQuestion,
      EntityTypes.studySession,
    ]) {
      final linked = store
          .records(type)
          .where((item) => item.payload['subjectId'] == subject.id)
          .toList();
      for (final item in linked) {
        await store.remove(item.id);
      }
    }
    await store.remove(subject.id);
  }

  static Future<void> deleteSemester(
    AppStore store,
    SyncEntity semester,
  ) async {
    final subjects = store
        .records(EntityTypes.subject)
        .where((item) => item.payload['semesterId'] == semester.id)
        .toList();
    for (final subject in subjects) {
      await deleteSubject(store, subject);
    }
    final linkedProjects = store
        .records(EntityTypes.codeProject)
        .where((item) => item.payload['semesterId'] == semester.id)
        .toList();
    for (final project in linkedProjects) {
      await store.save(
        EntityTypes.codeProject,
        <String, dynamic>{
          ...project.payload,
          'semesterId': null,
          'subjectId': null,
          'contentId': null,
        },
        id: project.id,
      );
    }
    await store.remove(semester.id);
  }
}
