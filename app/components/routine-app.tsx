'use client';

import {
  Activity,
  Bell,
  ArrowLeft,
  BookOpen,
  Brain,
  CalendarDays,
  Check,
  CheckCircle2,
  ChevronLeft,
  ChevronRight,
  CircleDollarSign,
  Clock3,
  Cloud,
  CloudOff,
  CreditCard,
  Download,
  Droplets,
  Dumbbell,
  Flame,
  Home,
  Landmark,
  Laptop,
  LogOut,
  Moon,
  Pencil,
  Plus,
  Settings,
  Smartphone,
  Sun,
  Target,
  Trash2,
  Upload,
  UserRound,
  WalletCards,
  X,
} from 'lucide-react';
import { useEffect, useMemo, useRef, useState, type FormEvent } from 'react';
import {
  createInitialState,
  createDefaultSets,
  ensureToday,
  mergeState,
  monthKey,
  uid,
  type AppState,
  type Workout,
} from '../lib/app-data';
import { StudyModule } from './study-module';
import { TrainingModule } from './training-module';
import { FinanceModule } from './finance-module';
import { financeMonthSnapshot } from '../lib/finance-utils';

type View = 'home' | 'study' | 'training' | 'finance' | 'settings';
type ModalType = 'subject' | 'flashcard' | 'workout' | 'exercise' | 'income' | 'expense' | 'account' | 'card' | 'edit-income';
type SaveStatus = 'loading' | 'saving' | 'saved' | 'offline';
type AgendaArea = 'study' | 'training' | 'finance';
type HomeAgendaItem = { id: string; area: AgendaArea; title: string; meta: string; date: string; time: string; priority: number };
type InstallPromptEvent = Event & { prompt: () => Promise<void>; userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }> };

type RoutineAppProps = {
  user: {
    displayName: string;
    email: string;
    fullName: string | null;
  };
};

const money = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });
const dateFormatter = new Intl.DateTimeFormat('pt-BR', { day: '2-digit', month: 'short' });
const monthFormatter = new Intl.DateTimeFormat('pt-BR', { month: 'long', year: 'numeric' });
const weekdayNames = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
const today = () => {
  const date = new Date();
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
};

function shiftDateKey(value: string, amount: number) {
  const date = new Date(`${value}T12:00:00`);
  date.setDate(date.getDate() + amount);
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
}

function greeting() {
  const hour = new Date().getHours();
  if (hour < 12) return 'Bom dia';
  if (hour < 18) return 'Boa tarde';
  return 'Boa noite';
}

function clamp(value: number, min: number, max: number) {
  return Math.min(Math.max(value, min), max);
}

function initials(name: string) {
  return name
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map(part => part[0])
    .join('')
    .toUpperCase();
}

