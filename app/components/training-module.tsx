'use client';

/* eslint-disable @next/next/no-img-element */

import {
  Activity,
  ArrowLeft,
  BarChart3,
  Bike,
  CalendarDays,
  Check,
  CheckCircle2,
  ChevronRight,
  CircleGauge,
  Clock3,
  Dumbbell,
  Edit3,
  Flame,
  Footprints,
  HeartPulse,
  History,
  ImageIcon,
  Library,
  Pause,
  Play,
  Plus,
  Ruler,
  Save,
  Scale,
  Sparkles,
  Square,
  TimerReset,
  Trash2,
  TrendingUp,
  Trophy,
  Upload,
  Waves,
  X,
  type LucideIcon,
} from 'lucide-react';
import {
  useEffect,
  useState,
  type Dispatch,
  type FormEvent,
  type SetStateAction,
} from 'react';
import {
  createDefaultSets,
  ensureToday,
  uid,
  type ActiveWorkoutSession,
  type AppState,
  type Exercise,
  type ExerciseLibraryItem,
  type ExerciseLog,
  type ProgressPhoto,
  type StudyAttachment,
  type Workout,
  type WorkoutSession,
  type WorkoutSet,
  type WorkoutSetKind,
} from '../lib/app-data';

type TrainingTab = 'today' | 'plans' | 'library' | 'history' | 'progress' | 'health';
type TrainingEditorKind = 'workout' | 'exercise' | 'library' | 'measurement' | 'cardio' | 'photo' | 'water';
type TrainingEditor = { kind: TrainingEditorKind; id?: string; workoutId?: string; defaults?: Record<string, string | number> };

type TrainingModuleProps = {
  state: AppState;
  setState: Dispatch<SetStateAction<AppState>>;
  openHome: () => void;
  notify: (message: string) => void;
};

const weekdayNames = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
const shortWeekdays = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB'];
const dateFormat = new Intl.DateTimeFormat('pt-BR', { day: '2-digit', month: 'short', year: 'numeric' });

const trainingTabs: { id: TrainingTab; label: string; icon: LucideIcon }[] = [
  { id: 'today', label: 'Hoje', icon: Activity },
  { id: 'plans', label: 'Treinos', icon: CalendarDays },
  { id: 'library', label: 'Exercícios', icon: Library },
  { id: 'history', label: 'Histórico', icon: History },
  { id: 'progress', label: 'Progresso', icon: TrendingUp },
  { id: 'health', label: 'Saúde', icon: HeartPulse },
];

const setKinds: WorkoutSetKind[] = ['Aquecimento', 'Preparatória', 'Trabalho', 'Falha', 'Drop set'];

function localDateKey(date = new Date()) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return year + '-' + month + '-' + day;
}

function formatDate(date: string) {
  return date ? dateFormat.format(new Date(date + 'T12:00:00')) : 'Sem data';
}

function durationLabel(seconds: number) {
  const safe = Math.max(0, Math.round(seconds));
  const hours = Math.floor(safe / 3600);
  const minutes = Math.floor((safe % 3600) / 60);
  const secs = safe % 60;
  return (hours ? String(hours).padStart(2, '0') + ':' : '') + String(minutes).padStart(2, '0') + ':' + String(secs).padStart(2, '0');
}

function compactDuration(seconds: number) {
  const minutes = Math.round(seconds / 60);
  return minutes >= 60 ? Math.floor(minutes / 60) + 'h ' + minutes % 60 + 'min' : minutes + ' min';
}

function updateTraining(setState: Dispatch<SetStateAction<AppState>>, updater: (training: AppState['training']) => AppState['training']) {
  setState(current => ({ ...current, training: updater(current.training) }));
}

function cloneExerciseLog(exercise: Exercise): ExerciseLog {
  return {
    exerciseId: exercise.id,
    name: exercise.name,
    muscleGroup: exercise.muscleGroup,
    sets: exercise.setDetails.map(set => ({ ...set, id: uid('performed-set'), actualReps: null, actualWeight: set.targetWeight, rpe: null, completed: false })),
    activeSeconds: 0,
    restSeconds: 0,
    finished: false,
  };
}

function elapsedDelta(session: ActiveWorkoutSession, now = Date.now()) {
  if (!session.modeStartedAt || session.timerMode === 'paused') return 0;
  return Math.max(0, Math.floor((now - new Date(session.modeStartedAt).getTime()) / 1000));
}

function displayLogTime(session: ActiveWorkoutSession, log: ExerciseLog, kind: 'exercise' | 'rest', now: number) {
  const base = kind === 'exercise' ? log.activeSeconds : log.restSeconds;
  return base + (session.currentExerciseId === log.exerciseId && session.timerMode === kind ? elapsedDelta(session, now) : 0);
}

function commitSessionDelta(session: ActiveWorkoutSession, now = Date.now()) {
  const delta = elapsedDelta(session, now);
  if (!delta || !session.currentExerciseId) return { ...session };
  return {
    ...session,
    exerciseLogs: session.exerciseLogs.map(log => log.exerciseId === session.currentExerciseId ? {
      ...log,
      activeSeconds: log.activeSeconds + (session.timerMode === 'exercise' ? delta : 0),
      restSeconds: log.restSeconds + (session.timerMode === 'rest' ? delta : 0),
    } : log),
  };
}

