import { redirect } from 'next/navigation';
import { chatGPTSignInPath } from '../chatgpt-auth';
import { RoutineApp } from '../components/routine-app';
import { getCurrentUser } from '../lib/current-user';

export const dynamic = 'force-dynamic';

export default async function Dashboard() {
  const user = await getCurrentUser();
  if (!user) redirect(chatGPTSignInPath('/dashboard'));

  return <RoutineApp user={user} />;
}
