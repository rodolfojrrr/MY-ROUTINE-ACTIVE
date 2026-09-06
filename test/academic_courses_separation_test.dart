import 'package:flutter_test/flutter_test.dart';
import 'package:my_routine_active/core/academic_data.dart';
import 'package:my_routine_active/core/app_store.dart';
import 'package:my_routine_active/core/sync_entity.dart';

void main() {
  test('faculdade e cursos ficam em coleções visuais separadas', () {
    final store = _AcademicStore();
    addTearDown(store.dispose);

    expect(
      AcademicData.sortedSemesters(store).map((item) => item.id),
      <String>['semester-current', 'semester-old'],
    );
    expect(
      AcademicData.sortedCourses(store).map((item) => item.id),
      <String>['course-current', 'track-planned', 'course-completed'],
    );
    expect(
      AcademicData.academicSubjects(store).map((item) => item.id),
      <String>['academic-subject'],
    );
    expect(
      AcademicData.subjectsForSemester(store, 'course-current')
          .map((item) => item.id),
      <String>['course-module'],
    );
    expect(AcademicData.isCourse(store.byId('course-current')), isTrue);
    expect(AcademicData.isCourseSubject(store, 'course-module'), isTrue);
    expect(
      AcademicData.subjectsForSelection(
        store,
        preferredSubjectId: 'course-module',
      ).map((item) => item.id),
      <String>['course-module'],
    );
  });

  test('imagens do certificado continuam dentro do registro do curso', () {
    final store = _AcademicStore();
    addTearDown(store.dispose);
    final course = store.byId('course-completed')!;

    expect(AcademicData.courseCertificates(course), hasLength(1));
    expect(
      AcademicData.courseCertificates(course).single['name'],
      'certificado.png',
    );
  });
}

class _AcademicStore extends AppStore {
  final List<SyncEntity> entities = const <SyncEntity>[
    SyncEntity(
      id: 'semester-old',
      type: EntityTypes.semester,
      payload: <String, dynamic>{
        'name': '2025.2',
        'kind': 'semester',
        'status': 'completed',
        'year': 2025,
        'term': 2,
      },
      updatedAtMs: 1,
      deviceId: 'test',
      revision: 1,
    ),
    SyncEntity(
      id: 'semester-current',
      type: EntityTypes.semester,
      payload: <String, dynamic>{
        'name': '2026.1',
        'kind': 'semester',
        'status': 'current',
        'year': 2026,
        'term': 1,
      },
      updatedAtMs: 1,
      deviceId: 'test',
      revision: 1,
    ),
    SyncEntity(
      id: 'course-current',
      type: EntityTypes.semester,
      payload: <String, dynamic>{
        'name': 'Flutter',
        'kind': 'course',
        'status': 'current',
      },
      updatedAtMs: 1,
      deviceId: 'test',
      revision: 1,
    ),
    SyncEntity(
      id: 'course-completed',
      type: EntityTypes.semester,
      payload: <String, dynamic>{
        'name': 'Git',
        'kind': 'course',
        'status': 'completed',
        'certificateImages': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'certificado.png',
            'base64': 'AQID',
          },
        ],
      },
      updatedAtMs: 1,
      deviceId: 'test',
      revision: 1,
    ),
    SyncEntity(
      id: 'track-planned',
      type: EntityTypes.semester,
      payload: <String, dynamic>{
        'name': 'Trilha de backend',
        'kind': 'track',
        'status': 'planned',
      },
      updatedAtMs: 1,
      deviceId: 'test',
      revision: 1,
    ),
    SyncEntity(
      id: 'academic-subject',
      type: EntityTypes.subject,
      payload: <String, dynamic>{
        'name': 'Banco de Dados',
        'semesterId': 'semester-current',
      },
      updatedAtMs: 1,
      deviceId: 'test',
      revision: 1,
    ),
    SyncEntity(
      id: 'course-module',
      type: EntityTypes.subject,
      payload: <String, dynamic>{
        'name': 'Widgets',
        'semesterId': 'course-current',
      },
      updatedAtMs: 1,
      deviceId: 'test',
      revision: 1,
    ),
  ];

  @override
  List<SyncEntity> records(String type) =>
      entities.where((item) => item.type == type).toList();

  @override
  SyncEntity? byId(String id) {
    for (final item in entities) {
      if (item.id == id) return item;
    }
    return null;
  }
}
