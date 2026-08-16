'use client';

/* eslint-disable @next/next/no-img-element */

import {
  ArrowLeft,
  BarChart3,
  Bell,
  BookOpen,
  Brain,
  CalendarDays,
  CalendarRange,
  Check,
  CheckCircle2,
  ChevronLeft,
  ChevronRight,
  CircleHelp,
  Clock3,
  Edit3,
  Flame,
  GraduationCap,
  Layers3,
  LayoutDashboard,
  ListChecks,
  NotebookPen,
  Pause,
  Play,
  Plus,
  RotateCcw,
  Search,
  Sparkles,
  Star,
  Target,
  TimerReset,
  Trash2,
  Trophy,
  Upload,
  X,
  XCircle,
  type LucideIcon,
} from 'lucide-react';
import {
  useEffect,
  useMemo,
  useRef,
  useState,
  type Dispatch,
  type FormEvent,
  type SetStateAction,
} from 'react';
import {
  ensureToday,
  uid,
  type AppState,
  type Assessment,
  type Flashcard,
  type StudyAttachment,
  type StudyNote,
  type StudyQuestion,
  type StudySimulation,
  type StudySubject,
} from '../lib/app-data';

type StudyTab = 'overview' | 'schedule' | 'subjects' | 'assessments' | 'notes' | 'flashcards' | 'questions' | 'simulations' | 'plan' | 'progress';
type EditorKind = 'academic' | 'subject' | 'period' | 'class' | 'assessment' | 'note' | 'deck' | 'flashcard' | 'question' | 'simulation' | 'task' | 'session';
type EditorState = { kind: EditorKind; id?: string; defaults?: Record<string, string | number> };

type StudyModuleProps = {
  state: AppState;
  setState: Dispatch<SetStateAction<AppState>>;
  openHome: () => void;
  notify: (message: string) => void;
};

const weekDays = [
  { value: 1, short: 'SEG', label: 'Segunda' },
  { value: 2, short: 'TER', label: 'Terça' },
  { value: 3, short: 'QUA', label: 'Quarta' },
  { value: 4, short: 'QUI', label: 'Quinta' },
  { value: 5, short: 'SEX', label: 'Sexta' },
  { value: 6, short: 'SÁB', label: 'Sábado' },
];

const tabs: { id: StudyTab; label: string; short: string; icon: LucideIcon }[] = [
  { id: 'overview', label: 'Visão geral', short: 'Início', icon: LayoutDashboard },
  { id: 'schedule', label: 'Horários', short: 'Horários', icon: CalendarRange },
  { id: 'subjects', label: 'Matérias', short: 'Matérias', icon: BookOpen },
  { id: 'assessments', label: 'Provas', short: 'Provas', icon: CalendarDays },
  { id: 'notes', label: 'Anotações', short: 'Notas', icon: NotebookPen },
  { id: 'flashcards', label: 'Flashcards', short: 'Cards', icon: Brain },
  { id: 'questions', label: 'Questões', short: 'Questões', icon: CircleHelp },
  { id: 'simulations', label: 'Simulados', short: 'Simulados', icon: TimerReset },
  { id: 'plan', label: 'Plano de estudo', short: 'Plano', icon: ListChecks },
  { id: 'progress', label: 'Progresso', short: 'Progresso', icon: BarChart3 },
];

const dateLabel = new Intl.DateTimeFormat('pt-BR', { day: '2-digit', month: 'short', year: 'numeric' });
const shortDateLabel = new Intl.DateTimeFormat('pt-BR', { day: '2-digit', month: 'short' });
const monthLabel = new Intl.DateTimeFormat('pt-BR', { month: 'long', year: 'numeric' });

function localDateKey(date = new Date()) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return year + '-' + month + '-' + day;
}

function addDays(date: string, amount: number) {
  const value = new Date(date + 'T12:00:00');
  value.setDate(value.getDate() + amount);
  return localDateKey(value);
}

function formatDate(value: string, compact = false) {
  if (!value) return 'Sem data';
  return (compact ? shortDateLabel : dateLabel).format(new Date(value + 'T12:00:00'));
}

function secondsLabel(seconds: number) {
  const safe = Math.max(0, seconds);
  const hours = Math.floor(safe / 3600);
  const minutes = Math.floor((safe % 3600) / 60);
  const secs = safe % 60;
  return (hours ? String(hours).padStart(2, '0') + ':' : '') + String(minutes).padStart(2, '0') + ':' + String(secs).padStart(2, '0');
}

function subjectFor(state: AppState, id: string) {
  return state.study.subjects.find(subject => subject.id === id);
}

function subjectName(state: AppState, id: string) {
  return subjectFor(state, id)?.name ?? 'Sem matéria';
}

function updateStudy(setState: Dispatch<SetStateAction<AppState>>, updater: (study: AppState['study']) => AppState['study']) {
  setState(current => ({ ...current, study: updater(current.study) }));
}

