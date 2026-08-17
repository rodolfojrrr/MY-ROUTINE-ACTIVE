import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_store.dart';
import '../core/app_theme.dart';
import '../core/study_utils.dart';
import '../core/sync_entity.dart';
import '../widgets/premium_widgets.dart';

class StudyTodayTab extends StatelessWidget {
  const StudyTodayTab({required this.store, super.key});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekday = now.weekday;
    final classes = store
        .records(EntityTypes.classSession)
        .where((item) => item.payload['weekday'] == weekday)
        .toList()
      ..sort((a, b) => (a.payload['start'] as String? ?? '')
          .compareTo(b.payload['start'] as String? ?? ''));
    final dueCards = store
        .records(EntityTypes.flashcard)
        .where((item) => StudyUtils.isDue(item.payload, now: now))
        .toList();
    final upcomingExams = store.records(EntityTypes.exam).where((item) {
      final date = DateTime.tryParse(item.payload['date'] as String? ?? '');
      if (date == null) return false;
      final start = DateTime(now.year, now.month, now.day);
      return !date.isBefore(start) && date.difference(start).inDays <= 14;
    }).toList()
      ..sort((a, b) => (a.payload['date'] as String? ?? '')
          .compareTo(b.payload['date'] as String? ?? ''));
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    final minutesToday = store.records(EntityTypes.studySession).fold<int>(0, (sum, item) {
      final date = item.payload['date'] as String? ?? '';
      return sum + (date.startsWith(todayKey) ? (item.payload['minutes'] as num? ?? 0).toInt() : 0);
    });
    final goals = store.records(EntityTypes.studyGoal);
    final dailyGoal = goals.isEmpty ? 60 : (goals.first.payload['dailyMinutes'] as num? ?? 60).toInt();

