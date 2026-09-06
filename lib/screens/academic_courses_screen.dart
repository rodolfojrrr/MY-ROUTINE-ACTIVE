import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/academic_data.dart';
import '../core/academic_folder_style.dart';
import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/file_transfer_service.dart';
import '../core/sync_entity.dart';
import '../widgets/premium_widgets.dart';
import '../widgets/pro_color_picker.dart';
import 'academic_faculty_screen.dart';
import 'academic_management_screen.dart';
import 'academic_shared.dart';
import 'academic_summaries_screen.dart';

class AcademicCoursesScreen extends StatelessWidget {
  const AcademicCoursesScreen({required this.store, super.key});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final courses = AcademicData.sortedCourses(store);
        final current = courses
            .where((item) => item.payload['status'] == 'current')
            .toList();
        final other = courses
            .where((item) => item.payload['status'] != 'current')
            .toList();
        final completed = courses
            .where((item) => item.payload['status'] == 'completed')
            .length;
        return AcademicPageBody(
          maxWidth: 1240,
          children: <Widget>[
            PageIntro(
              eyebrow: 'Formação complementar',
              title: 'Cursos',
              subtitle:
                  'Organize cada curso como uma pasta: curso, módulos, conteúdos e materiais. Tudo separado da faculdade e totalmente personalizável.',
              color: AppColors.green,
            ),
            const SizedBox(height: 18),
            _CourseOverview(
              total: courses.length,
              inProgress: current.length,
              completed: completed,
              onCreate: () => _openEditor(context, store),
            ),
            if (current.isNotEmpty) ...<Widget>[
              const SizedBox(height: 24),
              AcademicSectionTitle(
                title: 'Cursando agora',
                subtitle:
                    'Seus cursos atuais ficam sempre no topo para acesso rápido.',
                trailing: AcademicBadge(
                  label: '${current.length} em andamento',
                  color: AppColors.orange,
                  icon: Icons.play_circle_outline_rounded,
                ),
              ),
              const SizedBox(height: 14),
              _CourseFolderGrid(
                children: current
                    .map((course) => _CourseFolderTile(
                          store: store,
                          course: course,
                          highlighted: true,
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 24),
            AcademicSectionTitle(
              title:
                  current.isEmpty ? 'Seus cursos' : 'Planejados e concluídos',
              subtitle: current.isEmpty
                  ? 'O curso em andamento ficará destacado automaticamente.'
                  : 'Seu próximo passo e o histórico de cursos concluídos.',
              trailing: TextButton.icon(
                key: const Key('courses-add-course'),
                onPressed: () => _openEditor(context, store),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Adicionar curso'),
              ),
            ),
            const SizedBox(height: 14),
            if (courses.isEmpty)
              const EmptyState(
                icon: Icons.create_new_folder_outlined,
                title: 'Nenhum curso cadastrado',
                message:
                    'Crie um curso de programação, tecnologia, idiomas ou qualquer outro tema. Ele não será misturado à faculdade.',
              )
            else if (other.isNotEmpty)
              _CourseFolderGrid(
                children: other
                    .map((course) => _CourseFolderTile(
                          store: store,
                          course: course,
                        ))
                    .toList(),
              )
            else
              const PremiumCard(
                child: Text(
                  'Quando você planejar ou concluir um curso, ele aparecerá aqui sem sair da área Cursos.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CourseFolderGrid extends StatelessWidget {
  const _CourseFolderGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1120
            ? 4
            : constraints.maxWidth >= 790
                ? 3
                : constraints.maxWidth >= 520
                    ? 2
                    : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: columns == 1 ? 1.55 : .98,
          children: children,
        );
      },
    );
  }
}

class _CourseFolderTile extends StatelessWidget {
  const _CourseFolderTile({
    required this.store,
    required this.course,
    this.highlighted = false,
  });

  final AppStore store;
  final SyncEntity course;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final status = course.payload['status'] as String? ?? 'current';
    final modules = AcademicData.subjectsForSemester(store, course.id);
    final color = AcademicFolderStyle.colorFor(
      course,
      fallback: status == 'completed'
          ? AppColors.green
          : status == 'planned'
              ? AppColors.cyan
              : AppColors.orange,
    );
    return AcademicFolderCard(
      key: ValueKey<String>('course-folder-${course.id}'),
      title: course.payload['name'] as String? ?? 'Curso',
      subtitle: <String>[
        course.payload['institution'] as String? ?? '',
        _workloadLabel(course.payload['workload']),
      ].where((item) => item.isNotEmpty).join(' • '),
      countLabel: '${modules.length} módulo(s)',
      color: color,
      icon: AcademicFolderStyle.iconFor(course),
      coverBytes: AcademicFolderStyle.coverBytes(course),
      badge:
          highlighted ? 'CURSANDO AGORA' : _statusLabel(status).toUpperCase(),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AcademicCourseFolderPage(
            store: store,
            courseId: course.id,
          ),
        ),
      ),
      onEdit: () => _openEditor(context, store, course),
      onDelete: () => _confirmCourseDelete(context, store, course),
    );
  }
}