function stripMarkdown(value: string) {
  return value.replace(/[#*_>~\[\]()-]/g, ' ').replace(/\s+/g, ' ').trim();
}

function calculateStreak(dates: string[]) {
  const unique = new Set(dates);
  const cursor = new Date();
  let streak = 0;
  if (!unique.has(localDateKey(cursor))) cursor.setDate(cursor.getDate() - 1);
  while (unique.has(localDateKey(cursor))) {
    streak += 1;
    cursor.setDate(cursor.getDate() - 1);
  }
  return streak;
}

export function StudyModule({ state, setState, openHome, notify }: StudyModuleProps) {
  const [tab, setTab] = useState<StudyTab>('overview');
  const [editor, setEditor] = useState<EditorState | null>(null);
  const [selectedSubjectId, setSelectedSubjectId] = useState('');
  const [search, setSearch] = useState('');
  const [subjectFilter, setSubjectFilter] = useState('all');
  const [calendarMonth, setCalendarMonth] = useState(() => new Date(new Date().getFullYear(), new Date().getMonth(), 1));
  const [focusSubjectId, setFocusSubjectId] = useState('');
  const [focusTopic, setFocusTopic] = useState('');
  const [focusSeconds, setFocusSeconds] = useState(0);
  const [focusRunning, setFocusRunning] = useState(false);
  const [reviewIds, setReviewIds] = useState<string[]>([]);
  const [reviewIndex, setReviewIndex] = useState(0);
  const [reviewRevealed, setReviewRevealed] = useState(false);
  const [activeSimulationId, setActiveSimulationId] = useState('');
  const [simulationStartedAt, setSimulationStartedAt] = useState(0);
  const [simulationElapsed, setSimulationElapsed] = useState(0);
  const [noteContent, setNoteContent] = useState('');
  const [noteAttachments, setNoteAttachments] = useState<StudyAttachment[]>([]);
  const [uploading, setUploading] = useState(false);
  const noteTextRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    if (!focusRunning) return;
    const timer = window.setInterval(() => setFocusSeconds(value => value + 1), 1000);
    return () => window.clearInterval(timer);
  }, [focusRunning]);

  useEffect(() => {
    if (!activeSimulationId || !simulationStartedAt) return;
    const tick = () => setSimulationElapsed(Math.floor((Date.now() - simulationStartedAt) / 1000));
    tick();
    const timer = window.setInterval(tick, 1000);
    return () => window.clearInterval(timer);
  }, [activeSimulationId, simulationStartedAt]);

  const todayKey = localDateKey();
  const todayWeekday = new Date().getDay();
  const todayClasses = useMemo(
    () => state.study.schedule.filter(item => item.weekday === todayWeekday).sort((a, b) => a.startTime.localeCompare(b.startTime)),
    [state.study.schedule, todayWeekday],
  );
  const upcomingAssessments = useMemo(
    () => state.study.assessments.filter(item => item.date >= todayKey && item.status !== 'completed').sort((a, b) => a.date.localeCompare(b.date)),
    [state.study.assessments, todayKey],
  );
  const dueCards = state.study.flashcards.filter(card => card.dueDate <= todayKey);
  const answeredToday = state.study.questions.filter(question => question.answeredAt?.slice(0, 10) === todayKey);
  const weekStart = new Date();
  weekStart.setHours(0, 0, 0, 0);
  weekStart.setDate(weekStart.getDate() - ((weekStart.getDay() + 6) % 7));
  const weekMinutes = state.study.sessions
    .filter(session => new Date(session.date + 'T12:00:00') >= weekStart)
    .reduce((total, session) => total + session.durationMinutes, 0);
  const streak = calculateStreak(state.study.studyDates);
  const selectedSubject = subjectFor(state, selectedSubjectId);

  function switchTab(next: StudyTab) {
    setTab(next);
    setSelectedSubjectId('');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  function openEditor(kind: EditorKind, id?: string, defaults?: Record<string, string | number>) {
    setEditor({ kind, id, defaults });
    if (kind === 'note') {
      const note = state.study.notes.find(item => item.id === id);
      setNoteContent(note?.content ?? '');
      setNoteAttachments(note?.attachments ?? []);
    }
  }

  async function uploadImages(files: FileList | null) {
    if (!files?.length) return;
    setUploading(true);
    try {
      const uploads = await Promise.all(Array.from(files).slice(0, 6).map(async file => {
        const form = new FormData();
        form.append('file', file);
        const response = await fetch('/api/uploads', { method: 'POST', body: form });
        const result = await response.json() as { attachment?: StudyAttachment; error?: string };
        if (!response.ok || !result.attachment) throw new Error(result.error ?? 'Falha ao enviar imagem.');
        return result.attachment;
      }));
      setNoteAttachments(current => [...current, ...uploads]);
      notify(uploads.length === 1 ? 'Imagem anexada.' : 'Imagens anexadas.');
    } catch (error) {
      notify(error instanceof Error ? error.message : 'Falha ao enviar imagem.');
    } finally {
      setUploading(false);
    }
  }

  function formatNote(prefix: string, suffix = prefix) {
    const input = noteTextRef.current;
    if (!input) return;
    const start = input.selectionStart;
    const end = input.selectionEnd;
    const selected = noteContent.slice(start, end);
    const next = noteContent.slice(0, start) + prefix + selected + suffix + noteContent.slice(end);
    setNoteContent(next);
    window.requestAnimationFrame(() => {
      input.focus();
      input.setSelectionRange(start + prefix.length, end + prefix.length);
    });
  }

  function closeEditor() {
    setEditor(null);
    setNoteContent('');
    setNoteAttachments([]);
  }

  function saveEditor(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!editor) return;
    const form = new FormData(event.currentTarget);
    const text = (name: string) => String(form.get(name) ?? '').trim();
    const number = (name: string) => Number(form.get(name) ?? 0);
    const id = editor.id;
    const now = new Date().toISOString();

    updateStudy(setState, study => {
      if (editor.kind === 'academic') {
        return { ...study, academic: { course: text('course'), institution: text('institution'), semester: text('semester'), semesterStart: text('semesterStart'), semesterEnd: text('semesterEnd') } };
      }
      if (editor.kind === 'subject') {
        const next: StudySubject = {
          id: id ?? uid('subject'), name: text('name'), code: text('code'), professor: text('professor'), room: text('room'),
          color: text('color') || '#8b5cf6', description: text('description'), semester: text('semester'),
          cards: 0, questions: 0, summaries: 0, sessions: 0, archived: false,
        };
        return { ...study, subjects: id ? study.subjects.map(item => item.id === id ? { ...item, ...next, id } : item) : [...study.subjects, next] };
      }
      if (editor.kind === 'period') {
        const next = { id: id ?? uid('period'), label: text('label'), startTime: text('startTime'), endTime: text('endTime') };
        return { ...study, classPeriods: id ? study.classPeriods.map(item => item.id === id ? next : item) : [...study.classPeriods, next] };
      }
      if (editor.kind === 'class') {
        const next = {
          id: id ?? uid('class'), subjectId: text('subjectId'), weekday: number('weekday'), startTime: text('startTime'),
          endTime: text('endTime'), room: text('room'), professor: text('professor'), notes: text('notes'),
        };
        return { ...study, schedule: id ? study.schedule.map(item => item.id === id ? next : item) : [...study.schedule, next] };
      }
      if (editor.kind === 'assessment') {
        const previous = study.assessments.find(item => item.id === id);
        const next: Assessment = {
          id: id ?? uid('assessment'), subjectId: text('subjectId'), title: text('title'), kind: text('kind') as Assessment['kind'],
          date: text('date'), time: text('time'), content: text('content'), notes: text('notes'), weight: number('weight'),
          grade: text('grade') === '' ? null : number('grade'), maxGrade: number('maxGrade') || 10,
          reminderDays: number('reminderDays'), status: text('status') as Assessment['status'],
        };
        return { ...study, assessments: previous ? study.assessments.map(item => item.id === id ? next : item) : [...study.assessments, next] };
      }
      if (editor.kind === 'note') {
        const previous = study.notes.find(item => item.id === id);
        const next: StudyNote = {
          id: id ?? uid('note'), subjectId: text('subjectId'), title: text('title'), content: noteContent.trim(),
          tags: text('tags').split(',').map(tag => tag.trim()).filter(Boolean), favorite: previous?.favorite ?? false,
          attachments: noteAttachments, createdAt: previous?.createdAt ?? now, updatedAt: now,
        };
        if (previous) {
          const activeKeys = new Set(noteAttachments.map(item => item.storageKey));
          previous.attachments.filter(item => !activeKeys.has(item.storageKey)).forEach(item => {
            void fetch('/api/uploads?key=' + encodeURIComponent(item.storageKey), { method: 'DELETE' });
          });
        }
        return { ...study, notes: previous ? study.notes.map(item => item.id === id ? next : item) : [next, ...study.notes] };
      }
      if (editor.kind === 'deck') {
        const next = { id: id ?? uid('deck'), subjectId: text('subjectId'), name: text('name'), description: text('description'), color: text('color') || '#8b5cf6', createdAt: now };
        return { ...study, decks: id ? study.decks.map(item => item.id === id ? { ...item, ...next, id } : item) : [...study.decks, next] };
      }
      if (editor.kind === 'flashcard') {
        const previous = study.flashcards.find(item => item.id === id);
        const next: Flashcard = {
          id: id ?? uid('card'), subjectId: text('subjectId'), deckId: text('deckId'), topic: text('topic'), front: text('front'), back: text('back'),
          dueDate: text('dueDate') || todayKey, reviewed: previous?.reviewed ?? false, createdAt: previous?.createdAt ?? now,
          lastReviewedAt: previous?.lastReviewedAt ?? null, intervalDays: previous?.intervalDays ?? 0,
          repetitions: previous?.repetitions ?? 0, easeFactor: previous?.easeFactor ?? 2.5, lapses: previous?.lapses ?? 0,
        };
        return { ...study, flashcards: previous ? study.flashcards.map(item => item.id === id ? next : item) : [...study.flashcards, next] };
      }
      if (editor.kind === 'question') {
        const previous = study.questions.find(item => item.id === id);
        const next: StudyQuestion = {
          id: id ?? uid('question'), subjectId: text('subjectId'), topic: text('topic'), prompt: text('prompt'), answer: text('answer'),
          explanation: text('explanation'), source: text('source'), difficulty: text('difficulty') as StudyQuestion['difficulty'],
          result: previous?.result ?? 'pending', answeredAt: previous?.answeredAt ?? null, createdAt: previous?.createdAt ?? now,
        };
        return { ...study, questions: previous ? study.questions.map(item => item.id === id ? next : item) : [next, ...study.questions] };
      }
      if (editor.kind === 'simulation') {
        const previous = study.simulations.find(item => item.id === id);
        const selectedSubjects = form.getAll('subjectIds').map(String);
        const next: StudySimulation = {
          id: id ?? uid('simulation'), title: text('title'), subjectIds: selectedSubjects, questionCount: number('questionCount'),
          durationMinutes: number('durationMinutes'), correctAnswers: previous?.correctAnswers ?? null,
          completedAt: previous?.completedAt ?? null, elapsedSeconds: previous?.elapsedSeconds ?? 0, createdAt: previous?.createdAt ?? now,
        };
        return { ...study, simulations: previous ? study.simulations.map(item => item.id === id ? next : item) : [next, ...study.simulations] };
      }
      if (editor.kind === 'task') {
        const next = {
          id: id ?? uid('task'), subjectId: text('subjectId'), title: text('title'), date: text('date'), startTime: text('startTime'),
          endTime: text('endTime'), priority: text('priority') as 'Baixa' | 'Média' | 'Alta',
          completed: study.tasks.find(item => item.id === id)?.completed ?? false,
        };
        return { ...study, tasks: id ? study.tasks.map(item => item.id === id ? next : item) : [...study.tasks, next] };
      }
      if (editor.kind === 'session') {
        const duration = Math.max(1, number('durationMinutes'));
        const subjectId = text('subjectId');
        const next = { id: id ?? uid('session'), subjectId, date: text('date'), durationMinutes: duration, topic: text('topic'), notes: text('notes') };
        return {
          ...study,
          sessions: id ? study.sessions.map(item => item.id === id ? next : item) : [next, ...study.sessions],
          studyDates: ensureToday(study.studyDates),
          subjects: id ? study.subjects : study.subjects.map(item => item.id === subjectId ? { ...item, sessions: item.sessions + 1 } : item),
        };
      }
      return study;
    });
    closeEditor();
    notify('Informação salva e sincronizada.');
  }

  function removeSubject(subject: StudySubject) {
    if (!window.confirm('Excluir ' + subject.name + ' e todos os dados ligados a ela?')) return;
    updateStudy(setState, study => {
      const removedNotes = study.notes.filter(note => note.subjectId === subject.id);
      removedNotes.flatMap(note => note.attachments).forEach(item => void fetch('/api/uploads?key=' + encodeURIComponent(item.storageKey), { method: 'DELETE' }));
      return {
        ...study,
        subjects: study.subjects.filter(item => item.id !== subject.id),
        schedule: study.schedule.filter(item => item.subjectId !== subject.id),
        assessments: study.assessments.filter(item => item.subjectId !== subject.id),
        notes: study.notes.filter(item => item.subjectId !== subject.id),
        decks: study.decks.filter(item => item.subjectId !== subject.id),
        flashcards: study.flashcards.filter(item => item.subjectId !== subject.id),
        questions: study.questions.filter(item => item.subjectId !== subject.id),
        tasks: study.tasks.filter(item => item.subjectId !== subject.id),
        sessions: study.sessions.filter(item => item.subjectId !== subject.id),
      };
    });
    setSelectedSubjectId('');
    notify('Matéria removida.');
  }

  function deleteNote(note: StudyNote) {
    if (!window.confirm('Excluir esta anotação e suas imagens?')) return;
    note.attachments.forEach(item => void fetch('/api/uploads?key=' + encodeURIComponent(item.storageKey), { method: 'DELETE' }));
    updateStudy(setState, study => ({ ...study, notes: study.notes.filter(item => item.id !== note.id) }));
    notify('Anotação removida.');
  }

  function saveFocusSession() {
    if (!focusSubjectId) return notify('Escolha a matéria da sessão.');
    if (focusSeconds < 10) return notify('Cronometre pelo menos alguns segundos antes de salvar.');
    const minutes = Math.max(1, Math.round(focusSeconds / 60));
    updateStudy(setState, study => ({
      ...study,
      sessions: [{ id: uid('session'), subjectId: focusSubjectId, date: todayKey, durationMinutes: minutes, topic: focusTopic.trim(), notes: 'Sessão cronometrada' }, ...study.sessions],
      studyDates: ensureToday(study.studyDates),
      subjects: study.subjects.map(item => item.id === focusSubjectId ? { ...item, sessions: item.sessions + 1 } : item),
    }));
    setFocusRunning(false);
    setFocusSeconds(0);
    setFocusTopic('');
    notify('Sessão de ' + minutes + ' min registrada.');
  }

  function startReview(deckId?: string) {
    const candidates = state.study.flashcards.filter(card => card.dueDate <= todayKey && (!deckId || card.deckId === deckId));
    if (!candidates.length) return notify('Nenhum flashcard pendente neste baralho.');
    setReviewIds(candidates.map(card => card.id));
    setReviewIndex(0);
    setReviewRevealed(false);
    setTab('flashcards');
  }

  function gradeCard(grade: 'again' | 'hard' | 'good' | 'easy') {
    const cardId = reviewIds[reviewIndex];
    updateStudy(setState, study => ({
      ...study,
      flashcards: study.flashcards.map(card => {
        if (card.id !== cardId) return card;
        let repetitions = card.repetitions;
        let intervalDays = card.intervalDays;
        let easeFactor = card.easeFactor;
        let lapses = card.lapses;
        if (grade === 'again') {
          repetitions = 0; intervalDays = 1; easeFactor = Math.max(1.3, easeFactor - 0.2); lapses += 1;
        } else if (grade === 'hard') {
          repetitions += 1; intervalDays = Math.max(1, Math.ceil(Math.max(intervalDays, 1) * 1.2)); easeFactor = Math.max(1.3, easeFactor - 0.15);
        } else if (grade === 'good') {
          repetitions += 1; intervalDays = repetitions === 1 ? 1 : repetitions === 2 ? 6 : Math.ceil(Math.max(intervalDays, 1) * easeFactor);
        } else {
          repetitions += 1; intervalDays = repetitions === 1 ? 4 : Math.ceil(Math.max(intervalDays, 1) * (easeFactor + 0.3)); easeFactor = Math.min(3.2, easeFactor + 0.15);
        }
        return { ...card, reviewed: true, lastReviewedAt: new Date().toISOString(), dueDate: addDays(todayKey, intervalDays), intervalDays, repetitions, easeFactor, lapses };
      }),
      studyDates: ensureToday(study.studyDates),
    }));
    if (reviewIndex + 1 >= reviewIds.length) {
      setReviewIds([]);
      setReviewIndex(0);
      notify('Revisão concluída. Boa!');
    } else {
      setReviewIndex(index => index + 1);
      setReviewRevealed(false);
    }
  }

  function markQuestion(question: StudyQuestion, result: StudyQuestion['result']) {
    const firstAnswer = question.result === 'pending' && result !== 'pending';
    updateStudy(setState, study => ({
      ...study,
      questions: study.questions.map(item => item.id === question.id ? { ...item, result, answeredAt: result === 'pending' ? null : new Date().toISOString() } : item),
      questionsToday: study.questionsToday + (firstAnswer ? 1 : 0),
      studyDates: result === 'pending' ? study.studyDates : ensureToday(study.studyDates),
      subjects: firstAnswer ? study.subjects.map(item => item.id === question.subjectId ? { ...item, questions: item.questions + 1 } : item) : study.subjects,
    }));
  }

  function beginSimulation(simulation: StudySimulation) {
    setActiveSimulationId(simulation.id);
    setSimulationElapsed(simulation.elapsedSeconds);
    setSimulationStartedAt(Date.now() - simulation.elapsedSeconds * 1000);
  }

  function finishSimulation(simulation: StudySimulation, correct: number) {
    const safeCorrect = Math.min(Math.max(0, correct), simulation.questionCount);
    updateStudy(setState, study => ({
      ...study,
      simulations: study.simulations.map(item => item.id === simulation.id ? { ...item, correctAnswers: safeCorrect, completedAt: new Date().toISOString(), elapsedSeconds: simulationElapsed } : item),
      studyDates: ensureToday(study.studyDates),
    }));
    setActiveSimulationId('');
    setSimulationStartedAt(0);
    notify('Simulado finalizado e resultado salvo.');
  }

  const currentReview = state.study.flashcards.find(card => card.id === reviewIds[reviewIndex]);

  return (
    <div className="module-view studyx-view">
      <header className="studyx-heading">
        <div className="studyx-heading-copy">
          <button className="back-button" onClick={openHome} aria-label="Voltar ao início"><ArrowLeft size={20} /></button>
          <div>
            <span className="eyebrow">Faculdade em movimento</span>
            <h1>Estudos</h1>
            <p>{state.study.academic.course || 'Seu curso'}{state.study.academic.institution ? ' · ' + state.study.academic.institution : ''}</p>
          </div>
        </div>
        <div className="studyx-heading-actions">
          <button className="secondary-button" onClick={() => openEditor('session')}><Clock3 size={18} /> Registrar sessão</button>
          <button className="study-primary" onClick={() => openEditor('subject')}><Plus size={18} /> Nova matéria</button>
        </div>
      </header>

      <nav className="studyx-tabs" aria-label="Áreas de estudo">
        {tabs.map(item => {
          const Icon = item.icon;
          return <button key={item.id} className={tab === item.id ? 'active' : ''} onClick={() => switchTab(item.id)}><Icon size={17} /><span>{item.label}</span><small>{item.short}</small></button>;
        })}
      </nav>

      {tab === 'overview' && (
        <div className="studyx-stack">
          <section className="studyx-hero">
            <div>
              <span className="studyx-kicker"><Sparkles size={15} /> PAINEL ACADÊMICO</span>
              <h2>{todayClasses.length ? 'Sua noite já está organizada.' : 'Pronto para avançar no curso?'}</h2>
              <p>{todayClasses.length ? todayClasses.length + (todayClasses.length === 1 ? ' aula programada para hoje.' : ' aulas programadas para hoje.') : 'Monte o horário da semana e transforme cada matéria em um plano claro.'}</p>
              <div className="studyx-hero-actions">
                <button onClick={() => switchTab('schedule')}><CalendarRange size={18} /> Ver horário</button>
                <button onClick={() => startReview()}><Play size={17} /> Revisar agora</button>
              </div>
            </div>
            <div className="studyx-hero-orbit"><GraduationCap size={46} /><span>{streak}</span><small>dias de ritmo</small></div>
          </section>

          <section className="studyx-stats">
            <article><span className="violet"><CalendarDays size={20} /></span><div><small>Próxima entrega</small><strong>{upcomingAssessments[0] ? formatDate(upcomingAssessments[0].date, true) : 'Livre'}</strong><em>{upcomingAssessments[0]?.title ?? 'Nada pendente'}</em></div></article>
            <article><span className="blue"><Brain size={20} /></span><div><small>Revisões de hoje</small><strong>{dueCards.length}</strong><em>{state.study.flashcards.length} cartões no total</em></div></article>
            <article><span className="green"><Clock3 size={20} /></span><div><small>Tempo na semana</small><strong>{Math.floor(weekMinutes / 60)}h {weekMinutes % 60}min</strong><em>meta de {Math.floor(state.study.weeklyGoalMinutes / 60)}h</em></div></article>
            <article><span className="amber"><Target size={20} /></span><div><small>Questões hoje</small><strong>{answeredToday.length}</strong><em>meta de {state.study.questionGoal}</em></div></article>
          </section>

          <section className="studyx-dashboard-grid">
            <article className="studyx-panel studyx-today">
              <div className="studyx-section-head"><div><span className="eyebrow">Agenda de hoje</span><h2>Aulas e tarefas</h2></div><button onClick={() => switchTab('schedule')}>Semana <ChevronRight size={16} /></button></div>
              <div className="studyx-timeline">
                {todayClasses.map(item => {
                  const subject = subjectFor(state, item.subjectId);
                  return <button key={item.id} onClick={() => openEditor('class', item.id)} style={{ '--study-color': subject?.color ?? '#8b5cf6' } as React.CSSProperties}><span>{item.startTime}<small>{item.endTime}</small></span><i /><div><strong>{subject?.name ?? 'Matéria removida'}</strong><small>{item.room || subject?.room || 'Sala não informada'}{item.professor || subject?.professor ? ' · ' + (item.professor || subject?.professor) : ''}</small></div><Edit3 size={15} /></button>;
                })}
                {state.study.tasks.filter(item => item.date === todayKey).map(item => (
                  <button key={item.id} className={item.completed ? 'done' : ''} onClick={() => updateStudy(setState, study => ({ ...study, tasks: study.tasks.map(task => task.id === item.id ? { ...task, completed: !task.completed } : task) }))} style={{ '--study-color': subjectFor(state, item.subjectId)?.color ?? '#26c69a' } as React.CSSProperties}>
                    <span>{item.startTime || 'Hoje'}<small>{item.endTime}</small></span><i /><div><strong>{item.title}</strong><small>{subjectName(state, item.subjectId)} · {item.priority}</small></div>{item.completed ? <CheckCircle2 size={17} /> : <CircleHelp size={17} />}
                  </button>
                ))}
                {!todayClasses.length && !state.study.tasks.some(item => item.date === todayKey) && <CompactEmpty icon={<CalendarDays size={24} />} title="Noite livre por enquanto" text="Adicione suas aulas ou planeje uma sessão de estudo." action="Adicionar aula" onAction={() => openEditor('class', undefined, { weekday: todayWeekday || 1 })} />}
              </div>
            </article>

            <article className="studyx-panel studyx-focus">
              <div className="studyx-section-head"><div><span className="eyebrow">Modo foco</span><h2>Cronometrar estudo</h2></div><span className={focusRunning ? 'live' : ''}>{focusRunning ? 'EM ANDAMENTO' : 'PRONTO'}</span></div>
              <div className="studyx-timer">{secondsLabel(focusSeconds)}</div>
              <select value={focusSubjectId} onChange={event => setFocusSubjectId(event.target.value)}><option value="">Escolha a matéria</option>{state.study.subjects.map(subject => <option value={subject.id} key={subject.id}>{subject.name}</option>)}</select>
              <input value={focusTopic} onChange={event => setFocusTopic(event.target.value)} placeholder="Assunto estudado (opcional)" />
              <div className="studyx-timer-actions">
                <button className="focus-start" onClick={() => setFocusRunning(value => !value)}>{focusRunning ? <Pause size={19} /> : <Play size={19} />}{focusRunning ? 'Pausar' : focusSeconds ? 'Continuar' : 'Iniciar foco'}</button>
                <button onClick={() => { setFocusRunning(false); setFocusSeconds(0); }} aria-label="Zerar cronômetro"><RotateCcw size={18} /></button>
                <button disabled={!focusSeconds} onClick={saveFocusSession}><Check size={18} /></button>
              </div>
            </article>
          </section>

          <section className="studyx-dashboard-grid">
            <article className="studyx-panel">
              <div className="studyx-section-head"><div><span className="eyebrow">Prazos</span><h2>Próximas provas e trabalhos</h2></div><button onClick={() => openEditor('assessment')}><Plus size={17} /> Adicionar</button></div>
              <div className="studyx-assessment-list compact">
                {upcomingAssessments.slice(0, 4).map(item => <AssessmentRow key={item.id} item={item} state={state} onEdit={() => openEditor('assessment', item.id)} />)}
                {!upcomingAssessments.length && <CompactEmpty icon={<Trophy size={24} />} title="Tudo em dia" text="Nenhuma avaliação futura cadastrada." action="Nova prova" onAction={() => openEditor('assessment')} />}
              </div>
            </article>
            <article className="studyx-panel">
              <div className="studyx-section-head"><div><span className="eyebrow">Meta semanal</span><h2>{weekMinutes} de {state.study.weeklyGoalMinutes} minutos</h2></div><strong>{Math.min(100, Math.round(weekMinutes / Math.max(1, state.study.weeklyGoalMinutes) * 100))}%</strong></div>
              <div className="studyx-progress"><span style={{ width: Math.min(100, weekMinutes / Math.max(1, state.study.weeklyGoalMinutes) * 100) + '%' }} /></div>
              <div className="studyx-goal-grid"><span><Flame size={20} /><strong>{streak}</strong><small>dias seguidos</small></span><span><BookOpen size={20} /><strong>{state.study.subjects.length}</strong><small>matérias ativas</small></span><span><NotebookPen size={20} /><strong>{state.study.notes.length}</strong><small>anotações</small></span></div>
              <button className="studyx-wide-link" onClick={() => switchTab('progress')}>Ver relatório completo <ChevronRight size={17} /></button>
            </article>
          </section>
        </div>
      )}

      {tab === 'schedule' && (
        <div className="studyx-stack">
          <SectionIntro eyebrow="Rotina semanal" title="Horário de aulas" text="Organize as matérias por dia. Seus dois horários noturnos já estão preparados." actions={<><button className="secondary-button" onClick={() => openEditor('period')}><Plus size={17} /> Novo horário</button><button className="study-primary" onClick={() => openEditor('class')}><Plus size={17} /> Adicionar aula</button></>} />
          <section className="studyx-periods">
            {state.study.classPeriods.map(period => <button key={period.id} onClick={() => openEditor('period', period.id)}><Clock3 size={19} /><span><strong>{period.label}</strong><small>{period.startTime} às {period.endTime}</small></span><Edit3 size={16} /></button>)}
          </section>
          <section className="studyx-timetable studyx-panel">
            <div className="studyx-timetable-head"><span>HORÁRIO</span>{weekDays.map(day => <span key={day.value}>{day.short}<small>{day.label}</small></span>)}</div>
            {state.study.classPeriods.map(period => (
              <div className="studyx-timetable-row" key={period.id}>
                <div className="studyx-time-cell"><strong>{period.startTime}</strong><small>{period.endTime}</small></div>
                {weekDays.map(day => {
                  const classItem = state.study.schedule.find(item => item.weekday === day.value && item.startTime === period.startTime && item.endTime === period.endTime);
                  const subject = classItem ? subjectFor(state, classItem.subjectId) : undefined;
                  return classItem ? (
                    <button className="studyx-class-cell" key={day.value} onClick={() => openEditor('class', classItem.id)} style={{ '--study-color': subject?.color ?? '#8b5cf6' } as React.CSSProperties}><i /><strong>{subject?.name ?? 'Matéria'}</strong><small>{classItem.room || subject?.room || 'Sem sala'}</small><em>{classItem.professor || subject?.professor}</em></button>
                  ) : (
                    <button className="studyx-empty-cell" key={day.value} onClick={() => openEditor('class', undefined, { weekday: day.value, startTime: period.startTime, endTime: period.endTime })}><Plus size={17} /><span>Adicionar</span></button>
                  );
                })}
              </div>
            ))}
          </section>
          <section className="studyx-mobile-schedule">
            {weekDays.map(day => {
              const classes = state.study.schedule.filter(item => item.weekday === day.value).sort((a, b) => a.startTime.localeCompare(b.startTime));
              return <article className="studyx-panel" key={day.value}><div className="studyx-section-head"><h2>{day.label}</h2><button onClick={() => openEditor('class', undefined, { weekday: day.value })}><Plus size={17} /></button></div>{classes.map(item => { const subject = subjectFor(state, item.subjectId); return <button className="studyx-mobile-class" key={item.id} onClick={() => openEditor('class', item.id)} style={{ '--study-color': subject?.color ?? '#8b5cf6' } as React.CSSProperties}><i /><span><strong>{subject?.name}</strong><small>{item.startTime}–{item.endTime} · {item.room || subject?.room || 'Sem sala'}</small></span><Edit3 size={15} /></button>; })}{!classes.length && <small className="studyx-free-day">Sem aula cadastrada.</small>}</article>;
            })}
          </section>
          <section className="studyx-panel studyx-academic-settings">
            <div><span className="studyx-icon"><GraduationCap size={22} /></span><div><h2>Dados acadêmicos</h2><p>{state.study.academic.course || 'Curso não informado'} · {state.study.academic.institution || 'Instituição não informada'}{state.study.academic.semester ? ' · ' + state.study.academic.semester : ''}</p></div></div>
            <button onClick={() => openEditor('academic')}><Edit3 size={17} /> Editar</button>
          </section>
        </div>
      )}

      {tab === 'subjects' && (
        <div className="studyx-stack">
          {selectedSubject ? (
            <SubjectDetail subject={selectedSubject} state={state} onBack={() => setSelectedSubjectId('')} onEdit={() => openEditor('subject', selectedSubject.id)} onDelete={() => removeSubject(selectedSubject)} openEditor={openEditor} switchTab={switchTab} />
          ) : (
            <>
              <SectionIntro eyebrow="Organização" title="Matérias do curso" text="Cada matéria reúne aulas, provas, anotações, cards, questões e histórico." actions={<button className="study-primary" onClick={() => openEditor('subject')}><Plus size={18} /> Nova matéria</button>} />
              <div className="studyx-toolbar"><label><Search size={17} /><input value={search} onChange={event => setSearch(event.target.value)} placeholder="Buscar matéria..." /></label><span>{state.study.subjects.filter(item => !item.archived).length} matérias ativas</span></div>
              <section className="studyx-subject-grid">
                {state.study.subjects.filter(subject => subject.name.toLowerCase().includes(search.toLowerCase())).map(subject => {
                  const noteCount = state.study.notes.filter(item => item.subjectId === subject.id).length;
                  const cardCount = state.study.flashcards.filter(item => item.subjectId === subject.id).length;
                  const questionCount = state.study.questions.filter(item => item.subjectId === subject.id).length;
                  return <article key={subject.id} className="studyx-subject-card" style={{ '--study-color': subject.color } as React.CSSProperties}><i /><header><span><BookOpen size={22} /></span><button onClick={() => openEditor('subject', subject.id)}><Edit3 size={16} /></button></header><small>{subject.code || state.study.academic.course || 'Matéria acadêmica'}</small><h2>{subject.name}</h2><p>{subject.professor || 'Professor não informado'}{subject.room ? ' · ' + subject.room : ''}</p><div><span><strong>{noteCount}</strong><small>notas</small></span><span><strong>{cardCount}</strong><small>cards</small></span><span><strong>{questionCount}</strong><small>questões</small></span></div><button className="studyx-open-subject" onClick={() => setSelectedSubjectId(subject.id)}>Abrir matéria <ChevronRight size={17} /></button></article>;
                })}
                {!state.study.subjects.length && <LargeEmpty icon={<BookOpen size={34} />} title="Adicione as matérias do semestre" text="Depois você poderá montar o horário e guardar todo o conteúdo dentro de cada uma." action="Criar primeira matéria" onAction={() => openEditor('subject')} />}
              </section>
            </>
          )}
        </div>
      )}

      {tab === 'assessments' && (
        <div className="studyx-stack">
          <SectionIntro eyebrow="Calendário acadêmico" title="Provas e trabalhos" text="Prazos, conteúdo, peso, nota e lembretes em um só lugar." actions={<button className="study-primary" onClick={() => openEditor('assessment')}><Plus size={18} /> Nova avaliação</button>} />
          <section className="studyx-calendar-layout">
            <article className="studyx-panel studyx-calendar">
              <div className="studyx-calendar-nav"><button onClick={() => setCalendarMonth(value => new Date(value.getFullYear(), value.getMonth() - 1, 1))}><ChevronLeft size={19} /></button><strong>{monthLabel.format(calendarMonth)}</strong><button onClick={() => setCalendarMonth(value => new Date(value.getFullYear(), value.getMonth() + 1, 1))}><ChevronRight size={19} /></button></div>
              <MonthCalendar month={calendarMonth} assessments={state.study.assessments} onOpen={id => openEditor('assessment', id)} />
            </article>
            <article className="studyx-panel">
              <div className="studyx-section-head"><div><span className="eyebrow">A seguir</span><h2>Próximos prazos</h2></div><Bell size={20} /></div>
              <div className="studyx-assessment-list">{upcomingAssessments.map(item => <AssessmentRow key={item.id} item={item} state={state} onEdit={() => openEditor('assessment', item.id)} />)}{!upcomingAssessments.length && <CompactEmpty icon={<CheckCircle2 size={24} />} title="Agenda limpa" text="Cadastre uma prova ou trabalho para acompanhar." action="Adicionar" onAction={() => openEditor('assessment')} />}</div>
            </article>
          </section>
          {!!state.study.assessments.some(item => item.status === 'completed') && <section className="studyx-panel"><div className="studyx-section-head"><div><span className="eyebrow">Histórico</span><h2>Concluídas e notas</h2></div></div><div className="studyx-grade-grid">{state.study.assessments.filter(item => item.status === 'completed').map(item => <button key={item.id} onClick={() => openEditor('assessment', item.id)}><span style={{ background: subjectFor(state, item.subjectId)?.color }} /><div><strong>{item.title}</strong><small>{subjectName(state, item.subjectId)} · {formatDate(item.date, true)}</small></div><b>{item.grade === null ? '—' : item.grade + '/' + item.maxGrade}</b></button>)}</div></section>}
        </div>
      )}

      {tab === 'notes' && (
        <div className="studyx-stack">
          <SectionIntro eyebrow="Caderno digital" title="Anotações" text="Registre o conteúdo de cada matéria e anexe imagens do quadro, slides ou exercícios." actions={<button className="study-primary" onClick={() => openEditor('note')}><Plus size={18} /> Nova anotação</button>} />
          <div className="studyx-toolbar"><label><Search size={17} /><input value={search} onChange={event => setSearch(event.target.value)} placeholder="Buscar nas anotações..." /></label><select value={subjectFilter} onChange={event => setSubjectFilter(event.target.value)}><option value="all">Todas as matérias</option>{state.study.subjects.map(subject => <option key={subject.id} value={subject.id}>{subject.name}</option>)}</select></div>
          <section className="studyx-note-grid">
            {state.study.notes.filter(note => (subjectFilter === 'all' || note.subjectId === subjectFilter) && (note.title + ' ' + note.content + ' ' + note.tags.join(' ')).toLowerCase().includes(search.toLowerCase())).sort((a, b) => Number(b.favorite) - Number(a.favorite) || b.updatedAt.localeCompare(a.updatedAt)).map(note => (
              <article key={note.id} className="studyx-note-card" style={{ '--study-color': subjectFor(state, note.subjectId)?.color ?? '#8b5cf6' } as React.CSSProperties}>
                <header><span>{note.favorite && <Star size={15} fill="currentColor" />}{subjectName(state, note.subjectId)}</span><div><button onClick={() => updateStudy(setState, study => ({ ...study, notes: study.notes.map(item => item.id === note.id ? { ...item, favorite: !item.favorite } : item) }))}><Star size={16} /></button><button onClick={() => openEditor('note', note.id)}><Edit3 size={16} /></button><button className="danger" onClick={() => deleteNote(note)}><Trash2 size={16} /></button></div></header>
                <h2>{note.title}</h2><p>{stripMarkdown(note.content).slice(0, 180) || 'Sem texto nesta anotação.'}</p>
                {!!note.attachments.length && <div className="studyx-note-images">{note.attachments.slice(0, 3).map(image => <img key={image.id} src={image.url} alt={image.name} />)}{note.attachments.length > 3 && <span>+{note.attachments.length - 3}</span>}</div>}
                <footer><span>{note.tags.slice(0, 3).map(tag => <em key={tag}>#{tag}</em>)}</span><small>{formatDate(note.updatedAt.slice(0, 10), true)}</small></footer>
              </article>
            ))}
            {!state.study.notes.length && <LargeEmpty icon={<NotebookPen size={34} />} title="Seu caderno começa aqui" text="Crie uma anotação, organize por matéria e anexe quantas imagens precisar." action="Nova anotação" onAction={() => openEditor('note')} />}
          </section>
        </div>
      )}

      {tab === 'flashcards' && (
        <div className="studyx-stack">
          <SectionIntro eyebrow="Repetição espaçada" title="Flashcards" text="O aplicativo calcula a próxima revisão de acordo com a dificuldade de cada resposta." actions={<><button className="secondary-button" onClick={() => openEditor('deck')}><Layers3 size={18} /> Novo baralho</button><button className="study-primary" onClick={() => openEditor('flashcard')}><Plus size={18} /> Novo flashcard</button></>} />
          {currentReview ? (
            <section className="studyx-review">
              <div className="studyx-review-top"><button onClick={() => setReviewIds([])}><X size={18} /> Encerrar</button><span>{reviewIndex + 1} de {reviewIds.length}</span></div>
              <div className="studyx-progress"><span style={{ width: ((reviewIndex + 1) / reviewIds.length * 100) + '%' }} /></div>
              <article className="studyx-review-card" onClick={() => setReviewRevealed(true)}>
                <span>{subjectName(state, currentReview.subjectId)}{currentReview.topic ? ' · ' + currentReview.topic : ''}</span>
                <small>PERGUNTA</small><h2>{currentReview.front}</h2>
                {reviewRevealed ? <div className="studyx-review-answer"><small>RESPOSTA</small><p>{currentReview.back}</p></div> : <button onClick={() => setReviewRevealed(true)}>Mostrar resposta</button>}
              </article>
              {reviewRevealed && <div className="studyx-grades"><button className="again" onClick={() => gradeCard('again')}><XCircle size={18} /><strong>Errei</strong><small>1 dia</small></button><button className="hard" onClick={() => gradeCard('hard')}><Flame size={18} /><strong>Difícil</strong><small>curto</small></button><button className="good" onClick={() => gradeCard('good')}><Check size={18} /><strong>Bom</strong><small>normal</small></button><button className="easy" onClick={() => gradeCard('easy')}><Sparkles size={18} /><strong>Fácil</strong><small>longo</small></button></div>}
            </section>
          ) : (
            <>
              <section className="studyx-review-banner"><div><span><Brain size={25} /></span><div><small>REVISÕES DISPONÍVEIS</small><h2>{dueCards.length ? dueCards.length + ' cartões esperando por você' : 'Tudo revisado por enquanto'}</h2><p>Use Errei, Difícil, Bom ou Fácil para ajustar automaticamente o próximo intervalo.</p></div></div><button disabled={!dueCards.length} onClick={() => startReview()}><Play size={18} /> Revisar agora</button></section>
              <section className="studyx-deck-grid">
                {state.study.decks.map(deck => {
                  const deckCards = state.study.flashcards.filter(card => card.deckId === deck.id);
                  const due = deckCards.filter(card => card.dueDate <= todayKey).length;
                  return <article key={deck.id} style={{ '--study-color': deck.color } as React.CSSProperties}><i /><header><Layers3 size={23} /><button onClick={() => openEditor('deck', deck.id)}><Edit3 size={16} /></button></header><small>{subjectName(state, deck.subjectId)}</small><h2>{deck.name}</h2><p>{deck.description || 'Baralho de revisão'}</p><div><span><strong>{deckCards.length}</strong><small>cartões</small></span><span><strong>{due}</strong><small>pendentes</small></span></div><button disabled={!due} onClick={() => startReview(deck.id)}><Play size={16} /> Revisar baralho</button></article>;
                })}
                {!state.study.decks.length && <LargeEmpty icon={<Layers3 size={34} />} title="Crie seu primeiro baralho" text="Agrupe flashcards de um mesmo assunto e revise no momento certo." action="Novo baralho" onAction={() => openEditor('deck')} />}
              </section>
              {!!state.study.flashcards.length && <section className="studyx-panel"><div className="studyx-section-head"><div><span className="eyebrow">Biblioteca</span><h2>Todos os flashcards</h2></div><span>{state.study.flashcards.length} cartões</span></div><div className="studyx-card-library">{state.study.flashcards.map(card => <button key={card.id} onClick={() => openEditor('flashcard', card.id)}><span style={{ background: subjectFor(state, card.subjectId)?.color }} /><div><strong>{card.front}</strong><small>{subjectName(state, card.subjectId)} · revisar {formatDate(card.dueDate, true)}</small></div><Edit3 size={15} /></button>)}</div></section>}
            </>
          )}
        </div>
      )}

      {tab === 'questions' && (
        <div className="studyx-stack">
          <SectionIntro eyebrow="Treino ativo" title="Banco de questões" text="Registre enunciado, resposta, comentário, fonte e seu resultado." actions={<button className="study-primary" onClick={() => openEditor('question')}><Plus size={18} /> Nova questão</button>} />
          <QuestionStats questions={state.study.questions} />
          <div className="studyx-toolbar"><label><Search size={17} /><input value={search} onChange={event => setSearch(event.target.value)} placeholder="Buscar questão ou assunto..." /></label><select value={subjectFilter} onChange={event => setSubjectFilter(event.target.value)}><option value="all">Todas as matérias</option>{state.study.subjects.map(subject => <option key={subject.id} value={subject.id}>{subject.name}</option>)}</select></div>
          <section className="studyx-question-list">
            {state.study.questions.filter(item => (subjectFilter === 'all' || item.subjectId === subjectFilter) && (item.prompt + ' ' + item.topic).toLowerCase().includes(search.toLowerCase())).map((question, index) => <article key={question.id} className={'studyx-question ' + question.result}><header><span>QUESTÃO {String(index + 1).padStart(2, '0')}</span><div><em>{question.difficulty}</em><button onClick={() => openEditor('question', question.id)}><Edit3 size={16} /></button></div></header><small>{subjectName(state, question.subjectId)}{question.topic ? ' · ' + question.topic : ''}</small><h2>{question.prompt}</h2>{question.answer && <details><summary>Ver resposta e comentário</summary><strong>{question.answer}</strong>{question.explanation && <p>{question.explanation}</p>}{question.source && <small>Fonte: {question.source}</small>}</details>}<footer><button className={question.result === 'wrong' ? 'active wrong' : ''} onClick={() => markQuestion(question, 'wrong')}><XCircle size={17} /> Errei</button><button className={question.result === 'pending' ? 'active pending' : ''} onClick={() => markQuestion(question, 'pending')}><RotateCcw size={17} /> Pendente</button><button className={question.result === 'correct' ? 'active correct' : ''} onClick={() => markQuestion(question, 'correct')}><CheckCircle2 size={17} /> Acertei</button></footer></article>)}
            {!state.study.questions.length && <LargeEmpty icon={<CircleHelp size={34} />} title="Monte seu banco de questões" text="Cadastre questões da faculdade, listas e provas antigas para acompanhar seus acertos." action="Adicionar questão" onAction={() => openEditor('question')} />}
          </section>
        </div>
      )}

      {tab === 'simulations' && (
        <div className="studyx-stack">
          <SectionIntro eyebrow="Teste de desempenho" title="Simulados" text="Defina quantidade de questões e tempo. Ao finalizar, o resultado entra no histórico." actions={<button className="study-primary" onClick={() => openEditor('simulation')}><Plus size={18} /> Novo simulado</button>} />
          <section className="studyx-simulation-grid">
            {state.study.simulations.map(simulation => {
              const active = activeSimulationId === simulation.id;
              const remaining = simulation.durationMinutes * 60 - (active ? simulationElapsed : simulation.elapsedSeconds);
              const percent = simulation.correctAnswers === null ? null : Math.round(simulation.correctAnswers / Math.max(1, simulation.questionCount) * 100);
              return <article key={simulation.id} className={active ? 'active' : ''}><header><span><TimerReset size={23} /></span><button onClick={() => openEditor('simulation', simulation.id)}><Edit3 size={16} /></button></header><small>{simulation.subjectIds.map(id => subjectName(state, id)).join(' · ') || 'Todas as matérias'}</small><h2>{simulation.title}</h2><div className="studyx-sim-meta"><span><strong>{simulation.questionCount}</strong><small>questões</small></span><span><strong>{simulation.durationMinutes} min</strong><small>duração</small></span><span><strong>{percent === null ? '—' : percent + '%'}</strong><small>resultado</small></span></div>{active ? <form onSubmit={event => { event.preventDefault(); const data = new FormData(event.currentTarget); finishSimulation(simulation, Number(data.get('correct') ?? 0)); }}><div className="studyx-countdown"><small>TEMPO RESTANTE</small><strong className={remaining <= 0 ? 'expired' : ''}>{secondsLabel(remaining)}</strong></div><label>Quantas você acertou?<input name="correct" type="number" min="0" max={simulation.questionCount} required /></label><button type="submit"><Check size={17} /> Finalizar e salvar</button></form> : <button className="studyx-start-sim" onClick={() => beginSimulation(simulation)}><Play size={17} /> {simulation.completedAt ? 'Refazer simulado' : 'Iniciar simulado'}</button>}</article>;
            })}
            {!state.study.simulations.length && <LargeEmpty icon={<TimerReset size={34} />} title="Crie seu primeiro simulado" text="Configure matérias, número de questões e limite de tempo." action="Novo simulado" onAction={() => openEditor('simulation')} />}
          </section>
        </div>
      )}

      {tab === 'plan' && (
        <div className="studyx-stack">
          <SectionIntro eyebrow="Cronograma" title="Plano de estudos" text="Transforme conteúdo em blocos pequenos com data, horário e prioridade." actions={<button className="study-primary" onClick={() => openEditor('task')}><Plus size={18} /> Nova tarefa</button>} />
          <section className="studyx-plan-board">
            {['Hoje', 'Próximos 7 dias', 'Depois'].map(group => {
              const limit = addDays(todayKey, 7);
              const items = state.study.tasks.filter(task => group === 'Hoje' ? task.date === todayKey : group === 'Próximos 7 dias' ? task.date > todayKey && task.date <= limit : task.date > limit).sort((a, b) => (a.date + a.startTime).localeCompare(b.date + b.startTime));
              return <article className="studyx-panel" key={group}><header><h2>{group}</h2><span>{items.filter(item => !item.completed).length} pendentes</span></header><div>{items.map(task => <button key={task.id} className={task.completed ? 'done' : ''} onClick={() => updateStudy(setState, study => ({ ...study, tasks: study.tasks.map(item => item.id === task.id ? { ...item, completed: !item.completed } : item) }))}><span className={'priority ' + task.priority.toLowerCase()} /><i>{task.completed ? <Check size={15} /> : null}</i><div><strong>{task.title}</strong><small>{subjectName(state, task.subjectId)} · {formatDate(task.date, true)} {task.startTime}</small></div><em>{task.priority}</em><span className="edit" onClick={event => { event.stopPropagation(); openEditor('task', task.id); }}><Edit3 size={15} /></span></button>)}{!items.length && <small className="studyx-empty-column">Nenhuma tarefa neste período.</small>}</div></article>;
            })}
          </section>
        </div>
      )}

      {tab === 'progress' && (
        <div className="studyx-stack">
          <SectionIntro eyebrow="Evolução acadêmica" title="Progresso" text="Tempo estudado, constância, questões e desempenho por matéria." actions={<button className="secondary-button" onClick={() => openEditor('session')}><Plus size={17} /> Registrar sessão</button>} />
          <section className="studyx-stats progress">
            <article><span className="violet"><Clock3 size={20} /></span><div><small>Tempo total</small><strong>{Math.floor(state.study.sessions.reduce((sum, item) => sum + item.durationMinutes, 0) / 60)}h {state.study.sessions.reduce((sum, item) => sum + item.durationMinutes, 0) % 60}min</strong><em>{state.study.sessions.length} sessões</em></div></article>
            <article><span className="amber"><Flame size={20} /></span><div><small>Sequência atual</small><strong>{streak} dias</strong><em>{state.study.studyDates.length} dias estudados</em></div></article>
            <article><span className="green"><CheckCircle2 size={20} /></span><div><small>Taxa de acerto</small><strong>{accuracy(state.study.questions)}%</strong><em>{state.study.questions.filter(item => item.result !== 'pending').length} respondidas</em></div></article>
            <article><span className="blue"><Trophy size={20} /></span><div><small>Média das notas</small><strong>{gradeAverage(state.study.assessments)}</strong><em>{state.study.assessments.filter(item => item.grade !== null).length} avaliações</em></div></article>
          </section>
          <section className="studyx-progress-layout">
            <article className="studyx-panel"><div className="studyx-section-head"><div><span className="eyebrow">Por matéria</span><h2>Tempo acumulado</h2></div></div><SubjectBars state={state} /></article>
            <article className="studyx-panel studyx-goal-editor"><div className="studyx-section-head"><div><span className="eyebrow">Metas</span><h2>Ajuste seu ritmo</h2></div><Target size={21} /></div><label>Meta semanal de estudo <span>{state.study.weeklyGoalMinutes} min</span><input type="range" min="60" max="1800" step="30" value={state.study.weeklyGoalMinutes} onChange={event => updateStudy(setState, study => ({ ...study, weeklyGoalMinutes: Number(event.target.value) }))} /></label><label>Meta diária de questões <span>{state.study.questionGoal}</span><input type="range" min="5" max="100" step="5" value={state.study.questionGoal} onChange={event => updateStudy(setState, study => ({ ...study, questionGoal: Number(event.target.value) }))} /></label><div className="studyx-progress"><span style={{ width: Math.min(100, weekMinutes / Math.max(1, state.study.weeklyGoalMinutes) * 100) + '%' }} /></div><small>{weekMinutes} de {state.study.weeklyGoalMinutes} minutos nesta semana</small></article>
          </section>
          <section className="studyx-panel"><div className="studyx-section-head"><div><span className="eyebrow">Histórico</span><h2>Sessões recentes</h2></div><button onClick={() => openEditor('session')}><Plus size={17} /></button></div><div className="studyx-session-list">{state.study.sessions.slice().sort((a, b) => b.date.localeCompare(a.date)).map(session => <button key={session.id} onClick={() => openEditor('session', session.id)}><span style={{ background: subjectFor(state, session.subjectId)?.color }}><Clock3 size={17} /></span><div><strong>{session.topic || subjectName(state, session.subjectId)}</strong><small>{subjectName(state, session.subjectId)} · {formatDate(session.date, true)}</small></div><b>{session.durationMinutes} min</b><Edit3 size={15} /></button>)}{!state.study.sessions.length && <CompactEmpty icon={<Clock3 size={24} />} title="Sem sessões registradas" text="Use o Modo foco ou adicione uma sessão manualmente." action="Registrar" onAction={() => openEditor('session')} />}</div></section>
        </div>
      )}

      {editor && <StudyEditor editor={editor} state={state} onClose={closeEditor} onSubmit={saveEditor} onDelete={() => deleteEditorItem(editor, state, setState, closeEditor, notify)} noteContent={noteContent} setNoteContent={setNoteContent} noteTextRef={noteTextRef} noteAttachments={noteAttachments} setNoteAttachments={setNoteAttachments} uploadImages={uploadImages} uploading={uploading} formatNote={formatNote} />}
    </div>
  );
}

function SectionIntro({ eyebrow, title, text, actions }: { eyebrow: string; title: string; text: string; actions?: React.ReactNode }) {
  return <header className="studyx-intro"><div><span className="eyebrow">{eyebrow}</span><h2>{title}</h2><p>{text}</p></div>{actions && <div>{actions}</div>}</header>;
}

function CompactEmpty({ icon, title, text, action, onAction }: { icon: React.ReactNode; title: string; text: string; action: string; onAction: () => void }) {
  return <div className="studyx-compact-empty"><span>{icon}</span><div><strong>{title}</strong><small>{text}</small></div><button onClick={onAction}>{action}</button></div>;
}

function LargeEmpty({ icon, title, text, action, onAction }: { icon: React.ReactNode; title: string; text: string; action: string; onAction: () => void }) {
  return <div className="studyx-large-empty"><span>{icon}</span><h2>{title}</h2><p>{text}</p><button onClick={onAction}><Plus size={17} /> {action}</button></div>;
}

function AssessmentRow({ item, state, onEdit }: { item: Assessment; state: AppState; onEdit: () => void }) {
  const days = Math.ceil((new Date(item.date + 'T12:00:00').getTime() - new Date(localDateKey() + 'T12:00:00').getTime()) / 86400000);
  return <button className="studyx-assessment-row" onClick={onEdit} style={{ '--study-color': subjectFor(state, item.subjectId)?.color ?? '#8b5cf6' } as React.CSSProperties}><span><strong>{new Date(item.date + 'T12:00:00').getDate()}</strong><small>{new Intl.DateTimeFormat('pt-BR', { month: 'short' }).format(new Date(item.date + 'T12:00:00'))}</small></span><i /><div><small>{item.kind} · {subjectName(state, item.subjectId)}</small><strong>{item.title}</strong><em>{item.content || 'Conteúdo não informado'}</em></div><b className={days <= item.reminderDays ? 'urgent' : ''}>{days === 0 ? 'Hoje' : days === 1 ? 'Amanhã' : days + ' dias'}</b></button>;
}

function MonthCalendar({ month, assessments, onOpen }: { month: Date; assessments: Assessment[]; onOpen: (id: string) => void }) {
  const first = new Date(month.getFullYear(), month.getMonth(), 1);
  const startOffset = (first.getDay() + 6) % 7;
  const daysInMonth = new Date(month.getFullYear(), month.getMonth() + 1, 0).getDate();
  const cells = Array.from({ length: 42 }, (_, index) => {
    const day = index - startOffset + 1;
    return day >= 1 && day <= daysInMonth ? day : 0;
  });
  return <><div className="studyx-calendar-week"><span>SEG</span><span>TER</span><span>QUA</span><span>QUI</span><span>SEX</span><span>SÁB</span><span>DOM</span></div><div className="studyx-calendar-days">{cells.map((day, index) => {
    if (!day) return <span className="blank" key={index} />;
    const key = localDateKey(new Date(month.getFullYear(), month.getMonth(), day));
    const events = assessments.filter(item => item.date === key);
    return <button key={key} className={key === localDateKey() ? 'today' : ''} onClick={() => events[0] && onOpen(events[0].id)}><span>{day}</span><i>{events.slice(0, 3).map(item => <b key={item.id} title={item.title} />)}</i></button>;
  })}</div></>;
}

function SubjectDetail({ subject, state, onBack, onEdit, onDelete, openEditor, switchTab }: { subject: StudySubject; state: AppState; onBack: () => void; onEdit: () => void; onDelete: () => void; openEditor: (kind: EditorKind, id?: string, defaults?: Record<string, string | number>) => void; switchTab: (tab: StudyTab) => void }) {
  const notes = state.study.notes.filter(item => item.subjectId === subject.id);
  const cards = state.study.flashcards.filter(item => item.subjectId === subject.id);
  const questions = state.study.questions.filter(item => item.subjectId === subject.id);
  const sessions = state.study.sessions.filter(item => item.subjectId === subject.id);
  const minutes = sessions.reduce((sum, item) => sum + item.durationMinutes, 0);
  return <><header className="studyx-subject-detail-head" style={{ '--study-color': subject.color } as React.CSSProperties}><button onClick={onBack}><ArrowLeft size={19} /> Matérias</button><div><span><BookOpen size={27} /></span><div><small>{subject.code || 'MATÉRIA'}</small><h2>{subject.name}</h2><p>{subject.professor || 'Professor não informado'}{subject.room ? ' · ' + subject.room : ''}</p></div></div><aside><button onClick={onEdit}><Edit3 size={17} /> Editar</button><button className="danger" onClick={onDelete}><Trash2 size={17} /></button></aside></header><section className="studyx-subject-kpis"><article><strong>{notes.length}</strong><small>anotações</small></article><article><strong>{cards.length}</strong><small>flashcards</small></article><article><strong>{questions.length}</strong><small>questões</small></article><article><strong>{Math.floor(minutes / 60)}h {minutes % 60}min</strong><small>estudados</small></article></section><section className="studyx-dashboard-grid"><article className="studyx-panel"><div className="studyx-section-head"><div><span className="eyebrow">Conteúdo</span><h2>Anotações recentes</h2></div><button onClick={() => openEditor('note', undefined, { subjectId: subject.id })}><Plus size={17} /></button></div>{notes.slice(0, 4).map(note => <button className="studyx-detail-row" key={note.id} onClick={() => openEditor('note', note.id)}><NotebookPen size={18} /><div><strong>{note.title}</strong><small>{stripMarkdown(note.content).slice(0, 70)}</small></div><ChevronRight size={16} /></button>)}{!notes.length && <CompactEmpty icon={<NotebookPen size={22} />} title="Sem anotações" text="Registre o conteúdo desta matéria." action="Criar" onAction={() => openEditor('note', undefined, { subjectId: subject.id })} />}</article><article className="studyx-panel"><div className="studyx-section-head"><div><span className="eyebrow">Avaliações</span><h2>Próximos prazos</h2></div><button onClick={() => openEditor('assessment', undefined, { subjectId: subject.id })}><Plus size={17} /></button></div>{state.study.assessments.filter(item => item.subjectId === subject.id && item.date >= localDateKey()).slice(0, 4).map(item => <AssessmentRow key={item.id} item={item} state={state} onEdit={() => openEditor('assessment', item.id)} />)}{!state.study.assessments.some(item => item.subjectId === subject.id && item.date >= localDateKey()) && <CompactEmpty icon={<CalendarDays size={22} />} title="Sem provas futuras" text="Adicione um prazo quando precisar." action="Adicionar" onAction={() => openEditor('assessment', undefined, { subjectId: subject.id })} />}</article></section><section className="studyx-subject-actions"><button onClick={() => openEditor('note', undefined, { subjectId: subject.id })}><NotebookPen size={20} /><span><strong>Nova anotação</strong><small>Texto e imagens</small></span></button><button onClick={() => openEditor('flashcard', undefined, { subjectId: subject.id })}><Brain size={20} /><span><strong>Novo flashcard</strong><small>Memorização ativa</small></span></button><button onClick={() => openEditor('question', undefined, { subjectId: subject.id })}><CircleHelp size={20} /><span><strong>Nova questão</strong><small>Banco de treino</small></span></button><button onClick={() => switchTab('progress')}><BarChart3 size={20} /><span><strong>Ver progresso</strong><small>Histórico completo</small></span></button></section></>;
}

function QuestionStats({ questions }: { questions: StudyQuestion[] }) {
  const answered = questions.filter(item => item.result !== 'pending');
  const correct = questions.filter(item => item.result === 'correct').length;
  const wrong = questions.filter(item => item.result === 'wrong').length;
  return <section className="studyx-question-stats"><article><CircleHelp size={20} /><span><strong>{questions.length}</strong><small>Total</small></span></article><article><CheckCircle2 size={20} /><span><strong>{correct}</strong><small>Acertos</small></span></article><article><XCircle size={20} /><span><strong>{wrong}</strong><small>Erros</small></span></article><article><Target size={20} /><span><strong>{answered.length ? Math.round(correct / answered.length * 100) : 0}%</strong><small>Aproveitamento</small></span></article></section>;
}

function accuracy(questions: StudyQuestion[]) {
  const answered = questions.filter(item => item.result !== 'pending');
  return answered.length ? Math.round(answered.filter(item => item.result === 'correct').length / answered.length * 100) : 0;
}

function gradeAverage(assessments: Assessment[]) {
  const graded = assessments.filter(item => item.grade !== null && item.maxGrade > 0);
  if (!graded.length) return '—';
  return (graded.reduce((sum, item) => sum + (item.grade ?? 0) / item.maxGrade * 10, 0) / graded.length).toFixed(1);
}

function SubjectBars({ state }: { state: AppState }) {
  const values = state.study.subjects.map(subject => ({ subject, minutes: state.study.sessions.filter(item => item.subjectId === subject.id).reduce((sum, item) => sum + item.durationMinutes, 0) })).sort((a, b) => b.minutes - a.minutes);
  const max = Math.max(1, ...values.map(item => item.minutes));
  return <div className="studyx-bars">{values.map(item => <div key={item.subject.id}><header><span>{item.subject.name}</span><strong>{Math.floor(item.minutes / 60)}h {item.minutes % 60}min</strong></header><div><span style={{ width: item.minutes / max * 100 + '%', background: item.subject.color }} /></div></div>)}{!values.length && <CompactEmpty icon={<BarChart3 size={22} />} title="Ainda sem dados" text="Registre sessões para visualizar a distribuição." action="Entendi" onAction={() => undefined} />}</div>;
}

function deleteEditorItem(editor: EditorState, state: AppState, setState: Dispatch<SetStateAction<AppState>>, close: () => void, notify: (message: string) => void) {
  if (!editor.id || !window.confirm('Tem certeza que deseja excluir este item?')) return;
  updateStudy(setState, study => {
    if (editor.kind === 'period') return { ...study, classPeriods: study.classPeriods.filter(item => item.id !== editor.id) };
    if (editor.kind === 'class') return { ...study, schedule: study.schedule.filter(item => item.id !== editor.id) };
    if (editor.kind === 'assessment') return { ...study, assessments: study.assessments.filter(item => item.id !== editor.id) };
    if (editor.kind === 'deck') return { ...study, decks: study.decks.filter(item => item.id !== editor.id), flashcards: study.flashcards.map(card => card.deckId === editor.id ? { ...card, deckId: '' } : card) };
    if (editor.kind === 'flashcard') return { ...study, flashcards: study.flashcards.filter(item => item.id !== editor.id) };
    if (editor.kind === 'question') return { ...study, questions: study.questions.filter(item => item.id !== editor.id) };
    if (editor.kind === 'simulation') return { ...study, simulations: study.simulations.filter(item => item.id !== editor.id) };
    if (editor.kind === 'task') return { ...study, tasks: study.tasks.filter(item => item.id !== editor.id) };
    if (editor.kind === 'session') return { ...study, sessions: study.sessions.filter(item => item.id !== editor.id) };
    return study;
  });
  void state;
  close();
  notify('Item excluído.');
}

type StudyEditorProps = {
  editor: EditorState;
  state: AppState;
  onClose: () => void;
  onSubmit: (event: FormEvent<HTMLFormElement>) => void;
  onDelete: () => void;
  noteContent: string;
  setNoteContent: (value: string) => void;
  noteTextRef: React.RefObject<HTMLTextAreaElement | null>;
  noteAttachments: StudyAttachment[];
  setNoteAttachments: Dispatch<SetStateAction<StudyAttachment[]>>;
  uploadImages: (files: FileList | null) => Promise<void>;
  uploading: boolean;
  formatNote: (prefix: string, suffix?: string) => void;
};

function StudyEditor({ editor, state, onClose, onSubmit, onDelete, noteContent, setNoteContent, noteTextRef, noteAttachments, setNoteAttachments, uploadImages, uploading, formatNote }: StudyEditorProps) {
  const defaults = editor.defaults ?? {};
  const subject = state.study.subjects.find(item => item.id === editor.id);
  const period = state.study.classPeriods.find(item => item.id === editor.id);
  const classItem = state.study.schedule.find(item => item.id === editor.id);
  const assessment = state.study.assessments.find(item => item.id === editor.id);
  const note = state.study.notes.find(item => item.id === editor.id);
  const deck = state.study.decks.find(item => item.id === editor.id);
  const flashcard = state.study.flashcards.find(item => item.id === editor.id);
  const question = state.study.questions.find(item => item.id === editor.id);
  const simulation = state.study.simulations.find(item => item.id === editor.id);
  const task = state.study.tasks.find(item => item.id === editor.id);
  const session = state.study.sessions.find(item => item.id === editor.id);
  const titles: Record<EditorKind, string> = { academic: 'Dados acadêmicos', subject: editor.id ? 'Editar matéria' : 'Nova matéria', period: editor.id ? 'Editar horário' : 'Novo horário', class: editor.id ? 'Editar aula' : 'Adicionar aula', assessment: editor.id ? 'Editar avaliação' : 'Nova avaliação', note: editor.id ? 'Editar anotação' : 'Nova anotação', deck: editor.id ? 'Editar baralho' : 'Novo baralho', flashcard: editor.id ? 'Editar flashcard' : 'Novo flashcard', question: editor.id ? 'Editar questão' : 'Nova questão', simulation: editor.id ? 'Editar simulado' : 'Novo simulado', task: editor.id ? 'Editar tarefa' : 'Nova tarefa', session: editor.id ? 'Editar sessão' : 'Registrar sessão' };
  const canDelete = Boolean(editor.id) && editor.kind !== 'academic' && editor.kind !== 'subject' && editor.kind !== 'note';
  return <div className="modal-backdrop studyx-modal-backdrop" onMouseDown={event => event.target === event.currentTarget && onClose()}><form className="app-modal studyx-modal" onSubmit={onSubmit}><header><div><span className="eyebrow">Área de estudos</span><h2>{titles[editor.kind]}</h2></div><button type="button" onClick={onClose}><X size={21} /></button></header><div className="modal-fields">
    {editor.kind === 'academic' && <><div className="field-row"><label>Curso<input name="course" required defaultValue={state.study.academic.course} /></label><label>Instituição<input name="institution" defaultValue={state.study.academic.institution} /></label></div><label>Semestre atual<input name="semester" placeholder="Ex.: 2026.2" defaultValue={state.study.academic.semester} /></label><div className="field-row"><label>Início do semestre<input type="date" name="semesterStart" defaultValue={state.study.academic.semesterStart} /></label><label>Fim do semestre<input type="date" name="semesterEnd" defaultValue={state.study.academic.semesterEnd} /></label></div></>}
    {editor.kind === 'subject' && <><div className="field-row"><label>Nome da matéria<input name="name" required placeholder="Ex.: Banco de Dados" defaultValue={subject?.name} /></label><label>Código<input name="code" placeholder="Ex.: SI042" defaultValue={subject?.code} /></label></div><div className="field-row"><label>Professor(a)<input name="professor" defaultValue={subject?.professor} /></label><label>Sala ou laboratório<input name="room" defaultValue={subject?.room} /></label></div><div className="field-row"><label>Semestre<input name="semester" defaultValue={subject?.semester || state.study.academic.semester} /></label><label>Cor<input name="color" type="color" defaultValue={subject?.color || '#8b5cf6'} /></label></div><label>Descrição<textarea name="description" placeholder="Objetivo, ementa ou observações">{subject?.description}</textarea></label></>}
    {editor.kind === 'period' && <><label>Nome do horário<input name="label" required placeholder="Ex.: 1º horário" defaultValue={period?.label} /></label><div className="field-row"><label>Início<input name="startTime" type="time" required defaultValue={period?.startTime || '18:30'} /></label><label>Fim<input name="endTime" type="time" required defaultValue={period?.endTime || '20:10'} /></label></div></>}
    {editor.kind === 'class' && <><label>Matéria<SubjectSelect state={state} name="subjectId" value={classItem?.subjectId || String(defaults.subjectId ?? '')} /></label><div className="field-row"><label>Dia da semana<select name="weekday" defaultValue={classItem?.weekday ?? defaults.weekday ?? 1}>{weekDays.map(day => <option value={day.value} key={day.value}>{day.label}</option>)}</select></label><label>Sala<input name="room" defaultValue={classItem?.room} placeholder="Opcional" /></label></div><div className="field-row"><label>Começa<input name="startTime" type="time" required defaultValue={classItem?.startTime || String(defaults.startTime ?? '18:30')} /></label><label>Termina<input name="endTime" type="time" required defaultValue={classItem?.endTime || String(defaults.endTime ?? '20:10')} /></label></div><label>Professor(a)<input name="professor" defaultValue={classItem?.professor} placeholder="Se diferente do cadastro da matéria" /></label><label>Observações<textarea name="notes">{classItem?.notes}</textarea></label></>}
    {editor.kind === 'assessment' && <><div className="field-row"><label>Matéria<SubjectSelect state={state} name="subjectId" value={assessment?.subjectId || String(defaults.subjectId ?? '')} /></label><label>Tipo<select name="kind" defaultValue={assessment?.kind || 'Prova'}><option>Prova</option><option>Trabalho</option><option>Projeto</option><option>Seminário</option><option>Atividade</option></select></label></div><label>Título<input name="title" required placeholder="Ex.: Prova AP1" defaultValue={assessment?.title} /></label><div className="field-row"><label>Data<input type="date" name="date" required defaultValue={assessment?.date || localDateKey()} /></label><label>Horário<input type="time" name="time" defaultValue={assessment?.time || '18:30'} /></label></div><label>Conteúdo<textarea name="content" placeholder="Assuntos que serão cobrados">{assessment?.content}</textarea></label><div className="field-row three"><label>Peso<input type="number" name="weight" min="0" step="0.1" defaultValue={assessment?.weight || 1} /></label><label>Nota<input type="number" name="grade" min="0" step="0.1" defaultValue={assessment?.grade ?? ''} /></label><label>Nota máxima<input type="number" name="maxGrade" min="0.1" step="0.1" defaultValue={assessment?.maxGrade || 10} /></label></div><div className="field-row"><label>Lembrar antes<select name="reminderDays" defaultValue={assessment?.reminderDays ?? 7}><option value="1">1 dia</option><option value="3">3 dias</option><option value="7">7 dias</option><option value="14">14 dias</option><option value="30">30 dias</option></select></label><label>Status<select name="status" defaultValue={assessment?.status || 'scheduled'}><option value="scheduled">Agendada</option><option value="studying">Estudando</option><option value="completed">Concluída</option></select></label></div><label>Observações<textarea name="notes">{assessment?.notes}</textarea></label></>}
    {editor.kind === 'note' && <><label>Matéria<SubjectSelect state={state} name="subjectId" value={note?.subjectId || String(defaults.subjectId ?? '')} /></label><label>Título<input name="title" required placeholder="Ex.: Normalização de banco de dados" defaultValue={note?.title} /></label><div className="studyx-note-editor"><div><button type="button" onClick={() => formatNote('**')}><strong>B</strong></button><button type="button" onClick={() => formatNote('_')}><em>I</em></button><button type="button" onClick={() => formatNote('## ', '')}>H2</button><button type="button" onClick={() => formatNote('- ', '')}>• Lista</button><button type="button" onClick={() => formatNote('> ', '')}>❝</button></div><textarea ref={noteTextRef} value={noteContent} onChange={event => setNoteContent(event.target.value)} placeholder="Escreva sua anotação..." /></div><label>Tags separadas por vírgula<input name="tags" defaultValue={note?.tags.join(', ')} placeholder="ex.: prova, revisão, importante" /></label><div className="studyx-upload"><label className={uploading ? 'loading' : ''}><Upload size={19} /><span>{uploading ? 'Enviando...' : 'Adicionar imagens'}</span><input type="file" accept="image/jpeg,image/png,image/webp,image/gif" multiple disabled={uploading} onChange={event => void uploadImages(event.target.files)} /></label><small>JPG, PNG, WEBP ou GIF · até 8 MB por imagem</small></div>{!!noteAttachments.length && <div className="studyx-upload-grid">{noteAttachments.map(image => <figure key={image.id}><img src={image.url} alt={image.name} /><figcaption>{image.name}</figcaption><button type="button" onClick={() => setNoteAttachments(items => items.filter(item => item.id !== image.id))}><X size={15} /></button></figure>)}</div>}</>}
    {editor.kind === 'deck' && <><label>Matéria<SubjectSelect state={state} name="subjectId" value={deck?.subjectId || String(defaults.subjectId ?? '')} /></label><label>Nome do baralho<input name="name" required placeholder="Ex.: Modelagem de dados" defaultValue={deck?.name} /></label><label>Descrição<textarea name="description">{deck?.description}</textarea></label><label>Cor<input type="color" name="color" defaultValue={deck?.color || '#8b5cf6'} /></label></>}
    {editor.kind === 'flashcard' && <><label>Matéria<SubjectSelect state={state} name="subjectId" value={flashcard?.subjectId || String(defaults.subjectId ?? '')} /></label><label>Baralho<select name="deckId" defaultValue={flashcard?.deckId || ''}><option value="">Sem baralho</option>{state.study.decks.map(item => <option value={item.id} key={item.id}>{item.name}</option>)}</select></label><label>Assunto<input name="topic" defaultValue={flashcard?.topic} placeholder="Ex.: SQL" /></label><label>Pergunta<textarea name="front" required placeholder="Digite a pergunta">{flashcard?.front}</textarea></label><label>Resposta<textarea name="back" required placeholder="Digite a resposta">{flashcard?.back}</textarea></label><label>Próxima revisão<input name="dueDate" type="date" defaultValue={flashcard?.dueDate || localDateKey()} /></label></>}
    {editor.kind === 'question' && <><label>Matéria<SubjectSelect state={state} name="subjectId" value={question?.subjectId || String(defaults.subjectId ?? '')} /></label><div className="field-row"><label>Assunto<input name="topic" defaultValue={question?.topic} /></label><label>Dificuldade<select name="difficulty" defaultValue={question?.difficulty || 'Média'}><option>Fácil</option><option>Média</option><option>Difícil</option></select></label></div><label>Enunciado<textarea name="prompt" required>{question?.prompt}</textarea></label><label>Resposta correta<textarea name="answer">{question?.answer}</textarea></label><label>Comentário / explicação<textarea name="explanation">{question?.explanation}</textarea></label><label>Fonte<input name="source" defaultValue={question?.source} placeholder="Lista, livro, professor..." /></label></>}
    {editor.kind === 'simulation' && <><label>Nome do simulado<input name="title" required defaultValue={simulation?.title} placeholder="Ex.: Revisão AP1" /></label><fieldset><legend>Matérias</legend><div className="studyx-checkboxes">{state.study.subjects.map(item => <label key={item.id}><input type="checkbox" name="subjectIds" value={item.id} defaultChecked={simulation?.subjectIds.includes(item.id)} /><span style={{ background: item.color }} />{item.name}</label>)}</div></fieldset><div className="field-row"><label>Quantidade de questões<input name="questionCount" type="number" min="1" required defaultValue={simulation?.questionCount || 20} /></label><label>Tempo em minutos<input name="durationMinutes" type="number" min="1" required defaultValue={simulation?.durationMinutes || 60} /></label></div></>}
    {editor.kind === 'task' && <><label>Matéria<SubjectSelect state={state} name="subjectId" value={task?.subjectId || String(defaults.subjectId ?? '')} /></label><label>Tarefa<input name="title" required defaultValue={task?.title} placeholder="Ex.: Revisar capítulo 3" /></label><div className="field-row"><label>Data<input type="date" name="date" required defaultValue={task?.date || localDateKey()} /></label><label>Prioridade<select name="priority" defaultValue={task?.priority || 'Média'}><option>Baixa</option><option>Média</option><option>Alta</option></select></label></div><div className="field-row"><label>Início<input type="time" name="startTime" defaultValue={task?.startTime || '19:00'} /></label><label>Fim<input type="time" name="endTime" defaultValue={task?.endTime || '20:00'} /></label></div></>}
    {editor.kind === 'session' && <><label>Matéria<SubjectSelect state={state} name="subjectId" value={session?.subjectId || String(defaults.subjectId ?? '')} /></label><div className="field-row"><label>Data<input type="date" name="date" required defaultValue={session?.date || localDateKey()} /></label><label>Duração em minutos<input type="number" name="durationMinutes" min="1" required defaultValue={session?.durationMinutes || 60} /></label></div><label>Assunto estudado<input name="topic" defaultValue={session?.topic} /></label><label>Observações<textarea name="notes">{session?.notes}</textarea></label></>}
  </div><footer>{canDelete ? <button className="studyx-delete-button" type="button" onClick={onDelete}><Trash2 size={17} /> Excluir</button> : <span />}<div><button className="cancel-button" type="button" onClick={onClose}>Cancelar</button><button className="modal-save studyx-save" type="submit" disabled={uploading}>Salvar</button></div></footer></form></div>;
}

function SubjectSelect({ state, name, value }: { state: AppState; name: string; value: string }) {
  return <select name={name} required defaultValue={value}><option value="" disabled>Selecione a matéria</option>{state.study.subjects.filter(item => !item.archived).map(item => <option value={item.id} key={item.id}>{item.name}</option>)}</select>;
}
