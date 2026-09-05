import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/academic_data.dart';
import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/sync_entity.dart';
import '../widgets/premium_widgets.dart';
import 'academic_assessments_screen.dart';
import 'academic_shared.dart';
import 'academic_simulations_screen.dart';
import 'academic_summaries_screen.dart';
import 'studies_screen.dart';

class AcademicDashboardScreen extends StatefulWidget {
  const AcademicDashboardScreen({
    required this.store,
    required this.onOpenSection,
    super.key,
  });

  final AppStore store;
  final ValueChanged<int> onOpenSection;

  @override
  State<AcademicDashboardScreen> createState() =>
      _AcademicDashboardScreenState();
}

class _AcademicDashboardScreenState extends State<AcademicDashboardScreen> {
  late int selectedWeekday;

  @override
  void initState() {
    super.initState();
    selectedWeekday = DateTime.now().weekday;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final semesters = AcademicData.sortedSemesters(widget.store);
    final currentItems =
        semesters.where((item) => item.payload['status'] == 'current').toList();
    final currentSemester = currentItems.isEmpty ? null : currentItems.first;
    final allSubjects = AcademicData.academicSubjects(widget.store);
    final academicSubjectIds = allSubjects.map((item) => item.id).toSet();
    final currentSubjects = currentSemester == null
        ? allSubjects
        : AcademicData.subjectsForSemester(widget.store, currentSemester.id);
    final classes = widget.store
        .records(EntityTypes.classSession)
        .where(
          (item) =>
              item.payload['weekday'] == selectedWeekday &&
              academicSubjectIds.contains(item.payload['subjectId']),
        )
        .toList()
      ..sort(
        (a, b) => (a.payload['start'] as String? ?? '').compareTo(
          b.payload['start'] as String? ?? '',
        ),
      );
    final upcoming = widget.store.records(EntityTypes.exam).where((item) {
      if (!academicSubjectIds.contains(item.payload['subjectId'])) return false;
      if (item.payload['completed'] == true) return false;
      final date = DateTime.tryParse(item.payload['date'] as String? ?? '');
      if (date == null) return false;
      final today = DateTime(now.year, now.month, now.day);
      return !date.isBefore(today) && date.difference(today).inDays <= 30;
    }).toList()
      ..sort(
        (a, b) => (a.payload['date'] as String? ?? '').compareTo(
          b.payload['date'] as String? ?? '',
        ),
      );
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    final todayGoals = widget.store
        .records(EntityTypes.dailyStudyGoal)
        .where((item) => item.payload['date'] == todayKey)
        .toList();
    final openKanban = widget.store
        .records(EntityTypes.kanbanTask)
        .where((item) => item.payload['status'] != 'done')
        .toList();
    final academicSummaryCount = widget.store
        .records(EntityTypes.studyNote)
        .where((item) => academicSubjectIds.contains(item.payload['subjectId']))
        .length;
    final academicQuestionCount = widget.store
        .records(EntityTypes.studyQuestion)
        .where((item) => academicSubjectIds.contains(item.payload['subjectId']))
        .length;

    return AcademicPageBody(
      children: <Widget>[
        _AcademicHero(
          now: now,
          semester: currentSemester?.payload['name'] as String?,
          displayName: widget.store.activeAccount?.displayName,
        ),
        const SizedBox(height: 18),
        _AcademicInfoStrip(
          items: <_InfoStripItem>[
            _InfoStripItem(
              label: 'Cadeiras atuais',
              value: '${currentSubjects.length}',
              icon: Icons.menu_book_outlined,
              color: AppColors.primary,
            ),
            _InfoStripItem(
              label: 'Resumos',
              value: '$academicSummaryCount',
              icon: Icons.summarize_outlined,
              color: AppColors.cyan,
            ),
            _InfoStripItem(
              label: 'Avaliações próximas',
              value: '${upcoming.length}',
              icon: Icons.event_available_outlined,
              color: AppColors.orange,
            ),
            _InfoStripItem(
              label: 'Questões',
              value: '$academicQuestionCount',
              icon: Icons.quiz_outlined,
              color: AppColors.green,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const AcademicSectionTitle(
          title: 'Horário de aulas',
          subtitle: 'Selecione o dia para consultar a grade semanal.',
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: AcademicData.weekdayShort.entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: selectedWeekday == entry.key,
                      onSelected: (_) =>
                          setState(() => selectedWeekday = entry.key),
                      avatar: selectedWeekday == entry.key
                          ? const Icon(Icons.check, size: 17)
                          : null,
                      label: Text(entry.value),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        _ScheduleViewer(
          store: widget.store,
          weekday: selectedWeekday,
          sessions: classes,
        ),
        const SizedBox(height: 24),
        _TodayStudyOverview(
          store: widget.store,
          goals: todayGoals,
          tasks: openKanban,
          onOpenGoals: () => widget.onOpenSection(1),
          onOpenKanban: () => widget.onOpenSection(3),
        ),
        const SizedBox(height: 24),
        AcademicSectionTitle(
          title: 'Sua graduação',
          subtitle:
              'Semestres mais recentes primeiro. Abra uma cadeira para acessar conteúdos e ferramentas.',
          trailing: TextButton(
            onPressed: () => widget.onOpenSection(8),
            child: const Text('Organizar'),
          ),
        ),
        const SizedBox(height: 12),
        if (semesters.isEmpty && allSubjects.isEmpty)
          const EmptyState(
            icon: Icons.school_outlined,
            title: 'Sua graduação começa aqui',
            message:
                'Abra Faculdade no menu lateral e cadastre o semestre atual, as cadeiras e seus conteúdos.',
          )
        else ...<Widget>[
          ...semesters.map(
            (semester) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _SemesterViewer(store: widget.store, semester: semester),
            ),
          ),
          if (AcademicData.subjectsForSemester(widget.store, null).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _UnassignedSubjectsViewer(store: widget.store),
            ),
        ],
        const SizedBox(height: 24),
        AcademicSectionTitle(
          title: 'Próximas avaliações',
          subtitle: 'Provas, trabalhos, projetos e apresentações.',
          trailing: TextButton(
            onPressed: () => widget.onOpenSection(5),
            child: const Text('Ver agenda'),
          ),
        ),
        const SizedBox(height: 12),
        if (upcoming.isEmpty)
          const EmptyState(
            icon: Icons.event_available_outlined,
            title: 'Nada previsto nos próximos 30 dias',
            message: 'As próximas avaliações cadastradas aparecerão aqui.',
          )
        else
          PremiumCard(
            child: Column(
              children: upcoming.take(6).map((item) {
                final date = DateTime.tryParse(
                  item.payload['date'] as String? ?? '',
                );
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.assignment_outlined,
                    color: AppColors.orange,
                  ),
                  title: Text(
                    item.payload['title'] as String? ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    AcademicData.subjectName(
                      widget.store,
                      item.payload['subjectId'] as String?,
                    ),
                  ),
                  trailing: Text(
                    date == null ? '—' : DateFormat('dd/MM').format(date),
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final actions = <Widget>[
              AcademicActionCard(
                icon: Icons.summarize_outlined,
                color: AppColors.primary,
                title: 'Biblioteca de resumos',
                subtitle: 'Texto, imagens e PDF por conteúdo.',
                onTap: () => widget.onOpenSection(2),
              ),
              AcademicActionCard(
                icon: Icons.quiz_outlined,
                color: AppColors.green,
                title: 'Treinar com simulados',
                subtitle: 'Questões filtradas por matéria e conteúdo.',
                onTap: () => widget.onOpenSection(4),
              ),
              AcademicActionCard(
                icon: Icons.terminal_rounded,
                color: AppColors.cyan,
                title: 'Abrir IDE acadêmica',
                subtitle: 'Projetos de código ligados às matérias.',
                onTap: () => widget.onOpenSection(6),
              ),
            ];
            if (constraints.maxWidth >= 960) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: actions[0]),
                  const SizedBox(width: 13),
                  Expanded(child: actions[1]),
                  const SizedBox(width: 13),
                  Expanded(child: actions[2]),
                ],
              );
            }
            return Column(
              children: <Widget>[
                actions[0],
                const SizedBox(height: 12),
                actions[1],
                const SizedBox(height: 12),
                actions[2],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _InfoStripItem {
  const _InfoStripItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _AcademicInfoStrip extends StatelessWidget {
  const _AcademicInfoStrip({required this.items});

  final List<_InfoStripItem> items;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = constraints.maxWidth >= 900
              ? 4
              : constraints.maxWidth >= 520
                  ? 2
                  : 1;
          final width = (constraints.maxWidth - ((count - 1) * 8)) / count;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              return SizedBox(
                width: width,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 76),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: item.color.withValues(alpha: .28),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: item.color, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              item.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _TodayStudyOverview extends StatelessWidget {
  const _TodayStudyOverview({
    required this.store,
    required this.goals,
    required this.tasks,
    required this.onOpenGoals,
    required this.onOpenKanban,
  });

  final AppStore store;
  final List<SyncEntity> goals;
  final List<SyncEntity> tasks;
  final VoidCallback onOpenGoals;
  final VoidCallback onOpenKanban;

  @override
  Widget build(BuildContext context) {
    final goalsCard = PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _OverviewHeader(
            icon: Icons.flag_outlined,
            color: AppColors.cyan,
            title: 'Metas de hoje',
            onTap: onOpenGoals,
          ),
          const SizedBox(height: 8),
          if (goals.isEmpty)
            const Text(
              'Dia livre: crie metas somente quando elas ajudarem seu ritmo.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            ...goals.take(3).map(
                  (goal) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      goal.payload['completed'] == true
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: goal.payload['completed'] == true
                          ? AppColors.green
                          : AppColors.cyan,
                    ),
                    title: Text(
                      goal.payload['title'] as String? ?? 'Meta de estudo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${AcademicData.subjectName(store, goal.payload['subjectId'] as String?)} • ${goal.payload['plannedMinutes'] ?? 30} min',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
        ],
      ),
    );
    final tasksCard = PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _OverviewHeader(
            icon: Icons.view_kanban_outlined,
            color: AppColors.orange,
            title: 'Atividades em aberto',
            onTap: onOpenKanban,
          ),
          const SizedBox(height: 8),
          if (tasks.isEmpty)
            const Text(
              'Kanban limpo. Cadastre atividades quando precisar visualizar o fluxo.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            ...tasks.take(3).map(
                  (task) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      task.payload['status'] == 'doing'
                          ? Icons.timelapse
                          : Icons.pending_actions_outlined,
                      color: task.payload['status'] == 'doing'
                          ? AppColors.cyan
                          : AppColors.orange,
                    ),
                    title: Text(
                      task.payload['title'] as String? ?? 'Atividade',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      task.payload['status'] == 'doing'
                          ? 'Fazendo agora'
                          : 'Pendente',
                    ),
                  ),
                ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 760
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: goalsCard),
                const SizedBox(width: 14),
                Expanded(child: tasksCard),
              ],
            )
          : Column(
              children: <Widget>[
                goalsCard,
                const SizedBox(height: 12),
                tasksCard,
              ],
            ),
    );
  }
}

class _OverviewHeader extends StatelessWidget {
  const _OverviewHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
        ),
        TextButton(onPressed: onTap, child: const Text('Abrir')),
      ],
    );
  }
}

