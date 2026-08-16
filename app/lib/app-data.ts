export type ThemeMode = 'dark' | 'light';

export type StudySubject = {
  id: string;
  name: string;
  code: string;
  professor: string;
  room: string;
  color: string;
  description: string;
  semester: string;
  cards: number;
  questions: number;
  summaries: number;
  sessions: number;
  archived: boolean;
};

export type ClassPeriod = { id: string; label: string; startTime: string; endTime: string };
export type ClassSchedule = { id: string; subjectId: string; weekday: number; startTime: string; endTime: string; room: string; professor: string; notes: string };
export type AssessmentKind = 'Prova' | 'Trabalho' | 'Projeto' | 'Seminário' | 'Atividade';
export type AssessmentStatus = 'scheduled' | 'studying' | 'completed';
export type Assessment = { id: string; subjectId: string; title: string; kind: AssessmentKind; date: string; time: string; content: string; notes: string; weight: number; grade: number | null; maxGrade: number; reminderDays: number; status: AssessmentStatus };
export type StudyAttachment = { id: string; storageKey: string; name: string; contentType: string; size: number; url: string };
export type StudyNote = { id: string; subjectId: string; title: string; content: string; tags: string[]; favorite: boolean; attachments: StudyAttachment[]; createdAt: string; updatedAt: string };
export type StudyDeck = { id: string; subjectId: string; name: string; description: string; color: string; createdAt: string };

export type Flashcard = {
  id: string;
  subjectId: string;
  deckId: string;
  topic: string;
  front: string;
  back: string;
  dueDate: string;
  reviewed: boolean;
  createdAt: string;
  lastReviewedAt: string | null;
  intervalDays: number;
  repetitions: number;
  easeFactor: number;
  lapses: number;
};

export type QuestionResult = 'pending' | 'correct' | 'wrong';
export type StudyQuestion = { id: string; subjectId: string; topic: string; prompt: string; answer: string; explanation: string; source: string; difficulty: 'Fácil' | 'Média' | 'Difícil'; result: QuestionResult; answeredAt: string | null; createdAt: string };
export type StudySimulation = { id: string; title: string; subjectIds: string[]; questionCount: number; durationMinutes: number; correctAnswers: number | null; completedAt: string | null; elapsedSeconds: number; createdAt: string };
export type StudyTask = { id: string; subjectId: string; title: string; date: string; startTime: string; endTime: string; priority: 'Baixa' | 'Média' | 'Alta'; completed: boolean };
export type StudySession = { id: string; subjectId: string; date: string; durationMinutes: number; topic: string; notes: string };

