import { Activity, ArrowRight, BookOpen, Dumbbell, ShieldCheck, WalletCards } from 'lucide-react';
import { redirect } from 'next/navigation';
import { chatGPTSignInPath, getChatGPTUser } from './chatgpt-auth';

export const dynamic = 'force-dynamic';

export default async function Home() {
  const user = await getChatGPTUser();
  if (user) redirect('/dashboard');

  return (
    <main className="login-page">
      <div className="login-ambient login-ambient-one" />
      <div className="login-ambient login-ambient-two" />

      <section className="login-showcase">
        <div className="brand-lockup">
          <span className="brand-mark"><Activity size={27} strokeWidth={2.4} /></span>
          <span>
            <strong>My Routine Active</strong>
            <small>Sua vida em movimento</small>
          </span>
        </div>

        <div className="login-copy">
          <span className="eyebrow">Mente · Corpo · Organização</span>
          <h1>Uma rotina mais leve começa com tudo no lugar.</h1>
          <p>Estudos, treinos e finanças reunidos em um aplicativo pensado para acompanhar seu dia de verdade.</p>
        </div>

        <div className="login-module-preview">
          <article className="mini-module study-mini">
            <BookOpen size={22} />
            <span><strong>Estudos</strong><small>Foco e constância</small></span>
          </article>
          <article className="mini-module training-mini">
            <Dumbbell size={22} />
            <span><strong>Treinos</strong><small>Evolução diária</small></span>
          </article>
          <article className="mini-module finance-mini">
            <WalletCards size={22} />
            <span><strong>Finanças</strong><small>Controle tranquilo</small></span>
          </article>
        </div>
      </section>

      <section className="login-panel-wrap">
        <div className="login-panel">
          <div className="login-icon"><Activity size={30} /></div>
          <span className="eyebrow">Bem-vindo</span>
          <h2>Entre na sua rotina</h2>
          <p>Seus dados ficam associados à sua conta e disponíveis sempre que você voltar.</p>

          <a className="primary-login-button" href={chatGPTSignInPath('/dashboard')}>
            Entrar com ChatGPT
            <ArrowRight size={20} />
          </a>

          <div className="login-security">
            <ShieldCheck size={18} />
            <span>Acesso protegido e dados individuais</span>
          </div>
        </div>
      </section>
    </main>
  );
}
