import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/academic_data.dart';
import '../core/academic_folder_style.dart';
import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/file_transfer_service.dart';
import '../core/sync_entity.dart';
import '../widgets/premium_widgets.dart';
import 'academic_assessments_screen.dart';
import 'academic_management_screen.dart';
import 'academic_shared.dart';
import 'academic_simulations_screen.dart';
import 'academic_summaries_screen.dart';
import 'code_workspace_screen.dart';
import 'studies_screen.dart';

class AcademicFacultyScreen extends StatelessWidget {
  const AcademicFacultyScreen({required this.store, super.key});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final semesters = AcademicData.sortedSemesters(store);
        final current = semesters.where(
          (item) => item.payload['status'] == 'current',
        );
        final unassigned = AcademicData.subjectsForSemester(store, null);
        return AcademicPageBody(
          maxWidth: 1240,
          children: <Widget>[
            const PageIntro(
              eyebrow: 'Faculdade • Sistemas de Informação',
              title: 'Sua faculdade, organizada como pastas',
              subtitle:
                  'Entre no semestre, escolha a matéria e abra o conteúdo. Cada nível mostra somente o que pertence a ele.',
              color: AppColors.cyan,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ElevatedButton.icon(
                  key: const Key('faculty-add-semester'),
                  onPressed: () => showAcademicSemesterEditor(context, store),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Adicionar semestre'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AcademicSchedulePage(store: store),
                    ),
                  ),
                  icon: const Icon(Icons.calendar_view_week_outlined),
                  label: const Text('Horário de aulas'),
                ),
              ],
            ),
            if (current.isNotEmpty) ...<Widget>[
              const SizedBox(height: 22),
              _CurrentSemesterBanner(
                store: store,
                semester: current.first,
                onOpen: () => _openSemester(context, current.first.id),
              ),
            ],
            const SizedBox(height: 24),
            AcademicSectionTitle(
              title: 'Todos os semestres',
              subtitle:
                  'Os mais recentes aparecem primeiro. O semestre atual fica sempre destacado.',
              trailing: Text(
                '${semesters.length} pasta(s)',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 14),
            if (semesters.isEmpty && unassigned.isEmpty)
              const EmptyState(
                icon: Icons.folder_copy_outlined,
                title: 'Nenhum semestre cadastrado',
                message:
                    'Crie o semestre atual para começar sua organização acadêmica.',
              )
            else
              _AcademicFolderGrid(
                children: <Widget>[
                  ...semesters.map((semester) {
                    final subjects =
                        AcademicData.subjectsForSemester(store, semester.id);
                    final status =
                        semester.payload['status'] as String? ?? 'planned';
                    final currentSemester = status == 'current';
                    final color = currentSemester
                        ? AppColors.primary
                        : status == 'completed'
                            ? AppColors.green
                            : AppColors.cyan;
                    return AcademicFolderCard(
                      key: ValueKey<String>('semester-folder-${semester.id}'),
                      title: semester.payload['name'] as String? ?? 'Semestre',
                      subtitle: _semesterStatusLabel(status),
                      countLabel: '${subjects.length} matéria(s)',
                      color: color,
                      icon: currentSemester
                          ? Icons.folder_special_rounded
                          : Icons.folder_rounded,
                      badge: currentSemester ? 'CURSANDO AGORA' : null,
                      onTap: () => _openSemester(context, semester.id),
                      onEdit: () => showAcademicSemesterEditor(
                        context,
                        store,
                        entity: semester,
                      ),
                      onDelete: () => _confirmDelete(
                        context,
                        title: 'Excluir este semestre?',
                        message:
                            'As matérias, conteúdos e materiais vinculados irão para a lixeira.',
                        onConfirm: () =>
                            AcademicData.deleteSemester(store, semester),
                      ),
                    );
                  }),
                  if (unassigned.isNotEmpty)
                    AcademicFolderCard(
                      title: 'Matérias sem semestre',
                      subtitle: 'Organize registros de versões anteriores',
                      countLabel: '${unassigned.length} matéria(s)',
                      color: AppColors.orange,
                      icon: Icons.folder_off_rounded,
                      badge: 'REVISAR',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              AcademicUnassignedSubjectsPage(store: store),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  void _openSemester(BuildContext context, String semesterId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AcademicSemesterPage(
          store: store,
          semesterId: semesterId,
        ),
      ),
    );
  }
}

class AcademicUnassignedSubjectsPage extends StatelessWidget {
  const AcademicUnassignedSubjectsPage({required this.store, super.key});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matérias sem semestre')),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final subjects = AcademicData.subjectsForSemester(store, null);
          return AcademicPageBody(
            maxWidth: 1240,
            children: <Widget>[
              const _AcademicBreadcrumb(
                items: <String>['Faculdade', 'Matérias sem semestre'],
              ),
              const SizedBox(height: 14),
              const PageIntro(
                eyebrow: 'Organização pendente',
                title: 'Matérias sem semestre',
                subtitle:
                    'Estes registros foram preservados. Edite cada matéria e escolha o semestre correto para organizá-la.',
                color: AppColors.orange,
              ),
              const SizedBox(height: 20),
              if (subjects.isEmpty)
                const EmptyState(
                  icon: Icons.task_alt_rounded,
                  title: 'Tudo organizado',
                  message: 'Não há matérias soltas no banco.',
                )
              else
                _AcademicFolderGrid(
                  children: subjects.map((subject) {
                    final contents =
                        AcademicData.contentsForSubject(store, subject.id);
                    return AcademicFolderCard(
                      title: subject.payload['name'] as String? ?? 'Matéria',
                      subtitle: 'Escolha um semestre em Editar',
                      countLabel: '${contents.length} conteúdo(s)',
                      color: AcademicFolderStyle.colorFor(subject),
                      icon: AcademicFolderStyle.iconFor(subject),
                      coverBytes: AcademicFolderStyle.coverBytes(subject),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AcademicSubjectFolderPage(
                            store: store,
                            semesterId: '',
                            subjectId: subject.id,
                          ),
                        ),
                      ),
                      onEdit: () => showAcademicSubjectEditor(
                        context,
                        store,
                        entity: subject,
                      ),
                      onDelete: () => _confirmDelete(
                        context,
                        title: 'Excluir esta matéria?',
                        message:
                            'Seus conteúdos e materiais vinculados irão para a lixeira.',
                        onConfirm: () =>
                            AcademicData.deleteSubject(store, subject),
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

class _CurrentSemesterBanner extends StatelessWidget {
  const _CurrentSemesterBanner({
    required this.store,
    required this.semester,
    required this.onOpen,
  });

  final AppStore store;
  final SyncEntity semester;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final subjects = AcademicData.subjectsForSemester(store, semester.id);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('current-semester-banner'),
        onTap: onOpen,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                AppColors.primary.withValues(alpha: .34),
                AppColors.surface.withValues(alpha: .98),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: .72),
              width: 1.4,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .13),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: AppColors.primaryLight,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'CURSANDO AGORA',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      semester.payload['name'] as String? ?? 'Semestre atual',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${subjects.length} matéria(s) • toque para entrar',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: AppColors.primaryLight),
            ],
          ),
        ),
      ),
    );
  }
}