export type WorkoutSetKind = 'Aquecimento' | 'Preparatória' | 'Trabalho' | 'Falha' | 'Drop set';
export type WorkoutSet = {
  id: string;
  kind: WorkoutSetKind;
  targetReps: string;
  targetWeight: number;
  actualReps: number | null;
  actualWeight: number;
  restSeconds: number;
  rpe: number | null;
  toFailure: boolean;
  completed: boolean;
  notes: string;
};
export type Exercise = {
  id: string;
  name: string;
  muscleGroup: string;
  equipment: string;
  notes: string;
  sets: number;
  reps: string;
  weight: number;
  completed: boolean;
  setDetails: WorkoutSet[];
};
export type Workout = {
  id: string;
  name: string;
  focus: string;
  weekday: number;
  color: string;
  notes: string;
  exercises: Exercise[];
};
export type ExerciseLog = {
  exerciseId: string;
  name: string;
  muscleGroup: string;
  sets: WorkoutSet[];
  activeSeconds: number;
  restSeconds: number;
  finished: boolean;
};
export type ActiveWorkoutSession = {
  id: string;
  workoutId: string;
  workoutName: string;
  date: string;
  startedAt: string;
  currentExerciseId: string | null;
  timerMode: 'exercise' | 'rest' | 'paused';
  modeStartedAt: string | null;
  exerciseLogs: ExerciseLog[];
  notes: string;
};
export type WorkoutSession = {
  id: string;
  workoutId: string;
  workoutName: string;
  date: string;
  startedAt: string;
  finishedAt: string;
  totalExerciseSeconds: number;
  totalRestSeconds: number;
  totalSeconds: number;
  totalVolume: number;
  exerciseLogs: ExerciseLog[];
  notes: string;
};
export type ExerciseLibraryItem = { id: string; name: string; muscleGroup: string; equipment: string; notes: string };
export type BodyMeasurement = { id: string; date: string; weight: number; bodyFat: number | null; waist: number | null; chest: number | null; arm: number | null; thigh: number | null; notes: string };
export type ProgressPhoto = { id: string; date: string; label: string; attachment: StudyAttachment };
export type CardioSession = { id: string; date: string; kind: string; durationMinutes: number; distanceKm: number | null; calories: number | null; notes: string };
export type WaterEntry = { id: string; date: string; liters: number };
export type RecurringIncome = {
  id: string;
  description: string;
  amount: number;
  day: number;
  category: string;
  accountId: string;
  active: boolean;
  startMonth: string;
  endMonth: string;
  receivedMonths: string[];
};
export type Income = {
  id: string;
  description: string;
  amount: number;
  date: string;
  category: string;
  accountId: string;
  notes: string;
  attachment: StudyAttachment | null;
  received: boolean;
};
export type Expense = {
  id: string;
  description: string;
  category: string;
  amount: number;
  dueDate: string;
  accountId: string;
  paymentMethod: string;
  notes: string;
  attachment: StudyAttachment | null;
  paidAt: string | null;
  paid: boolean;
};
export type RecurringExpense = {
  id: string;
  description: string;
  category: string;
  amount: number;
  day: number;
  accountId: string;
  active: boolean;
  startMonth: string;
  endMonth: string;
  paidMonths: string[];
  notes: string;
};
export type Account = {
  id: string;
  name: string;
  institution: string;
  kind: 'Conta corrente' | 'Carteira' | 'Dinheiro' | 'Poupança' | 'Investimento';
  balance: number;
  color: string;
  includeInTotal: boolean;
};
export type AccountTransaction = {
  id: string;
  kind: 'income' | 'expense' | 'transfer';
  accountId: string;
  destinationAccountId: string;
  description: string;
  amount: number;
  date: string;
  notes: string;
};
export type FinanceCard = {
  id: string;
  bank: string;
  holder: string;
  brand: string;
  lastDigits: string;
  limit: number;
  closingDay: number;
  dueDay: number;
  color: string;
  active: boolean;
};
export type CardPurchase = {
  id: string;
  cardId: string;
  description: string;
  category: string;
  totalAmount: number;
  purchaseDate: string;
  installmentCount: number;
  paidInstallments: string[];
  notes: string;
  attachment: StudyAttachment | null;
};
export type FinanceDebt = {
  id: string;
  name: string;
  kind: 'Dívida' | 'Empréstimo' | 'Financiamento';
  creditor: string;
  totalAmount: number;
  installmentAmount: number;
  installmentCount: number;
  startDate: string;
  dueDay: number;
  interestRate: number;
  accountId: string;
  paidInstallments: string[];
  notes: string;
  active: boolean;
};
export type FinanceCategory = { id: string; name: string; kind: 'income' | 'expense'; color: string; bucket: 'Necessidades' | 'Desejos' | 'Metas' };
export type FinanceBudget = { id: string; category: string; monthlyLimit: number; alertPercent: number };
export type Investment = { id: string; name: string; kind: string; institution: string; currentValue: number; investedValue: number; monthlyContribution: number; color: string; updatedAt: string };