    return _StudyBody(
      children: <Widget>[
        const PageIntro(
          eyebrow: 'Hoje',
          title: 'Seu plano de estudos do dia',
          subtitle: 'Aulas, revisões, avaliações próximas e tempo de foco em uma única tela.',
          color: AppColors.purple,
        ),
        const SizedBox(height: 20),
        ResponsiveGrid(
          minItemWidth: 220,
          children: <Widget>[
            MetricCard(
              label: 'Foco hoje',
              value: '$minutesToday min',
              caption: 'Meta: $dailyGoal min',
              icon: Icons.timer_outlined,
              color: AppColors.purple,
            ),
            MetricCard(
              label: 'Flashcards vencidos',
              value: '${dueCards.length}',
              icon: Icons.style_outlined,
              color: AppColors.orange,
            ),
            MetricCard(
              label: 'Avaliações em 14 dias',
              value: '${upcomingExams.length}',
              icon: Icons.event_available_outlined,
              color: AppColors.green,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (dueCards.isNotEmpty)
          PremiumCard(
            borderColor: AppColors.purple,
            child: Row(
              children: <Widget>[
                const Icon(Icons.psychology_alt_outlined, color: AppColors.purple, size: 34),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${dueCards.length} flashcards para revisar',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const Text(
                        'As revisões usam intervalos automáticos conforme suas respostas.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FlashcardReviewScreen(store: store),
                    ),
                  ),
                  child: const Text('Revisar'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Aulas de hoje', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              if (classes.isEmpty)
                const Text('Nenhuma aula cadastrada para hoje.', style: TextStyle(color: AppColors.textMuted))
              else
                ...classes.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule, color: AppColors.purple),
                    title: Text(_subjectName(store, item.payload['subjectId'] as String?)),
                    subtitle: Text('${item.payload['start']} – ${item.payload['end']}'),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Próximas avaliações', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              if (upcomingExams.isEmpty)
                const Text('Nenhuma prova ou trabalho nos próximos 14 dias.', style: TextStyle(color: AppColors.textMuted))
              else
                ...upcomingExams.take(6).map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.assignment_outlined, color: AppColors.orange),
                    title: Text(item.payload['title'] as String? ?? ''),
                    subtitle: Text(
                      '${_subjectName(store, item.payload['subjectId'] as String?)} • ${_formatDate(item.payload['date'] as String?)}',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class FlashcardReviewScreen extends StatefulWidget {
  const FlashcardReviewScreen({required this.store, super.key});

  final AppStore store;

  @override
  State<FlashcardReviewScreen> createState() => _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends State<FlashcardReviewScreen> {
  int index = 0;
  bool revealed = false;
  int reviewed = 0;

  List<SyncEntity> get due => widget.store
      .records(EntityTypes.flashcard)
      .where((item) => StudyUtils.isDue(item.payload))
      .toList();

  Future<void> _rate(String rating) async {
    final cards = due;
    if (cards.isEmpty) return;
    final card = cards[index.clamp(0, cards.length - 1).toInt()];
    final currentInterval = (card.payload['intervalDays'] as num? ?? 0).toInt();
    final currentStreak = (card.payload['streak'] as num? ?? 0).toInt();
    final result = StudyUtils.nextReview(
      rating: rating,
      currentIntervalDays: currentInterval,
      currentStreak: currentStreak,
    );
    final correct = rating != 'again';
    await widget.store.save(
      EntityTypes.flashcard,
      <String, dynamic>{
        ...card.payload,
        'lastReviewAt': DateTime.now().toIso8601String(),
        'nextReviewAt': result.nextReview.toIso8601String(),
        'intervalDays': result.intervalDays,
        'streak': result.streak,
        'correctCount': (card.payload['correctCount'] as num? ?? 0).toInt() + (correct ? 1 : 0),
        'wrongCount': (card.payload['wrongCount'] as num? ?? 0).toInt() + (correct ? 0 : 1),
      },
      id: card.id,
    );
    if (!mounted) return;
    setState(() {
      reviewed++;
      index = 0;
      revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cards = due;
    return Scaffold(
      appBar: AppBar(title: const Text('Revisão de flashcards')),
      body: PremiumBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: cards.isEmpty
                  ? EmptyState(
                      icon: Icons.check_circle_outline,
                      title: 'Revisão em dia',
                      message: reviewed == 0
                          ? 'Nenhum flashcard está vencido agora.'
                          : '$reviewed cartões revisados nesta sessão.',
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          '${cards.length} pendente(s) • $reviewed revisado(s)',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 14),
                        PremiumCard(
                          borderColor: AppColors.purple,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: <Widget>[
                                Text(
                                  cards.first.payload['front'] as String? ?? '',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 22),
                                if (revealed)
                                  Text(
                                    cards.first.payload['back'] as String? ?? '',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 18, height: 1.5),
                                  )
                                else
                                  FilledButton.tonal(
                                    onPressed: () => setState(() => revealed = true),
                                    child: const Text('Mostrar resposta'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (revealed) ...<Widget>[
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 10,
                            runSpacing: 10,
                            children: <Widget>[
                              OutlinedButton(onPressed: () => _rate('again'), child: const Text('Errei')),
                              OutlinedButton(onPressed: () => _rate('hard'), child: const Text('Difícil')),
                              FilledButton.tonal(onPressed: () => _rate('good'), child: const Text('Acertei')),
                              ElevatedButton(onPressed: () => _rate('easy'), child: const Text('Muito fácil')),
                            ],
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class QuestionBankTab extends StatelessWidget {
  const QuestionBankTab({required this.store, super.key});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final questions = store.records(EntityTypes.studyQuestion);
    final attempts = questions.fold<int>(0, (sum, item) => sum + (item.payload['attempts'] as num? ?? 0).toInt());
    final correct = questions.fold<int>(0, (sum, item) => sum + (item.payload['correct'] as num? ?? 0).toInt());
    final subjectStats = <String?, ({int attempts, int correct})>{};
    for (final item in questions) {
      final subjectId = item.payload['subjectId'] as String?;
      final previous = subjectStats[subjectId] ?? (attempts: 0, correct: 0);
      subjectStats[subjectId] = (
        attempts: previous.attempts + (item.payload['attempts'] as num? ?? 0).toInt(),
        correct: previous.correct + (item.payload['correct'] as num? ?? 0).toInt(),
      );
    }
    final subjectEntries = subjectStats.entries.toList()
      ..sort((a, b) => b.value.attempts.compareTo(a.value.attempts));
    final mocks = store.records(EntityTypes.mockExam).take(8).toList();
    return _StudyBody(
      children: <Widget>[
        const PageIntro(
          eyebrow: 'Questões',
          title: 'Banco de questões e simulados',
          subtitle: 'Cadastre questões, pratique e acompanhe seu percentual de acertos por matéria.',
          color: AppColors.purple,
        ),
        const SizedBox(height: 20),
        ResponsiveGrid(
          minItemWidth: 220,
          children: <Widget>[
            MetricCard(
              label: 'Questões',
              value: '${questions.length}',
              icon: Icons.quiz_outlined,
              color: AppColors.purple,
            ),
            MetricCard(
              label: 'Tentativas',
              value: '$attempts',
              icon: Icons.fact_check_outlined,
              color: AppColors.blue,
            ),
            MetricCard(
              label: 'Aproveitamento',
              value: attempts == 0 ? '—' : '${(correct * 100 / attempts).round()}%',
              icon: Icons.insights,
              color: AppColors.green,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ElevatedButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => _QuestionDialog(store: store),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Nova questão'),
            ),
            FilledButton.tonalIcon(
              onPressed: questions.isEmpty
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => QuickMockScreen(store: store),
                        ),
                      ),
              icon: const Icon(Icons.timer_outlined),
              label: const Text('Simulado rápido'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (subjectEntries.isNotEmpty) ...<Widget>[
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Desempenho por matéria',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                ...subjectEntries.map((entry) {
                  final value = entry.value;
                  final percent = value.attempts == 0
                      ? null
                      : (value.correct * 100 / value.attempts).round();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.insights, color: AppColors.purple),
                    title: Text(_subjectName(store, entry.key)),
                    subtitle: Text('${value.correct}/${value.attempts} acertos'),
                    trailing: Text(
                      percent == null ? '—' : '$percent%',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (mocks.isNotEmpty) ...<Widget>[
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Histórico de simulados',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                ...mocks.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.fact_check_outlined, color: AppColors.green),
                    title: Text(
                      '${(item.payload['scorePercent'] as num? ?? 0).round()}% de aproveitamento',
                    ),
                    subtitle: Text(
                      '${item.payload['correct'] ?? 0}/${item.payload['questionCount'] ?? 0} acertos • ${_formatDateTime(item.payload['date'] as String?)}',
                    ),
                    trailing: ConfirmDeleteButton(onDelete: () => store.remove(item.id)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (questions.isEmpty)
          const EmptyState(
            icon: Icons.quiz_outlined,
            title: 'Seu banco de questões está vazio',
            message: 'Cadastre perguntas objetivas para praticar por matéria.',
          )
        else
          ...questions.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PremiumCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.quiz_outlined, color: AppColors.purple),
                  title: Text(item.payload['question'] as String? ?? ''),
                  subtitle: Text(
                    '${_subjectName(store, item.payload['subjectId'] as String?)} • '
                    '${item.payload['correct'] ?? 0}/${item.payload['attempts'] ?? 0} acertos',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => _QuestionDialog(store: store, entity: item),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      ConfirmDeleteButton(onDelete: () => store.remove(item.id)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class StudyFocusTab extends StatefulWidget {
  const StudyFocusTab({required this.store, super.key});

  final AppStore store;

  @override
  State<StudyFocusTab> createState() => _StudyFocusTabState();
}

class _StudyFocusTabState extends State<StudyFocusTab> {
  Timer? timer;
  int selectedMinutes = 25;
  int remainingSeconds = 25 * 60;
  int initialSeconds = 25 * 60;
  bool running = false;
  String? subjectId;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _setMinutes(int value) {
    if (running) return;
    setState(() {
      selectedMinutes = value;
      initialSeconds = value * 60;
      remainingSeconds = initialSeconds;
    });
  }

  void _startPause() {
    if (running) {
      timer?.cancel();
      setState(() => running = false);
      return;
    }
    setState(() => running = true);
    timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      if (remainingSeconds <= 1) {
        timer?.cancel();
        setState(() {
          remainingSeconds = 0;
          running = false;
        });
        await _saveSession(selectedMinutes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sessão de foco concluída.')),
          );
        }
        return;
      }
      setState(() => remainingSeconds--);
    });
  }

  Future<void> _finishNow() async {
    timer?.cancel();
    final elapsed = initialSeconds - remainingSeconds;
    final minutes = (elapsed / 60).ceil();
    if (minutes > 0) await _saveSession(minutes);
    if (!mounted) return;
    setState(() {
      running = false;
      remainingSeconds = initialSeconds;
    });
  }

  Future<void> _saveSession(int minutes) => widget.store.save(
        EntityTypes.studySession,
        <String, dynamic>{
          'subjectId': subjectId,
          'minutes': minutes,
          'date': DateTime.now().toIso8601String(),
          'mode': 'Foco',
        },
      );

  Future<void> _configureGoal(BuildContext context) async {
    final existing = widget.store.records(EntityTypes.studyGoal);
    final controller = TextEditingController(
      text: (existing.isEmpty ? 60 : existing.first.payload['dailyMinutes'] ?? 60).toString(),
    );
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Meta diária de estudos'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Minutos por dia'),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, int.tryParse(controller.text) ?? 60),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) {
      await widget.store.save(
        EntityTypes.studyGoal,
        <String, dynamic>{'dailyMinutes': value.clamp(1, 1440)},
        id: existing.isEmpty ? null : existing.first.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = widget.store.records(EntityTypes.subject);
    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    final sessions = widget.store.records(EntityTypes.studySession);
    final todayMinutes = sessions.fold<int>(0, (sum, item) {
      final date = item.payload['date'] as String? ?? '';
      return sum + (date.startsWith(todayKey) ? (item.payload['minutes'] as num? ?? 0).toInt() : 0);
    });
    final goals = widget.store.records(EntityTypes.studyGoal);
    final goal = goals.isEmpty ? 60 : (goals.first.payload['dailyMinutes'] as num? ?? 60).toInt();
    final minutesBySubject = <String?, int>{};
    for (final session in sessions) {
      final id = session.payload['subjectId'] as String?;
      minutesBySubject[id] = (minutesBySubject[id] ?? 0) +
          (session.payload['minutes'] as num? ?? 0).toInt();
    }
    final subjectMinutes = minutesBySubject.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;

    return _StudyBody(
      children: <Widget>[
        const PageIntro(
          eyebrow: 'Foco',
          title: 'Pomodoro e tempo estudado',
          subtitle: 'Use o cronômetro para registrar seu tempo real por matéria e bater sua meta diária.',
          color: AppColors.purple,
        ),
        const SizedBox(height: 20),
        ResponsiveGrid(
          minItemWidth: 230,
          children: <Widget>[
            MetricCard(
              label: 'Estudado hoje',
              value: '$todayMinutes min',
              caption: 'Meta: $goal min',
              icon: Icons.timer_outlined,
              color: AppColors.purple,
            ),
            MetricCard(
              label: 'Sessões registradas',
              value: '${sessions.length}',
              icon: Icons.history,
              color: AppColors.green,
            ),
          ],
        ),
        const SizedBox(height: 16),
        PremiumCard(
          borderColor: AppColors.purple,
          child: Column(
            children: <Widget>[
              DropdownButtonFormField<String?>(
                initialValue: subjectId,
                decoration: const InputDecoration(labelText: 'Matéria desta sessão'),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(value: null, child: Text('Estudo geral')),
                  ...subjects.map(
                    (item) => DropdownMenuItem<String?>(
                      value: item.id,
                      child: Text(item.payload['name'] as String? ?? ''),
                    ),
                  ),
                ],
                onChanged: running ? null : (value) => setState(() => subjectId = value),
              ),
              const SizedBox(height: 20),
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 58,
                  fontWeight: FontWeight.w900,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 14),
              SegmentedButton<int>(
                segments: const <ButtonSegment<int>>[
                  ButtonSegment(value: 15, label: Text('15 min')),
                  ButtonSegment(value: 25, label: Text('25 min')),
                  ButtonSegment(value: 50, label: Text('50 min')),
                ],
                selected: <int>{selectedMinutes},
                onSelectionChanged: running ? null : (value) => _setMinutes(value.first),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  ElevatedButton.icon(
                    onPressed: _startPause,
                    icon: Icon(running ? Icons.pause : Icons.play_arrow),
                    label: Text(running ? 'Pausar' : 'Iniciar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: remainingSeconds == initialSeconds ? null : _finishNow,
                    icon: const Icon(Icons.check),
                    label: const Text('Concluir agora'),
                  ),
                  TextButton.icon(
                    onPressed: () => _configureGoal(context),
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Alterar meta'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (subjectMinutes.isNotEmpty) ...<Widget>[
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Tempo acumulado por matéria',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                ...subjectMinutes.take(10).map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.menu_book_outlined, color: AppColors.purple),
                    title: Text(_subjectName(widget.store, entry.key)),
                    trailing: Text(
                      '${entry.value} min',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Últimas sessões', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              if (sessions.isEmpty)
                const Text('Nenhuma sessão de foco concluída.', style: TextStyle(color: AppColors.textMuted))
              else
                ...sessions.take(10).map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.timer_outlined, color: AppColors.purple),
                    title: Text('${item.payload['minutes'] ?? 0} min • ${_subjectName(widget.store, item.payload['subjectId'] as String?)}'),
                    subtitle: Text(_formatDateTime(item.payload['date'] as String?)),
                    trailing: ConfirmDeleteButton(onDelete: () => widget.store.remove(item.id)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class QuickMockScreen extends StatefulWidget {
  const QuickMockScreen({required this.store, super.key});

  final AppStore store;

  @override
  State<QuickMockScreen> createState() => _QuickMockScreenState();
}

class _QuickMockScreenState extends State<QuickMockScreen> {
  late final List<SyncEntity> questions;
  final Map<String, int> answers = <String, int>{};
  bool finished = false;
  int score = 0;

  @override
  void initState() {
    super.initState();
    final all = widget.store.records(EntityTypes.studyQuestion).toList();
    all.shuffle(Random());
    questions = all.take(10).toList();
  }

  Future<void> _finish() async {
    var correctCount = 0;
    for (final question in questions) {
      final selected = answers[question.id];
      final expected = (question.payload['correctIndex'] as num? ?? 0).toInt();
      final isCorrect = selected == expected;
      if (isCorrect) correctCount++;
      await widget.store.save(
        EntityTypes.studyQuestion,
        <String, dynamic>{
          ...question.payload,
          'attempts': (question.payload['attempts'] as num? ?? 0).toInt() + 1,
          'correct': (question.payload['correct'] as num? ?? 0).toInt() + (isCorrect ? 1 : 0),
        },
        id: question.id,
      );
    }
    await widget.store.save(EntityTypes.mockExam, <String, dynamic>{
      'date': DateTime.now().toIso8601String(),
      'questionCount': questions.length,
      'correct': correctCount,
      'scorePercent': questions.isEmpty ? 0 : correctCount * 100 / questions.length,
    });
    if (!mounted) return;
    setState(() {
      finished = true;
      score = correctCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulado rápido')),
      body: PremiumBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: finished
                    ? EmptyState(
                        icon: Icons.fact_check_outlined,
                        title: 'Resultado: $score/${questions.length}',
                        message: questions.isEmpty
                            ? 'Cadastre questões para criar um simulado.'
                            : 'Aproveitamento de ${(score * 100 / questions.length).round()}%. O desempenho foi salvo no histórico.',
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const PageIntro(
                            eyebrow: 'Simulado',
                            title: 'Resolva sem consultar',
                            subtitle: 'As respostas são corrigidas ao finalizar.',
                            color: AppColors.purple,
                          ),
                          const SizedBox(height: 18),
                          ...questions.asMap().entries.map((entry) {
                            final question = entry.value;
                            final options = (question.payload['options'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: PremiumCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      '${entry.key + 1}. ${question.payload['question'] ?? ''}',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                                    ),
                                    const SizedBox(height: 8),
                                    ...List<Widget>.generate(options.length, (index) {
                                      final selected = answers[question.id] == index;
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        onTap: () => setState(() => answers[question.id] = index),
                                        leading: Icon(
                                          selected ? Icons.radio_button_checked : Icons.radio_button_off,
                                          color: selected ? AppColors.purple : AppColors.textMuted,
                                        ),
                                        title: Text(options[index]),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            );
                          }),
                          ElevatedButton.icon(
                            onPressed: questions.isEmpty ? null : _finish,
                            icon: const Icon(Icons.check),
                            label: const Text('Finalizar simulado'),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionDialog extends StatefulWidget {
  const _QuestionDialog({required this.store, this.entity});

  final AppStore store;
  final SyncEntity? entity;

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  late final TextEditingController question;
  late final List<TextEditingController> options;
  String? subjectId;
  int correctIndex = 0;

  @override
  void initState() {
    super.initState();
    question = TextEditingController(text: widget.entity?.payload['question'] as String? ?? '');
    final existing = (widget.entity?.payload['options'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    options = List<TextEditingController>.generate(
      4,
      (index) => TextEditingController(text: index < existing.length ? existing[index] : ''),
    );
    correctIndex = (widget.entity?.payload['correctIndex'] as num? ?? 0).toInt().clamp(0, 3).toInt();
    final subjects = widget.store.records(EntityTypes.subject);
    final existingSubject = widget.entity?.payload['subjectId'] as String?;
    subjectId = subjects.any((item) => item.id == existingSubject)
        ? existingSubject
        : (subjects.isEmpty ? null : subjects.first.id);
  }

  @override
  void dispose() {
    question.dispose();
    for (final item in options) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = widget.store.records(EntityTypes.subject);
    return AlertDialog(
      title: Text(widget.entity == null ? 'Nova questão' : 'Editar questão'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<String?>(
                initialValue: subjectId,
                decoration: const InputDecoration(labelText: 'Matéria'),
                items: subjects
                    .map((item) => DropdownMenuItem<String?>(value: item.id, child: Text(item.payload['name'] as String? ?? '')))
                    .toList(),
                onChanged: (value) => setState(() => subjectId = value),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: question,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Enunciado'),
              ),
              const SizedBox(height: 10),
              ...List<Widget>.generate(4, (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          tooltip: 'Marcar como resposta correta',
                          onPressed: () => setState(() => correctIndex = index),
                          icon: Icon(
                            correctIndex == index
                                ? Icons.check_circle
                                : Icons.radio_button_off,
                            color: correctIndex == index
                                ? AppColors.green
                                : AppColors.textMuted,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: options[index],
                            decoration: InputDecoration(labelText: 'Alternativa ${String.fromCharCode(65 + index)}'),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () async {
            if (question.text.trim().isEmpty || options.any((item) => item.text.trim().isEmpty)) return;
            final previous = widget.entity?.payload ?? <String, dynamic>{};
            await widget.store.save(EntityTypes.studyQuestion, <String, dynamic>{
              ...previous,
              'subjectId': subjectId,
              'question': question.text.trim(),
              'options': options.map((item) => item.text.trim()).toList(),
              'correctIndex': correctIndex,
              'attempts': previous['attempts'] ?? 0,
              'correct': previous['correct'] ?? 0,
            }, id: widget.entity?.id);
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _StudyBody extends StatelessWidget {
  const _StudyBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ),
    );
  }
}

String _subjectName(AppStore store, String? id) {
  if (id == null) return 'Geral';
  return store.byId(id)?.payload['name'] as String? ?? 'Matéria removida';
}

String _formatDate(String? value) {
  final date = DateTime.tryParse(value ?? '');
  return date == null ? 'Sem data' : DateFormat('dd/MM/yyyy').format(date);
}

String _formatDateTime(String? value) {
  final date = DateTime.tryParse(value ?? '');
  return date == null ? 'Sem data' : DateFormat('dd/MM/yyyy HH:mm').format(date);
}