function sessionVolume(logs: ExerciseLog[]) {
  return logs.reduce((total, log) => total + log.sets.reduce((subtotal, set) => subtotal + (set.completed ? (set.actualWeight || set.targetWeight) * (set.actualReps ?? 0) : 0), 0), 0);
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

export function TrainingModule({ state, setState, openHome, notify }: TrainingModuleProps) {
  const [tab, setTab] = useState<TrainingTab>('today');
  const [editor, setEditor] = useState<TrainingEditor | null>(null);
  const [selectedWorkoutId, setSelectedWorkoutId] = useState(() => state.training.workouts.find(item => item.weekday === new Date().getDay())?.id ?? state.training.workouts[0]?.id ?? '');
  const [selectedHistoryId, setSelectedHistoryId] = useState('');
  const [seriesDraft, setSeriesDraft] = useState<WorkoutSet[]>([]);
  const [photoAttachment, setPhotoAttachment] = useState<StudyAttachment | null>(null);
  const [uploading, setUploading] = useState(false);
  const [now, setNow] = useState(0);
  const [librarySearch, setLibrarySearch] = useState('');
  const activeSession = state.training.activeSession;

  useEffect(() => {
    if (!activeSession || activeSession.timerMode === 'paused') return;
    const timer = window.setInterval(() => setNow(Date.now()), 1000);
    return () => window.clearInterval(timer);
  }, [activeSession]);

  const selectedWorkout = state.training.workouts.find(item => item.id === selectedWorkoutId) ?? state.training.workouts[0];
  const todayWorkout = state.training.workouts.find(item => item.weekday === new Date().getDay()) ?? selectedWorkout;
  const todayWater = state.training.waterEntries.filter(item => item.date === localDateKey()).reduce((sum, item) => sum + item.liters, 0);
  const streak = calculateStreak(state.training.completedDates);
  const selectedHistory = state.training.sessions.find(item => item.id === selectedHistoryId);
  const activeTotalExercise = activeSession?.exerciseLogs.reduce((sum, log) => sum + displayLogTime(activeSession, log, 'exercise', now), 0) ?? 0;
  const activeTotalRest = activeSession?.exerciseLogs.reduce((sum, log) => sum + displayLogTime(activeSession, log, 'rest', now), 0) ?? 0;
  const completedSets = activeSession?.exerciseLogs.reduce((sum, log) => sum + log.sets.filter(set => set.completed).length, 0) ?? 0;
  const totalSets = activeSession?.exerciseLogs.reduce((sum, log) => sum + log.sets.length, 0) ?? 0;

  function switchTab(next: TrainingTab) {
    setTab(next);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  function openEditor(kind: TrainingEditorKind, id?: string, workoutId?: string, defaults?: Record<string, string | number>) {
    setEditor({ kind, id, workoutId, defaults });
    if (kind === 'exercise') {
      const workout = state.training.workouts.find(item => item.id === workoutId);
      const exercise = workout?.exercises.find(item => item.id === id);
      setSeriesDraft(exercise?.setDetails.map(set => ({ ...set })) ?? createDefaultSets(3, '8–12', 0));
    }
    if (kind === 'photo') setPhotoAttachment(null);
  }

  function closeEditor() {
    setEditor(null);
    setSeriesDraft([]);
    setPhotoAttachment(null);
  }

  function startWorkout(workout: Workout) {
    if (activeSession && !window.confirm('Já existe um treino em andamento. Substituir pela nova sessão?')) return;
    const session: ActiveWorkoutSession = {
      id: uid('active-workout'),
      workoutId: workout.id,
      workoutName: workout.name,
      date: localDateKey(),
      startedAt: new Date().toISOString(),
      currentExerciseId: null,
      timerMode: 'paused',
      modeStartedAt: null,
      exerciseLogs: workout.exercises.map(cloneExerciseLog),
      notes: '',
    };
    updateTraining(setState, training => ({ ...training, activeSession: session }));
    setSelectedWorkoutId(workout.id);
    setTab('today');
    notify('Treino iniciado. Escolha o primeiro exercício.');
  }

  function switchTimer(exerciseId: string | null, mode: ActiveWorkoutSession['timerMode']) {
    updateTraining(setState, training => {
      if (!training.activeSession) return training;
      const committed = commitSessionDelta(training.activeSession);
      return {
        ...training,
        activeSession: {
          ...committed,
          currentExerciseId: exerciseId,
          timerMode: mode,
          modeStartedAt: mode === 'paused' ? null : new Date().toISOString(),
        },
      };
    });
  }

  function finishExercise(exerciseId: string) {
    updateTraining(setState, training => {
      if (!training.activeSession) return training;
      const committed = commitSessionDelta(training.activeSession);
      return {
        ...training,
        activeSession: {
          ...committed,
          currentExerciseId: committed.currentExerciseId === exerciseId ? null : committed.currentExerciseId,
          timerMode: committed.currentExerciseId === exerciseId ? 'paused' : committed.timerMode,
          modeStartedAt: committed.currentExerciseId === exerciseId ? null : committed.modeStartedAt,
          exerciseLogs: committed.exerciseLogs.map(log => log.exerciseId === exerciseId ? { ...log, finished: true } : log),
        },
      };
    });
    notify('Exercício finalizado. O tempo foi somado.');
  }

  function reopenExercise(exerciseId: string) {
    updateTraining(setState, training => training.activeSession ? {
      ...training,
      activeSession: { ...training.activeSession, exerciseLogs: training.activeSession.exerciseLogs.map(log => log.exerciseId === exerciseId ? { ...log, finished: false } : log) },
    } : training);
  }

  function updateActiveSet(exerciseId: string, setId: string, patch: Partial<WorkoutSet>) {
    updateTraining(setState, training => training.activeSession ? {
      ...training,
      activeSession: {
        ...training.activeSession,
        exerciseLogs: training.activeSession.exerciseLogs.map(log => log.exerciseId === exerciseId ? { ...log, sets: log.sets.map(set => set.id === setId ? { ...set, ...patch } : set) } : log),
      },
    } : training);
  }

  function completeSet(exerciseId: string, set: WorkoutSet) {
    const completing = !set.completed;
    updateActiveSet(exerciseId, set.id, { completed: completing });
    if (completing) switchTimer(exerciseId, 'rest');
  }

  function cancelActiveWorkout() {
    if (!window.confirm('Cancelar este treino em andamento? Os dados desta sessão não serão salvos.')) return;
    updateTraining(setState, training => ({ ...training, activeSession: null }));
    notify('Sessão cancelada.');
  }

  function finishWorkout() {
    updateTraining(setState, training => {
      if (!training.activeSession) return training;
      const committed = commitSessionDelta(training.activeSession);
      const totalExerciseSeconds = committed.exerciseLogs.reduce((sum, log) => sum + log.activeSeconds, 0);
      const totalRestSeconds = committed.exerciseLogs.reduce((sum, log) => sum + log.restSeconds, 0);
      const session: WorkoutSession = {
        id: committed.id,
        workoutId: committed.workoutId,
        workoutName: committed.workoutName,
        date: committed.date,
        startedAt: committed.startedAt,
        finishedAt: new Date().toISOString(),
        totalExerciseSeconds,
        totalRestSeconds,
        totalSeconds: totalExerciseSeconds + totalRestSeconds,
        totalVolume: sessionVolume(committed.exerciseLogs),
        exerciseLogs: committed.exerciseLogs,
        notes: committed.notes,
      };
      return {
        ...training,
        activeSession: null,
        sessions: [session, ...training.sessions],
        completedDates: ensureToday(training.completedDates),
      };
    });
    setTab('history');
    notify('Treino finalizado. Tempo e séries salvos no histórico.');
  }

  function updateActiveNotes(notes: string) {
    updateTraining(setState, training => training.activeSession ? { ...training, activeSession: { ...training.activeSession, notes } } : training);
  }

  function saveEditor(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!editor) return;
    const form = new FormData(event.currentTarget);
    const text = (name: string) => String(form.get(name) ?? '').trim();
    const number = (name: string) => Number(form.get(name) ?? 0);

    updateTraining(setState, training => {
      if (editor.kind === 'workout') {
        const previous = training.workouts.find(item => item.id === editor.id);
        const next: Workout = {
          id: editor.id ?? uid('workout'), name: text('name'), focus: text('focus'), weekday: number('weekday'),
          color: text('color') || '#ff7a3d', notes: text('notes'), exercises: previous?.exercises ?? [],
        };
        return { ...training, workouts: previous ? training.workouts.map(item => item.id === editor.id ? next : item) : [...training.workouts, next] };
      }
      if (editor.kind === 'exercise' && editor.workoutId) {
        const workout = training.workouts.find(item => item.id === editor.workoutId);
        const previous = workout?.exercises.find(item => item.id === editor.id);
        const next: Exercise = {
          id: editor.id ?? uid('exercise'), name: text('name'), muscleGroup: text('muscleGroup'), equipment: text('equipment'),
          notes: text('notes'), sets: seriesDraft.length, reps: seriesDraft[0]?.targetReps ?? '', weight: seriesDraft[0]?.targetWeight ?? 0,
          completed: false, setDetails: seriesDraft.map(set => ({ ...set, id: set.id || uid('set') })),
        };
        return {
          ...training,
          workouts: training.workouts.map(item => item.id === editor.workoutId ? {
            ...item,
            exercises: previous ? item.exercises.map(exercise => exercise.id === editor.id ? next : exercise) : [...item.exercises, next],
          } : item),
        };
      }
      if (editor.kind === 'library') {
        const next: ExerciseLibraryItem = { id: editor.id ?? uid('library'), name: text('name'), muscleGroup: text('muscleGroup'), equipment: text('equipment'), notes: text('notes') };
        return { ...training, exerciseLibrary: editor.id ? training.exerciseLibrary.map(item => item.id === editor.id ? next : item) : [...training.exerciseLibrary, next] };
      }
      if (editor.kind === 'measurement') {
        const next = {
          id: editor.id ?? uid('measurement'), date: text('date'), weight: number('weight'),
          bodyFat: text('bodyFat') ? number('bodyFat') : null, waist: text('waist') ? number('waist') : null,
          chest: text('chest') ? number('chest') : null, arm: text('arm') ? number('arm') : null,
          thigh: text('thigh') ? number('thigh') : null, notes: text('notes'),
        };
        return { ...training, measurements: editor.id ? training.measurements.map(item => item.id === editor.id ? next : item) : [next, ...training.measurements] };
      }
      if (editor.kind === 'cardio') {
        const next = {
          id: editor.id ?? uid('cardio'), date: text('date'), kind: text('kind'), durationMinutes: number('durationMinutes'),
          distanceKm: text('distanceKm') ? number('distanceKm') : null, calories: text('calories') ? number('calories') : null, notes: text('notes'),
        };
        return { ...training, cardioSessions: editor.id ? training.cardioSessions.map(item => item.id === editor.id ? next : item) : [next, ...training.cardioSessions] };
      }
      if (editor.kind === 'water') {
        const liters = number('liters');
        const next = { id: editor.id ?? uid('water'), date: text('date'), liters };
        return { ...training, waterEntries: editor.id ? training.waterEntries.map(item => item.id === editor.id ? next : item) : [next, ...training.waterEntries], waterLiters: text('date') === localDateKey() ? liters : training.waterLiters };
      }
      if (editor.kind === 'photo' && photoAttachment) {
        const next: ProgressPhoto = { id: editor.id ?? uid('progress-photo'), date: text('date'), label: text('label'), attachment: photoAttachment };
        return { ...training, progressPhotos: editor.id ? training.progressPhotos.map(item => item.id === editor.id ? next : item) : [next, ...training.progressPhotos] };
      }
      return training;
    });
    closeEditor();
    notify('Informação salva e sincronizada.');
  }

  async function uploadPhoto(file: File | undefined) {
    if (!file) return;
    setUploading(true);
    try {
      const form = new FormData();
      form.append('file', file);
      form.append('scope', 'training');
      const response = await fetch('/api/uploads', { method: 'POST', body: form });
      const result = await response.json() as { attachment?: StudyAttachment; error?: string };
      if (!response.ok || !result.attachment) throw new Error(result.error ?? 'Falha ao enviar foto.');
      setPhotoAttachment(result.attachment);
      notify('Foto pronta para salvar.');
    } catch (error) {
      notify(error instanceof Error ? error.message : 'Falha ao enviar foto.');
    } finally {
      setUploading(false);
    }
  }

  function removeWorkout(workout: Workout) {
    if (!window.confirm('Excluir ' + workout.name + ' e sua estrutura de exercícios? O histórico será preservado.')) return;
    updateTraining(setState, training => ({ ...training, workouts: training.workouts.filter(item => item.id !== workout.id) }));
    setSelectedWorkoutId(state.training.workouts.find(item => item.id !== workout.id)?.id ?? '');
    notify('Treino removido.');
  }

  function removeExercise(workoutId: string, exerciseId: string) {
    if (!window.confirm('Excluir este exercício do treino?')) return;
    updateTraining(setState, training => ({ ...training, workouts: training.workouts.map(workout => workout.id === workoutId ? { ...workout, exercises: workout.exercises.filter(item => item.id !== exerciseId) } : workout) }));
  }

  function addLibraryToWorkout(item: ExerciseLibraryItem, workoutId: string) {
    openEditor('exercise', undefined, workoutId, { name: item.name, muscleGroup: item.muscleGroup, equipment: item.equipment, notes: item.notes });
  }

  function quickWater(amount: number) {
    const todayEntries = state.training.waterEntries.filter(item => item.date === localDateKey());
    const next = Math.max(0, todayEntries.reduce((sum, item) => sum + item.liters, 0) + amount);
    updateTraining(setState, training => ({ ...training, waterEntries: [...training.waterEntries.filter(item => item.date !== localDateKey()), { id: todayEntries[0]?.id ?? uid('water'), date: localDateKey(), liters: next }], waterLiters: next }));
  }

  return (
    <div className="module-view trainingx-view">
      <header className="trainingx-heading">
        <div><button className="back-button" onClick={openHome}><ArrowLeft size={20} /></button><span><small>Corpo em movimento</small><h1>Treinos</h1><p>Séries precisas, tempo real e evolução registrada.</p></span></div>
        <aside>{activeSession ? <span className="trainingx-live"><i /> TREINO EM ANDAMENTO</span> : <button className="training-primary" onClick={() => todayWorkout && startWorkout(todayWorkout)} disabled={!todayWorkout}><Play size={18} /> Iniciar treino</button>}</aside>
      </header>

      <nav className="trainingx-tabs">
        {trainingTabs.map(item => { const Icon = item.icon; return <button key={item.id} className={tab === item.id ? 'active' : ''} onClick={() => switchTab(item.id)}><Icon size={18} /><span>{item.label}</span></button>; })}
      </nav>

      {tab === 'today' && (
        activeSession ? (
          <div className="trainingx-stack">
            <section className="trainingx-session-hero">
              <div><span className="trainingx-kicker"><Flame size={15} /> SESSÃO ATIVA</span><h2>{activeSession.workoutName}</h2><p>{completedSets} de {totalSets} séries concluídas · {activeSession.exerciseLogs.filter(item => item.finished).length} de {activeSession.exerciseLogs.length} exercícios finalizados</p></div>
              <div className="trainingx-total-time"><small>TEMPO TOTAL</small><strong>{durationLabel(activeTotalExercise + activeTotalRest)}</strong><span><em>{durationLabel(activeTotalExercise)} execução</em><em>{durationLabel(activeTotalRest)} descanso</em></span></div>
              <div className="trainingx-session-progress"><span style={{ width: (totalSets ? completedSets / totalSets * 100 : 0) + '%' }} /></div>
            </section>

            <section className="trainingx-active-grid">
              <div className="trainingx-exercise-stack">
                {activeSession.exerciseLogs.map((log, index) => {
                  const active = activeSession.currentExerciseId === log.exerciseId;
                  return <article key={log.exerciseId} className={'trainingx-active-exercise ' + (active ? 'active ' : '') + (log.finished ? 'finished' : '')}>
                    <header onClick={() => !log.finished && switchTimer(log.exerciseId, active && activeSession.timerMode !== 'paused' ? 'paused' : 'exercise')}>
                      <span className="trainingx-exercise-number">{log.finished ? <Check size={19} /> : String(index + 1).padStart(2, '0')}</span>
                      <div><small>{log.muscleGroup || 'EXERCÍCIO'}</small><h2>{log.name}</h2><p>{log.sets.filter(set => set.completed).length}/{log.sets.length} séries · {durationLabel(displayLogTime(activeSession, log, 'exercise', now))} ativo · {durationLabel(displayLogTime(activeSession, log, 'rest', now))} descanso</p></div>
                      <span className="trainingx-exercise-action">{log.finished ? 'Finalizado' : active ? activeSession.timerMode === 'paused' ? 'Continuar' : activeSession.timerMode === 'rest' ? 'Descansando' : 'Cronometrando' : 'Abrir'} <ChevronRight size={17} /></span>
                    </header>
                    {active && !log.finished && <div className="trainingx-live-exercise">
                      <div className={'trainingx-exercise-clock ' + activeSession.timerMode}><small>{activeSession.timerMode === 'rest' ? 'DESCANSO' : activeSession.timerMode === 'paused' ? 'PAUSADO' : 'TEMPO DO EXERCÍCIO'}</small><strong>{durationLabel(activeSession.timerMode === 'rest' ? displayLogTime(activeSession, log, 'rest', now) : displayLogTime(activeSession, log, 'exercise', now))}</strong><div><button onClick={() => switchTimer(log.exerciseId, activeSession.timerMode === 'paused' ? 'exercise' : 'paused')}>{activeSession.timerMode === 'paused' ? <Play size={18} /> : <Pause size={18} />}{activeSession.timerMode === 'paused' ? 'Continuar' : 'Pausar'}</button><button onClick={() => switchTimer(log.exerciseId, activeSession.timerMode === 'rest' ? 'exercise' : 'rest')}><TimerReset size={18} />{activeSession.timerMode === 'rest' ? 'Próxima série' : 'Descanso'}</button></div></div>
                      <div className="trainingx-set-table"><div className="trainingx-set-head"><span>SÉRIE</span><span>TIPO</span><span>CARGA</span><span>REPS</span><span>RPE</span><span>OK</span></div>{log.sets.map((set, setIndex) => <div className={'trainingx-set-row ' + (set.completed ? 'done' : '')} key={set.id}><strong>{setIndex + 1}</strong><span className={'kind ' + set.kind.toLowerCase().replace(' ', '-')}><em>{set.kind}</em>{set.toFailure && <b>FALHA</b>}</span><label><input type="number" min="0" step="0.5" value={set.actualWeight} onChange={event => updateActiveSet(log.exerciseId, set.id, { actualWeight: Number(event.target.value) })} /><small>kg</small></label><label><input type="number" min="0" value={set.actualReps ?? ''} placeholder={set.targetReps} onChange={event => updateActiveSet(log.exerciseId, set.id, { actualReps: event.target.value ? Number(event.target.value) : null })} /></label><label><input type="number" min="1" max="10" step=".5" value={set.rpe ?? ''} placeholder="—" onChange={event => updateActiveSet(log.exerciseId, set.id, { rpe: event.target.value ? Number(event.target.value) : null })} /></label><button onClick={() => completeSet(log.exerciseId, set)}>{set.completed ? <Check size={17} /> : <Square size={16} />}</button></div>)}</div>
                      <footer><span><Clock3 size={16} /> Descanso sugerido: {log.sets.find(set => !set.completed)?.restSeconds ?? state.training.defaultRestSeconds}s</span><button onClick={() => finishExercise(log.exerciseId)}><CheckCircle2 size={18} /> Finalizar exercício</button></footer>
                    </div>}
                    {log.finished && <div className="trainingx-finished-strip"><CheckCircle2 size={17} /><span>{log.sets.filter(set => set.completed).length} séries · {compactDuration(log.activeSeconds)} execução + {compactDuration(log.restSeconds)} descanso</span><button onClick={() => reopenExercise(log.exerciseId)}>Reabrir</button></div>}
                  </article>;
                })}
              </div>
              <aside className="trainingx-session-side">
                <article><span className="trainingx-side-icon"><CircleGauge size={21} /></span><h2>Resumo ao vivo</h2><div><span><small>Execução</small><strong>{durationLabel(activeTotalExercise)}</strong></span><span><small>Descansos</small><strong>{durationLabel(activeTotalRest)}</strong></span><span><small>Volume</small><strong>{Math.round(sessionVolume(activeSession.exerciseLogs)).toLocaleString('pt-BR')} kg</strong></span></div></article>
                <article><h2>Notas do treino</h2><textarea value={activeSession.notes} onChange={event => updateActiveNotes(event.target.value)} placeholder="Como você se sentiu hoje?" /></article>
                <button className="trainingx-finish-workout" onClick={finishWorkout}><Trophy size={19} /> Finalizar e salvar treino</button>
                <button className="trainingx-cancel-workout" onClick={cancelActiveWorkout}><Trash2 size={17} /> Cancelar sessão</button>
              </aside>
            </section>
          </div>
        ) : (
          <div className="trainingx-stack">
            <section className="trainingx-hero">
              <div><span className="trainingx-kicker"><Sparkles size={15} /> TREINO DO DIA</span><h2>{todayWorkout?.name ?? 'Dia livre'}</h2><p>{todayWorkout ? todayWorkout.focus + ' · ' + todayWorkout.exercises.length + ' exercícios preparados' : 'Escolha um treino do seu plano semanal.'}</p><div><button onClick={() => todayWorkout && startWorkout(todayWorkout)} disabled={!todayWorkout}><Play size={19} /> Começar treino</button><button onClick={() => switchTab('plans')}><CalendarDays size={18} /> Ver planejamento</button></div></div><span className="trainingx-hero-mark"><Dumbbell size={54} /></span>
            </section>
            <section className="trainingx-stats"><article><span><Flame size={21} /></span><div><small>Sequência</small><strong>{streak} dias</strong><em>continue no ritmo</em></div></article><article><span><History size={21} /></span><div><small>Último treino</small><strong>{state.training.sessions[0]?.workoutName ?? 'Nenhum'}</strong><em>{state.training.sessions[0] ? formatDate(state.training.sessions[0].date) : 'comece hoje'}</em></div></article><article><span><TrendingUp size={21} /></span><div><small>Volume recente</small><strong>{Math.round(state.training.sessions[0]?.totalVolume ?? 0).toLocaleString('pt-BR')} kg</strong><em>na última sessão</em></div></article><article><span><Waves size={21} /></span><div><small>Água hoje</small><strong>{todayWater.toFixed(2)} L</strong><em>meta de {state.training.waterGoal} L</em></div></article></section>
            <section className="trainingx-dashboard-grid"><article className="trainingx-panel"><div className="trainingx-section-head"><div><small>SEMANA</small><h2>Planejamento de treinos</h2></div><button onClick={() => switchTab('plans')}>Editar <ChevronRight size={16} /></button></div><div className="trainingx-week">{[1,2,3,4,5,6,0].map(day => { const workout = state.training.workouts.find(item => item.weekday === day); return <button key={day} className={day === new Date().getDay() ? 'today' : ''} onClick={() => workout && startWorkout(workout)}><span>{shortWeekdays[day]}</span><i style={{ background: workout?.color }} />{workout ? <><strong>{workout.name}</strong><small>{workout.focus}</small></> : <><strong>Descanso</strong><small>Recuperação</small></>}</button>; })}</div></article><article className="trainingx-panel trainingx-water"><div className="trainingx-section-head"><div><small>HIDRATAÇÃO</small><h2>Meta diária</h2></div><Waves size={21} /></div><div className="trainingx-water-ring" style={{ '--water-progress': Math.min(100, todayWater / Math.max(.1, state.training.waterGoal) * 100) + '%' } as React.CSSProperties}><strong>{todayWater.toFixed(2)}L</strong><small>de {state.training.waterGoal}L</small></div><div><button onClick={() => quickWater(-.25)}>− 250ml</button><button onClick={() => quickWater(.25)}>+ 250ml</button></div></article></section>
          </div>
        )
      )}

      {tab === 'plans' && <div className="trainingx-stack"><TrainingIntro eyebrow="Planejamento semanal" title="Seus treinos" text="Monte cada dia com exercícios e séries independentes." actions={<button className="training-primary" onClick={() => openEditor('workout')}><Plus size={18} /> Novo treino</button>} /><section className="trainingx-workout-tabs">{state.training.workouts.map(workout => <button key={workout.id} className={selectedWorkout?.id === workout.id ? 'active' : ''} onClick={() => setSelectedWorkoutId(workout.id)} style={{ '--training-color': workout.color } as React.CSSProperties}><i /><strong>{workout.name}</strong><small>{weekdayNames[workout.weekday]} · {workout.focus}</small></button>)}</section>{selectedWorkout ? <section className="trainingx-plan-detail" style={{ '--training-color': selectedWorkout.color } as React.CSSProperties}><header><div><span><Dumbbell size={27} /></span><div><small>{weekdayNames[selectedWorkout.weekday].toUpperCase()}</small><h2>{selectedWorkout.name}</h2><p>{selectedWorkout.focus} · {selectedWorkout.exercises.length} exercícios</p></div></div><aside><button onClick={() => openEditor('workout', selectedWorkout.id)}><Edit3 size={17} /> Editar</button><button onClick={() => startWorkout(selectedWorkout)}><Play size={17} /> Iniciar</button><button className="danger" onClick={() => removeWorkout(selectedWorkout)}><Trash2 size={17} /></button></aside></header><div className="trainingx-template-exercises">{selectedWorkout.exercises.map((exercise, index) => <article key={exercise.id}><span>{String(index + 1).padStart(2, '0')}</span><div><small>{exercise.muscleGroup || 'GRUPO NÃO INFORMADO'}</small><h3>{exercise.name}</h3><p>{exercise.equipment || 'Equipamento livre'} · {exercise.setDetails.length} séries</p></div><div className="trainingx-series-preview">{exercise.setDetails.map((set, setIndex) => <span key={set.id} className={set.kind.toLowerCase().replace(' ', '-')}><strong>{setIndex + 1}</strong><small>{set.kind}</small><em>{set.targetWeight || '—'}kg × {set.targetReps}{set.toFailure ? ' · falha' : ''}</em></span>)}</div><aside><button onClick={() => openEditor('exercise', exercise.id, selectedWorkout.id)}><Edit3 size={16} /></button><button className="danger" onClick={() => removeExercise(selectedWorkout.id, exercise.id)}><Trash2 size={16} /></button></aside></article>)}</div><footer><button onClick={() => openEditor('exercise', undefined, selectedWorkout.id)}><Plus size={18} /> Adicionar exercício</button><button onClick={() => switchTab('library')}><Library size={18} /> Abrir biblioteca</button></footer></section> : <TrainingEmpty icon={<Dumbbell size={34} />} title="Crie seu primeiro treino" text="Defina o dia e depois adicione exercícios com séries personalizadas." action="Novo treino" onAction={() => openEditor('workout')} />}</div>}

      {tab === 'library' && <div className="trainingx-stack"><TrainingIntro eyebrow="Biblioteca" title="Exercícios" text="Mantenha sua lista pessoal e adicione qualquer exercício a um treino." actions={<button className="training-primary" onClick={() => openEditor('library')}><Plus size={18} /> Novo exercício</button>} /><div className="trainingx-search"><Library size={18} /><input value={librarySearch} onChange={event => setLibrarySearch(event.target.value)} placeholder="Buscar exercício ou grupo muscular..." /></div><section className="trainingx-library-grid">{state.training.exerciseLibrary.filter(item => (item.name + ' ' + item.muscleGroup).toLowerCase().includes(librarySearch.toLowerCase())).map(item => <article key={item.id}><span><Dumbbell size={23} /></span><div><small>{item.muscleGroup || 'GERAL'}</small><h2>{item.name}</h2><p>{item.equipment || 'Sem equipamento específico'}</p></div><button onClick={() => openEditor('library', item.id)}><Edit3 size={16} /></button><footer><select defaultValue={selectedWorkout?.id}><option value="">Escolha o treino</option>{state.training.workouts.map(workout => <option value={workout.id} key={workout.id}>{workout.name}</option>)}</select><button onClick={event => { const select = event.currentTarget.previousElementSibling as HTMLSelectElement | null; if (select?.value) addLibraryToWorkout(item, select.value); else notify('Escolha o treino.'); }}><Plus size={16} /> Adicionar</button></footer></article>)}{!state.training.exerciseLibrary.length && <TrainingEmpty icon={<Library size={34} />} title="Sua biblioteca está vazia" text="Cadastre exercícios para reutilizá-los em qualquer treino." action="Cadastrar exercício" onAction={() => openEditor('library')} />}</section></div>}

      {tab === 'history' && <div className="trainingx-stack"><TrainingIntro eyebrow="Registro completo" title="Histórico de treinos" text="Tempo de execução, descansos, volume e desempenho de cada série." />{selectedHistory ? <HistoryDetail session={selectedHistory} onBack={() => setSelectedHistoryId('')} /> : <section className="trainingx-history-list">{state.training.sessions.map(session => <button key={session.id} onClick={() => setSelectedHistoryId(session.id)}><span><strong>{new Date(session.date + 'T12:00:00').getDate()}</strong><small>{new Intl.DateTimeFormat('pt-BR', { month: 'short' }).format(new Date(session.date + 'T12:00:00'))}</small></span><div><small>TREINO CONCLUÍDO</small><h2>{session.workoutName}</h2><p>{session.exerciseLogs.length} exercícios · {session.exerciseLogs.reduce((sum, log) => sum + log.sets.filter(set => set.completed).length, 0)} séries</p></div><div><span><Clock3 size={16} /> {compactDuration(session.totalSeconds)}</span><span><Dumbbell size={16} /> {Math.round(session.totalVolume).toLocaleString('pt-BR')} kg</span></div><ChevronRight size={19} /></button>)}{!state.training.sessions.length && <TrainingEmpty icon={<History size={34} />} title="Nenhum treino concluído" text="Quando você finalizar uma sessão, o relatório completo aparecerá aqui." action="Ir para hoje" onAction={() => switchTab('today')} />}</section>}</div>}

      {tab === 'progress' && <div className="trainingx-stack"><TrainingIntro eyebrow="Evolução" title="Progresso" text="Acompanhe frequência, volume, recordes de carga e medidas." actions={<button className="secondary-button" onClick={() => openEditor('measurement')}><Plus size={17} /> Nova medida</button>} /><section className="trainingx-stats progress"><article><span><Trophy size={21} /></span><div><small>Treinos concluídos</small><strong>{state.training.sessions.length}</strong><em>histórico total</em></div></article><article><span><Flame size={21} /></span><div><small>Sequência atual</small><strong>{streak} dias</strong><em>consistência</em></div></article><article><span><Dumbbell size={21} /></span><div><small>Volume acumulado</small><strong>{Math.round(state.training.sessions.reduce((sum, item) => sum + item.totalVolume, 0)).toLocaleString('pt-BR')} kg</strong><em>todas as sessões</em></div></article><article><span><Clock3 size={21} /></span><div><small>Tempo total</small><strong>{compactDuration(state.training.sessions.reduce((sum, item) => sum + item.totalSeconds, 0))}</strong><em>execução + descanso</em></div></article></section><section className="trainingx-progress-grid"><article className="trainingx-panel"><div className="trainingx-section-head"><div><small>VOLUME</small><h2>Últimas sessões</h2></div><BarChart3 size={20} /></div><VolumeChart sessions={state.training.sessions.slice(0, 8).reverse()} /></article><article className="trainingx-panel"><div className="trainingx-section-head"><div><small>RECORDES</small><h2>Maiores cargas</h2></div><Trophy size={20} /></div><PersonalRecords sessions={state.training.sessions} /></article></section><section className="trainingx-panel"><div className="trainingx-section-head"><div><small>MEDIDAS CORPORAIS</small><h2>Evolução física</h2></div><button onClick={() => openEditor('measurement')}><Plus size={17} /> Registrar</button></div><div className="trainingx-measurements">{state.training.measurements.slice().sort((a,b) => b.date.localeCompare(a.date)).map(item => <button key={item.id} onClick={() => openEditor('measurement', item.id)}><span><Scale size={19} /></span><div><strong>{item.weight} kg</strong><small>{formatDate(item.date)}</small></div><em>{item.bodyFat !== null ? item.bodyFat + '% gordura' : 'Composição não informada'}</em><ChevronRight size={16} /></button>)}{!state.training.measurements.length && <TrainingEmpty icon={<Ruler size={30} />} title="Sem medidas registradas" text="Adicione peso e circunferências para acompanhar sua evolução." action="Nova medida" onAction={() => openEditor('measurement')} />}</div></section></div>}

      {tab === 'health' && <div className="trainingx-stack"><TrainingIntro eyebrow="Recuperação e saúde" title="Corpo completo" text="Hidratação, cardio, medidas e fotos de evolução." actions={<><button className="secondary-button" onClick={() => openEditor('cardio')}><Bike size={17} /> Cardio</button><button className="training-primary" onClick={() => openEditor('photo')}><ImageIcon size={17} /> Foto de progresso</button></>} /><section className="trainingx-health-grid"><article className="trainingx-panel trainingx-water-card"><div className="trainingx-section-head"><div><small>HIDRATAÇÃO DE HOJE</small><h2>{todayWater.toFixed(2)} de {state.training.waterGoal} litros</h2></div><Waves size={22} /></div><div className="trainingx-water-track"><span style={{ width: Math.min(100, todayWater / Math.max(.1, state.training.waterGoal) * 100) + '%' }} /></div><div><button onClick={() => quickWater(-.25)}>− 250 ml</button><button onClick={() => quickWater(.25)}>+ 250 ml</button><button onClick={() => openEditor('water')}>Editar</button></div><label>Meta diária <strong>{state.training.waterGoal.toFixed(1)} L</strong><input type="range" min="1" max="6" step=".25" value={state.training.waterGoal} onChange={event => updateTraining(setState, training => ({ ...training, waterGoal: Number(event.target.value) }))} /></label></article><article className="trainingx-panel"><div className="trainingx-section-head"><div><small>CARDIO</small><h2>Sessões recentes</h2></div><button onClick={() => openEditor('cardio')}><Plus size={17} /></button></div><div className="trainingx-cardio-list">{state.training.cardioSessions.slice(0,5).map(item => <button key={item.id} onClick={() => openEditor('cardio', item.id)}><span>{item.kind.toLowerCase().includes('corr') ? <Footprints size={18} /> : <Bike size={18} />}</span><div><strong>{item.kind}</strong><small>{formatDate(item.date)} · {item.distanceKm ? item.distanceKm + ' km' : 'distância livre'}</small></div><b>{item.durationMinutes} min</b></button>)}{!state.training.cardioSessions.length && <TrainingEmpty icon={<Bike size={28} />} title="Sem cardio registrado" text="Adicione corrida, caminhada, bike ou outra atividade." action="Registrar" onAction={() => openEditor('cardio')} />}</div></article></section><section className="trainingx-panel"><div className="trainingx-section-head"><div><small>FOTOS DE EVOLUÇÃO</small><h2>Comparação visual</h2></div><button onClick={() => openEditor('photo')}><Plus size={17} /> Adicionar</button></div><div className="trainingx-photo-grid">{state.training.progressPhotos.map(photo => <figure key={photo.id}><img src={photo.attachment.url} alt={photo.label || 'Foto de progresso'} /><figcaption><strong>{photo.label || 'Progresso'}</strong><small>{formatDate(photo.date)}</small></figcaption><button onClick={() => { if (!window.confirm('Excluir esta foto?')) return; void fetch('/api/uploads?key=' + encodeURIComponent(photo.attachment.storageKey), { method: 'DELETE' }); updateTraining(setState, training => ({ ...training, progressPhotos: training.progressPhotos.filter(item => item.id !== photo.id) })); }}><Trash2 size={16} /></button></figure>)}{!state.training.progressPhotos.length && <TrainingEmpty icon={<ImageIcon size={32} />} title="Sem fotos de evolução" text="Registre sua evolução com imagens protegidas pela sua conta." action="Adicionar foto" onAction={() => openEditor('photo')} />}</div></section></div>}

      {editor && <TrainingEditorModal editor={editor} state={state} seriesDraft={seriesDraft} setSeriesDraft={setSeriesDraft} photoAttachment={photoAttachment} uploading={uploading} uploadPhoto={uploadPhoto} onClose={closeEditor} onSubmit={saveEditor} onDelete={() => deleteEditorItem(editor, state, setState, closeEditor, notify)} />}
    </div>
  );
}

function TrainingIntro({ eyebrow, title, text, actions }: { eyebrow: string; title: string; text: string; actions?: React.ReactNode }) {
  return <header className="trainingx-intro"><div><small>{eyebrow}</small><h2>{title}</h2><p>{text}</p></div>{actions && <aside>{actions}</aside>}</header>;
}

function TrainingEmpty({ icon, title, text, action, onAction }: { icon: React.ReactNode; title: string; text: string; action: string; onAction: () => void }) {
  return <div className="trainingx-empty"><span>{icon}</span><h2>{title}</h2><p>{text}</p><button onClick={onAction}><Plus size={17} /> {action}</button></div>;
}

function HistoryDetail({ session, onBack }: { session: WorkoutSession; onBack: () => void }) {
  return <section className="trainingx-history-detail"><header><button onClick={onBack}><ArrowLeft size={18} /> Histórico</button><span>CONCLUÍDO EM {formatDate(session.date).toUpperCase()}</span><h2>{session.workoutName}</h2><div><span><Clock3 size={17} /><strong>{compactDuration(session.totalExerciseSeconds)}</strong><small>execução</small></span><span><TimerReset size={17} /><strong>{compactDuration(session.totalRestSeconds)}</strong><small>descanso</small></span><span><Dumbbell size={17} /><strong>{Math.round(session.totalVolume).toLocaleString('pt-BR')} kg</strong><small>volume</small></span></div></header><div>{session.exerciseLogs.map((log, index) => <article key={log.exerciseId}><div><span>{String(index + 1).padStart(2, '0')}</span><div><small>{log.muscleGroup || 'EXERCÍCIO'}</small><h3>{log.name}</h3><p>{compactDuration(log.activeSeconds)} execução · {compactDuration(log.restSeconds)} descanso</p></div></div><div className="trainingx-history-sets">{log.sets.map((set, setIndex) => <span key={set.id} className={set.completed ? 'done' : ''}><strong>{setIndex + 1}</strong><small>{set.kind}</small><b>{set.actualWeight || set.targetWeight} kg × {set.actualReps ?? '—'}</b><em>{set.rpe ? 'RPE ' + set.rpe : set.toFailure ? 'Falha' : ''}</em></span>)}</div></article>)}</div>{session.notes && <footer><strong>Notas</strong><p>{session.notes}</p></footer>}</section>;
}

function VolumeChart({ sessions }: { sessions: WorkoutSession[] }) {
  const max = Math.max(1, ...sessions.map(item => item.totalVolume));
  return <div className="trainingx-volume-chart">{sessions.map(item => <div key={item.id}><span title={Math.round(item.totalVolume) + ' kg'} style={{ height: Math.max(5, item.totalVolume / max * 100) + '%' }} /><small>{new Date(item.date + 'T12:00:00').getDate()}/{new Date(item.date + 'T12:00:00').getMonth() + 1}</small></div>)}{!sessions.length && <TrainingEmpty icon={<BarChart3 size={28} />} title="Sem volume ainda" text="Finalize treinos para alimentar o gráfico." action="Tudo certo" onAction={() => undefined} />}</div>;
}

function PersonalRecords({ sessions }: { sessions: WorkoutSession[] }) {
  const records = new Map<string, { name: string; weight: number; reps: number }>();
  sessions.forEach(session => session.exerciseLogs.forEach(log => log.sets.forEach(set => {
    const weight = set.actualWeight || set.targetWeight;
    const current = records.get(log.name);
    if (set.completed && (!current || weight > current.weight)) records.set(log.name, { name: log.name, weight, reps: set.actualReps ?? 0 });
  })));
  return <div className="trainingx-records">{Array.from(records.values()).sort((a,b) => b.weight - a.weight).slice(0,6).map((item, index) => <span key={item.name}><i>{index + 1}</i><div><strong>{item.name}</strong><small>{item.reps} repetições</small></div><b>{item.weight} kg</b></span>)}{!records.size && <TrainingEmpty icon={<Trophy size={28} />} title="Sem recordes ainda" text="Conclua séries com carga para criar seus recordes." action="Entendi" onAction={() => undefined} />}</div>;
}

function deleteEditorItem(editor: TrainingEditor, state: AppState, setState: Dispatch<SetStateAction<AppState>>, close: () => void, notify: (message: string) => void) {
  if (!editor.id || !window.confirm('Excluir este registro?')) return;
  updateTraining(setState, training => {
    if (editor.kind === 'library') return { ...training, exerciseLibrary: training.exerciseLibrary.filter(item => item.id !== editor.id) };
    if (editor.kind === 'measurement') return { ...training, measurements: training.measurements.filter(item => item.id !== editor.id) };
    if (editor.kind === 'cardio') return { ...training, cardioSessions: training.cardioSessions.filter(item => item.id !== editor.id) };
    if (editor.kind === 'water') return { ...training, waterEntries: training.waterEntries.filter(item => item.id !== editor.id) };
    return training;
  });
  void state;
  close();
  notify('Registro excluído.');
}

type TrainingEditorModalProps = {
  editor: TrainingEditor;
  state: AppState;
  seriesDraft: WorkoutSet[];
  setSeriesDraft: Dispatch<SetStateAction<WorkoutSet[]>>;
  photoAttachment: StudyAttachment | null;
  uploading: boolean;
  uploadPhoto: (file: File | undefined) => Promise<void>;
  onClose: () => void;
  onSubmit: (event: FormEvent<HTMLFormElement>) => void;
  onDelete: () => void;
};

function TrainingEditorModal({ editor, state, seriesDraft, setSeriesDraft, photoAttachment, uploading, uploadPhoto, onClose, onSubmit, onDelete }: TrainingEditorModalProps) {
  const workout = state.training.workouts.find(item => item.id === editor.id);
  const exercise = state.training.workouts.find(item => item.id === editor.workoutId)?.exercises.find(item => item.id === editor.id);
  const library = state.training.exerciseLibrary.find(item => item.id === editor.id);
  const measurement = state.training.measurements.find(item => item.id === editor.id);
  const cardio = state.training.cardioSessions.find(item => item.id === editor.id);
  const water = state.training.waterEntries.find(item => item.id === editor.id);
  const defaults = editor.defaults ?? {};
  const titles: Record<TrainingEditorKind, string> = { workout: editor.id ? 'Editar treino' : 'Novo treino', exercise: editor.id ? 'Editar exercício e séries' : 'Adicionar exercício', library: editor.id ? 'Editar exercício' : 'Novo exercício da biblioteca', measurement: editor.id ? 'Editar medidas' : 'Registrar medidas', cardio: editor.id ? 'Editar cardio' : 'Registrar cardio', photo: 'Foto de progresso', water: editor.id ? 'Editar hidratação' : 'Registrar hidratação' };
  const canDelete = Boolean(editor.id) && editor.kind !== 'workout' && editor.kind !== 'exercise' && editor.kind !== 'photo';

  function updateSeries(id: string, patch: Partial<WorkoutSet>) {
    setSeriesDraft(items => items.map(item => item.id === id ? { ...item, ...patch } : item));
  }

  function addSeries() {
    setSeriesDraft(items => [...items, { ...createDefaultSets(1, '8–12', 0)[0], id: uid('set'), kind: items.length ? 'Trabalho' : 'Aquecimento', restSeconds: state.training.defaultRestSeconds }]);
  }

  return <div className="modal-backdrop trainingx-modal-backdrop" onMouseDown={event => event.target === event.currentTarget && onClose()}><form className="app-modal trainingx-modal" onSubmit={onSubmit}><header><div><span className="eyebrow">Área de treinos</span><h2>{titles[editor.kind]}</h2></div><button type="button" onClick={onClose}><X size={21} /></button></header><div className="modal-fields">
    {editor.kind === 'workout' && <><div className="field-row"><label>Nome do treino<input name="name" required defaultValue={workout?.name} placeholder="Ex.: Treino D" /></label><label>Dia da semana<select name="weekday" defaultValue={workout?.weekday ?? 1}>{weekdayNames.map((day,index) => <option value={index} key={day}>{day}</option>)}</select></label></div><label>Foco<input name="focus" defaultValue={workout?.focus} placeholder="Ex.: Costas e bíceps" /></label><div className="field-row"><label>Cor<input type="color" name="color" defaultValue={workout?.color || '#ff7a3d'} /></label><label>Observações<input name="notes" defaultValue={workout?.notes} /></label></div></>}
    {editor.kind === 'exercise' && <><div className="field-row"><label>Exercício<input name="name" required defaultValue={exercise?.name || String(defaults.name ?? '')} placeholder="Ex.: Supino reto" /></label><label>Grupo muscular<input name="muscleGroup" defaultValue={exercise?.muscleGroup || String(defaults.muscleGroup ?? '')} /></label></div><div className="field-row"><label>Equipamento<input name="equipment" defaultValue={exercise?.equipment || String(defaults.equipment ?? '')} /></label><label>Observações<input name="notes" defaultValue={exercise?.notes || String(defaults.notes ?? '')} /></label></div><div className="trainingx-series-editor"><header><div><strong>Configuração por série</strong><small>Cada linha pode ter carga, reps e descanso diferentes.</small></div><button type="button" onClick={addSeries}><Plus size={16} /> Série</button></header><div className="trainingx-series-editor-head"><span>#</span><span>Tipo</span><span>Reps alvo</span><span>Carga</span><span>Descanso</span><span>Falha</span><span /></div>{seriesDraft.map((set,index) => <div className="trainingx-series-editor-row" key={set.id}><strong>{index + 1}</strong><select value={set.kind} onChange={event => updateSeries(set.id, { kind: event.target.value as WorkoutSetKind })}>{setKinds.map(kind => <option key={kind}>{kind}</option>)}</select><input value={set.targetReps} onChange={event => updateSeries(set.id, { targetReps: event.target.value })} placeholder="8–12" /><label><input type="number" min="0" step=".5" value={set.targetWeight} onChange={event => updateSeries(set.id, { targetWeight: Number(event.target.value), actualWeight: Number(event.target.value) })} /><small>kg</small></label><label><input type="number" min="0" value={set.restSeconds} onChange={event => updateSeries(set.id, { restSeconds: Number(event.target.value) })} /><small>s</small></label><input type="checkbox" checked={set.toFailure} onChange={event => updateSeries(set.id, { toFailure: event.target.checked })} /><button type="button" onClick={() => setSeriesDraft(items => items.filter(item => item.id !== set.id))}><Trash2 size={15} /></button></div>)}</div></>}
    {editor.kind === 'library' && <><label>Nome do exercício<input name="name" required defaultValue={library?.name} /></label><div className="field-row"><label>Grupo muscular<input name="muscleGroup" defaultValue={library?.muscleGroup} /></label><label>Equipamento<input name="equipment" defaultValue={library?.equipment} /></label></div><label>Observações<textarea name="notes">{library?.notes}</textarea></label></>}
    {editor.kind === 'measurement' && <><div className="field-row"><label>Data<input type="date" name="date" required defaultValue={measurement?.date || localDateKey()} /></label><label>Peso (kg)<input type="number" name="weight" min="0" step=".1" required defaultValue={measurement?.weight} /></label></div><div className="field-row three"><label>Gordura (%)<input type="number" name="bodyFat" min="0" step=".1" defaultValue={measurement?.bodyFat ?? ''} /></label><label>Cintura (cm)<input type="number" name="waist" min="0" step=".1" defaultValue={measurement?.waist ?? ''} /></label><label>Peito (cm)<input type="number" name="chest" min="0" step=".1" defaultValue={measurement?.chest ?? ''} /></label></div><div className="field-row"><label>Braço (cm)<input type="number" name="arm" min="0" step=".1" defaultValue={measurement?.arm ?? ''} /></label><label>Coxa (cm)<input type="number" name="thigh" min="0" step=".1" defaultValue={measurement?.thigh ?? ''} /></label></div><label>Observações<textarea name="notes">{measurement?.notes}</textarea></label></>}
    {editor.kind === 'cardio' && <><div className="field-row"><label>Data<input type="date" name="date" required defaultValue={cardio?.date || localDateKey()} /></label><label>Atividade<select name="kind" defaultValue={cardio?.kind || 'Caminhada'}><option>Caminhada</option><option>Corrida</option><option>Bicicleta</option><option>Elíptico</option><option>Escada</option><option>Natação</option><option>Outro</option></select></label></div><div className="field-row three"><label>Duração (min)<input type="number" name="durationMinutes" min="1" required defaultValue={cardio?.durationMinutes || 30} /></label><label>Distância (km)<input type="number" name="distanceKm" min="0" step=".01" defaultValue={cardio?.distanceKm ?? ''} /></label><label>Calorias<input type="number" name="calories" min="0" defaultValue={cardio?.calories ?? ''} /></label></div><label>Observações<textarea name="notes">{cardio?.notes}</textarea></label></>}
    {editor.kind === 'water' && <><label>Data<input type="date" name="date" required defaultValue={water?.date || localDateKey()} /></label><label>Total de água (litros)<input type="number" name="liters" min="0" max="15" step=".05" required defaultValue={water?.liters ?? state.training.waterEntries.filter(item => item.date === localDateKey()).reduce((sum,item) => sum + item.liters, 0)} /></label></>}
    {editor.kind === 'photo' && <><div className="field-row"><label>Data<input type="date" name="date" required defaultValue={localDateKey()} /></label><label>Legenda<input name="label" placeholder="Ex.: Evolução de agosto" /></label></div><div className="trainingx-photo-upload"><label className={uploading ? 'loading' : ''}>{photoAttachment ? <img src={photoAttachment.url} alt="Prévia" /> : <><Upload size={28} /><strong>{uploading ? 'Enviando...' : 'Escolher foto'}</strong><small>JPG, PNG, WEBP ou GIF · até 8 MB</small></>}<input type="file" accept="image/jpeg,image/png,image/webp,image/gif" disabled={uploading} onChange={event => void uploadPhoto(event.target.files?.[0])} /></label></div></>}
  </div><footer>{canDelete ? <button className="trainingx-delete" type="button" onClick={onDelete}><Trash2 size={17} /> Excluir</button> : <span />}<div><button className="cancel-button" type="button" onClick={onClose}>Cancelar</button><button className="modal-save trainingx-save" type="submit" disabled={uploading || (editor.kind === 'photo' && !photoAttachment)}><Save size={17} /> Salvar</button></div></footer></form></div>;
}