export type AppState = {
  version: 2;
  profile: { displayName: string; theme: ThemeMode; workoutColor: string };
  study: {
    academic: { course: string; institution: string; semester: string; semesterStart: string; semesterEnd: string };
    subjects: StudySubject[];
    classPeriods: ClassPeriod[];
    schedule: ClassSchedule[];
    assessments: Assessment[];
    notes: StudyNote[];
    decks: StudyDeck[];
    flashcards: Flashcard[];
    questions: StudyQuestion[];
    simulations: StudySimulation[];
    tasks: StudyTask[];
    sessions: StudySession[];
    questionsToday: number;
    questionGoal: number;
    weeklyGoalMinutes: number;
    studyDates: string[];
  };
  training: {
    workouts: Workout[];
    activeSession: ActiveWorkoutSession | null;
    sessions: WorkoutSession[];
    exerciseLibrary: ExerciseLibraryItem[];
    measurements: BodyMeasurement[];
    progressPhotos: ProgressPhoto[];
    cardioSessions: CardioSession[];
    waterEntries: WaterEntry[];
    completedDates: string[];
    waterLiters: number;
    waterGoal: number;
    defaultRestSeconds: number;
  };
  finance: {
    recurringIncomes: RecurringIncome[];
    incomes: Income[];
    expenses: Expense[];
    recurringExpenses: RecurringExpense[];
    accounts: Account[];
    accountTransactions: AccountTransaction[];
    cards: FinanceCard[];
    cardPurchases: CardPurchase[];
    debts: FinanceDebt[];
    categories: FinanceCategory[];
    budgets: FinanceBudget[];
    investments: Investment[];
    planning: { needsPercent: number; wantsPercent: number; goalsPercent: number };
  };
};

const todayKey = () => {
  const date = new Date();
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
};
const nowIso = () => new Date().toISOString();

export function monthKey(date = new Date()) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
}

export function createInitialState(displayName: string): AppState {
  return {
    version: 2,
    profile: { displayName: displayName.split(' ')[0] || 'Usuário', theme: 'dark', workoutColor: '#ff7a3d' },
    study: {
      academic: { course: '', institution: '', semester: '', semesterStart: '', semesterEnd: '' },
      subjects: [],
      classPeriods: [],
      schedule: [], assessments: [], notes: [], decks: [], flashcards: [], questions: [], simulations: [], tasks: [], sessions: [],
      questionsToday: 0, questionGoal: 20, weeklyGoalMinutes: 600, studyDates: [],
    },
    training: {
      workouts: [],
      activeSession: null,
      sessions: [],
      exerciseLibrary: [
        { id: 'library-supino', name: 'Supino reto', muscleGroup: 'Peito', equipment: 'Barra', notes: '' },
        { id: 'library-agachamento', name: 'Agachamento livre', muscleGroup: 'Quadríceps', equipment: 'Barra', notes: '' },
        { id: 'library-remada', name: 'Remada baixa', muscleGroup: 'Costas', equipment: 'Polia', notes: '' },
        { id: 'library-desenvolvimento', name: 'Desenvolvimento', muscleGroup: 'Ombros', equipment: 'Halteres', notes: '' },
      ],
      measurements: [], progressPhotos: [], cardioSessions: [], waterEntries: [],
      completedDates: [], waterLiters: 0, waterGoal: 2.5, defaultRestSeconds: 90,
    },
    finance: {
      recurringIncomes: [],
      incomes: [],
      expenses: [],
      recurringExpenses: [],
      accounts: [],
      accountTransactions: [],
      cards: [],
      cardPurchases: [],
      debts: [],
      categories: [
        { id: 'category-salary', name: 'Salário', kind: 'income', color: '#20c997', bucket: 'Metas' },
        { id: 'category-extra', name: 'Renda extra', kind: 'income', color: '#3b82f6', bucket: 'Metas' },
        { id: 'category-home', name: 'Moradia', kind: 'expense', color: '#8b5cf6', bucket: 'Necessidades' },
        { id: 'category-food', name: 'Alimentação', kind: 'expense', color: '#f59e0b', bucket: 'Necessidades' },
        { id: 'category-transport', name: 'Transporte', kind: 'expense', color: '#3b82f6', bucket: 'Necessidades' },
        { id: 'category-health', name: 'Saúde', kind: 'expense', color: '#ef476f', bucket: 'Necessidades' },
        { id: 'category-leisure', name: 'Lazer', kind: 'expense', color: '#ec4899', bucket: 'Desejos' },
        { id: 'category-study', name: 'Estudos', kind: 'expense', color: '#14b8a6', bucket: 'Metas' },
        { id: 'category-other', name: 'Outros', kind: 'expense', color: '#64748b', bucket: 'Desejos' },
      ],
      budgets: [],
      investments: [],
      planning: { needsPercent: 50, wantsPercent: 30, goalsPercent: 20 },
    },
  };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return Boolean(value) && typeof value === 'object' && !Array.isArray(value);
}