class AcademicCourseFolderPage extends StatelessWidget {
  const AcademicCourseFolderPage({
    required this.store,
    required this.courseId,
    super.key,
  });

  final AppStore store;
  final String courseId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conteúdos do curso')),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final course = store.byId(courseId);
          if (course == null) {
            return const Center(child: Text('Curso não encontrado.'));
          }
          final modules = AcademicData.subjectsForSemester(store, courseId);
          final color = AcademicFolderStyle.colorFor(
            course,
            fallback: AppColors.green,
          );
          return AcademicPageBody(
            maxWidth: 1240,
            children: <Widget>[
              _CourseBreadcrumb(
                items: <String>[
                  'Cursos',
                  course.payload['name'] as String? ?? 'Curso',
                ],
              ),
              const SizedBox(height: 14),
              _CourseCard(
                store: store,
                course: course,
                showModules: false,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  ElevatedButton.icon(
                    key: const Key('courses-add-module'),
                    onPressed: () => showAcademicSubjectEditor(
                      context,
                      store,
                      initialSemesterId: courseId,
                      courseMode: true,
                    ),
                    icon: const Icon(Icons.create_new_folder_outlined),
                    label: const Text('Adicionar módulo'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _openEditor(context, store, course),
                    icon: const Icon(Icons.palette_outlined),
                    label: const Text('Personalizar curso'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AcademicSchedulePage(
                          store: store,
                          courseId: courseId,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.calendar_view_week_outlined),
                    label: const Text('Horários do curso'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AcademicSectionTitle(
                title: 'Módulos e conteúdos',
                subtitle:
                    'Abra um módulo para organizar aulas, capítulos e todos os materiais do curso.',
                trailing: Text(
                  '${modules.length} pasta(s)',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 14),
              if (modules.isEmpty)
                const EmptyState(
                  icon: Icons.folder_open_outlined,
                  title: 'Este curso ainda está vazio',
                  message:
                      'Use “Adicionar módulo” para criar a primeira etapa ou disciplina do curso.',
                )
              else
                _CourseFolderGrid(
                  children: modules.map((module) {
                    final contents =
                        AcademicData.contentsForSubject(store, module.id);
                    final moduleColor = AcademicFolderStyle.colorFor(
                      module,
                      fallback: color,
                    );
                    return AcademicFolderCard(
                      key: ValueKey<String>('course-module-${module.id}'),
                      title: module.payload['name'] as String? ?? 'Módulo',
                      subtitle: <String>[
                        module.payload['code'] as String? ?? '',
                        module.payload['professor'] as String? ?? '',
                      ].where((item) => item.isNotEmpty).join(' • '),
                      countLabel: '${contents.length} conteúdo(s)',
                      color: moduleColor,
                      icon: AcademicFolderStyle.iconFor(module),
                      coverBytes: AcademicFolderStyle.coverBytes(module),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AcademicSubjectFolderPage(
                            store: store,
                            semesterId: courseId,
                            subjectId: module.id,
                            courseMode: true,
                          ),
                        ),
                      ),
                      onEdit: () => showAcademicSubjectEditor(
                        context,
                        store,
                        entity: module,
                        initialSemesterId: courseId,
                        courseMode: true,
                      ),
                      onDelete: () => _confirmModuleDelete(
                        context,
                        store,
                        module,
                      ),
                    );
                  }).toList(),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CourseBreadcrumb extends StatelessWidget {
  const _CourseBreadcrumb({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          Icon(Icons.workspace_premium_outlined,
              size: 17, color: AppColors.green),
          const SizedBox(width: 7),
          for (var index = 0; index < items.length; index++) ...<Widget>[
            if (index > 0) ...<Widget>[
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textMuted),
              const SizedBox(width: 4),
            ],
            Text(
              items[index],
              style: TextStyle(
                color: index == items.length - 1
                    ? Colors.white
                    : AppColors.textMuted,
                fontWeight: index == items.length - 1
                    ? FontWeight.w900
                    : FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

Future<void> _confirmCourseDelete(
  BuildContext context,
  AppStore store,
  SyncEntity course,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Excluir curso?'),
      content: const Text(
        'O curso, os módulos, certificados e materiais vinculados irão para a lixeira.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  if (confirmed == true) await AcademicData.deleteSemester(store, course);
}

Future<void> _confirmModuleDelete(
  BuildContext context,
  AppStore store,
  SyncEntity module,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Excluir módulo?'),
      content: const Text(
        'Os conteúdos e materiais vinculados irão para a lixeira e poderão ser restaurados.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  if (confirmed == true) await AcademicData.deleteSubject(store, module);
}

Future<void> _openEditor(
  BuildContext context,
  AppStore store, [
  SyncEntity? entity,
]) {
  return showDialog<void>(
    context: context,
    builder: (_) => _CourseEditorDialog(store: store, entity: entity),
  );
}

class _CourseOverview extends StatelessWidget {
  const _CourseOverview({
    required this.total,
    required this.inProgress,
    required this.completed,
    required this.onCreate,
  });

  final int total;
  final int inProgress;
  final int completed;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            AppColors.green.withValues(alpha: .22),
            AppColors.appSurface.withValues(alpha: .97),
          ],
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppColors.green.withValues(alpha: .42)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stats = Wrap(
            spacing: 18,
            runSpacing: 10,
            children: <Widget>[
              _CourseStat(
                  label: 'Total', value: total, color: AppColors.primary),
              _CourseStat(
                label: 'Em andamento',
                value: inProgress,
                color: AppColors.orange,
              ),
              _CourseStat(
                label: 'Concluídos',
                value: completed,
                color: AppColors.green,
              ),
            ],
          );
          if (constraints.maxWidth < 650) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                stats,
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Cadastrar curso'),
                ),
              ],
            );
          }
          return Row(
            children: <Widget>[
              Expanded(child: stats),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar curso'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CourseStat extends StatelessWidget {
  const _CourseStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 115),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: .32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.store,
    required this.course,
    required this.showModules,
  });

  final AppStore store;
  final SyncEntity course;
  final bool showModules;

  @override
  Widget build(BuildContext context) {
    final status = course.payload['status'] as String? ?? 'current';
    final certificates = AcademicData.courseCertificates(course);
    final legacySubjects = AcademicData.subjectsForSemester(store, course.id);
    final defaultStatusColor = switch (status) {
      'completed' => AppColors.green,
      'planned' => AppColors.cyan,
      _ => AppColors.orange,
    };
    final statusColor = AcademicFolderStyle.colorFor(
      course,
      fallback: defaultStatusColor,
    );
    final cover = AcademicFolderStyle.coverBytes(course);
    return PremiumCard(
      borderColor: statusColor.withValues(alpha: .45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (cover != null) ...<Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Image.memory(cover, fit: BoxFit.cover),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Colors.transparent,
                            Colors.black.withValues(alpha: .72),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 13),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  AcademicFolderStyle.iconFor(course),
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      course.payload['name'] as String? ?? '',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      <String>[
                        course.payload['institution'] as String? ?? '',
                        _workloadLabel(course.payload['workload']),
                      ].where((item) => item.isNotEmpty).join(' • '),
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: <Widget>[
                        AcademicBadge(
                          label: _statusLabel(status),
                          color: statusColor,
                        ),
                        if (certificates.isNotEmpty)
                          AcademicBadge(
                            label: '${certificates.length} certificado(s)',
                            color: AppColors.green,
                            icon: Icons.workspace_premium_outlined,
                          ),
                        if (legacySubjects.isNotEmpty)
                          AcademicBadge(
                            label: '${legacySubjects.length} módulo(s)',
                            color: AppColors.primary,
                            icon: Icons.menu_book_outlined,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Editar curso',
                onPressed: () => _openEditor(context, store, course),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Excluir curso',
                color: AppColors.red,
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          if ((course.payload['notes'] as String? ?? '')
              .isNotEmpty) ...<Widget>[
            const SizedBox(height: 13),
            Text(
              course.payload['notes'] as String,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, height: 1.45),
            ),
          ],
          if (showModules && legacySubjects.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 5),
            const Text(
              'Conteúdos preservados',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            ...legacySubjects.map(
              (subject) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    Icon(Icons.menu_book_outlined, color: AppColors.primary),
                title: Text(subject.payload['name'] as String? ?? ''),
                subtitle: Text(
                  '${AcademicData.contentsForSubject(store, subject.id).length} conteúdo(s)',
                ),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _CourseModuleDetailScreen(
                      store: store,
                      subjectId: subject.id,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (certificates.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 8),
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: certificates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 9),
                itemBuilder: (_, index) {
                  final item = certificates[index];
                  return InkWell(
                    onTap: () => _previewCertificate(context, item),
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 170,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          _decode(item['base64'] as String? ?? ''),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => ColoredBox(
                            color: AppColors.appSurfaceRaised,
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir curso?'),
        content: const Text(
          'O curso, certificados e conteúdos vinculados irão para a lixeira. Essa ação será sincronizada entre seus aparelhos.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) await AcademicData.deleteSemester(store, course);
  }
}

class _CourseModuleDetailScreen extends StatelessWidget {
  const _CourseModuleDetailScreen({
    required this.store,
    required this.subjectId,
  });

  final AppStore store;
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final subject = store.byId(subjectId);
        if (subject == null) {
          return const Scaffold(
            body: Center(child: Text('Módulo não encontrado.')),
          );
        }
        final contents = AcademicData.contentsForSubject(store, subjectId);
        final summaries = store
            .records(EntityTypes.studyNote)
            .where((item) => item.payload['subjectId'] == subjectId)
            .toList();
        return Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: Text(subject.payload['name'] as String? ?? 'Módulo'),
          ),
          body: PremiumBackground(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
              children: <Widget>[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        PageIntro(
                          eyebrow: 'Material de curso preservado',
                          title: subject.payload['name'] as String? ?? '',
                          subtitle:
                              'Este módulo veio de uma versão anterior e permanece acessível na área Cursos, sem aparecer junto à faculdade.',
                          color: AppColors.green,
                        ),
                        const SizedBox(height: 18),
                        if (contents.isEmpty)
                          const EmptyState(
                            icon: Icons.folder_open_outlined,
                            title: 'Nenhum conteúdo neste módulo',
                            message:
                                'O cadastro do curso e seus certificados continuam preservados.',
                          )
                        else
                          ...contents.map((content) {
                            final linked = summaries
                                .where(
                                  (item) =>
                                      item.payload['contentId'] == content.id,
                                )
                                .toList();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: PremiumCard(
                                borderColor:
                                    AppColors.green.withValues(alpha: .36),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    Text(
                                      content.payload['title'] as String? ?? '',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    if ((content.payload['description']
                                                as String? ??
                                            '')
                                        .isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 6),
                                      Text(
                                        content.payload['description']
                                            as String,
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 9),
                                    if (linked.isEmpty)
                                      const Text(
                                        'Nenhum resumo salvo neste conteúdo.',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                        ),
                                      )
                                    else
                                      ...linked.map(
                                        (summary) => ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(
                                            Icons.description_outlined,
                                            color: AppColors.green,
                                          ),
                                          title: Text(
                                            summary.payload['title']
                                                    as String? ??
                                                '',
                                          ),
                                          trailing: const Icon(
                                            Icons.arrow_forward,
                                          ),
                                          onTap: () =>
                                              Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  AcademicSummaryDetailScreen(
                                                store: store,
                                                summaryId: summary.id,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CourseEditorDialog extends StatefulWidget {
  const _CourseEditorDialog({required this.store, this.entity});

  final AppStore store;
  final SyncEntity? entity;

  @override
  State<_CourseEditorDialog> createState() => _CourseEditorDialogState();
}

class _CourseEditorDialogState extends State<_CourseEditorDialog> {
  late final TextEditingController name;
  late final TextEditingController institution;
  late final TextEditingController workload;
  late final TextEditingController notes;
  late String status;
  DateTime? startedAt;
  DateTime? completedAt;
  late List<Map<String, dynamic>> certificates;
  bool picking = false;
  late int folderColor;
  late String folderIcon;
  late String coverImageBase64;
  late String coverImageName;
  bool pickingCover = false;

  @override
  void initState() {
    super.initState();
    final payload = widget.entity?.payload ?? const <String, dynamic>{};
    name = TextEditingController(text: payload['name'] as String? ?? '');
    institution = TextEditingController(
      text: payload['institution'] as String? ?? '',
    );
    workload = TextEditingController(text: '${payload['workload'] ?? ''}');
    notes = TextEditingController(text: payload['notes'] as String? ?? '');
    status = payload['status'] as String? ?? 'current';
    startedAt = DateTime.tryParse(payload['startedAt'] as String? ?? '');
    completedAt = DateTime.tryParse(payload['completedAt'] as String? ?? '');
    certificates = widget.entity == null
        ? <Map<String, dynamic>>[]
        : AcademicData.courseCertificates(widget.entity!)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
    folderColor =
        (payload['folderColor'] as num?)?.toInt() ?? AppColors.green.toARGB32();
    folderIcon = payload['folderIcon'] as String? ?? 'school';
    coverImageBase64 = payload['coverImageBase64'] as String? ?? '';
    coverImageName = payload['coverImageName'] as String? ?? '';
  }

  @override
  void dispose() {
    name.dispose();
    institution.dispose();
    workload.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> _pickCertificates() async {
    if (certificates.length >= 8) return;
    setState(() => picking = true);
    try {
      final picked = await FileTransferService.pickImagePayloads();
      if (!mounted || picked.isEmpty) return;
      setState(() {
        certificates.addAll(
          picked.map(
            (item) => <String, dynamic>{
              'name': item['imageName'] as String,
              'base64': base64Encode(item['imageBytes'] as Uint8List),
            },
          ),
        );
        if (certificates.length > 8) {
          certificates = certificates.take(8).toList();
        }
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível adicionar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  Future<void> _pickCover() async {
    if (pickingCover) return;
    setState(() => pickingCover = true);
    try {
      final picked = await FileTransferService.pickImagePayload();
      final bytes = picked?['imageBytes'];
      if (picked != null && bytes is List<int> && mounted) {
        setState(() {
          coverImageBase64 = base64Encode(bytes);
          coverImageName = picked['imageName'] as String? ?? 'capa.jpg';
        });
      }
    } finally {
      if (mounted) setState(() => pickingCover = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.entity == null ? 'Novo curso' : 'Editar curso'),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nome do curso'),
              ),
              const SizedBox(height: 11),
              TextField(
                controller: institution,
                decoration: const InputDecoration(
                  labelText: 'Instituição ou plataforma',
                ),
              ),
              const SizedBox(height: 11),
              LayoutBuilder(
                builder: (context, constraints) {
                  final statusField = DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Situação'),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(
                        value: 'planned',
                        child: Text('Planejado'),
                      ),
                      DropdownMenuItem(
                        value: 'current',
                        child: Text('Em andamento'),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('Concluído'),
                      ),
                    ],
                    onChanged: (value) => setState(() {
                      status = value ?? status;
                      if (status == 'completed') {
                        completedAt ??= DateTime.now();
                      }
                    }),
                  );
                  final workloadField = TextField(
                    controller: workload,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Carga horária (horas)',
                    ),
                  );
                  if (constraints.maxWidth < 520) {
                    return Column(
                      children: <Widget>[
                        statusField,
                        const SizedBox(height: 11),
                        workloadField,
                      ],
                    );
                  }
                  return Row(
                    children: <Widget>[
                      Expanded(child: statusField),
                      const SizedBox(width: 11),
                      Expanded(child: workloadField),
                    ],
                  );
                },
              ),
              const SizedBox(height: 11),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () async {
                      final selected = await pickAppDate(
                        context,
                        startedAt ?? DateTime.now(),
                      );
                      if (selected != null) {
                        setState(() => startedAt = selected);
                      }
                    },
                    icon: const Icon(Icons.play_circle_outline),
                    label: Text(
                      startedAt == null
                          ? 'Data de início'
                          : 'Início: ${DateFormat('dd/MM/yyyy').format(startedAt!)}',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final selected = await pickAppDate(
                        context,
                        completedAt ?? DateTime.now(),
                      );
                      if (selected != null) {
                        setState(() => completedAt = selected);
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      completedAt == null
                          ? 'Data de conclusão'
                          : 'Conclusão: ${DateFormat('dd/MM/yyyy').format(completedAt!)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              TextField(
                controller: notes,
                minLines: 3,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Conteúdos estudados e observações',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),
              ProColorTile(
                title: 'Cor da pasta do curso',
                subtitle: 'Toque para escolher livremente ou usar HEX',
                color: Color(folderColor),
                onChanged: (value) =>
                    setState(() => folderColor = value.toARGB32()),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: AcademicFolderStyle.icons
                    .map(
                      (option) => IconButton.filledTonal(
                        tooltip: option.label,
                        onPressed: () => setState(() => folderIcon = option.id),
                        style: IconButton.styleFrom(
                          side: folderIcon == option.id
                              ? BorderSide(color: Color(folderColor))
                              : null,
                        ),
                        icon: Icon(option.icon, size: 19),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: pickingCover ? null : _pickCover,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(
                        coverImageName.isEmpty
                            ? 'Adicionar capa do curso'
                            : 'Trocar capa do curso',
                      ),
                    ),
                  ),
                  if (coverImageName.isNotEmpty)
                    IconButton(
                      tooltip: 'Remover capa',
                      onPressed: () => setState(() {
                        coverImageBase64 = '';
                        coverImageName = '';
                      }),
                      icon: const Icon(Icons.delete_outline),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: picking || certificates.length >= 8
                    ? null
                    : _pickCertificates,
                icon: picking
                    ? const SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.workspace_premium_outlined),
                label: Text(
                  certificates.isEmpty
                      ? 'Adicionar imagens do certificado'
                      : 'Adicionar certificado (${certificates.length}/8)',
                ),
              ),
              if (certificates.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                SizedBox(
                  height: 105,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: certificates.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, index) => SizedBox(
                      width: 145,
                      child: Stack(
                        children: <Widget>[
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: Image.memory(
                                _decode(
                                  certificates[index]['base64'] as String? ??
                                      '',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 3,
                            top: 3,
                            child: IconButton.filled(
                              tooltip: 'Remover certificado',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => setState(
                                () => certificates.removeAt(index),
                              ),
                              icon: const Icon(Icons.close, size: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            if (name.text.trim().isEmpty) return;
            final previous =
                widget.entity?.payload ?? const <String, dynamic>{};
            await widget.store.save(
              EntityTypes.semester,
              <String, dynamic>{
                ...previous,
                'name': name.text.trim(),
                'kind': 'course',
                'status': status,
                'institution': institution.text.trim(),
                'workload': int.tryParse(workload.text.trim()),
                'startedAt': startedAt?.toIso8601String(),
                'completedAt': completedAt?.toIso8601String(),
                'notes': notes.text.trim(),
                'certificateImages': certificates,
                'folderColor': folderColor,
                'folderIcon': folderIcon,
                'coverImageBase64': coverImageBase64,
                'coverImageName': coverImageName,
                'year': previous['year'] ?? DateTime.now().year,
                'term': previous['term'] ?? 1,
              },
              id: widget.entity?.id,
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Salvar curso'),
        ),
      ],
    );
  }
}

void _previewCertificate(BuildContext context, Map<String, dynamic> item) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: AppColors.appSurface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 720),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: InteractiveViewer(
                  child: Image.memory(
                    _decode(item['base64'] as String? ?? ''),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 7,
              top: 7,
              child: IconButton.filled(
                tooltip: 'Fechar',
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _statusLabel(String status) => switch (status) {
      'completed' => 'Concluído',
      'planned' => 'Planejado',
      _ => 'Em andamento',
    };

String _workloadLabel(dynamic value) {
  final parsed = value is num ? value.toInt() : int.tryParse('$value');
  return parsed == null || parsed <= 0 ? '' : '$parsed h';
}

Uint8List _decode(String value) {
  try {
    return base64Decode(value);
  } catch (_) {
    return Uint8List(0);
  }
}
