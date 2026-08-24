import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/academic_data.dart';
import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/sync_entity.dart';
import '../widgets/premium_widgets.dart';
import 'academic_shared.dart';
import 'academic_summaries_screen.dart';

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
    final currentItems = semesters
        .where((item) => item.payload['status'] == 'current')
        .toList();
    final currentSemester = currentItems.isEmpty ? null : currentItems.first;
    final allSubjects = widget.store.records(EntityTypes.subject);
    final currentSubjects = currentSemester == null
        ? allSubjects
        : AcademicData.subjectsForSemester(widget.store, currentSemester.id);
    final classes =
        widget.store
            .records(EntityTypes.classSession)
            .where((item) => item.payload['weekday'] == selectedWeekday)
            .toList()
          ..sort(
            (a, b) => (a.payload['start'] as String? ?? '').compareTo(
              b.payload['start'] as String? ?? '',
            ),
          );
    final upcoming =
        widget.store.records(EntityTypes.exam).where((item) {
          if (item.payload['completed'] == true) return false;
          final date = DateTime.tryParse(item.payload['date'] as String? ?? '');
          if (date == null) return false;
          final today = DateTime(now.year, now.month, now.day);
          return !date.isBefore(today) && date.difference(today).inDays <= 30;
        }).toList()..sort(
          (a, b) => (a.payload['date'] as String? ?? '').compareTo(
            b.payload['date'] as String? ?? '',
          ),
        );

    return AcademicPageBody(
      children: <Widget>[
        _AcademicHero(
          now: now,
          semester: currentSemester?.payload['name'] as String?,
        ),
        const SizedBox(height: 18),
        ResponsiveGrid(
          minItemWidth: 220,
          children: <Widget>[
            MetricCard(
              label: 'Matérias no semestre',
              value: '${currentSubjects.length}',
              icon: Icons.menu_book_outlined,
              color: AppColors.purple,
            ),
            MetricCard(
              label: 'Resumos salvos',
              value: '${widget.store.records(EntityTypes.studyNote).length}',
              icon: Icons.summarize_outlined,
              color: AppColors.blue,
            ),
            MetricCard(
              label: 'Próximas avaliações',
              value: '${upcoming.length}',
              caption: 'Nos próximos 30 dias',
              icon: Icons.event_available_outlined,
              color: AppColors.orange,
            ),
            MetricCard(
              label: 'Questões cadastradas',
              value:
                  '${widget.store.records(EntityTypes.studyQuestion).length}',
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
        AcademicSectionTitle(
          title: 'Semestres e matérias',
          subtitle: 'Abra uma cadeira para visualizar conteúdos, resumos e avaliações.',
          trailing: TextButton(
            onPressed: () => widget.onOpenSection(6),
            child: const Text('Organizar'),
          ),
        ),
        const SizedBox(height: 12),
        if (semesters.isEmpty && allSubjects.isEmpty)
          const EmptyState(
            icon: Icons.school_outlined,
            title: 'Sua graduação começa aqui',
            message: 'Abra Organização acadêmica no menu lateral e cadastre o semestre atual, as matérias e seus conteúdos.',
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
            onPressed: () => widget.onOpenSection(3),
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
                color: AppColors.purple,
                title: 'Biblioteca de resumos',
                subtitle: 'Texto, imagens e PDF por conteúdo.',
                onTap: () => widget.onOpenSection(1),
              ),
              AcademicActionCard(
                icon: Icons.quiz_outlined,
                color: AppColors.green,
                title: 'Treinar com simulados',
                subtitle: 'Questões filtradas por matéria e conteúdo.',
                onTap: () => widget.onOpenSection(2),
              ),
            ];
            if (constraints.maxWidth >= 760) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: actions[0]),
                  const SizedBox(width: 13),
                  Expanded(child: actions[1]),
                ],
              );
            }
            return Column(
              children: <Widget>[
                actions[0],
                const SizedBox(height: 12),
                actions[1],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AcademicHero extends StatelessWidget {
  const _AcademicHero({required this.now, required this.semester});

  final DateTime now;
  final String? semester;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF8B36F4), Color(0xFF4A32D7)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.purple.withValues(alpha: .28),
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
                _greeting(now),
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
          : AppColors.purple.withValues(alpha: .5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AcademicData.weekdayLong[weekday] ?? '',
            style: const TextStyle(
              color: AppColors.purple,
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
                    color: AppColors.purple.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${item.payload['start']}\n${item.payload['end']}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.purple,
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
      borderColor: current
          ? AppColors.purple.withValues(alpha: .65)
          : AppColors.border,
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
                color: current ? AppColors.purple : AppColors.green,
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: count == 1 ? 3.4 : 2.45,
                  ),
                  itemCount: subjects.length,
                  itemBuilder: (_, index) => _SubjectViewerCard(
                    store: store,
                    subject: subjects[index],
                  ),
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
                const Icon(Icons.code_rounded, color: AppColors.purple),
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
        final exams =
            store
                .records(EntityTypes.exam)
                .where((item) => item.payload['subjectId'] == subjectId)
                .toList()
              ..sort(
                (a, b) => (a.payload['date'] as String? ?? '').compareTo(
                  b.payload['date'] as String? ?? '',
                ),
              );
        return Scaffold(
          appBar: AppBar(
            title: Text(subject.payload['name'] as String? ?? 'Matéria'),
          ),
          body: PremiumBackground(
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
                            gradient: const LinearGradient(
                              colors: <Color>[
                                Color(0xFF6D3BE8),
                                Color(0xFF28235F),
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
                                  subject.payload['semesterId'] as String?,
                                ).toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: .72),
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
                                  if ((subject.payload['code'] as String? ?? '')
                                      .isNotEmpty)
                                    AcademicBadge(
                                      label: subject.payload['code'] as String,
                                      color: Colors.white,
                                    ),
                                  if ((subject.payload['professor']
                                              as String? ??
                                          '')
                                      .isNotEmpty)
                                    AcademicBadge(
                                      label:
                                          subject.payload['professor']
                                              as String,
                                      color: Colors.white,
                                      icon: Icons.person_outline,
                                    ),
                                  if ((subject.payload['room'] as String? ?? '')
                                      .isNotEmpty)
                                    AcademicBadge(
                                      label: subject.payload['room'] as String,
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
                          title: 'Conteúdos da matéria',
                          subtitle: 'Estrutura do que foi ou será estudado nesta cadeira.',
                        ),
                        const SizedBox(height: 11),
                        if (contents.isEmpty)
                          const EmptyState(
                            icon: Icons.account_tree_outlined,
                            title: 'Nenhum conteúdo cadastrado',
                            message: 'Use Organização acadêmica no menu principal para criar a estrutura.',
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
                              padding: const EdgeInsets.only(bottom: 11),
                              child: PremiumCard(
                                child: ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  childrenPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.purple
                                        .withValues(alpha: .16),
                                    foregroundColor: AppColors.purple,
                                    child: Text(
                                      '${content.payload['order'] ?? '•'}',
                                    ),
                                  ),
                                  title: Text(
                                    content.payload['title'] as String? ?? '',
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
                                          leading: const Icon(
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
                                          onTap: () => Navigator.of(context).push(
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
                        if (exams.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 18),
                          const AcademicSectionTitle(
                            title: 'Avaliações da matéria',
                          ),
                          const SizedBox(height: 11),
                          PremiumCard(
                            child: Column(
                              children: exams.map((item) {
                                final date = DateTime.tryParse(
                                  item.payload['date'] as String? ?? '',
                                );
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    item.payload['completed'] == true
                                        ? Icons.check_circle_outline
                                        : Icons.event_outlined,
                                    color: item.payload['completed'] == true
                                        ? AppColors.green
                                        : AppColors.orange,
                                  ),
                                  title: Text(
                                    item.payload['title'] as String? ?? '',
                                  ),
                                  trailing: Text(
                                    date == null
                                        ? '—'
                                        : DateFormat('dd/MM/yyyy').format(date),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
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

String _greeting(DateTime now) {
  if (now.hour < 12) return 'Bom dia, Rodolfo.';
  if (now.hour < 18) return 'Boa tarde, Rodolfo.';
  return 'Boa noite, Rodolfo.';
}