function asArray<T>(value: unknown, fallback: T[] = []): T[] {
  return Array.isArray(value) ? value as T[] : fallback;
}

export function mergeState(value: unknown, displayName: string): AppState {
  const fallback = createInitialState(displayName);
  if (!isRecord(value) || (value.version !== 1 && value.version !== 2)) return fallback;

  const profile = isRecord(value.profile) ? value.profile : {};
  const legacyStudy = isRecord(value.study) ? value.study : {};
  const training = isRecord(value.training) ? value.training : {};
  const finance = isRecord(value.finance) ? value.finance : {};
  const academic = isRecord(legacyStudy.academic) ? legacyStudy.academic : {};
  const subjects = asArray<Partial<StudySubject>>(legacyStudy.subjects).map(subject => ({
    id: String(subject.id ?? uid('subject')), name: String(subject.name ?? 'Matéria'), code: String(subject.code ?? ''),
    professor: String(subject.professor ?? ''), room: String(subject.room ?? ''), color: String(subject.color ?? '#8b5cf6'),
    description: String(subject.description ?? ''), semester: String(subject.semester ?? academic.semester ?? ''),
    cards: Number(subject.cards ?? 0), questions: Number(subject.questions ?? 0), summaries: Number(subject.summaries ?? 0),
    sessions: Number(subject.sessions ?? 0), archived: Boolean(subject.archived),
  }));
  const flashcards = asArray<Partial<Flashcard>>(legacyStudy.flashcards).map(card => ({
    id: String(card.id ?? uid('card')), subjectId: String(card.subjectId ?? ''), deckId: String(card.deckId ?? ''),
    topic: String(card.topic ?? ''), front: String(card.front ?? ''), back: String(card.back ?? ''),
    dueDate: String(card.dueDate ?? todayKey()), reviewed: Boolean(card.reviewed), createdAt: String(card.createdAt ?? nowIso()),
    lastReviewedAt: card.lastReviewedAt ? String(card.lastReviewedAt) : null, intervalDays: Number(card.intervalDays ?? 0),
    repetitions: Number(card.repetitions ?? 0), easeFactor: Number(card.easeFactor ?? 2.5), lapses: Number(card.lapses ?? 0),
  }));

  return {
    version: 2,
    profile: {
      ...fallback.profile,
      displayName: String(profile.displayName ?? fallback.profile.displayName),
      theme: profile.theme === 'light' ? 'light' : 'dark',
      workoutColor: String(profile.workoutColor ?? fallback.profile.workoutColor),
    },
    study: {
      ...fallback.study,
      academic: {
        ...fallback.study.academic,
        course: String(academic.course ?? fallback.study.academic.course), institution: String(academic.institution ?? fallback.study.academic.institution),
        semester: String(academic.semester ?? ''), semesterStart: String(academic.semesterStart ?? ''), semesterEnd: String(academic.semesterEnd ?? ''),
      },
      subjects,
      classPeriods: asArray<ClassPeriod>(legacyStudy.classPeriods, fallback.study.classPeriods),
      schedule: asArray<ClassSchedule>(legacyStudy.schedule), assessments: asArray<Assessment>(legacyStudy.assessments),
      notes: asArray<StudyNote>(legacyStudy.notes), decks: asArray<StudyDeck>(legacyStudy.decks), flashcards,
      questions: asArray<StudyQuestion>(legacyStudy.questions), simulations: asArray<StudySimulation>(legacyStudy.simulations),
      tasks: asArray<StudyTask>(legacyStudy.tasks), sessions: asArray<StudySession>(legacyStudy.sessions),
      questionsToday: Number(legacyStudy.questionsToday ?? 0), questionGoal: Number(legacyStudy.questionGoal ?? 20),
      weeklyGoalMinutes: Number(legacyStudy.weeklyGoalMinutes ?? 600), studyDates: asArray<string>(legacyStudy.studyDates),
    },
    training: {
      ...fallback.training,
      workouts: normalizeWorkouts(training.workouts, fallback.training.workouts),
      activeSession: isRecord(training.activeSession) ? training.activeSession as unknown as ActiveWorkoutSession : null,
      sessions: asArray<WorkoutSession>(training.sessions),
      exerciseLibrary: asArray<ExerciseLibraryItem>(training.exerciseLibrary, fallback.training.exerciseLibrary),
      measurements: asArray<BodyMeasurement>(training.measurements),
      progressPhotos: asArray<ProgressPhoto>(training.progressPhotos),
      cardioSessions: asArray<CardioSession>(training.cardioSessions),
      waterEntries: asArray<WaterEntry>(training.waterEntries),
      completedDates: asArray<string>(training.completedDates),
      waterLiters: Number(training.waterLiters ?? fallback.training.waterLiters), waterGoal: Number(training.waterGoal ?? fallback.training.waterGoal),
      defaultRestSeconds: Number(training.defaultRestSeconds ?? fallback.training.defaultRestSeconds),
    },
    finance: normalizeFinance(finance, fallback.finance),
  };
}