export function RoutineApp({ user }: RoutineAppProps) {
  const initial = useMemo(() => createInitialState(user.displayName), [user.displayName]);
  const [state, setState] = useState<AppState>(initial);
  const [view, setView] = useState<View>('home');
  const [modal, setModal] = useState<{ type: ModalType; id?: string } | null>(null);
  const [saveStatus, setSaveStatus] = useState<SaveStatus>('loading');
  const [hydrated, setHydrated] = useState(false);
  const [selectedMonth] = useState(() => new Date());
  const [selectedWorkoutId, setSelectedWorkoutId] = useState(() => {
    const day = new Date().getDay();
    return initial.training.workouts.find(item => item.weekday === day)?.id ?? initial.training.workouts[0]?.id ?? '';
  });
  const [toast, setToast] = useState('');
  const [installPrompt, setInstallPrompt] = useState<InstallPromptEvent | null>(null);
  const importRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    let active = true;
    fetch('/api/state')
      .then(async response => {
        if (!response.ok) throw new Error('offline');
        return response.json() as Promise<{ state: unknown }>; 
      })
      .then(result => {
        if (!active) return;
        setState(result.state ? mergeState(result.state, user.displayName) : initial);
        setSaveStatus('saved');
      })
      .catch(() => {
        if (!active) return;
        setSaveStatus('offline');
      })
      .finally(() => active && setHydrated(true));
    return () => {
      active = false;
    };
  }, [initial, user.displayName]);

  useEffect(() => {
    if (!hydrated) return;
    const timer = window.setTimeout(() => {
      setSaveStatus('saving');
      fetch('/api/state', {
        method: 'PUT',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ state }),
      })
        .then(response => {
          if (!response.ok) throw new Error('offline');
          setSaveStatus('saved');
        })
        .catch(() => setSaveStatus('offline'));
    }, 650);
    return () => window.clearTimeout(timer);
  }, [state, hydrated]);

  useEffect(() => {
    if (!toast) return;
    const timer = window.setTimeout(() => setToast(''), 2600);
    return () => window.clearTimeout(timer);
  }, [toast]);

  useEffect(() => {
    const capturePrompt = (event: Event) => {
      event.preventDefault();
      setInstallPrompt(event as InstallPromptEvent);
    };
    window.addEventListener('beforeinstallprompt', capturePrompt);
    return () => window.removeEventListener('beforeinstallprompt', capturePrompt);
  }, []);

  const currentMonth = monthKey(selectedMonth);
  const financeSummary = financeMonthSnapshot(state.finance, currentMonth);
  const predictedIncome = financeSummary.predictedIncome;
  const predictedExpense = financeSummary.predictedExpense;
  const pendingCount = financeSummary.pendingCount;
  const todayWorkout = state.training.workouts.find(item => item.weekday === new Date().getDay());
  const selectedWorkout = state.training.workouts.find(item => item.id === selectedWorkoutId) ?? todayWorkout ?? state.training.workouts[0];
  const dueFlashcards = state.study.flashcards.filter(item => item.dueDate <= today());
  const studySessions = state.study.sessions.length || state.study.subjects.reduce((total, subject) => total + subject.sessions, 0);
  const workoutProgress = state.training.activeSession?.exerciseLogs.length
    ? Math.round(state.training.activeSession.exerciseLogs.filter(item => item.finished).length / state.training.activeSession.exerciseLogs.length * 100)
    : state.training.sessions.some(item => item.date === today()) ? 100 : 0;
  const homeAgenda = useMemo<HomeAgendaItem[]>(() => {
    const currentDate = today();
    const horizon = shiftDateKey(currentDate, 7);
    const weekday = new Date().getDay();
    const items: HomeAgendaItem[] = [];

    state.study.schedule.filter(item => item.weekday === weekday).forEach(item => {
      const subject = state.study.subjects.find(subjectItem => subjectItem.id === item.subjectId);
      items.push({ id: `class-${item.id}`, area: 'study', title: subject?.name || 'Aula', meta: `${item.startTime}–${item.endTime}${item.room ? ` · ${item.room}` : ''}`, date: currentDate, time: item.startTime, priority: 1 });
    });
    state.study.assessments.filter(item => item.status !== 'completed' && item.date >= currentDate && item.date <= horizon).forEach(item => {
      const subject = state.study.subjects.find(subjectItem => subjectItem.id === item.subjectId);
      items.push({ id: `assessment-${item.id}`, area: 'study', title: `${item.kind}: ${item.title}`, meta: subject?.name || 'Avaliação acadêmica', date: item.date, time: item.time || '23:59', priority: item.date === currentDate ? 0 : 2 });
    });
    state.study.tasks.filter(item => !item.completed && item.date >= currentDate && item.date <= horizon).forEach(item => {
      const subject = state.study.subjects.find(subjectItem => subjectItem.id === item.subjectId);
      items.push({ id: `task-${item.id}`, area: 'study', title: item.title, meta: subject?.name || 'Tarefa de estudo', date: item.date, time: item.startTime || '23:58', priority: item.priority === 'Alta' ? 0 : 3 });
    });
    if (todayWorkout) items.push({ id: `workout-${todayWorkout.id}`, area: 'training', title: todayWorkout.name, meta: `${todayWorkout.focus || 'Treino do dia'} · ${todayWorkout.exercises.length} exercícios`, date: currentDate, time: '23:57', priority: 2 });
    financeSummary.obligations.filter(item => !item.paid && item.dueDate >= currentDate && item.dueDate <= horizon).forEach(item => {
      items.push({ id: `finance-${item.id}`, area: 'finance', title: item.description, meta: `${item.typeLabel} · ${money.format(item.amount)}`, date: item.dueDate, time: '23:59', priority: item.dueDate === currentDate ? 0 : 4 });
    });

    return items.sort((left, right) => `${left.date}-${left.time}`.localeCompare(`${right.date}-${right.time}`) || left.priority - right.priority).slice(0, 8);
  }, [financeSummary.obligations, state.study.assessments, state.study.schedule, state.study.subjects, state.study.tasks, todayWorkout]);

  function notify(message: string) {
    setToast(message);
  }

  function openView(next: View) {
    setView(next);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  function updateWorkout(workoutId: string, updater: (workout: Workout) => Workout) {
    setState(current => ({
      ...current,
      training: {
        ...current.training,
        workouts: current.training.workouts.map(workout => workout.id === workoutId ? updater(workout) : workout),
      },
    }));
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!modal) return;
    const form = new FormData(event.currentTarget);
    const text = (name: string) => String(form.get(name) ?? '').trim();
    const number = (name: string) => Number(form.get(name) ?? 0);

    if (modal.type === 'subject') {
      const name = text('name');
      if (!name) return;
      setState(current => ({
        ...current,
        study: {
          ...current.study,
          subjects: [...current.study.subjects, {
            id: uid('subject'),
            name,
            code: '',
            professor: '',
            room: '',
            color: text('color') || '#8b5cf6',
            description: '',
            semester: '',
            cards: 0,
            questions: 0,
            summaries: 0,
            sessions: 0,
            archived: false,
          }],
        },
      }));
    }

    if (modal.type === 'flashcard') {
      const subjectId = text('subjectId');
      const front = text('front');
      const back = text('back');
      if (!subjectId || !front || !back) return;
      setState(current => ({
        ...current,
        study: {
          ...current.study,
          flashcards: [...current.study.flashcards, {
            id: uid('card'),
            subjectId,
            deckId: '',
            topic: '',
            front,
            back,
            dueDate: text('dueDate') || today(),
            reviewed: false,
            createdAt: new Date().toISOString(),
            lastReviewedAt: null,
            intervalDays: 0,
            repetitions: 0,
            easeFactor: 2.5,
            lapses: 0,
          }],
          subjects: current.study.subjects.map(subject => subject.id === subjectId ? { ...subject, cards: subject.cards + 1 } : subject),
        },
      }));
    }

    if (modal.type === 'workout') {
      const workout: Workout = { id: uid('workout'), name: text('name'), focus: text('focus'), weekday: number('weekday'), color: state.profile.workoutColor, notes: '', exercises: [] };
      if (!workout.name) return;
      setState(current => ({ ...current, training: { ...current.training, workouts: [...current.training.workouts, workout] } }));
      setSelectedWorkoutId(workout.id);
    }

    if (modal.type === 'exercise') {
      const workoutId = text('workoutId');
      const name = text('name');
      if (!workoutId || !name) return;
      updateWorkout(workoutId, workout => ({
        ...workout,
        exercises: [...workout.exercises, {
          id: uid('exercise'),
          name,
          muscleGroup: '',
          equipment: '',
          notes: '',
          sets: number('sets') || 3,
          reps: text('reps') || '10–12',
          weight: number('weight'),
          completed: false,
          setDetails: createDefaultSets(number('sets') || 3, text('reps') || '10–12', number('weight')),
        }],
      }));
      setSelectedWorkoutId(workoutId);
    }

    if (modal.type === 'income') {
      const description = text('description');
      const amount = number('amount');
      const frequency = text('frequency');
      if (!description || amount <= 0) return;
      setState(current => ({
        ...current,
        finance: frequency === 'monthly'
          ? { ...current.finance, recurringIncomes: [...current.finance.recurringIncomes, { id: uid('income'), description, amount, day: clamp(number('day') || 1, 1, 31), category: 'Salário', accountId: '', active: true, startMonth: '', endMonth: '', receivedMonths: [] }] }
          : { ...current.finance, incomes: [...current.finance.incomes, { id: uid('income'), description, amount, date: text('date') || today(), category: 'Renda extra', accountId: '', notes: '', attachment: null, received: false }] },
      }));
    }

    if (modal.type === 'edit-income' && modal.id) {
      setState(current => ({
        ...current,
        finance: {
          ...current.finance,
          recurringIncomes: current.finance.recurringIncomes.map(item => item.id === modal.id ? {
            ...item,
            description: text('description') || item.description,
            amount: number('amount') || item.amount,
            day: clamp(number('day') || item.day, 1, 31),
          } : item),
        },
      }));
    }

    if (modal.type === 'expense') {
      const description = text('description');
      const amount = number('amount');
      if (!description || amount <= 0) return;
      setState(current => ({
        ...current,
        finance: {
          ...current.finance,
          expenses: [...current.finance.expenses, { id: uid('expense'), description, category: text('category') || 'Outros', amount, dueDate: text('dueDate') || today(), accountId: '', paymentMethod: '', notes: '', attachment: null, paidAt: null, paid: false }],
        },
      }));
    }

    if (modal.type === 'account') {
      const name = text('name');
      if (!name) return;
      setState(current => ({
        ...current,
        finance: { ...current.finance, accounts: [...current.finance.accounts, { id: uid('account'), name, institution: name, kind: 'Conta corrente', balance: number('balance'), color: text('color') || '#10b981', includeInTotal: true }] },
      }));
    }

    if (modal.type === 'card') {
      const bank = text('bank');
      if (!bank) return;
      setState(current => ({
        ...current,
        finance: {
          ...current.finance,
          cards: [...current.finance.cards, { id: uid('credit-card'), bank, holder: text('holder') || state.profile.displayName, brand: 'Mastercard', lastDigits: '', limit: number('limit'), closingDay: clamp(number('closingDay') || 1, 1, 31), dueDay: clamp(number('dueDay') || 1, 1, 31), color: text('color') || '#7454f6', active: true }],
        },
      }));
    }

    setModal(null);
    notify('Informação salva com sucesso.');
  }

  function exportBackup() {
    const blob = new Blob([JSON.stringify(state, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `my-routine-active-${today()}.json`;
    link.click();
    URL.revokeObjectURL(url);
    notify('Backup exportado.');
  }

  function importBackup(file: File | undefined) {
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => {
      try {
        setState(mergeState(JSON.parse(String(reader.result)), user.displayName));
        notify('Backup restaurado com sucesso.');
      } catch {
        notify('O arquivo selecionado não é um backup válido.');
      }
    };
    reader.readAsText(file);
  }

  async function installWebApp() {
    if (!installPrompt) {
      notify('Use o menu do navegador e escolha “Instalar aplicativo” ou “Adicionar à tela inicial”.');
      return;
    }
    await installPrompt.prompt();
    const choice = await installPrompt.userChoice;
    if (choice.outcome === 'accepted') notify('My Routine Active instalado neste dispositivo.');
    setInstallPrompt(null);
  }

  const navItems: { id: View; label: string; icon: typeof Home }[] = [
    { id: 'home', label: 'Início', icon: Home },
    { id: 'study', label: 'Estudos', icon: BookOpen },
    { id: 'training', label: 'Treinos', icon: Dumbbell },
    { id: 'finance', label: 'Finanças', icon: WalletCards },
    { id: 'settings', label: 'Mais', icon: Settings },
  ];

  return (
    <main className={`routine-app theme-${state.profile.theme}`} style={{ '--workout-accent': state.profile.workoutColor } as React.CSSProperties}>
      <div className="app-ambient app-ambient-one" />
      <div className="app-ambient app-ambient-two" />

      <header className="app-header">
        <button className="brand-button" onClick={() => openView('home')} aria-label="Ir para o início">
          <span className="brand-mark"><Activity size={25} strokeWidth={2.4} /></span>
          <span className="header-brand-copy">
            <strong>My Routine Active</strong>
            <small>{view === 'home' ? 'Visão geral' : navItems.find(item => item.id === view)?.label}</small>
          </span>
        </button>

        <div className="header-actions">
          <div className={`save-chip save-${saveStatus}`}>
            {saveStatus === 'offline' ? <CloudOff size={15} /> : <Cloud size={15} />}
            <span>{saveStatus === 'loading' ? 'Carregando' : saveStatus === 'saving' ? 'Salvando' : saveStatus === 'saved' ? 'Sincronizado' : 'Sem conexão'}</span>
          </div>
          <button
            className="icon-button"
            onClick={() => setState(current => ({ ...current, profile: { ...current.profile, theme: current.profile.theme === 'dark' ? 'light' : 'dark' } }))}
            aria-label="Alternar tema"
          >
            {state.profile.theme === 'dark' ? <Sun size={20} /> : <Moon size={20} />}
          </button>
          <button className="avatar-button" onClick={() => openView('settings')} aria-label="Abrir perfil">
            {initials(state.profile.displayName)}
          </button>
        </div>
      </header>

      <div className="app-layout">
        <aside className="desktop-sidebar">
          <nav>
            {navItems.map(item => {
              const Icon = item.icon;
              return (
                <button key={item.id} className={view === item.id ? 'active' : ''} onClick={() => openView(item.id)}>
                  <Icon size={20} />
                  <span>{item.label}</span>
                </button>
              );
            })}
          </nav>
          <div className="sidebar-profile">
            <span className="avatar-large">{initials(state.profile.displayName)}</span>
            <span><strong>{state.profile.displayName}</strong><small>{user.email}</small></span>
          </div>
        </aside>

        <section className="app-content">
          {view === 'home' && (
            <HomeView
              name={state.profile.displayName}
              studySessions={studySessions}
              dueFlashcards={dueFlashcards.length}
              workout={todayWorkout ?? selectedWorkout}
              workoutProgress={workoutProgress}
              balance={predictedIncome - predictedExpense}
              pending={pendingCount}
              agenda={homeAgenda}
              openView={openView}
            />
          )}

          {view === 'study' && (
            <StudyModule
              state={state}
              setState={setState}
              openHome={() => openView('home')}
              notify={notify}
            />
          )}

          {view === 'training' && (
            <TrainingModule
              state={state}
              setState={setState}
              openHome={() => openView('home')}
              notify={notify}
            />
          )}

          {view === 'finance' && (
            <FinanceModule
              state={state}
              setState={setState}
              openHome={() => openView('home')}
              notify={notify}
            />
          )}

          {view === 'settings' && (
            <SettingsView
              state={state}
              user={user}
              setState={setState}
              exportBackup={exportBackup}
              importRef={importRef}
              installApp={installWebApp}
              installReady={Boolean(installPrompt)}
            />
          )}
        </section>
      </div>

      <nav className="mobile-nav">
        {navItems.map(item => {
          const Icon = item.icon;
          return (
            <button key={item.id} className={view === item.id ? 'active' : ''} onClick={() => openView(item.id)}>
              <Icon size={19} />
              <span>{item.label}</span>
            </button>
          );
        })}
      </nav>

      <input ref={importRef} className="hidden-input" type="file" accept="application/json" onChange={event => importBackup(event.target.files?.[0])} />

      {modal && (
        <Modal
          modal={modal}
          state={state}
          selectedWorkoutId={selectedWorkout?.id ?? ''}
          onClose={() => setModal(null)}
          onSubmit={handleSubmit}
        />
      )}

      {toast && <div className="toast"><CheckCircle2 size={18} />{toast}</div>}
    </main>
  );
}

function PageHeading({ eyebrow, title, description, onBack, actions }: { eyebrow: string; title: string; description: string; onBack?: () => void; actions?: React.ReactNode }) {
  return (
    <div className="page-heading">
      <div className="page-heading-main">
        {onBack && <button className="back-button" onClick={onBack}><ArrowLeft size={20} /></button>}
        <div><span className="eyebrow">{eyebrow}</span><h1>{title}</h1><p>{description}</p></div>
      </div>
      {actions && <div className="page-actions">{actions}</div>}
    </div>
  );
}

function HomeView({ name, studySessions, dueFlashcards, workout, workoutProgress, balance, pending, agenda, openView }: { name: string; studySessions: number; dueFlashcards: number; workout?: Workout; workoutProgress: number; balance: number; pending: number; agenda: HomeAgendaItem[]; openView: (view: View) => void }) {
  const agendaIcons = { study: BookOpen, training: Dumbbell, finance: WalletCards };
  const areaLabels = { study: 'Estudos', training: 'Treinos', finance: 'Finanças' };
  const currentDate = today();
  const tomorrow = shiftDateKey(currentDate, 1);
  const agendaDate = (value: string) => value === currentDate ? 'Hoje' : value === tomorrow ? 'Amanhã' : dateFormatter.format(new Date(`${value}T12:00:00`));
  return (
    <div className="home-view">
      <section className="welcome-block">
        <span className="eyebrow">Seu painel de hoje</span>
        <h1>{greeting()}, {name}.</h1>
        <p>Qual área da sua vida vamos colocar em movimento agora?</p>
      </section>

      <section className="pillar-grid">
        <button className="pillar-card study-card" onClick={() => openView('study')}>
          <span className="pillar-icon"><BookOpen size={28} /></span>
          <span className="pillar-copy"><small>Mente em movimento</small><strong>Estudos</strong><em>Aulas, matérias, provas, anotações e revisão ativa.</em></span>
          <span className="pillar-metrics"><b>{dueFlashcards}</b><small>revisões pendentes</small><b>{studySessions}</b><small>sessões registradas</small></span>
          <span className="pillar-open">Abrir estudos <ChevronRight size={18} /></span>
        </button>

        <button className="pillar-card training-card" onClick={() => openView('training')}>
          <span className="pillar-icon"><Dumbbell size={28} /></span>
          <span className="pillar-copy"><small>Corpo em movimento</small><strong>Treinos</strong><em>Séries independentes, cronômetros, evolução e saúde.</em></span>
          <span className="pillar-metrics"><b>{workout?.name ?? 'Livre'}</b><small>{workout?.focus ?? 'Monte seu primeiro treino'}</small><b>{workoutProgress}%</b><small>concluído hoje</small></span>
          <span className="pillar-open">Abrir treinos <ChevronRight size={18} /></span>
        </button>

        <button className="pillar-card finance-card" onClick={() => openView('finance')}>
          <span className="pillar-icon"><WalletCards size={28} /></span>
          <span className="pillar-copy"><small>Vida em equilíbrio</small><strong>Finanças</strong><em>Fluxo mensal, contas, faturas, parcelas e patrimônio.</em></span>
          <span className="pillar-metrics"><b>{money.format(balance)}</b><small>saldo previsto no mês</small><b>{pending}</b><small>pendências</small></span>
          <span className="pillar-open">Abrir finanças <ChevronRight size={18} /></span>
        </button>
      </section>

      <section className="home-agenda">
        <header>
          <div><span className="eyebrow">Tudo em um só lugar</span><h2>Hoje e próximos 7 dias</h2><p>Aulas, avaliações, treino e vencimentos organizados em uma linha do tempo.</p></div>
          <span><Bell size={18} /> {agenda.length} lembretes</span>
        </header>
        <div className="home-agenda-list">
          {agenda.map(item => {
            const Icon = agendaIcons[item.area];
            return <button key={item.id} className={item.area} onClick={() => openView(item.area)}><span className="home-agenda-icon"><Icon size={19} /></span><span className="home-agenda-copy"><small>{areaLabels[item.area]}</small><strong>{item.title}</strong><em>{item.meta}</em></span><span className="home-agenda-time"><b>{agendaDate(item.date)}</b><small>{item.time.startsWith('23:') ? 'Ao longo do dia' : item.time}</small></span><ChevronRight size={17} /></button>;
          })}
          {!agenda.length && <div className="home-agenda-empty"><span><CheckCircle2 size={24} /></span><div><strong>Agenda tranquila por enquanto</strong><p>Quando você cadastrar aulas, provas, treinos ou contas, os próximos compromissos aparecerão aqui.</p></div></div>}
        </div>
      </section>

      <section className="daily-message">
        <span className="daily-message-icon"><Clock3 size={24} /></span>
        <div><strong>Três áreas. Um só ritmo.</strong><p>Seus dados ficam sincronizados na mesma conta para continuar no celular ou no computador.</p></div>
      </section>
    </div>
  );
}

export function LegacyStudyView({ state, dueFlashcards, openHome, openModal, registerStudy, setState }: { state: AppState; dueFlashcards: number; openHome: () => void; openModal: (type: ModalType) => void; registerStudy: (id: string) => void; setState: React.Dispatch<React.SetStateAction<AppState>> }) {
  const totalSessions = state.study.subjects.reduce((total, item) => total + item.sessions, 0);
  const progress = Math.round((state.study.questionsToday / Math.max(state.study.questionGoal, 1)) * 100);
  return (
    <div className="module-view study-view">
      <PageHeading eyebrow="Memorização ativa" title="Estudos" description="Conteúdo organizado para você revisar no momento certo." onBack={openHome} actions={<><button className="secondary-button" onClick={() => openModal('flashcard')}><Brain size={18} /> Novo flashcard</button><button className="study-primary" onClick={() => openModal('subject')}><Plus size={18} /> Nova matéria</button></>} />

      <section className="stat-grid three">
        <article><span className="stat-icon purple"><Brain size={20} /></span><small>Revisões de hoje</small><strong>{dueFlashcards}</strong><em>{state.study.flashcards.length} cartões cadastrados</em></article>
        <article><span className="stat-icon blue"><Target size={20} /></span><small>Questões hoje</small><strong>{state.study.questionsToday}</strong><em>meta de {state.study.questionGoal}</em></article>
        <article><span className="stat-icon amber"><Flame size={20} /></span><small>Sessões</small><strong>{totalSessions}</strong><em>{state.study.studyDates.length} dias ativos</em></article>
      </section>

      <section className="study-progress-card panel-card">
        <div className="section-title"><div><span className="eyebrow">Meta diária</span><h2>Questões resolvidas</h2></div><strong>{Math.min(progress, 100)}%</strong></div>
        <div className="progress-track"><span style={{ width: `${Math.min(progress, 100)}%` }} /></div>
        <div className="quick-stepper">
          <button onClick={() => setState(current => ({ ...current, study: { ...current.study, questionsToday: Math.max(0, current.study.questionsToday - 5) } }))}>− 5</button>
          <span>{state.study.questionsToday} de {state.study.questionGoal}</span>
          <button onClick={() => setState(current => ({ ...current, study: { ...current.study, questionsToday: current.study.questionsToday + 5, studyDates: ensureToday(current.study.studyDates) } }))}>+ 5</button>
        </div>
      </section>

      <div className="section-title section-title-row"><div><span className="eyebrow">Organização</span><h2>Suas matérias</h2></div><span>{state.study.subjects.length} cadastradas</span></div>
      <section className="subject-grid">
        {state.study.subjects.map(subject => (
          <article className="subject-card" key={subject.id} style={{ '--subject-color': subject.color } as React.CSSProperties}>
            <div className="subject-card-head"><span className="subject-icon"><BookOpen size={23} /></span><button className="ghost-icon danger" aria-label="Excluir matéria" onClick={() => setState(current => ({ ...current, study: { ...current.study, subjects: current.study.subjects.filter(item => item.id !== subject.id), flashcards: current.study.flashcards.filter(card => card.subjectId !== subject.id) } }))}><Trash2 size={17} /></button></div>
            <h3>{subject.name}</h3>
            <p>{subject.sessions ? `${subject.sessions} sessões concluídas` : 'Pronta para sua primeira sessão.'}</p>
            <div className="subject-metrics"><span><b>{subject.cards}</b><small>cartões</small></span><span><b>{subject.questions}</b><small>questões</small></span><span><b>{subject.summaries}</b><small>resumos</small></span></div>
            <button className="subject-action" onClick={() => registerStudy(subject.id)}>Registrar estudo <ChevronRight size={17} /></button>
          </article>
        ))}
        {!state.study.subjects.length && <EmptyState icon={<BookOpen size={30} />} title="Crie sua primeira matéria" text="Separe o conteúdo por assunto para acompanhar seu avanço." action="Nova matéria" onAction={() => openModal('subject')} />}
      </section>

      {!!state.study.flashcards.length && (
        <section className="panel-card flashcard-list">
          <div className="section-title"><div><span className="eyebrow">Repetição espaçada</span><h2>Flashcards</h2></div></div>
          {state.study.flashcards.map(card => (
            <article key={card.id} className={card.reviewed ? 'done' : ''}>
              <div><strong>{card.front}</strong><p>{card.back}</p></div>
              <button onClick={() => setState(current => ({ ...current, study: { ...current.study, flashcards: current.study.flashcards.map(item => item.id === card.id ? { ...item, reviewed: !item.reviewed } : item), studyDates: ensureToday(current.study.studyDates) } }))}>{card.reviewed ? <Check size={18} /> : 'Revisar'}</button>
            </article>
          ))}
        </section>
      )}
    </div>
  );
}

export function LegacyTrainingView({ state, selectedWorkout, selectedWorkoutId, workoutProgress, setSelectedWorkoutId, toggleExercise, finishWorkout, openHome, openModal, setState, updateWorkout }: { state: AppState; selectedWorkout?: Workout; selectedWorkoutId: string; workoutProgress: number; setSelectedWorkoutId: (id: string) => void; toggleExercise: (id: string) => void; finishWorkout: () => void; openHome: () => void; openModal: (type: ModalType) => void; setState: React.Dispatch<React.SetStateAction<AppState>>; updateWorkout: (id: string, updater: (workout: Workout) => Workout) => void }) {
  return (
    <div className="module-view training-view">
      <PageHeading eyebrow="Seu ritmo" title="Treinos" description="Planeje a semana e acompanhe cada exercício sem distração." onBack={openHome} actions={<><button className="secondary-button" onClick={() => openModal('workout')}><CalendarDays size={18} /> Novo treino</button><button className="training-primary" onClick={() => openModal('exercise')}><Plus size={18} /> Exercício</button></>} />

      <div className="workout-tabs">
        {state.training.workouts.map(workout => <button key={workout.id} className={selectedWorkoutId === workout.id ? 'active' : ''} onClick={() => setSelectedWorkoutId(workout.id)}><strong>{workout.name}</strong><small>{weekdayNames[workout.weekday]}</small></button>)}
      </div>

      {selectedWorkout ? (
        <>
          <section className="workout-hero">
            <div className="workout-hero-copy"><span className="eyebrow">{weekdayNames[selectedWorkout.weekday]}</span><h2>{selectedWorkout.focus}</h2><p>{selectedWorkout.exercises.length} exercícios preparados para hoje.</p></div>
            <div className="progress-ring" style={{ '--progress': `${workoutProgress * 3.6}deg` } as React.CSSProperties}><span><strong>{workoutProgress}%</strong><small>concluído</small></span></div>
          </section>

          <section className="exercise-list panel-card">
            <div className="section-title section-title-row"><div><span className="eyebrow">Ficha de treino</span><h2>Exercícios</h2></div><button className="ghost-icon danger" onClick={() => {
              setState(current => ({ ...current, training: { ...current.training, workouts: current.training.workouts.filter(item => item.id !== selectedWorkout.id) } }));
              setSelectedWorkoutId(state.training.workouts.find(item => item.id !== selectedWorkout.id)?.id ?? '');
            }}><Trash2 size={18} /></button></div>
            {selectedWorkout.exercises.map(exercise => (
              <article key={exercise.id} className={exercise.completed ? 'completed' : ''}>
                <button className="exercise-check" onClick={() => toggleExercise(exercise.id)}>{exercise.completed && <Check size={18} />}</button>
                <div className="exercise-copy"><strong>{exercise.name}</strong><span>{exercise.sets} séries · {exercise.reps} repetições</span></div>
                <label><span>Carga</span><input type="number" min="0" value={exercise.weight || ''} placeholder="0" onChange={event => updateWorkout(selectedWorkout.id, workout => ({ ...workout, exercises: workout.exercises.map(item => item.id === exercise.id ? { ...item, weight: Number(event.target.value) } : item) }))} /><em>kg</em></label>
                <button className="ghost-icon danger" onClick={() => updateWorkout(selectedWorkout.id, workout => ({ ...workout, exercises: workout.exercises.filter(item => item.id !== exercise.id) }))}><Trash2 size={17} /></button>
              </article>
            ))}
            {!selectedWorkout.exercises.length && <EmptyState icon={<Dumbbell size={30} />} title="Treino ainda vazio" text="Adicione os exercícios na ordem em que pretende executá-los." action="Adicionar exercício" onAction={() => openModal('exercise')} />}
            {!!selectedWorkout.exercises.length && <button className="finish-workout" onClick={finishWorkout}><CheckCircle2 size={20} /> Concluir treino</button>}
          </section>
        </>
      ) : <EmptyState icon={<Dumbbell size={30} />} title="Monte sua primeira ficha" text="Crie um treino e organize os exercícios por dia da semana." action="Criar treino" onAction={() => openModal('workout')} />}

      <section className="training-support-grid">
        <article className="panel-card hydration-card">
          <span className="stat-icon aqua"><Droplets size={20} /></span><div><small>Hidratação hoje</small><strong>{state.training.waterLiters.toFixed(2).replace('.', ',')} L</strong><em>Meta de {state.training.waterGoal.toFixed(1).replace('.', ',')} L</em></div>
          <div className="progress-track"><span style={{ width: `${Math.min((state.training.waterLiters / state.training.waterGoal) * 100, 100)}%` }} /></div>
          <div className="quick-stepper"><button onClick={() => setState(current => ({ ...current, training: { ...current.training, waterLiters: Math.max(0, current.training.waterLiters - 0.25) } }))}>− 250 ml</button><button onClick={() => setState(current => ({ ...current, training: { ...current.training, waterLiters: Math.min(current.training.waterLiters + 0.25, 10) } }))}>+ 250 ml</button></div>
        </article>
        <article className="panel-card consistency-card"><span className="stat-icon amber"><Flame size={20} /></span><div><small>Treinos concluídos</small><strong>{state.training.completedDates.length}</strong><em>Continue construindo sua sequência.</em></div></article>
      </section>
    </div>
  );
}

export function LegacyFinanceView({ state, selectedMonth, currentMonth, predictedIncome, receivedIncome, predictedExpense, paidExpense, pendingCount, monthIncomes, monthExpenses, shiftMonth, openHome, openModal, toggleRecurringIncome, setState }: { state: AppState; selectedMonth: Date; currentMonth: string; predictedIncome: number; receivedIncome: number; predictedExpense: number; paidExpense: number; pendingCount: number; monthIncomes: AppState['finance']['incomes']; monthExpenses: AppState['finance']['expenses']; shiftMonth: (amount: number) => void; openHome: () => void; openModal: (type: ModalType, id?: string) => void; toggleRecurringIncome: (id: string) => void; setState: React.Dispatch<React.SetStateAction<AppState>> }) {
  const incomePercent = predictedIncome ? Math.round((receivedIncome / predictedIncome) * 100) : 0;
  const expensePercent = predictedExpense ? Math.round((paidExpense / predictedExpense) * 100) : 0;
  return (
    <div className="module-view finance-view">
      <PageHeading eyebrow="Organização financeira" title="Finanças" description="Veja com clareza o que entra, o que sai e o que ainda falta." onBack={openHome} actions={<><button className="secondary-button" onClick={() => openModal('expense')}><Plus size={18} /> Despesa</button><button className="finance-primary" onClick={() => openModal('income')}><Plus size={18} /> Nova renda</button></>} />

      <div className="month-picker"><button onClick={() => shiftMonth(-1)}><ChevronLeft size={20} /></button><span>{monthFormatter.format(selectedMonth)}</span><button onClick={() => shiftMonth(1)}><ChevronRight size={20} /></button></div>

      <section className="stat-grid four finance-stats">
        <article><small>Renda prevista</small><strong>{money.format(predictedIncome)}</strong><em>Recebido: {money.format(receivedIncome)}</em></article>
        <article><small>Despesas previstas</small><strong>{money.format(predictedExpense)}</strong><em>Pago: {money.format(paidExpense)}</em></article>
        <article className="positive"><small>Saldo previsto</small><strong>{money.format(predictedIncome - predictedExpense)}</strong><em>Saldo real: {money.format(receivedIncome - paidExpense)}</em></article>
        <article><small>Pendências</small><strong>{pendingCount}</strong><em>lançamentos no mês</em></article>
      </section>

      <section className="financial-progress panel-card">
        <div className="section-title"><div><span className="eyebrow">Andamento do mês</span><h2>Seu fluxo financeiro</h2></div></div>
        <div className="progress-panels">
          <article className="income-progress"><div><strong>Recebimento das rendas</strong><b>{incomePercent}%</b></div><p>{money.format(receivedIncome)} de {money.format(predictedIncome)}</p><div className="progress-track"><span style={{ width: `${Math.min(incomePercent, 100)}%` }} /></div><footer><span><small>Recebido</small><strong>{money.format(receivedIncome)}</strong></span><span><small>A receber</small><strong>{money.format(predictedIncome - receivedIncome)}</strong></span></footer></article>
          <article className="expense-progress"><div><strong>Pagamento das despesas</strong><b>{expensePercent}%</b></div><p>{money.format(paidExpense)} de {money.format(predictedExpense)}</p><div className="progress-track"><span style={{ width: `${Math.min(expensePercent, 100)}%` }} /></div><footer><span><small>Pago</small><strong>{money.format(paidExpense)}</strong></span><span><small>A pagar</small><strong>{money.format(predictedExpense - paidExpense)}</strong></span></footer></article>
        </div>
      </section>

      <section className="finance-columns">
        <div className="panel-card transaction-card">
          <div className="section-title section-title-row"><div><span className="eyebrow">Entradas</span><h2>Rendas do mês</h2></div><button className="ghost-icon" onClick={() => openModal('income')}><Plus size={19} /></button></div>
          {state.finance.recurringIncomes.map(item => {
            const received = item.receivedMonths.includes(currentMonth);
            return <article className="transaction-row" key={item.id}><button className={`status-dot ${received ? 'paid' : ''}`} onClick={() => toggleRecurringIncome(item.id)}>{received && <Check size={14} />}</button><div><strong>{item.description}</strong><span>Todo dia {item.day} · renda mensal</span></div><b>{money.format(item.amount)}</b><button className="ghost-icon" onClick={() => openModal('edit-income', item.id)}><Pencil size={16} /></button></article>;
          })}
          {monthIncomes.map(item => <article className="transaction-row" key={item.id}><button className={`status-dot ${item.received ? 'paid' : ''}`} onClick={() => setState(current => ({ ...current, finance: { ...current.finance, incomes: current.finance.incomes.map(income => income.id === item.id ? { ...income, received: !income.received } : income) } }))}>{item.received && <Check size={14} />}</button><div><strong>{item.description}</strong><span>{dateFormatter.format(new Date(`${item.date}T12:00:00`))} · renda avulsa</span></div><b>{money.format(item.amount)}</b><button className="ghost-icon danger" onClick={() => setState(current => ({ ...current, finance: { ...current.finance, incomes: current.finance.incomes.filter(income => income.id !== item.id) } }))}><Trash2 size={16} /></button></article>)}
        </div>

        <div className="panel-card transaction-card">
          <div className="section-title section-title-row"><div><span className="eyebrow">Saídas</span><h2>Despesas do mês</h2></div><button className="ghost-icon" onClick={() => openModal('expense')}><Plus size={19} /></button></div>
          {monthExpenses.map(item => <article className="transaction-row" key={item.id}><button className={`status-dot ${item.paid ? 'paid' : 'expense'}`} onClick={() => setState(current => ({ ...current, finance: { ...current.finance, expenses: current.finance.expenses.map(expense => expense.id === item.id ? { ...expense, paid: !expense.paid } : expense) } }))}>{item.paid && <Check size={14} />}</button><div><strong>{item.description}</strong><span>{item.category} · vence {dateFormatter.format(new Date(`${item.dueDate}T12:00:00`))}</span></div><b>{money.format(item.amount)}</b><button className="ghost-icon danger" onClick={() => setState(current => ({ ...current, finance: { ...current.finance, expenses: current.finance.expenses.filter(expense => expense.id !== item.id) } }))}><Trash2 size={16} /></button></article>)}
          {!monthExpenses.length && <div className="compact-empty"><CircleDollarSign size={25} /><span><strong>Nenhuma despesa neste mês.</strong><small>Quando houver uma conta, ela aparecerá aqui.</small></span></div>}
        </div>
      </section>

      <section className="finance-columns assets-columns">
        <div className="panel-card"><div className="section-title section-title-row"><div><span className="eyebrow">Patrimônio</span><h2>Contas e carteiras</h2></div><button className="ghost-icon" onClick={() => openModal('account')}><Plus size={19} /></button></div><div className="account-list">{state.finance.accounts.map(account => <article key={account.id}><span style={{ background: account.color }}><Landmark size={19} /></span><div><strong>{account.name}</strong><small>Saldo disponível</small></div><b>{money.format(account.balance)}</b></article>)}{!state.finance.accounts.length && <div className="compact-empty"><Landmark size={25} /><span><strong>Nenhuma conta cadastrada.</strong><small>Adicione bancos, carteira ou dinheiro.</small></span></div>}</div></div>
        <div className="panel-card"><div className="section-title section-title-row"><div><span className="eyebrow">Crédito</span><h2>Cartões</h2></div><button className="ghost-icon" onClick={() => openModal('card')}><Plus size={19} /></button></div><div className="credit-card-list">{state.finance.cards.map(card => <article key={card.id} style={{ '--card-color': card.color } as React.CSSProperties}><CreditCard size={24} /><small>{card.bank}</small><strong>{card.holder}</strong><span>Limite {money.format(card.limit)}</span><em>Vence dia {card.dueDay}</em></article>)}{!state.finance.cards.length && <div className="compact-empty"><CreditCard size={25} /><span><strong>Nenhum cartão cadastrado.</strong><small>Cadastre para organizar limites e faturas.</small></span></div>}</div></div>
      </section>
    </div>
  );
}

function SettingsView({ state, user, setState, exportBackup, importRef, installApp, installReady }: { state: AppState; user: RoutineAppProps['user']; setState: React.Dispatch<React.SetStateAction<AppState>>; exportBackup: () => void; importRef: React.RefObject<HTMLInputElement | null>; installApp: () => Promise<void>; installReady: boolean }) {
  const colors = ['#ff7a3d', '#e84a5f', '#f59e0b', '#10b981', '#3b82f6', '#8b5cf6'];
  return (
    <div className="module-view settings-view">
      <PageHeading eyebrow="Sua conta" title="Perfil e configurações" description="Personalize o aplicativo e mantenha uma cópia segura dos seus dados." />
      <section className="settings-grid">
        <article className="panel-card profile-settings"><div className="settings-title"><span className="settings-icon"><UserRound size={21} /></span><div><h2>Seu perfil</h2><p>Nome exibido no aplicativo.</p></div></div><label>Nome de exibição<input value={state.profile.displayName} onChange={event => setState(current => ({ ...current, profile: { ...current.profile, displayName: event.target.value } }))} /></label><div className="account-identity"><span>{initials(state.profile.displayName)}</span><div><strong>{user.fullName ?? user.displayName}</strong><small>{user.email}</small></div></div></article>
        <article className="panel-card"><div className="settings-title"><span className="settings-icon"><Sun size={21} /></span><div><h2>Aparência</h2><p>Escolha como prefere visualizar.</p></div></div><div className="theme-options"><button className={state.profile.theme === 'dark' ? 'active' : ''} onClick={() => setState(current => ({ ...current, profile: { ...current.profile, theme: 'dark' } }))}><Moon size={20} /><span><strong>Escuro</strong><small>Azul-marinho</small></span></button><button className={state.profile.theme === 'light' ? 'active' : ''} onClick={() => setState(current => ({ ...current, profile: { ...current.profile, theme: 'light' } }))}><Sun size={20} /><span><strong>Claro</strong><small>Leve e limpo</small></span></button></div></article>
        <article className="panel-card"><div className="settings-title"><span className="settings-icon"><Dumbbell size={21} /></span><div><h2>Cor dos treinos</h2><p>Deixe sua área de treino com sua identidade.</p></div></div><div className="color-picker">{colors.map(color => <button key={color} style={{ background: color }} className={state.profile.workoutColor === color ? 'active' : ''} onClick={() => setState(current => ({ ...current, profile: { ...current.profile, workoutColor: color } }))}>{state.profile.workoutColor === color && <Check size={17} />}</button>)}</div></article>
        <article className="panel-card"><div className="settings-title"><span className="settings-icon"><Download size={21} /></span><div><h2>Backup dos dados</h2><p>Exporte ou restaure toda a sua rotina.</p></div></div><div className="backup-actions"><button onClick={exportBackup}><Download size={18} /> Exportar backup</button><button onClick={() => importRef.current?.click()}><Upload size={18} /> Restaurar backup</button></div></article>
        <article className="panel-card install-settings"><div className="settings-title"><span className="settings-icon"><Smartphone size={21} /></span><div><h2>Instalar como aplicativo</h2><p>Abra em tela cheia no celular ou computador.</p></div></div><div className="install-devices"><span><Smartphone size={19} /><small>Android</small></span><span><Laptop size={19} /><small>Windows</small></span></div><button onClick={() => void installApp()}><Download size={18} /> {installReady ? 'Instalar neste dispositivo' : 'Ver como instalar'}</button></article>
      </section>
      <a className="signout-button" href="/signout-with-chatgpt?return_to=%2F"><LogOut size={19} /> Sair da conta</a>
    </div>
  );
}

function EmptyState({ icon, title, text, action, onAction }: { icon: React.ReactNode; title: string; text: string; action: string; onAction: () => void }) {
  return <div className="empty-state"><span>{icon}</span><strong>{title}</strong><p>{text}</p><button onClick={onAction}><Plus size={17} /> {action}</button></div>;
}

function Modal({ modal, state, selectedWorkoutId, onClose, onSubmit }: { modal: { type: ModalType; id?: string }; state: AppState; selectedWorkoutId: string; onClose: () => void; onSubmit: (event: FormEvent<HTMLFormElement>) => void }) {
  const editedIncome = state.finance.recurringIncomes.find(item => item.id === modal.id);
  const titles: Record<ModalType, string> = {
    subject: 'Nova matéria', flashcard: 'Novo flashcard', workout: 'Novo treino', exercise: 'Novo exercício', income: 'Nova renda', expense: 'Nova despesa', account: 'Nova conta', card: 'Novo cartão', 'edit-income': 'Editar renda mensal',
  };
  return (
    <div className="modal-backdrop" onMouseDown={event => event.target === event.currentTarget && onClose()}>
      <form className="app-modal" onSubmit={onSubmit}>
        <header><div><span className="eyebrow">Adicionar à rotina</span><h2>{titles[modal.type]}</h2></div><button type="button" onClick={onClose}><X size={21} /></button></header>
        <div className="modal-fields">
          {modal.type === 'subject' && <><label>Nome da matéria<input name="name" required placeholder="Ex.: Direito Constitucional" /></label><label>Cor de identificação<input name="color" type="color" defaultValue="#8b5cf6" /></label></>}
          {modal.type === 'flashcard' && <><label>Matéria<select name="subjectId" required defaultValue=""><option value="" disabled>Selecione</option>{state.study.subjects.map(subject => <option key={subject.id} value={subject.id}>{subject.name}</option>)}</select></label><label>Pergunta<textarea name="front" required placeholder="Digite a pergunta" /></label><label>Resposta<textarea name="back" required placeholder="Digite a resposta" /></label><label>Revisar em<input name="dueDate" type="date" defaultValue={today()} /></label></>}
          {modal.type === 'workout' && <><label>Nome do treino<input name="name" required placeholder="Ex.: Treino D" /></label><label>Foco<input name="focus" placeholder="Ex.: Ombros e abdômen" /></label><label>Dia da semana<select name="weekday" defaultValue="1">{weekdayNames.map((day, index) => <option key={day} value={index}>{day}</option>)}</select></label></>}
          {modal.type === 'exercise' && <><label>Treino<select name="workoutId" required defaultValue={selectedWorkoutId}>{state.training.workouts.map(workout => <option key={workout.id} value={workout.id}>{workout.name} · {workout.focus}</option>)}</select></label><label>Exercício<input name="name" required placeholder="Ex.: Crucifixo máquina" /></label><div className="field-row"><label>Séries<input name="sets" type="number" min="1" defaultValue="3" /></label><label>Repetições<input name="reps" defaultValue="10–12" /></label><label>Carga inicial<input name="weight" type="number" min="0" step="0.5" placeholder="0" /></label></div></>}
          {modal.type === 'income' && <><label>Descrição<input name="description" required placeholder="Ex.: Salário" /></label><label>Valor<input name="amount" type="number" min="0.01" step="0.01" required placeholder="0,00" /></label><label>Frequência<select name="frequency" defaultValue="monthly"><option value="monthly">Todo mês</option><option value="once">Somente uma vez</option></select></label><div className="field-row"><label>Dia fixo do mês<input name="day" type="number" min="1" max="31" defaultValue="5" /></label><label>Data avulsa<input name="date" type="date" defaultValue={today()} /></label></div><p className="field-hint">Para salário mensal, escolha “Todo mês” e informe apenas o dia. O mês será gerado automaticamente.</p></>}
          {modal.type === 'edit-income' && <><label>Descrição<input name="description" required defaultValue={editedIncome?.description} /></label><label>Valor mensal<input name="amount" type="number" min="0.01" step="0.01" required defaultValue={editedIncome?.amount} /></label><label>Dia fixo do recebimento<input name="day" type="number" min="1" max="31" required defaultValue={editedIncome?.day} /></label><p className="field-hint">A mudança valerá para os próximos meses. Os status já registrados serão preservados.</p></>}
          {modal.type === 'expense' && <><label>Descrição<input name="description" required placeholder="Ex.: Internet" /></label><label>Categoria<select name="category" defaultValue="Conta fixa"><option>Conta fixa</option><option>Alimentação</option><option>Transporte</option><option>Saúde</option><option>Lazer</option><option>Cartão</option><option>Outros</option></select></label><div className="field-row"><label>Valor<input name="amount" type="number" min="0.01" step="0.01" required /></label><label>Vencimento<input name="dueDate" type="date" defaultValue={today()} required /></label></div></>}
          {modal.type === 'account' && <><label>Nome da conta<input name="name" required placeholder="Ex.: Inter" /></label><label>Saldo atual<input name="balance" type="number" step="0.01" defaultValue="0" /></label><label>Cor<input name="color" type="color" defaultValue="#10b981" /></label></>}
          {modal.type === 'card' && <><label>Banco ou cartão<input name="bank" required placeholder="Ex.: Nubank" /></label><label>Nome no cartão<input name="holder" defaultValue={state.profile.displayName} /></label><label>Limite<input name="limit" type="number" min="0" step="0.01" /></label><div className="field-row"><label>Fechamento<input name="closingDay" type="number" min="1" max="31" defaultValue="1" /></label><label>Vencimento<input name="dueDay" type="number" min="1" max="31" defaultValue="10" /></label><label>Cor<input name="color" type="color" defaultValue="#7454f6" /></label></div></>}
        </div>
        <footer><button className="cancel-button" type="button" onClick={onClose}>Cancelar</button><button className="modal-save" type="submit">Salvar</button></footer>
      </form>
    </div>
  );
}