class _AcademicHero extends StatelessWidget {
  const _AcademicHero({
    required this.now,
    required this.semester,
    required this.displayName,
  });

  final DateTime now;
  final String? semester;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primaryLight, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .28),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -28,
            top: -52,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .08),
                  width: 32,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                DateFormat('EEEE, dd MMMM', 'pt_BR').format(now).toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .78),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.7,
                ),
              ),
              const SizedBox(height: 11),
              Text(
                _greeting(now, displayName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                semester == null
                    ? 'Organize cada etapa da sua graduação em Sistemas de Informação.'
                    : '$semester • Sistemas de Informação',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .82),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleViewer extends StatelessWidget {
  const _ScheduleViewer({
    required this.store,
    required this.weekday,
    required this.sessions,
  });

  final AppStore store;
  final int weekday;
  final List<SyncEntity> sessions;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      borderColor: sessions.isEmpty
          ? AppColors.border
          : AppColors.primary.withValues(alpha: .5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AcademicData.weekdayLong[weekday] ?? '',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          if (sessions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Nenhuma aula cadastrada para este dia.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          else
            ...sessions.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 92,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${item.payload['start']}\n${item.payload['end']}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                title: Text(
                  AcademicData.subjectName(
                    store,
                    item.payload['subjectId'] as String?,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  (item.payload['room'] as String? ?? '').isEmpty
                      ? 'Sala não informada'
                      : item.payload['room'] as String,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SemesterViewer extends StatelessWidget {
  const _SemesterViewer({required this.store, required this.semester});

  final AppStore store;
  final SyncEntity semester;

  @override
  Widget build(BuildContext context) {
    final subjects = AcademicData.subjectsForSemester(store, semester.id);
    final current = semester.payload['status'] == 'current';
    return PremiumCard(
      borderColor:
          current ? AppColors.primary.withValues(alpha: .65) : AppColors.border,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  semester.payload['name'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              AcademicBadge(
                label: current
                    ? 'Em andamento'
                    : semester.payload['status'] == 'planned'
                        ? 'Planejado'
                        : 'Concluído',
                color: current ? AppColors.primary : AppColors.green,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'SEMESTRE → CADEIRAS → CONTEÚDOS',
            style: TextStyle(
              color: current ? AppColors.primaryLight : AppColors.textMuted,
              fontSize: 10,
              letterSpacing: 1.25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (subjects.isEmpty)
            const Text(
              'Nenhuma matéria neste semestre.',
              style: TextStyle(color: AppColors.textMuted),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final count = width >= 900
                    ? 3
                    : width >= 560
                        ? 2
                        : 1;
                final itemWidth = (width - ((count - 1) * 10)) / count;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: subjects
                      .map(
                        (subject) => SizedBox(
                          width: itemWidth,
                          height: count == 1 ? 104 : 118,
                          child: _SubjectViewerCard(
                            store: store,
                            subject: subject,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _UnassignedSubjectsViewer extends StatelessWidget {
  const _UnassignedSubjectsViewer({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final subjects = AcademicData.subjectsForSemester(store, null);
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Matérias ainda sem semestre',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ...subjects.map(
            (subject) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.menu_book, color: AppColors.orange),
              title: Text(subject.payload['name'] as String? ?? ''),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AcademicSubjectDetailScreen(
                    store: store,
                    subjectId: subject.id,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectViewerCard extends StatelessWidget {
  const _SubjectViewerCard({required this.store, required this.subject});

  final AppStore store;
  final SyncEntity subject;

  @override
  Widget build(BuildContext context) {
    final contents = AcademicData.contentsForSubject(store, subject.id);
    final summaries = store
        .records(EntityTypes.studyNote)
        .where((item) => item.payload['subjectId'] == subject.id)
        .length;
    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              AcademicSubjectDetailScreen(store: store, subjectId: subject.id),
        ),
      ),
      child: Ink(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised.withValues(alpha: .82),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.code_rounded, color: AppColors.primary),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.textMuted,
                  size: 19,
                ),
              ],
            ),
            const Spacer(),
            Text(
              subject.payload['name'] as String? ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              '${contents.length} conteúdos • $summaries resumos',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class AcademicSubjectDetailScreen extends StatelessWidget {
  const AcademicSubjectDetailScreen({
    required this.store,
    required this.subjectId,
    super.key,
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
            body: Center(child: Text('Matéria não encontrada.')),
          );
        }
        final contents = AcademicData.contentsForSubject(store, subjectId);
        final summaries = store
            .records(EntityTypes.studyNote)
            .where((item) => item.payload['subjectId'] == subjectId)
            .toList();
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: Text(subject.payload['name'] as String? ?? 'Cadeira'),
              bottom: const TabBar(
                isScrollable: true,
                tabs: <Widget>[
                  Tab(
                      icon: Icon(Icons.account_tree_outlined),
                      text: 'Conteúdos'),
                  Tab(icon: Icon(Icons.style_outlined), text: 'Flashcards'),
                  Tab(
                      icon: Icon(Icons.event_available_outlined),
                      text: 'Provas e notas'),
                  Tab(icon: Icon(Icons.quiz_outlined), text: 'Simulados'),
                ],
              ),
            ),
            body: TabBarView(
              children: <Widget>[
                PremiumBackground(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    children: <Widget>[
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 980),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: <Color>[
                                      AppColors.primaryLight,
                                      AppColors.primaryDark,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      AcademicData.semesterName(
                                        store,
                                        subject.payload['semesterId']
                                            as String?,
                                      ).toUpperCase(),
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: .72),
                                        letterSpacing: 1.5,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 9),
                                    Text(
                                      subject.payload['name'] as String? ?? '',
                                      style: const TextStyle(
                                        fontSize: 29,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: <Widget>[
                                        if ((subject.payload['code']
                                                    as String? ??
                                                '')
                                            .isNotEmpty)
                                          AcademicBadge(
                                            label: subject.payload['code']
                                                as String,
                                            color: Colors.white,
                                          ),
                                        if ((subject.payload['professor']
                                                    as String? ??
                                                '')
                                            .isNotEmpty)
                                          AcademicBadge(
                                            label: subject.payload['professor']
                                                as String,
                                            color: Colors.white,
                                            icon: Icons.person_outline,
                                          ),
                                        if ((subject.payload['room']
                                                    as String? ??
                                                '')
                                            .isNotEmpty)
                                          AcademicBadge(
                                            label: subject.payload['room']
                                                as String,
                                            color: Colors.white,
                                            icon: Icons.location_on_outlined,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              const AcademicSectionTitle(
                                title: 'Conteúdos da cadeira',
                                subtitle:
                                    'Cada conteúdo reúne seus próprios resumos e mantém a sequência da disciplina.',
                              ),
                              const SizedBox(height: 11),
                              if (contents.isEmpty)
                                const EmptyState(
                                  icon: Icons.account_tree_outlined,
                                  title: 'Nenhum conteúdo cadastrado',
                                  message:
                                      'Use Faculdade no menu principal para criar a estrutura.',
                                )
                              else
                                ...contents.map((content) {
                                  final linked = summaries
                                      .where(
                                        (item) =>
                                            item.payload['contentId'] ==
                                            content.id,
                                      )
                                      .toList();
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 11),
                                    child: PremiumCard(
                                      child: ExpansionTile(
                                        tilePadding: EdgeInsets.zero,
                                        childrenPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(
                                          backgroundColor: AppColors.primary
                                              .withValues(alpha: .16),
                                          foregroundColor: AppColors.primary,
                                          child: Text(
                                            '${content.payload['order'] ?? '•'}',
                                          ),
                                        ),
                                        title: Text(
                                          content.payload['title'] as String? ??
                                              '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${linked.length} resumo(s)',
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                        children: <Widget>[
                                          ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: const Icon(
                                              Icons.open_in_new,
                                              color: AppColors.green,
                                            ),
                                            title: const Text(
                                              'Abrir ambiente deste conteúdo',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            subtitle: const Text(
                                              'Resumos, flashcards, provas e simulados filtrados.',
                                            ),
                                            trailing: const Icon(
                                              Icons.arrow_forward,
                                            ),
                                            onTap: () =>
                                                Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    AcademicContentDetailScreen(
                                                  store: store,
                                                  subjectId: subjectId,
                                                  contentId: content.id,
                                                ),
                                              ),
                                            ),
                                          ),
                                          ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: Icon(
                                              Icons.note_add_outlined,
                                              color: AppColors.primary,
                                            ),
                                            title: const Text(
                                              'Novo resumo neste conteúdo',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            trailing: const Icon(Icons.add),
                                            onTap: () =>
                                                Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    AcademicSummaryEditorDialog(
                                                  store: store,
                                                  initialSubjectId: subjectId,
                                                  initialContentId: content.id,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if ((content.payload['description']
                                                      as String? ??
                                                  '')
                                              .isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 16,
                                                right: 16,
                                                bottom: 10,
                                              ),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  content.payload['description']
                                                      as String,
                                                  style: const TextStyle(
                                                    color: AppColors.textMuted,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (linked.isEmpty)
                                            const ListTile(
                                              title: Text(
                                                'Nenhum resumo neste conteúdo.',
                                              ),
                                            )
                                          else
                                            ...linked.map(
                                              (summary) => ListTile(
                                                leading: Icon(
                                                  Icons.description_outlined,
                                                  color: AppColors.blue,
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
                StudyFlashcardsPage(
                  store: store,
                  initialSubjectId: subjectId,
                ),
                AcademicAssessmentsScreen(
                  store: store,
                  initialSubjectId: subjectId,
                ),
                AcademicSimulationsScreen(
                  store: store,
                  initialSubjectId: subjectId,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AcademicContentDetailScreen extends StatelessWidget {
  const AcademicContentDetailScreen({
    required this.store,
    required this.subjectId,
    required this.contentId,
    super.key,
  });

  final AppStore store;
  final String subjectId;
  final String contentId;

  @override
  Widget build(BuildContext context) {
    final subject = store.byId(subjectId);
    final content = store.byId(contentId);
    if (subject == null || content == null) {
      return const Scaffold(
        body: Center(child: Text('Conteúdo não encontrado.')),
      );
    }
    final subjectName = subject.payload['name'] as String? ?? 'Cadeira';
    final contentName = content.payload['title'] as String? ?? 'Conteúdo';
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(contentName, overflow: TextOverflow.ellipsis),
              Text(
                subjectName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: <Widget>[
              Tab(icon: Icon(Icons.description_outlined), text: 'Resumos'),
              Tab(icon: Icon(Icons.style_outlined), text: 'Flashcards'),
              Tab(
                icon: Icon(Icons.event_available_outlined),
                text: 'Provas e notas',
              ),
              Tab(icon: Icon(Icons.quiz_outlined), text: 'Simulados'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            AcademicSummariesScreen(
              store: store,
              initialSubjectId: subjectId,
              initialContentId: contentId,
            ),
            StudyFlashcardsPage(
              store: store,
              initialSubjectId: subjectId,
              initialContentId: contentId,
            ),
            AcademicAssessmentsScreen(
              store: store,
              initialSubjectId: subjectId,
              initialContentId: contentId,
            ),
            AcademicSimulationsScreen(
              store: store,
              initialSubjectId: subjectId,
              initialContentId: contentId,
            ),
          ],
        ),
      ),
    );
  }
}

String _greeting(DateTime now, String? displayName) {
  final clean = displayName?.trim() ?? '';
  final firstName =
      clean.isEmpty ? '' : ', ${clean.split(RegExp(r'\s+')).first}';
  if (now.hour < 12) return 'Bom dia$firstName.';
  if (now.hour < 18) return 'Boa tarde$firstName.';
  return 'Boa noite$firstName.';
}