export function uid(prefix: string) {
  return `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}

export function ensureToday(values: string[]) {
  const today = todayKey();
  return values.includes(today) ? values : [...values, today];
}

export function createDefaultSets(count = 3, reps = '8–12', weight = 0): WorkoutSet[] {
  return Array.from({ length: Math.max(1, count) }, (_, index) => ({
    id: uid('set'),
    kind: index === 0 ? 'Aquecimento' : 'Trabalho',
    targetReps: reps,
    targetWeight: weight,
    actualReps: null,
    actualWeight: weight,
    restSeconds: index === 0 ? 60 : 90,
    rpe: null,
    toFailure: false,
    completed: false,
    notes: '',
  }));
}

function normalizeWorkouts(value: unknown, fallback: Workout[]): Workout[] {
  return asArray<Partial<Workout>>(value, fallback).map((workout, workoutIndex) => ({
    id: String(workout.id ?? uid('workout')),
    name: String(workout.name ?? 'Treino'),
    focus: String(workout.focus ?? ''),
    weekday: Number(workout.weekday ?? 1),
    color: String(workout.color ?? ['#ff7a3d', '#3b82f6', '#a855f7'][workoutIndex % 3]),
    notes: String(workout.notes ?? ''),
    exercises: asArray<Partial<Exercise>>(workout.exercises).map(exercise => {
      const count = Number(exercise.sets ?? 3);
      const reps = String(exercise.reps ?? '8–12');
      const weight = Number(exercise.weight ?? 0);
      return {
        id: String(exercise.id ?? uid('exercise')),
        name: String(exercise.name ?? 'Exercício'),
        muscleGroup: String(exercise.muscleGroup ?? ''),
        equipment: String(exercise.equipment ?? ''),
        notes: String(exercise.notes ?? ''),
        sets: count,
        reps,
        weight,
        completed: Boolean(exercise.completed),
        setDetails: asArray<WorkoutSet>(exercise.setDetails, createDefaultSets(count, reps, weight)),
      };
    }),
  }));
}

function normalizeFinance(value: Record<string, unknown>, fallback: AppState['finance']): AppState['finance'] {
  const recurringIncomes = asArray<Partial<RecurringIncome>>(value.recurringIncomes, fallback.recurringIncomes).map(item => ({
    id: String(item.id ?? uid('income')), description: String(item.description ?? 'Renda mensal'), amount: Number(item.amount ?? 0),
    day: Number(item.day ?? 1), category: String(item.category ?? 'Salário'), accountId: String(item.accountId ?? ''),
    active: item.active === undefined ? true : Boolean(item.active), startMonth: String(item.startMonth ?? ''), endMonth: String(item.endMonth ?? ''),
    receivedMonths: asArray<string>(item.receivedMonths),
  }));
  const incomes = asArray<Partial<Income>>(value.incomes).map(item => ({
    id: String(item.id ?? uid('income')), description: String(item.description ?? 'Renda'), amount: Number(item.amount ?? 0),
    date: String(item.date ?? todayKey()), category: String(item.category ?? 'Renda extra'), accountId: String(item.accountId ?? ''),
    notes: String(item.notes ?? ''), attachment: item.attachment ?? null, received: Boolean(item.received),
  }));
  const expenses = asArray<Partial<Expense>>(value.expenses).map(item => ({
    id: String(item.id ?? uid('expense')), description: String(item.description ?? 'Despesa'), category: String(item.category ?? 'Outros'),
    amount: Number(item.amount ?? 0), dueDate: String(item.dueDate ?? todayKey()), accountId: String(item.accountId ?? ''),
    paymentMethod: String(item.paymentMethod ?? ''), notes: String(item.notes ?? ''), attachment: item.attachment ?? null,
    paidAt: item.paidAt ? String(item.paidAt) : null, paid: Boolean(item.paid),
  }));
  const accounts = asArray<Partial<Account>>(value.accounts).map(item => ({
    id: String(item.id ?? uid('account')), name: String(item.name ?? 'Conta'), institution: String(item.institution ?? item.name ?? ''),
    kind: (item.kind ?? 'Conta corrente') as Account['kind'], balance: Number(item.balance ?? 0), color: String(item.color ?? '#10b981'),
    includeInTotal: item.includeInTotal === undefined ? true : Boolean(item.includeInTotal),
  }));
  const cards = asArray<Partial<FinanceCard>>(value.cards).map(item => ({
    id: String(item.id ?? uid('card')), bank: String(item.bank ?? 'Cartão'), holder: String(item.holder ?? ''),
    brand: String(item.brand ?? 'Mastercard'), lastDigits: String(item.lastDigits ?? ''), limit: Number(item.limit ?? 0),
    closingDay: Number(item.closingDay ?? 1), dueDay: Number(item.dueDay ?? 10), color: String(item.color ?? '#7454f6'),
    active: item.active === undefined ? true : Boolean(item.active),
  }));
  const planning = isRecord(value.planning) ? value.planning : {};
  return {
    recurringIncomes,
    incomes,
    expenses,
    recurringExpenses: asArray<RecurringExpense>(value.recurringExpenses),
    accounts,
    accountTransactions: asArray<AccountTransaction>(value.accountTransactions),
    cards,
    cardPurchases: asArray<CardPurchase>(value.cardPurchases),
    debts: asArray<FinanceDebt>(value.debts),
    categories: asArray<FinanceCategory>(value.categories, fallback.categories),
    budgets: asArray<FinanceBudget>(value.budgets),
    investments: asArray<Investment>(value.investments),
    planning: {
      needsPercent: Number(planning.needsPercent ?? fallback.planning.needsPercent),
      wantsPercent: Number(planning.wantsPercent ?? fallback.planning.wantsPercent),
      goalsPercent: Number(planning.goalsPercent ?? fallback.planning.goalsPercent),
    },
  };
}