class AcademicSemesterPage extends StatelessWidget {
  const AcademicSemesterPage({
    required this.store,
    required this.semesterId,
    super.key,
  });

  final AppStore store;
  final String semesterId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matérias do semestre')),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final semester = store.byId(semesterId);
          if (semester == null) {
            return const _MissingAcademicItem(message: 'Semestre removido.');
          }
          final subjects = AcademicData.subjectsForSemester(store, semesterId);
          return AcademicPageBody(
            maxWidth: 1240,
            children: <Widget>[
              _AcademicBreadcrumb(
                items: <String>[
                  'Faculdade',
                  semester.payload['name'] as String? ?? 'Semestre',
                ],
              ),
              const SizedBox(height: 13),
              PageIntro(
                eyebrow: semester.payload['status'] == 'current'
                    ? 'Semestre atual'
                    : 'Semestre acadêmico',
                title: semester.payload['name'] as String? ?? 'Semestre',
                subtitle:
                    'Abra uma matéria para encontrar somente os conteúdos e materiais dela.',
                color: semester.payload['status'] == 'current'
                    ? AppColors.primary
                    : AppColors.cyan,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  ElevatedButton.icon(
                    key: const Key('faculty-add-subject'),
                    onPressed: () => showAcademicSubjectEditor(
                      context,
                      store,
                      initialSemesterId: semesterId,
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Adicionar matéria'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => showAcademicSemesterEditor(
                      context,
                      store,
                      entity: semester,
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar semestre'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AcademicSchedulePage(
                          store: store,
                          semesterId: semesterId,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.calendar_view_week_outlined),
                    label: const Text('Horários deste semestre'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AcademicSectionTitle(
                title: 'Matérias',
                subtitle:
                    'Capas, cores e símbolos ajudam a reconhecer cada matéria rapidamente.',
                trailing: Text(
                  '${subjects.length} pasta(s)',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 14),
              if (subjects.isEmpty)
                const EmptyState(
                  icon: Icons.folder_open_outlined,
                  title: 'Este semestre ainda está vazio',
                  message:
                      'Use “Adicionar matéria” para cadastrar a primeira disciplina.',
                )
              else
                _AcademicFolderGrid(
                  children: subjects.map((subject) {
                    final contents =
                        AcademicData.contentsForSubject(store, subject.id);
                    final color = AcademicFolderStyle.colorFor(subject);
                    return AcademicFolderCard(
                      key: ValueKey<String>('subject-folder-${subject.id}'),
                      title: subject.payload['name'] as String? ?? 'Matéria',
                      subtitle: <String>[
                        subject.payload['code'] as String? ?? '',
                        subject.payload['professor'] as String? ?? '',
                      ].where((item) => item.isNotEmpty).join(' • '),
                      countLabel: '${contents.length} conteúdo(s)',
                      color: color,
                      icon: AcademicFolderStyle.iconFor(subject),
                      coverBytes: AcademicFolderStyle.coverBytes(subject),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AcademicSubjectFolderPage(
                            store: store,
                            semesterId: semesterId,
                            subjectId: subject.id,
                          ),
                        ),
                      ),
                      onEdit: () => showAcademicSubjectEditor(
                        context,
                        store,
                        entity: subject,
                        initialSemesterId: semesterId,
                      ),
                      onDelete: () => _confirmDelete(
                        context,
                        title: 'Excluir esta matéria?',
                        message:
                            'Seus conteúdos e materiais vinculados irão para a lixeira.',
                        onConfirm: () =>
                            AcademicData.deleteSubject(store, subject),
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

class AcademicSubjectFolderPage extends StatelessWidget {
  const AcademicSubjectFolderPage({
    required this.store,
    required this.semesterId,
    required this.subjectId,
    super.key,
  });

  final AppStore store;
  final String semesterId;
  final String subjectId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conteúdos da matéria')),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final semester = store.byId(semesterId);
          final subject = store.byId(subjectId);
          if (subject == null) {
            return const _MissingAcademicItem(message: 'Matéria removida.');
          }
          final contents = AcademicData.contentsForSubject(store, subjectId);
          final color = AcademicFolderStyle.colorFor(subject);
          return AcademicPageBody(
            maxWidth: 1240,
            children: <Widget>[
              _AcademicBreadcrumb(
                items: <String>[
                  'Faculdade',
                  semester?.payload['name'] as String? ?? 'Semestre',
                  subject.payload['name'] as String? ?? 'Matéria',
                ],
              ),
              const SizedBox(height: 14),
              _SubjectHero(subject: subject, color: color),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  ElevatedButton.icon(
                    key: const Key('faculty-add-content'),
                    onPressed: () => showAcademicContentEditor(
                      context,
                      store,
                      initialSubjectId: subjectId,
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Adicionar conteúdo'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => showAcademicSubjectEditor(
                      context,
                      store,
                      entity: subject,
                      initialSemesterId: semesterId,
                    ),
                    icon: const Icon(Icons.palette_outlined),
                    label: const Text('Personalizar matéria'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AcademicSectionTitle(
                title: 'Conteúdos',
                subtitle:
                    'Cada pasta reúne os resumos, códigos, arquivos e exercícios daquele assunto.',
                trailing: Text(
                  '${contents.length} pasta(s)',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 14),
              if (contents.isEmpty)
                const EmptyState(
                  icon: Icons.create_new_folder_outlined,
                  title: 'Nenhum conteúdo nesta matéria',
                  message:
                      'Crie unidades, capítulos ou assuntos conforme o plano de ensino.',
                )
              else
                _AcademicFolderGrid(
                  children: contents.map((content) {
                    return AcademicFolderCard(
                      key: ValueKey<String>('content-folder-${content.id}'),
                      title: content.payload['title'] as String? ?? 'Conteúdo',
                      subtitle: content.payload['description'] as String? ?? '',
                      countLabel:
                          '${_contentItemCount(store, content.id)} item(ns)',
                      color: color,
                      icon: content.payload['completed'] == true
                          ? Icons.task_alt_rounded
                          : Icons.folder_open_rounded,
                      badge: content.payload['completed'] == true
                          ? 'CONCLUÍDO'
                          : null,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AcademicContentHubPage(
                            store: store,
                            semesterId: semesterId,
                            subjectId: subjectId,
                            contentId: content.id,
                          ),
                        ),
                      ),
                      onEdit: () => showAcademicContentEditor(
                        context,
                        store,
                        entity: content,
                        initialSubjectId: subjectId,
                      ),
                      onDelete: () => _confirmDelete(
                        context,
                        title: 'Excluir este conteúdo?',
                        message:
                            'Os resumos, questões, flashcards e arquivos vinculados irão para a lixeira.',
                        onConfirm: () =>
                            AcademicData.deleteContent(store, content),
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

class AcademicContentHubPage extends StatelessWidget {
  const AcademicContentHubPage({
    required this.store,
    required this.semesterId,
    required this.subjectId,
    required this.contentId,
    super.key,
  });

  final AppStore store;
  final String semesterId;
  final String subjectId;
  final String contentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ambiente do conteúdo')),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final semester = store.byId(semesterId);
          final subject = store.byId(subjectId);
          final content = store.byId(contentId);
          if (subject == null || content == null) {
            return const _MissingAcademicItem(message: 'Conteúdo removido.');
          }
          final color = AcademicFolderStyle.colorFor(subject);
          final folders = _contentTools(context, subject, content, color);
          return AcademicPageBody(
            maxWidth: 1240,
            children: <Widget>[
              _AcademicBreadcrumb(
                items: <String>[
                  'Faculdade',
                  semester?.payload['name'] as String? ?? 'Semestre',
                  subject.payload['name'] as String? ?? 'Matéria',
                  content.payload['title'] as String? ?? 'Conteúdo',
                ],
              ),
              const SizedBox(height: 14),
              PremiumCard(
                borderColor: color.withValues(alpha: .65),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(Icons.folder_open_rounded, color: color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            subject.payload['name'] as String? ?? 'Matéria',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            content.payload['title'] as String? ?? 'Conteúdo',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if ((content.payload['description'] as String? ?? '')
                              .isNotEmpty) ...<Widget>[
                            const SizedBox(height: 7),
                            Text(
                              content.payload['description'] as String,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Editar conteúdo',
                      onPressed: () => showAcademicContentEditor(
                        context,
                        store,
                        entity: content,
                        initialSubjectId: subjectId,
                      ),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const AcademicSectionTitle(
                title: 'Pastas deste conteúdo',
                subtitle:
                    'Tudo o que você produzir sobre este assunto fica separado aqui.',
              ),
              const SizedBox(height: 14),
              _AcademicFolderGrid(children: folders),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _contentTools(
    BuildContext context,
    SyncEntity subject,
    SyncEntity content,
    Color subjectColor,
  ) {
    final notes = _recordsForContent(store, EntityTypes.studyNote, contentId);
    final projects =
        _recordsForContent(store, EntityTypes.codeProject, contentId);
    final images =
        AcademicData.assetsForContent(store, contentId, kind: 'image');
    final attachments =
        AcademicData.assetsForContent(store, contentId, kind: 'attachment');
    final questions =
        _recordsForContent(store, EntityTypes.studyQuestion, contentId);
    final flashcards =
        _recordsForContent(store, EntityTypes.flashcard, contentId);
    final exams = _recordsForContent(store, EntityTypes.exam, contentId);
    return <Widget>[
      AcademicFolderCard(
        title: 'Resumos',
        subtitle: 'Editor completo, imagens, anexos e PDF',
        countLabel: '${notes.length} resumo(s)',
        color: subjectColor,
        icon: Icons.description_rounded,
        onTap: () => _openTool(
          context,
          'Resumos • ${content.payload['title']}',
          AcademicSummariesScreen(
            store: store,
            initialSubjectId: subjectId,
            initialContentId: contentId,
          ),
        ),
      ),
      AcademicFolderCard(
        title: 'Códigos',
        subtitle: 'Projetos e arquivos ligados à matéria',
        countLabel: '${projects.length} projeto(s)',
        color: AppColors.cyan,
        icon: Icons.terminal_rounded,
        onTap: () => _openTool(
          context,
          'Códigos • ${content.payload['title']}',
          CodeWorkspaceScreen(
            store: store,
            initialSemesterId: semesterId,
            initialSubjectId: subjectId,
            initialContentId: contentId,
          ),
        ),
      ),
      AcademicFolderCard(
        title: 'Imagens',
        subtitle: 'Diagramas, quadros e referências visuais',
        countLabel: '${images.length} imagem(ns)',
        color: const Color(0xFFE5488C),
        icon: Icons.photo_library_rounded,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AcademicContentAssetsPage(
              store: store,
              subjectId: subjectId,
              contentId: contentId,
              kind: ContentAssetKind.image,
            ),
          ),
        ),
      ),
      AcademicFolderCard(
        title: 'Anexos',
        subtitle: 'PDFs, documentos, planilhas e outros arquivos',
        countLabel: '${attachments.length} arquivo(s)',
        color: AppColors.orange,
        icon: Icons.attach_file_rounded,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AcademicContentAssetsPage(
              store: store,
              subjectId: subjectId,
              contentId: contentId,
              kind: ContentAssetKind.attachment,
            ),
          ),
        ),
      ),
      AcademicFolderCard(
        title: 'Simulados',
        subtitle: 'Questões e resultados deste conteúdo',
        countLabel: '${questions.length} questão(ões)',
        color: AppColors.green,
        icon: Icons.quiz_rounded,
        onTap: () => _openTool(
          context,
          'Simulados • ${content.payload['title']}',
          AcademicSimulationsScreen(
            store: store,
            initialSubjectId: subjectId,
            initialContentId: contentId,
          ),
        ),
      ),
      AcademicFolderCard(
        title: 'Flashcards',
        subtitle: 'Revisão rápida e repetição espaçada',
        countLabel: '${flashcards.length} card(s)',
        color: const Color(0xFF7B61FF),
        icon: Icons.style_rounded,
        onTap: () => _openTool(
          context,
          'Flashcards • ${content.payload['title']}',
          StudyFlashcardsPage(
            store: store,
            initialSubjectId: subjectId,
            initialContentId: contentId,
          ),
        ),
      ),
      AcademicFolderCard(
        title: 'Provas e notas',
        subtitle: 'Datas, avaliações, pesos e desempenho',
        countLabel: '${exams.length} avaliação(ões)',
        color: const Color(0xFFFFB020),
        icon: Icons.fact_check_rounded,
        onTap: () => _openTool(
          context,
          'Provas • ${content.payload['title']}',
          AcademicAssessmentsScreen(
            store: store,
            initialSubjectId: subjectId,
            initialContentId: contentId,
          ),
        ),
      ),
    ];
  }

  void _openTool(BuildContext context, String title, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: page,
        ),
      ),
    );
  }
}

enum ContentAssetKind { image, attachment }

class AcademicContentAssetsPage extends StatefulWidget {
  const AcademicContentAssetsPage({
    required this.store,
    required this.subjectId,
    required this.contentId,
    required this.kind,
    super.key,
  });

  final AppStore store;
  final String subjectId;
  final String contentId;
  final ContentAssetKind kind;

  @override
  State<AcademicContentAssetsPage> createState() =>
      _AcademicContentAssetsPageState();
}

class _AcademicContentAssetsPageState extends State<AcademicContentAssetsPage> {
  bool adding = false;

  String get kindValue =>
      widget.kind == ContentAssetKind.image ? 'image' : 'attachment';

  Future<void> _add() async {
    if (adding) return;
    setState(() => adding = true);
    try {
      if (widget.kind == ContentAssetKind.image) {
        final picked = await FileTransferService.pickImagePayloads();
        for (final item in picked) {
          final bytes = item['imageBytes'];
          if (bytes is! List<int>) continue;
          final name = item['imageName'] as String? ?? 'imagem.jpg';
          await widget.store.save(
            EntityTypes.contentAsset,
            <String, dynamic>{
              'subjectId': widget.subjectId,
              'contentId': widget.contentId,
              'kind': kindValue,
              'name': name,
              'extension': _extensionFromName(name),
              'sizeBytes': bytes.length,
              'base64': base64Encode(bytes),
              'createdAt': DateTime.now().millisecondsSinceEpoch,
            },
          );
        }
      } else {
        final picked = await FileTransferService.pickAttachmentPayloads();
        for (final item in picked) {
          await widget.store.save(
            EntityTypes.contentAsset,
            <String, dynamic>{
              ...item,
              'subjectId': widget.subjectId,
              'contentId': widget.contentId,
              'kind': kindValue,
              'createdAt': DateTime.now().millisecondsSinceEpoch,
            },
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível adicionar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => adding = false);
    }
  }

  Future<void> _saveFile(SyncEntity asset) async {
    try {
      await FileTransferService.saveAttachment(asset.payload);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível salvar: $error')),
        );
      }
    }
  }

  Future<void> _rename(SyncEntity asset) async {
    final controller = TextEditingController(
      text: asset.payload['name'] as String? ?? '',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Renomear arquivo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim(),
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    await widget.store.save(
      EntityTypes.contentAsset,
      <String, dynamic>{...asset.payload, 'name': name},
      id: asset.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isImage = widget.kind == ContentAssetKind.image;
    return Scaffold(
      appBar: AppBar(title: Text(isImage ? 'Imagens do conteúdo' : 'Anexos')),
      body: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          final content = widget.store.byId(widget.contentId);
          final assets = AcademicData.assetsForContent(
            widget.store,
            widget.contentId,
            kind: kindValue,
          );
          return AcademicPageBody(
            maxWidth: 1240,
            children: <Widget>[
              _AcademicBreadcrumb(
                items: <String>[
                  AcademicData.subjectName(widget.store, widget.subjectId),
                  AcademicData.contentName(widget.store, widget.contentId),
                  isImage ? 'Imagens' : 'Anexos',
                ],
              ),
              const SizedBox(height: 14),
              PageIntro(
                eyebrow: isImage ? 'Galeria local' : 'Arquivos locais',
                title: isImage ? 'Imagens do conteúdo' : 'Anexos do conteúdo',
                subtitle: isImage
                    ? 'Guarde diagramas, fotos do quadro, prints e referências de ${content?.payload['title'] ?? 'estudo'}.'
                    : 'Guarde PDFs, documentos, planilhas e qualquer material ligado a este conteúdo.',
                color: isImage ? const Color(0xFFE5488C) : AppColors.orange,
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  key: const Key('content-assets-add'),
                  onPressed: adding ? null : _add,
                  icon: adding
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(isImage
                          ? Icons.add_photo_alternate_outlined
                          : Icons.attach_file_rounded),
                  label:
                      Text(isImage ? 'Adicionar imagens' : 'Adicionar anexos'),
                ),
              ),
              const SizedBox(height: 20),
              if (assets.isEmpty)
                EmptyState(
                  icon: isImage
                      ? Icons.photo_library_outlined
                      : Icons.folder_zip_outlined,
                  title: isImage ? 'Galeria vazia' : 'Nenhum anexo',
                  message: isImage
                      ? 'As imagens adicionadas aqui ficarão neste conteúdo.'
                      : 'Adicione arquivos para manter todo o material no lugar certo.',
                )
              else if (isImage)
                _AcademicFolderGrid(
                  children: assets
                      .map(
                        (asset) => _ContentImageCard(
                          asset: asset,
                          onOpen: () => _openImage(context, asset),
                          onSave: () => _saveFile(asset),
                          onRename: () => _rename(asset),
                          onDelete: () => _confirmDelete(
                            context,
                            title: 'Excluir esta imagem?',
                            message: 'A imagem será enviada para a lixeira.',
                            onConfirm: () => widget.store.remove(asset.id),
                          ),
                        ),
                      )
                      .toList(),
                )
              else
                ...assets.map(
                  (asset) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PremiumCard(
                      padding: const EdgeInsets.all(10),
                      child: ListTile(
                        leading: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.insert_drive_file_outlined,
                            color: AppColors.orange,
                          ),
                        ),
                        title: Text(
                          asset.payload['name'] as String? ?? 'Arquivo',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          _formatBytes(
                            (asset.payload['sizeBytes'] as num? ?? 0).toInt(),
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'save') _saveFile(asset);
                            if (value == 'rename') _rename(asset);
                            if (value == 'delete') {
                              _confirmDelete(
                                context,
                                title: 'Excluir este anexo?',
                                message:
                                    'O arquivo será enviado para a lixeira.',
                                onConfirm: () => widget.store.remove(asset.id),
                              );
                            }
                          },
                          itemBuilder: (_) => const <PopupMenuEntry<String>>[
                            PopupMenuItem(
                                value: 'save', child: Text('Salvar cópia')),
                            PopupMenuItem(
                                value: 'rename', child: Text('Renomear')),
                            PopupMenuItem(
                                value: 'delete', child: Text('Excluir')),
                          ],
                        ),
                        onTap: () => _saveFile(asset),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _openImage(BuildContext context, SyncEntity asset) {
    final bytes = _assetBytes(asset);
    if (bytes == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(asset.payload['name'] as String? ?? 'Imagem'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Salvar cópia',
                onPressed: () => _saveFile(asset),
                icon: const Icon(Icons.download_outlined),
              ),
            ],
          ),
          body: ColoredBox(
            color: Colors.black,
            child: Center(
              child: InteractiveViewer(
                minScale: .5,
                maxScale: 5,
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AcademicSchedulePage extends StatelessWidget {
  const AcademicSchedulePage({
    required this.store,
    this.semesterId,
    super.key,
  });

  final AppStore store;
  final String? semesterId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Horário de aulas')),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final subjects = semesterId == null
              ? AcademicData.academicSubjects(store)
              : AcademicData.subjectsForSemester(store, semesterId);
          final subjectIds = subjects.map((item) => item.id).toSet();
          final sessions = store
              .records(EntityTypes.classSession)
              .where((item) => subjectIds.contains(item.payload['subjectId']))
              .toList()
            ..sort((a, b) {
              final day = (a.payload['weekday'] as num? ?? 1).compareTo(
                b.payload['weekday'] as num? ?? 1,
              );
              if (day != 0) return day;
              return (a.payload['start'] as String? ?? '')
                  .compareTo(b.payload['start'] as String? ?? '');
            });
          return AcademicPageBody(
            maxWidth: 980,
            children: <Widget>[
              const PageIntro(
                eyebrow: 'Semana acadêmica',
                title: 'Horário de aulas',
                subtitle:
                    'Organize suas aulas de segunda a domingo sem misturar cursos livres.',
                color: AppColors.cyan,
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: subjects.isEmpty
                      ? null
                      : () => showAcademicScheduleEditor(
                            context,
                            store,
                            initialSubjectId:
                                subjects.length == 1 ? subjects.first.id : null,
                          ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Adicionar aula'),
                ),
              ),
              const SizedBox(height: 20),
              if (subjects.isEmpty)
                const EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'Cadastre uma matéria primeiro',
                  message:
                      'O horário é sempre ligado a uma matéria da faculdade.',
                )
              else if (sessions.isEmpty)
                const EmptyState(
                  icon: Icons.calendar_view_week_outlined,
                  title: 'Nenhuma aula cadastrada',
                  message: 'Use o botão acima para montar sua semana.',
                )
              else
                ...AcademicData.weekdayLong.entries.map((day) {
                  final daySessions = sessions
                      .where((item) => item.payload['weekday'] == day.key)
                      .toList();
                  if (daySessions.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PremiumCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            day.value,
                            style: TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...daySessions.map(
                            (session) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.schedule_rounded,
                                color: AppColors.cyan,
                              ),
                              title: Text(
                                AcademicData.subjectName(
                                  store,
                                  session.payload['subjectId'] as String?,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                '${session.payload['start']}–${session.payload['end']}'
                                '${(session.payload['room'] as String? ?? '').isEmpty ? '' : ' • ${session.payload['room']}'}',
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    showAcademicScheduleEditor(
                                      context,
                                      store,
                                      entity: session,
                                    );
                                  }
                                  if (value == 'delete') {
                                    _confirmDelete(
                                      context,
                                      title: 'Excluir este horário?',
                                      message:
                                          'A aula será removida do cronograma.',
                                      onConfirm: () => store.remove(session.id),
                                    );
                                  }
                                },
                                itemBuilder: (_) =>
                                    const <PopupMenuEntry<String>>[
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Editar'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Excluir'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _SubjectHero extends StatelessWidget {
  const _SubjectHero({required this.subject, required this.color});

  final SyncEntity subject;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cover = AcademicFolderStyle.coverBytes(subject);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: <Widget>[
          if (cover != null)
            Positioned.fill(
              child: Image.memory(
                cover,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: cover == null
                      ? <Color>[
                          color.withValues(alpha: .42),
                          AppColors.surface,
                        ]
                      : <Color>[
                          Colors.black.withValues(alpha: .32),
                          Colors.black.withValues(alpha: .82),
                        ],
                ),
                border: Border.all(color: color.withValues(alpha: .65)),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: <Widget>[
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .24),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color.withValues(alpha: .55)),
                  ),
                  child: Icon(
                    AcademicFolderStyle.iconFor(subject),
                    color: Colors.white,
                    size: 31,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'MATÉRIA',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subject.payload['name'] as String? ?? 'Matéria',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        <String>[
                          subject.payload['code'] as String? ?? '',
                          subject.payload['professor'] as String? ?? '',
                          subject.payload['room'] as String? ?? '',
                        ].where((item) => item.isNotEmpty).join(' • '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AcademicFolderGrid extends StatelessWidget {
  const _AcademicFolderGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1040
            ? 4
            : width >= 720
                ? 3
                : width >= 330
                    ? 2
                    : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: width < 440 ? .72 : 1.08,
          children: children,
        );
      },
    );
  }
}

class AcademicFolderCard extends StatelessWidget {
  const AcademicFolderCard({
    required this.title,
    required this.subtitle,
    required this.countLabel,
    required this.color,
    required this.icon,
    required this.onTap,
    this.coverBytes,
    this.badge,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final String title;
  final String subtitle;
  final String countLabel;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final Uint8List? coverBytes;
  final String? badge;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final hasImage = coverBytes != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withValues(alpha: .55)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: color.withValues(alpha: .09),
                blurRadius: 20,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Stack(
              children: <Widget>[
                if (hasImage)
                  Positioned.fill(
                    child: Image.memory(
                      coverBytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: hasImage
                            ? <Color>[
                                Colors.black.withValues(alpha: .20),
                                Colors.black.withValues(alpha: .88),
                              ]
                            : <Color>[
                                color.withValues(alpha: .24),
                                AppColors.surface.withValues(alpha: .98),
                              ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 15,
                  top: 0,
                  child: Container(
                    width: 72,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(8),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .22),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: color.withValues(alpha: .52),
                              ),
                            ),
                            child: Icon(icon, color: Colors.white, size: 25),
                          ),
                          const Spacer(),
                          if (onEdit != null || onDelete != null)
                            PopupMenuButton<String>(
                              tooltip: 'Opções da pasta',
                              onSelected: (value) {
                                if (value == 'edit') onEdit?.call();
                                if (value == 'delete') onDelete?.call();
                              },
                              itemBuilder: (_) => <PopupMenuEntry<String>>[
                                if (onEdit != null)
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Editar'),
                                  ),
                                if (onDelete != null)
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Excluir'),
                                  ),
                              ],
                            ),
                        ],
                      ),
                      const Spacer(),
                      if (badge != null) ...<Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .24),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: color.withValues(alpha: .5),
                            ),
                          ),
                          child: Text(
                            badge!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                      ],
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Icon(Icons.folder_outlined, color: color, size: 16),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              countLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: hasImage
                                    ? Colors.white70
                                    : AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: color,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentImageCard extends StatelessWidget {
  const _ContentImageCard({
    required this.asset,
    required this.onOpen,
    required this.onSave,
    required this.onRename,
    required this.onDelete,
  });

  final SyncEntity asset;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final bytes = _assetBytes(asset);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE5488C).withValues(alpha: .5),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (bytes != null)
                  Image.memory(bytes, fit: BoxFit.cover)
                else
                  const Center(child: Icon(Icons.broken_image_outlined)),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: <Color>[Colors.transparent, Colors.black87],
                    ),
                  ),
                ),
                Positioned(
                  right: 5,
                  top: 5,
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'save') onSave();
                      if (value == 'rename') onRename();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const <PopupMenuEntry<String>>[
                      PopupMenuItem(value: 'save', child: Text('Salvar cópia')),
                      PopupMenuItem(value: 'rename', child: Text('Renomear')),
                      PopupMenuItem(value: 'delete', child: Text('Excluir')),
                    ],
                  ),
                ),
                Positioned(
                  left: 13,
                  right: 13,
                  bottom: 13,
                  child: Text(
                    asset.payload['name'] as String? ?? 'Imagem',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AcademicBreadcrumb extends StatelessWidget {
  const _AcademicBreadcrumb({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          const Icon(Icons.home_work_outlined, size: 18, color: AppColors.cyan),
          const SizedBox(width: 7),
          for (var index = 0; index < items.length; index++) ...<Widget>[
            if (index > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 7),
                child: Icon(
                  Icons.chevron_right,
                  size: 17,
                  color: AppColors.textMuted,
                ),
              ),
            Text(
              items[index],
              style: TextStyle(
                color: index == items.length - 1
                    ? Colors.white
                    : AppColors.textMuted,
                fontWeight: index == items.length - 1
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MissingAcademicItem extends StatelessWidget {
  const _MissingAcademicItem({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Center(
        child: EmptyState(
          icon: Icons.folder_off_outlined,
          title: message,
          message: 'Volte para a pasta anterior para continuar.',
        ),
      ),
    );
  }
}

List<SyncEntity> _recordsForContent(
  AppStore store,
  String type,
  String contentId,
) =>
    store
        .records(type)
        .where((item) => item.payload['contentId'] == contentId)
        .toList(growable: false);

int _contentItemCount(AppStore store, String contentId) {
  var total = 0;
  for (final type in <String>[
    EntityTypes.studyNote,
    EntityTypes.codeProject,
    EntityTypes.studyQuestion,
    EntityTypes.flashcard,
    EntityTypes.exam,
    EntityTypes.contentAsset,
  ]) {
    total += _recordsForContent(store, type, contentId).length;
  }
  return total;
}

Uint8List? _assetBytes(SyncEntity asset) {
  final encoded = asset.payload['base64'] as String? ?? '';
  if (encoded.isEmpty) return null;
  try {
    return base64Decode(encoded);
  } catch (_) {
    return null;
  }
}

String _extensionFromName(String name) {
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) return '';
  return name.substring(dot + 1).toLowerCase();
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _semesterStatusLabel(String status) {
  return switch (status) {
    'completed' => 'Concluído',
    'planned' => 'Planejado',
    _ => 'Em andamento',
  };
}

Future<void> _confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
  required Future<void> Function() onConfirm,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text('$message\n\nNada será apagado definitivamente agora.'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Mover para lixeira'),
        ),
      ],
    ),
  );
  if (confirmed == true) await onConfirm();
}
